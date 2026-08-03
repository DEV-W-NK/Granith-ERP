export const corsHeaders = {
  'Access-Control-Allow-Headers':
      'authorization, x-client-info, apikey, content-type, x-granith-dispatch-token, x-granith-pades-token',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const defaultAllowedOrigins = [
  'https://granith-skyforge.web.app',
  'https://granith-skyforge.firebaseapp.com',
];

export async function withCors(
  request: Request,
  handler: () => Promise<Response>,
): Promise<Response> {
  const origin = request.headers.get('Origin')?.trim() ?? '';
  if (origin && !isAllowedOrigin(origin)) {
    return new Response(
      JSON.stringify({
        error: 'origin_not_allowed',
        message: 'Origin is not allowed to call this function.',
      }),
      {
        status: 403,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
          'Vary': 'Origin',
        },
      },
    );
  }

  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: responseCorsHeaders(origin),
    });
  }

  const response = await handler();
  const headers = new Headers(response.headers);
  headers.delete('Access-Control-Allow-Origin');
  for (const [key, value] of Object.entries(responseCorsHeaders(origin))) {
    headers.set(key, value);
  }

  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

function responseCorsHeaders(origin: string) {
  return {
    ...corsHeaders,
    ...(origin ? { 'Access-Control-Allow-Origin': origin } : {}),
    'Vary': 'Origin',
  };
}

export function isAllowedOrigin(origin: string) {
  if (/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i.test(origin)) {
    return true;
  }

  const configured = (Deno.env.get('CORS_ALLOWED_ORIGINS') ?? '')
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);
  return new Set([...defaultAllowedOrigins, ...configured]).has(origin);
}
