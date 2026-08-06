import { createClient } from 'npm:@supabase/supabase-js@2.101.1';

const maxRequestBytes = 12 * 1024;
const deviceIdPattern = /^[A-Za-z0-9_-]{3,96}$/;
const bootIdPattern = /^[A-Za-z0-9_-]{8,96}$/;

type JsonRecord = Record<string, unknown>;

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return jsonResponse(
      { error: 'method_not_allowed', message: 'Use POST para enviar telemetria.' },
      405,
    );
  }

  try {
    authorizeBroker(request);
    const rawBody = await request.text();
    if (!rawBody.trim()) {
      throw new HttpError(400, 'empty_payload', 'Telemetria ausente.');
    }
    if (new TextEncoder().encode(rawBody).length > maxRequestBytes) {
      throw new HttpError(413, 'payload_too_large', 'Telemetria acima do limite.');
    }

    const input = asRecord(JSON.parse(rawBody));
    const payload = normalizePayload(input.payload);
    const deviceId = requiredId(input.deviceId ?? input.device_id, 'deviceId', deviceIdPattern);
    const bootId = requiredId(
      input.bootId ?? input.boot_id ?? payload.bootId,
      'bootId',
      bootIdPattern,
    );
    const sequence = requiredSequence(input.sequence ?? payload.sequence);
    const sampledAt = optionalTimestamp(input.sampledAt ?? input.sampled_at ?? payload.sampledAt);

    if (String(payload.bootId ?? bootId).trim() !== bootId) {
      throw new HttpError(422, 'boot_id_mismatch', 'bootId diverge do payload.');
    }
    if (payload.sequence !== undefined && Number(payload.sequence) !== sequence) {
      throw new HttpError(422, 'sequence_mismatch', 'sequence diverge do payload.');
    }

    const admin = createClient(
      requireEnv('SUPABASE_URL'),
      requireEnv('SUPABASE_SERVICE_ROLE_KEY'),
      { auth: { persistSession: false, autoRefreshToken: false } },
    );
    const { error } = await admin.from('iot_telemetry').insert({
      deviceId,
      bootId,
      sequence,
      sampledAt,
      payload,
    });

    if (error) {
      if (error.code === '23505') {
        return jsonResponse({ ok: true, duplicate: true });
      }
      throw new Error(`Falha ao persistir telemetria: ${error.message}`);
    }

    return jsonResponse({ ok: true, duplicate: false });
  } catch (error) {
    if (error instanceof HttpError) {
      return jsonResponse({ error: error.code, message: error.message }, error.status);
    }

    const response: JsonRecord = {
      error: 'iot_ingestion_failed',
      message: 'Nao foi possivel receber a telemetria.',
    };
    if (Deno.env.get('GRANITH_DEBUG_ERRORS') === 'true') {
      response.details = error instanceof Error ? error.message : String(error);
    }
    return jsonResponse(response, 500);
  }
});

function authorizeBroker(request: Request) {
  const expected = requireEnv('GRANITH_IOT_INGEST_TOKEN');
  const received = request.headers.get('x-granith-iot-token')?.trim() ?? '';
  if (!constantTimeEqual(expected, received)) {
    throw new HttpError(401, 'invalid_ingest_token', 'Token de ingestao invalido.');
  }
}

function normalizePayload(value: unknown): JsonRecord {
  const parsed = typeof value === 'string' ? tryParseRecord(value) : asRecord(value);
  if (Object.keys(parsed).length === 0) {
    throw new HttpError(400, 'invalid_payload', 'payload deve ser um objeto JSON.');
  }
  const serialized = JSON.stringify(parsed);
  if (new TextEncoder().encode(serialized).length > 4096) {
    throw new HttpError(413, 'payload_too_large', 'payload acima de 4 KB.');
  }
  return parsed;
}

function requiredId(value: unknown, field: string, pattern: RegExp) {
  const normalized = String(value ?? '').trim();
  if (!pattern.test(normalized)) {
    throw new HttpError(400, 'invalid_identifier', `${field} invalido.`);
  }
  return normalized;
}

function requiredSequence(value: unknown) {
  const parsed = typeof value === 'number' ? value : Number(String(value ?? '').trim());
  if (!Number.isSafeInteger(parsed) || parsed < 0) {
    throw new HttpError(400, 'invalid_sequence', 'sequence deve ser um inteiro positivo.');
  }
  return parsed;
}

function optionalTimestamp(value: unknown) {
  const normalized = String(value ?? '').trim();
  if (!normalized) return null;
  const parsed = new Date(normalized);
  if (Number.isNaN(parsed.getTime())) {
    throw new HttpError(400, 'invalid_sampled_at', 'sampledAt invalido.');
  }
  return parsed.toISOString();
}

function tryParseRecord(value: string): JsonRecord {
  try {
    return asRecord(JSON.parse(value));
  } catch (_) {
    return {};
  }
}

function asRecord(value: unknown): JsonRecord {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return {};
  return value as JsonRecord;
}

function requireEnv(name: string) {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Variavel de ambiente ausente: ${name}`);
  return value;
}

function constantTimeEqual(left: string, right: string) {
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

function jsonResponse(body: JsonRecord, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
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
