import { createClient } from 'npm:@supabase/supabase-js@2';

import { corsHeaders } from '../_shared/cors.ts';

type MobilePushNotification = {
  id: string;
  recipientUserId: string | null;
  recipientEmployeeId: string | null;
  title: string;
  body: string;
  category: string;
  actionRoute: string;
  payload: Record<string, unknown> | null;
  priority: string;
};

type MobileDeviceToken = {
  id: string;
  fcmToken: string;
  userId: string;
  employeeId: string | null;
};

type FirebaseConfig = {
  projectId: string;
  clientEmail: string;
  privateKey: string;
};

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return jsonResponse(
      { error: 'method_not_allowed', message: 'Use POST para despachar pushes.' },
      405,
    );
  }

  try {
    const supabaseUrl = requireEnv('SUPABASE_URL');
    const serviceRoleKey = requireEnv('SUPABASE_SERVICE_ROLE_KEY');
    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    await authorizeDispatch(request, adminClient);

    const body = await readBody(request);
    const limit = clampNumber(Number(body.limit ?? 25), 1, 100);
    const dryRun = body.dryRun === true;

    const firebase = dryRun ? null : readFirebaseConfig();
    const accessToken = dryRun ? '' : await getFirebaseAccessToken(firebase!);

    const { data, error } = await adminClient
      .from('mobile_push_notifications')
      .select(
        'id,recipientUserId,recipientEmployeeId,title,body,category,actionRoute,payload,priority',
      )
      .eq('status', 'pending')
      .order('createdAt', { ascending: true })
      .limit(limit);

    if (error) {
      throw new Error(`Falha ao buscar notificacoes pendentes: ${error.message}`);
    }

    const notifications = (data ?? []) as MobilePushNotification[];
    const results = [];

    for (const notification of notifications) {
      const tokens = await fetchNotificationTokens(adminClient, notification);

      if (tokens.length === 0) {
        if (!dryRun) {
          await markNotification(adminClient, notification.id, {
            status: 'failed',
            errorMessage: 'Nenhum token FCM ativo encontrado para o destinatario.',
          });
        }
        results.push({
          id: notification.id,
          status: dryRun ? 'would_fail' : 'failed',
          tokens: 0,
          sent: 0,
          failed: 0,
        });
        continue;
      }

      let sent = 0;
      const failures: string[] = [];

      for (const token of tokens) {
        if (dryRun) {
          continue;
        }

        const response = await sendFcmMessage(
          firebase!.projectId,
          accessToken,
          token.fcmToken,
          notification,
        );

        if (response.ok) {
          sent += 1;
          continue;
        }

        failures.push(response.errorMessage);

        if (response.shouldDisableToken) {
          await adminClient
            .from('mobile_device_tokens')
            .update({
              isActive: false,
              revokedAt: new Date().toISOString(),
              updatedAt: new Date().toISOString(),
            })
            .eq('id', token.id);
        }
      }

      if (!dryRun) {
        await markNotification(adminClient, notification.id, {
          status: sent > 0 ? 'sent' : 'failed',
          sentAt: sent > 0 ? new Date().toISOString() : null,
          errorMessage: failures.join(' | ').slice(0, 1200),
        });
      }

      results.push({
        id: notification.id,
        status: dryRun ? 'would_send' : sent > 0 ? 'sent' : 'failed',
        tokens: tokens.length,
        sent: dryRun ? tokens.length : sent,
        failed: dryRun ? 0 : tokens.length - sent,
      });
    }

    return jsonResponse({
      ok: true,
      dryRun,
      processed: notifications.length,
      results,
    });
  } catch (error) {
    const details = error instanceof Error ? error.message : String(error);
    const body: Record<string, unknown> = {
      error: 'dispatch_failed',
      message: 'Nao foi possivel despachar notificacoes mobile.',
    };

    if (Deno.env.get('GRANITH_DEBUG_ERRORS') === 'true') {
      body.details = details;
    }

    return jsonResponse(body, 500);
  }
});

async function authorizeDispatch(
  request: Request,
  adminClient: ReturnType<typeof createClient>,
) {
  const dispatchToken = Deno.env.get('GRANITH_PUSH_DISPATCH_TOKEN')?.trim();
  const providedDispatchToken = request.headers
    .get('x-granith-dispatch-token')
    ?.trim();

  if (
    dispatchToken &&
    providedDispatchToken &&
    constantTimeEqual(dispatchToken, providedDispatchToken)
  ) {
    return;
  }

  const authHeader = request.headers.get('Authorization');
  if (!authHeader) {
    throw new Error('Sessao ausente para despachar notificacoes.');
  }

  const supabaseUrl = requireEnv('SUPABASE_URL');
  const anonKey = requireEnv('SUPABASE_ANON_KEY');
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const {
    data: { user },
    error,
  } = await userClient.auth.getUser();

  if (error || !user) {
    throw new Error('Sessao invalida para despachar notificacoes.');
  }

  const { data: profile, error: profileError } = await adminClient
    .from('users')
    .select('role,permissions')
    .eq('id', user.id)
    .maybeSingle();

  if (profileError || !profile || !canDispatch(profile)) {
    throw new Error('Usuario sem permissao para despachar notificacoes.');
  }
}

function canDispatch(profile: { role?: string; permissions?: unknown }) {
  if (profile.role === 'admin') return true;
  if (profile.role === 'employee') return true;
  const permissions = Array.isArray(profile.permissions)
    ? profile.permissions.map((value) => String(value))
    : [];
  return (
    permissions.includes('settings.manage') ||
    permissions.includes('access.manage') ||
    permissions.includes('mobile.notifications.dispatch')
  );
}

async function fetchNotificationTokens(
  adminClient: ReturnType<typeof createClient>,
  notification: MobilePushNotification,
) {
  const byId = new Map<string, MobileDeviceToken>();

  if (notification.recipientUserId) {
    const { data, error } = await adminClient
      .from('mobile_device_tokens')
      .select('id,fcmToken,userId,employeeId')
      .eq('userId', notification.recipientUserId)
      .eq('isActive', true);

    if (error) {
      throw new Error(`Falha ao buscar tokens por usuario: ${error.message}`);
    }

    for (const token of (data ?? []) as MobileDeviceToken[]) {
      byId.set(token.id, token);
    }
  }

  if (notification.recipientEmployeeId) {
    const { data, error } = await adminClient
      .from('mobile_device_tokens')
      .select('id,fcmToken,userId,employeeId')
      .eq('employeeId', notification.recipientEmployeeId)
      .eq('isActive', true);

    if (error) {
      throw new Error(`Falha ao buscar tokens por funcionario: ${error.message}`);
    }

    for (const token of (data ?? []) as MobileDeviceToken[]) {
      byId.set(token.id, token);
    }
  }

  return [...byId.values()].filter((token) => token.fcmToken.trim().length > 0);
}

async function markNotification(
  adminClient: ReturnType<typeof createClient>,
  id: string,
  fields: {
    status: 'sent' | 'failed';
    sentAt?: string | null;
    errorMessage?: string;
  },
) {
  const { error } = await adminClient
    .from('mobile_push_notifications')
    .update({
      status: fields.status,
      sentAt: fields.sentAt ?? null,
      errorMessage: fields.errorMessage ?? '',
    })
    .eq('id', id);

  if (error) {
    throw new Error(`Falha ao atualizar notificacao ${id}: ${error.message}`);
  }
}

async function sendFcmMessage(
  projectId: string,
  accessToken: string,
  token: string,
  notification: MobilePushNotification,
) {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: {
            title: notification.title,
            body: notification.body,
          },
          data: notificationData(notification),
          android: {
            priority:
              notification.priority === 'high' ? 'HIGH' : 'NORMAL',
            notification: {
              channel_id: 'granith_mobile_operations',
              sound: 'default',
            },
          },
        },
      }),
    },
  );

  if (response.ok) {
    return { ok: true, errorMessage: '', shouldDisableToken: false };
  }

  const errorBody = await response.json().catch(() => ({}));
  const errorMessage = JSON.stringify(errorBody);

  return {
    ok: false,
    errorMessage,
    shouldDisableToken:
      errorMessage.includes('UNREGISTERED') ||
      errorMessage.includes('Requested entity was not found'),
  };
}

function notificationData(notification: MobilePushNotification) {
  const raw = {
    notificationId: notification.id,
    category: notification.category,
    actionRoute: notification.actionRoute,
    ...(notification.payload ?? {}),
  };

  return Object.fromEntries(
    Object.entries(raw).map(([key, value]) => [
      key,
      typeof value === 'string' ? value : JSON.stringify(value),
    ]),
  );
}

function readFirebaseConfig(): FirebaseConfig {
  const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON');
  if (serviceAccountJson?.trim()) {
    const parsed = JSON.parse(serviceAccountJson);
    return {
      projectId: requireValue(parsed.project_id, 'project_id'),
      clientEmail: requireValue(parsed.client_email, 'client_email'),
      privateKey: normalizePrivateKey(
        requireValue(parsed.private_key, 'private_key'),
      ),
    };
  }

  return {
    projectId: requireEnv('FIREBASE_PROJECT_ID'),
    clientEmail: requireEnv('FIREBASE_CLIENT_EMAIL'),
    privateKey: normalizePrivateKey(requireEnv('FIREBASE_PRIVATE_KEY')),
  };
}

async function getFirebaseAccessToken(config: FirebaseConfig) {
  const now = Math.floor(Date.now() / 1000);
  const header = base64UrlJson({ alg: 'RS256', typ: 'JWT' });
  const claims = base64UrlJson({
    iss: config.clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  });
  const unsignedJwt = `${header}.${claims}`;
  const key = await importPrivateKey(config.privateKey);
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(unsignedJwt),
  );
  const assertion = `${unsignedJwt}.${base64UrlBytes(new Uint8Array(signature))}`;

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });

  if (!response.ok) {
    throw new Error(
      `Falha ao autenticar no Firebase: ${response.status} ${await response.text()}`,
    );
  }

  const body = await response.json();
  return requireValue(body.access_token, 'access_token');
}

async function importPrivateKey(privateKey: string) {
  const pem = privateKey
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s+/g, '');
  const binary = atob(pem);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }

  return await crypto.subtle.importKey(
    'pkcs8',
    bytes.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
}

function base64UrlJson(value: Record<string, unknown>) {
  return base64UrlBytes(new TextEncoder().encode(JSON.stringify(value)));
}

function base64UrlBytes(bytes: Uint8Array) {
  let binary = '';
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/g, '');
}

async function readBody(request: Request) {
  if (!request.body) return {};
  try {
    return await request.json();
  } catch (_) {
    return {};
  }
}

function requireEnv(name: string) {
  const value = Deno.env.get(name)?.trim();
  if (!value) {
    throw new Error(`Variavel de ambiente ausente: ${name}`);
  }
  return value;
}

function requireValue(value: unknown, name: string) {
  const normalized = String(value ?? '').trim();
  if (!normalized) {
    throw new Error(`Valor Firebase ausente: ${name}`);
  }
  return normalized;
}

function normalizePrivateKey(value: string) {
  return value.replace(/\\n/g, '\n');
}

function clampNumber(value: number, min: number, max: number) {
  if (!Number.isFinite(value)) return min;
  return Math.min(max, Math.max(min, Math.trunc(value)));
}

function constantTimeEqual(left: string, right: string) {
  if (left.length !== right.length) return false;
  let result = 0;
  for (let i = 0; i < left.length; i += 1) {
    result |= left.charCodeAt(i) ^ right.charCodeAt(i);
  }
  return result === 0;
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
