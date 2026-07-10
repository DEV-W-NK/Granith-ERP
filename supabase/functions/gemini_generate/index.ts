import { createClient } from 'npm:@supabase/supabase-js@2';

import { corsHeaders } from '../_shared/cors.ts';

type GeminiRole = 'user' | 'model';

type GeminiHistoryItem = {
  role: GeminiRole;
  content: string;
};

const defaultModel = 'gemini-2.5-flash';
const maxMessageChars = 12_000;
const maxSystemChars = 60_000;
const maxHistoryItems = 12;
const maxHistoryItemChars = 8_000;

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return jsonResponse(
      { error: 'method_not_allowed', message: 'Use POST para chamar a IA.' },
      405,
    );
  }

  try {
    await authorizeRequest(request);

    const body = await readBody(request);
    const action = normalizeText(body.action) || 'generate';
    const model = resolveModel(normalizeText(body.model));

    if (action === 'countTokens') {
      return await countTokens(model, body);
    }

    if (action === 'generate') {
      return await generateContent(model, body);
    }

    return jsonResponse(
      { error: 'invalid_action', message: 'Acao de IA invalida.' },
      400,
    );
  } catch (error) {
    if (error instanceof HttpError) {
      return jsonResponse(
        { error: error.code, message: error.message },
        error.status,
      );
    }

    const details = error instanceof Error ? error.message : String(error);
    const response: Record<string, unknown> = {
      error: 'gemini_proxy_failed',
      message: 'Nao foi possivel chamar a IA com seguranca.',
    };

    if (Deno.env.get('GRANITH_DEBUG_ERRORS') === 'true') {
      response.details = details;
    }

    return jsonResponse(response, 500);
  }
});

async function authorizeRequest(request: Request) {
  const authHeader = request.headers.get('Authorization');
  if (!authHeader) {
    throw new HttpError(401, 'missing_authorization', 'Sessao ausente.');
  }

  const supabaseUrl = requireEnv('SUPABASE_URL');
  const supabaseAnonKey = requireEnv('SUPABASE_ANON_KEY');
  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const {
    data: { user },
    error,
  } = await userClient.auth.getUser();

  if (error || !user) {
    throw new HttpError(401, 'invalid_session', 'Sessao invalida.');
  }
}

async function generateContent(model: string, body: Record<string, unknown>) {
  const systemInstruction = limitText(
    normalizeText(body.systemInstruction),
    maxSystemChars,
    'Instrucao de sistema muito grande.',
  );
  const message = limitText(
    normalizeText(body.message),
    maxMessageChars,
    'Pergunta muito grande para processamento seguro.',
  );

  if (!message) {
    throw new HttpError(400, 'empty_message', 'Digite uma pergunta para a IA.');
  }

  const history = normalizeHistory(body.history);
  const contents = [
    ...history.map((item) => ({
      role: item.role,
      parts: [{ text: item.content }],
    })),
    {
      role: 'user',
      parts: [{ text: message }],
    },
  ];

  const payload: Record<string, unknown> = {
    contents,
    generationConfig: {
      temperature: 0.2,
      topP: 0.8,
      maxOutputTokens: clampNumber(
        Number(body.maxOutputTokens ?? Deno.env.get('GEMINI_MAX_OUTPUT_TOKENS') ?? 1200),
        128,
        4096,
      ),
    },
  };

  if (systemInstruction) {
    payload.systemInstruction = {
      parts: [{ text: systemInstruction }],
    };
  }

  const geminiResponse = await callGemini(model, 'generateContent', payload);
  const text = extractText(geminiResponse);
  const usage = asRecord(geminiResponse.usageMetadata);

  return jsonResponse({
    ok: true,
    model,
    text: text.trim(),
    usageMetadata: usage,
    promptTokens: readInt(usage.promptTokenCount),
    outputTokens: readInt(usage.candidatesTokenCount),
    totalTokens: readInt(usage.totalTokenCount),
  });
}

async function countTokens(model: string, body: Record<string, unknown>) {
  const systemInstruction = limitText(
    normalizeText(body.systemInstruction),
    maxSystemChars,
    'Instrucao de sistema muito grande.',
  );
  const message = limitText(
    normalizeText(body.message),
    maxMessageChars,
    'Mensagem muito grande.',
  );

  const geminiResponse = await callGemini(model, 'countTokens', {
    contents: [
      {
        role: 'user',
        parts: [{ text: `${systemInstruction}\n\n${message}`.trim() }],
      },
    ],
  });

  return jsonResponse({
    ok: true,
    model,
    totalTokens: readInt(geminiResponse.totalTokens),
  });
}

async function callGemini(
  model: string,
  method: 'generateContent' | 'countTokens',
  payload: Record<string, unknown>,
) {
  const apiKey = requireEnv('GEMINI_API_KEY');
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:${method}?key=${encodeURIComponent(apiKey)}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    },
  );

  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    const message = friendlyGeminiError(response.status, body);
    throw new HttpError(response.status, 'gemini_api_failed', message);
  }

  return asRecord(body);
}

function resolveModel(requestedModel: string) {
  const configuredModel =
    normalizeText(Deno.env.get('GEMINI_MODEL')) || defaultModel;
  const model = requestedModel || configuredModel;
  const allowed = allowedModels(configuredModel);

  if (!allowed.has(model)) {
    throw new HttpError(
      400,
      'model_not_allowed',
      'Modelo de IA nao autorizado para este ambiente.',
    );
  }

  return model;
}

function allowedModels(configuredModel: string) {
  const raw = Deno.env.get('GEMINI_ALLOWED_MODELS');
  if (!raw?.trim()) return new Set([configuredModel]);
  return new Set(
    raw
      .split(',')
      .map((item) => item.trim())
      .filter(Boolean),
  );
}

function normalizeHistory(value: unknown): GeminiHistoryItem[] {
  if (!Array.isArray(value)) return [];

  return value.slice(-maxHistoryItems).flatMap((item) => {
    if (!item || typeof item !== 'object') return [];
    const row = item as Record<string, unknown>;
    const role = normalizeText(row.role) === 'model' ? 'model' : 'user';
    const content = limitText(
      normalizeText(row.content),
      maxHistoryItemChars,
      'Historico de conversa muito grande.',
    );
    if (!content) return [];
    return [{ role, content }];
  });
}

function extractText(decoded: Record<string, unknown>) {
  const candidates = decoded.candidates;
  if (!Array.isArray(candidates) || candidates.length === 0) return '';
  const first = candidates[0];
  if (!first || typeof first !== 'object') return '';
  const content = (first as Record<string, unknown>).content;
  if (!content || typeof content !== 'object') return '';
  const parts = (content as Record<string, unknown>).parts;
  if (!Array.isArray(parts)) return '';

  return parts
    .map((part) =>
      part && typeof part === 'object'
        ? normalizeText((part as Record<string, unknown>).text)
        : '',
    )
    .filter(Boolean)
    .join('\n');
}

function friendlyGeminiError(status: number, body: unknown) {
  const record = asRecord(body);
  const error = asRecord(record.error);
  const message = normalizeText(error.message);
  if (message) return `Falha no Gemini (${status}): ${message}`;
  return `Falha no Gemini (${status}).`;
}

function asRecord(value: unknown): Record<string, unknown> {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return {};
}

async function readBody(request: Request) {
  try {
    const decoded = await request.json();
    return asRecord(decoded);
  } catch (_) {
    return {};
  }
}

function requireEnv(name: string) {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Variavel de ambiente ausente: ${name}`);
  return value;
}

function normalizeText(value: unknown) {
  return String(value ?? '').trim();
}

function limitText(value: string, maxLength: number, errorMessage: string) {
  if (value.length > maxLength) {
    throw new HttpError(400, 'payload_too_large', errorMessage);
  }
  return value;
}

function clampNumber(value: number, min: number, max: number) {
  if (!Number.isFinite(value)) return min;
  return Math.min(max, Math.max(min, Math.trunc(value)));
}

function readInt(value: unknown) {
  if (typeof value === 'number') return Math.trunc(value);
  return Number.parseInt(String(value ?? ''), 10) || 0;
}

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
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
