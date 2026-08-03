import { createClient } from "npm:@supabase/supabase-js@2.101.1";

import { corsHeaders, withCors } from "../_shared/cors.ts";

const maxSignedPdfBytes = 60 * 1024 * 1024;
const derivedBucket = "engineering-derived";

Deno.serve((request) =>
  withCors(request, async () => {
    if (request.method === "OPTIONS") {
      return new Response("ok", { headers: corsHeaders });
    }
    if (request.method !== "POST") {
      return jsonResponse({ error: "method_not_allowed" }, 405);
    }

    try {
      const body = await readJson(request);
      const action = text(body.action) || "request";
      if (action === "callback") {
        return await completeSignature(request, body);
      }
      if (action === "request") {
        return await requestSignature(request, body);
      }
      throw new HttpError(400, "invalid_action", "Ação PAdES inválida.");
    } catch (error) {
      if (error instanceof HttpError) {
        return jsonResponse(
          { error: error.code, message: error.message },
          error.status,
        );
      }
      const details = error instanceof Error ? error.message : String(error);
      const response: Record<string, unknown> = {
        error: "pades_gateway_failed",
        message: "Não foi possível processar a assinatura digital.",
      };
      if (Deno.env.get("GRANITH_DEBUG_ERRORS") === "true") {
        response.details = details;
      }
      return jsonResponse(response, 500);
    }
  })
);

async function requestSignature(
  request: Request,
  body: Record<string, unknown>,
) {
  const userClient = await authorizedUserClient(request);
  const revisionId = requiredText(body.revisionId, "revisionId");
  const policy = text(body.policy) || "PAdES-AD-RB";

  const { data: requestId, error: rpcError } = await userClient.rpc(
    "request_engineering_signature",
    {
      revision_id: revisionId,
      signature_policy: policy,
      signature_provider: text(body.provider) || "external",
    },
  );
  if (rpcError || !requestId) {
    throw new HttpError(
      400,
      "signature_request_rejected",
      rpcError?.message ?? "A assinatura não pôde ser solicitada.",
    );
  }

  const providerUrl = text(Deno.env.get("PADES_PROVIDER_URL"));
  const providerToken = text(Deno.env.get("PADES_PROVIDER_TOKEN"));
  if (!providerUrl || !providerToken) {
    return jsonResponse(
      {
        requestId,
        status: "queued",
        providerConfigured: false,
        message:
          "Solicitação registrada. Configure o provedor PAdES para despachar a assinatura.",
      },
      202,
    );
  }

  const admin = adminClient();
  const signatureRequest = await findSignatureRequest(admin, String(requestId));
  const revision = await findRevision(
    admin,
    text(signatureRequest.documentRevisionId),
  );
  const { data: signedUrl, error: signedUrlError } = await admin.storage
    .from("engineering-documents")
    .createSignedUrl(text(revision.filePath), 15 * 60);
  if (signedUrlError || !signedUrl?.signedUrl) {
    await markFailed(
      admin,
      String(requestId),
      "source_url_failed",
      signedUrlError?.message ?? "Não foi possível liberar o PDF ao provedor.",
    );
    throw new HttpError(
      502,
      "source_url_failed",
      "Não foi possível preparar o arquivo para assinatura.",
    );
  }

  const callbackUrl = `${
    requireEnv("SUPABASE_URL")
  }/functions/v1/engineering_pades`;
  const providerResponse = await fetch(providerUrl, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${providerToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      requestId,
      sourceUrl: signedUrl.signedUrl,
      callbackUrl,
      callbackAction: "callback",
      callbackHeader: "x-granith-pades-token",
      policy: text(signatureRequest.policy),
      policyOid: text(signatureRequest.policyOid),
      fileName: text(revision.originalFileName),
    }),
  });

  const providerBody = await providerResponse.json().catch(() => ({}));
  if (!providerResponse.ok) {
    await markFailed(
      admin,
      String(requestId),
      "provider_rejected",
      text(providerBody.message) || `HTTP ${providerResponse.status}`,
    );
    throw new HttpError(
      502,
      "provider_rejected",
      "O provedor recusou a solicitação de assinatura.",
    );
  }

  const providerRequestId = text(providerBody.requestId) ||
    text(providerBody.id) || null;
  const { error: updateError } = await admin
    .from("engineering_signature_requests")
    .update({
      status: "awaitingProvider",
      providerRequestId,
      updatedAt: new Date().toISOString(),
      errorCode: null,
      errorMessage: null,
    })
    .eq("id", requestId);
  if (updateError) throw updateError;

  return jsonResponse({
    requestId,
    providerRequestId,
    status: "awaitingProvider",
    providerConfigured: true,
  });
}

async function completeSignature(
  request: Request,
  body: Record<string, unknown>,
) {
  const configuredSecret = requireEnv("PADES_WEBHOOK_SECRET");
  const receivedSecret = request.headers.get("x-granith-pades-token") ?? "";
  if (!constantTimeEquals(configuredSecret, receivedSecret)) {
    throw new HttpError(401, "invalid_webhook_secret", "Webhook inválido.");
  }

  const requestId = requiredText(body.requestId, "requestId");
  const bytes = await loadSignedPdf(body);
  if (bytes.length === 0 || bytes.length > maxSignedPdfBytes) {
    throw new HttpError(
      413,
      "signed_pdf_size_invalid",
      "PDF assinado vazio ou acima do limite permitido.",
    );
  }
  if (!startsWithPdfHeader(bytes)) {
    throw new HttpError(
      422,
      "signed_pdf_invalid",
      "O retorno do provedor não é um PDF válido.",
    );
  }

  const admin = adminClient();
  const signatureRequest = await findSignatureRequest(admin, requestId);
  if (text(signatureRequest.status) === "completed") {
    return jsonResponse({ requestId, status: "completed", idempotent: true });
  }
  const revision = await findRevision(
    admin,
    text(signatureRequest.documentRevisionId),
  );
  const digest = await sha256Hex(bytes);
  const filePath =
    `${text(signatureRequest.projectId)}/${
      text(signatureRequest.documentId)
    }/` +
    `${text(signatureRequest.documentRevisionId)}/signed/${requestId}.pdf`;

  const { error: uploadError } = await admin.storage
    .from(derivedBucket)
    .upload(filePath, bytes, {
      contentType: "application/pdf",
      upsert: false,
    });
  if (uploadError && !uploadError.message.toLowerCase().includes("exists")) {
    throw uploadError;
  }

  const certificate = asRecord(body.certificate);
  const completedAt = new Date().toISOString();
  const { error: updateError } = await admin
    .from("engineering_signature_requests")
    .update({
      status: "completed",
      signedFilePath: filePath,
      signedSha256: digest,
      certificateSubject: nullableText(certificate.subject),
      certificateSerial: nullableText(certificate.serial),
      certificateIssuer: nullableText(certificate.issuer),
      certificateValidFrom: nullableText(certificate.validFrom),
      certificateValidTo: nullableText(certificate.validTo),
      completedAt,
      updatedAt: completedAt,
      errorCode: null,
      errorMessage: null,
    })
    .eq("id", requestId);
  if (updateError) throw updateError;

  await admin.from("engineering_document_review_events").insert({
    projectId: text(signatureRequest.projectId),
    documentId: text(signatureRequest.documentId),
    documentRevisionId: text(signatureRequest.documentRevisionId),
    decision: "signatureCompleted",
    comment: `${text(signatureRequest.policy)} · SHA-256 ${digest}`,
    actorUserId: "pades-provider",
  });

  return jsonResponse({
    requestId,
    revisionId: text(revision.id),
    status: "completed",
    signedSha256: digest,
  });
}

async function loadSignedPdf(body: Record<string, unknown>) {
  const encodedPdf = text(body.signedPdfBase64);
  if (encodedPdf) return decodeBase64(encodedPdf);

  const signedPdfUrl = requiredText(body.signedPdfUrl, "signedPdfUrl");
  const uri = new URL(signedPdfUrl);
  if (uri.protocol !== "https:") {
    throw new HttpError(
      400,
      "signed_pdf_url_invalid",
      "A URL do PDF assinado deve usar HTTPS.",
    );
  }

  const providerOrigin = new URL(requireEnv("PADES_PROVIDER_URL")).origin;
  const allowedOrigin = text(Deno.env.get("PADES_ALLOWED_DOWNLOAD_ORIGIN")) ||
    providerOrigin;
  if (uri.origin !== allowedOrigin) {
    throw new HttpError(
      403,
      "signed_pdf_origin_denied",
      "A origem do PDF assinado não pertence ao provedor configurado.",
    );
  }

  const response = await fetch(uri, {
    headers: {
      "Authorization": `Bearer ${requireEnv("PADES_PROVIDER_TOKEN")}`,
    },
  });
  if (!response.ok) {
    throw new HttpError(
      502,
      "signed_pdf_download_failed",
      "O provedor não liberou o PDF assinado.",
    );
  }
  const declaredLength = Number(response.headers.get("content-length") ?? 0);
  if (declaredLength > maxSignedPdfBytes) {
    throw new HttpError(
      413,
      "signed_pdf_size_invalid",
      "PDF assinado acima do limite permitido.",
    );
  }
  return new Uint8Array(await response.arrayBuffer());
}

async function authorizedUserClient(request: Request) {
  const authorization = request.headers.get("Authorization");
  if (!authorization) {
    throw new HttpError(401, "missing_authorization", "Sessão ausente.");
  }
  const client = createClient(
    requireEnv("SUPABASE_URL"),
    requireEnv("SUPABASE_ANON_KEY"),
    {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    },
  );
  const { data, error } = await client.auth.getUser();
  if (error || !data.user) {
    throw new HttpError(401, "invalid_session", "Sessão inválida.");
  }
  return client;
}

function adminClient() {
  return createClient(
    requireEnv("SUPABASE_URL"),
    requireEnv("SUPABASE_SERVICE_ROLE_KEY"),
    { auth: { persistSession: false, autoRefreshToken: false } },
  );
}

async function findSignatureRequest(
  admin: ReturnType<typeof createClient<any, "public">>,
  requestId: string,
) {
  const { data, error } = await admin
    .from("engineering_signature_requests")
    .select()
    .eq("id", requestId)
    .maybeSingle();
  if (error || !data) {
    throw new HttpError(
      404,
      "signature_request_not_found",
      "Solicitação não encontrada.",
    );
  }
  return data as Record<string, unknown>;
}

async function findRevision(
  admin: ReturnType<typeof createClient<any, "public">>,
  revisionId: string,
) {
  const { data, error } = await admin
    .from("engineering_document_revisions")
    .select()
    .eq("id", revisionId)
    .maybeSingle();
  if (error || !data) {
    throw new HttpError(404, "revision_not_found", "Revisão não encontrada.");
  }
  return data as Record<string, unknown>;
}

async function markFailed(
  admin: ReturnType<typeof createClient<any, "public">>,
  requestId: string,
  code: string,
  message: string,
) {
  await admin
    .from("engineering_signature_requests")
    .update({
      status: "failed",
      errorCode: code,
      errorMessage: message.slice(0, 1000),
      updatedAt: new Date().toISOString(),
    })
    .eq("id", requestId);
}

async function sha256Hex(bytes: Uint8Array) {
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)]
    .map((value) => value.toString(16).padStart(2, "0"))
    .join("");
}

function decodeBase64(value: string) {
  const normalized = value.includes(",") ? value.split(",").pop()! : value;
  const binary = atob(normalized);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index += 1) {
    bytes[index] = binary.charCodeAt(index);
  }
  return bytes;
}

function startsWithPdfHeader(bytes: Uint8Array) {
  return bytes.length >= 5 &&
    bytes[0] === 0x25 &&
    bytes[1] === 0x50 &&
    bytes[2] === 0x44 &&
    bytes[3] === 0x46 &&
    bytes[4] === 0x2d;
}

function constantTimeEquals(left: string, right: string) {
  const encoder = new TextEncoder();
  const a = encoder.encode(left);
  const b = encoder.encode(right);
  if (a.length !== b.length) return false;
  let result = 0;
  for (let index = 0; index < a.length; index += 1) {
    result |= a[index] ^ b[index];
  }
  return result === 0;
}

async function readJson(request: Request) {
  try {
    return asRecord(await request.json());
  } catch (_) {
    throw new HttpError(400, "invalid_json", "Corpo JSON inválido.");
  }
}

function asRecord(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) return {};
  return value as Record<string, unknown>;
}

function text(value: unknown) {
  return typeof value === "string" ? value.trim() : "";
}

function nullableText(value: unknown) {
  return text(value) || null;
}

function requiredText(value: unknown, field: string) {
  const result = text(value);
  if (!result) {
    throw new HttpError(400, "missing_field", `Campo obrigatório: ${field}.`);
  }
  return result;
}

function requireEnv(name: string) {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing environment variable: ${name}`);
  return value;
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

class HttpError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
  ) {
    super(message);
  }
}
