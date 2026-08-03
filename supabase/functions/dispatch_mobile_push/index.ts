import { createClient } from 'npm:@supabase/supabase-js@2.101.1';

import { corsHeaders, withCors } from '../_shared/cors.ts';

type UntypedSupabaseClient = ReturnType<typeof createClient<any, 'public'>>;

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
  attempts: number;
  maxAttempts: number;
  processingBy?: string | null;
};

type MobileDeviceToken = {
  id: string;
  fcmToken: string;
  userId: string;
  employeeId: string | null;
};

type MobilePushDelivery = {
  id: string;
  notificationId: string;
  deviceTokenId: string | null;
  status: 'pending' | 'sent' | 'failed';
  attempts: number;
  maxAttempts: number;
  nextAttemptAt: string | null;
};

type FirebaseConfig = {
  projectId: string;
  clientEmail: string;
  privateKey: string;
};

Deno.serve((request) =>
  withCors(request, async () => {
    if (request.method === 'OPTIONS') {
      return new Response('ok', { headers: corsHeaders });
    }

    if (request.method !== 'POST') {
      return jsonResponse(
        {
          error: 'method_not_allowed',
          message: 'Use POST para despachar pushes.',
        },
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
      const workerId = crypto.randomUUID();
      const firebase = dryRun ? null : readFirebaseConfig();
      const accessToken = dryRun ? '' : await getFirebaseAccessToken(firebase!);
      const notifications = await fetchNotificationsForDispatch(
        adminClient,
        limit,
        workerId,
        dryRun,
      );
      const results = [];

      for (const notification of notifications) {
        try {
          results.push(
            await dispatchNotification({
              adminClient,
              notification,
              firebase,
              accessToken,
              workerId,
              dryRun,
            }),
          );
        } catch (error) {
          const message = error instanceof Error ? error.message : String(error);
          if (!dryRun) {
            await scheduleNotificationRetry(
              adminClient,
              notification,
              workerId,
              message,
            );
          }
          results.push({
            id: notification.id,
            status: dryRun ? 'would_fail' : 'retry_scheduled',
            tokens: 0,
            sent: 0,
            failed: 0,
            error: message.slice(0, 500),
          });
        }
      }

      return jsonResponse({
        ok: true,
        dryRun,
        workerId: dryRun ? null : workerId,
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
  })
);

async function fetchNotificationsForDispatch(
  adminClient: UntypedSupabaseClient,
  limit: number,
  workerId: string,
  dryRun: boolean,
) {
  if (!dryRun) {
    const { data, error } = await adminClient.rpc(
      'claim_mobile_push_notifications',
      {
        p_limit: limit,
        p_worker_id: workerId,
      },
    );

    if (error) {
      throw new Error(`Falha ao reservar notificacoes: ${error.message}`);
    }

    return (data ?? []) as MobilePushNotification[];
  }

  const { data, error } = await adminClient
    .from('mobile_push_notifications')
    .select(
      'id,recipientUserId,recipientEmployeeId,title,body,category,actionRoute,payload,priority,attempts,maxAttempts',
    )
    .eq('status', 'pending')
    .lte('nextAttemptAt', new Date().toISOString())
    .order('createdAt', { ascending: true })
    .limit(limit);

  if (error) {
    throw new Error(`Falha ao buscar notificacoes pendentes: ${error.message}`);
  }

  return (data ?? []) as MobilePushNotification[];
}

async function dispatchNotification({
  adminClient,
  notification,
  firebase,
  accessToken,
  workerId,
  dryRun,
}: {
  adminClient: UntypedSupabaseClient;
  notification: MobilePushNotification;
  firebase: FirebaseConfig | null;
  accessToken: string;
  workerId: string;
  dryRun: boolean;
}) {
  const tokens = await fetchNotificationTokens(adminClient, notification);

  if (dryRun) {
    return {
      id: notification.id,
      status: tokens.length === 0 ? 'would_retry' : 'would_send',
      tokens: tokens.length,
      sent: tokens.length,
      failed: 0,
    };
  }

  if (tokens.length === 0) {
    const status = await scheduleNotificationRetry(
      adminClient,
      notification,
      workerId,
      'Nenhum token FCM ativo encontrado para o destinatario.',
    );
    return {
      id: notification.id,
      status,
      tokens: 0,
      sent: 0,
      failed: 0,
    };
  }

  await ensureDeliveryRows(adminClient, notification, tokens);
  const tokenById = new Map(tokens.map((token) => [token.id, token]));
  const deliveries = await fetchDeliveryRows(
    adminClient,
    notification.id,
    [...tokenById.keys()],
  );
  const attemptStartedAt = new Date();

  for (const delivery of deliveries) {
    if (delivery.status !== 'pending' || !delivery.deviceTokenId) continue;
    if (
      delivery.nextAttemptAt &&
      new Date(delivery.nextAttemptAt).getTime() > attemptStartedAt.getTime()
    ) {
      continue;
    }

    const token = tokenById.get(delivery.deviceTokenId);
    if (!token) continue;

    const response = await sendFcmMessage(
      firebase!.projectId,
      accessToken,
      token.fcmToken,
      notification,
    );
    const attempt = Math.min(
      Number(delivery.attempts ?? 0) + 1,
      Number(delivery.maxAttempts ?? 5),
    );

    if (response.ok) {
      await updateDelivery(adminClient, delivery.id, {
        status: 'sent',
        attempts: attempt,
        lastAttemptAt: attemptStartedAt.toISOString(),
        sentAt: new Date().toISOString(),
        nextAttemptAt: null,
        errorMessage: '',
      });
      continue;
    }

    const canRetry =
      response.retryable && attempt < Number(delivery.maxAttempts ?? 5);
    await updateDelivery(adminClient, delivery.id, {
      status: canRetry ? 'pending' : 'failed',
      attempts: attempt,
      lastAttemptAt: attemptStartedAt.toISOString(),
      sentAt: null,
      nextAttemptAt: canRetry
        ? calculateNextAttemptAt(attemptStartedAt, attempt).toISOString()
        : null,
      errorMessage: response.errorMessage.slice(0, 1200),
    });

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

  const refreshed = await fetchDeliveryRows(
    adminClient,
    notification.id,
    [...tokenById.keys()],
  );
  const pending = refreshed.filter((item) => item.status === 'pending');
  const sent = refreshed.filter((item) => item.status === 'sent');
  const failed = refreshed.filter((item) => item.status === 'failed');
  const errors = failed
    .map((item) => item.id)
    .length > 0
    ? `${failed.length} dispositivo(s) falharam definitivamente.`
    : '';
  const maxAttempts = refreshed.reduce(
    (value, item) => Math.max(value, Number(item.attempts ?? 0)),
    0,
  );

  if (pending.length > 0) {
    const nextAttemptAt = pending
      .map((item) => item.nextAttemptAt)
      .filter((value): value is string => Boolean(value))
      .sort()[0] ?? new Date().toISOString();
    await markNotification(adminClient, notification.id, workerId, {
      status: 'pending',
      attempts: maxAttempts,
      lastAttemptAt: attemptStartedAt.toISOString(),
      nextAttemptAt,
      errorMessage: errors,
    });
  } else if (sent.length > 0) {
    await markNotification(adminClient, notification.id, workerId, {
      status: 'sent',
      attempts: maxAttempts,
      sentAt: new Date().toISOString(),
      lastAttemptAt: attemptStartedAt.toISOString(),
      nextAttemptAt: null,
      errorMessage: errors,
    });
  } else {
    await markNotification(adminClient, notification.id, workerId, {
      status: 'failed',
      attempts: maxAttempts,
      sentAt: null,
      lastAttemptAt: attemptStartedAt.toISOString(),
      nextAttemptAt: null,
      errorMessage: errors || 'Falha definitiva em todos os dispositivos.',
    });
  }

  return {
    id: notification.id,
    status: pending.length > 0
      ? 'retry_scheduled'
      : sent.length > 0
        ? 'sent'
        : 'failed',
    tokens: tokens.length,
    sent: sent.length,
    failed: failed.length,
    pending: pending.length,
    attempt: maxAttempts,
  };
}

async function ensureDeliveryRows(
  adminClient: UntypedSupabaseClient,
  notification: MobilePushNotification,
  tokens: MobileDeviceToken[],
) {
  const { error } = await adminClient
    .from('mobile_push_deliveries')
    .upsert(
      tokens.map((token) => ({
        notificationId: notification.id,
        deviceTokenId: token.id,
        status: 'pending',
        attempts: 0,
        maxAttempts: Number(notification.maxAttempts ?? 5),
        nextAttemptAt: new Date().toISOString(),
      })),
      {
        onConflict: 'notificationId,deviceTokenId',
        ignoreDuplicates: true,
      },
    );

  if (error) {
    throw new Error(`Falha ao preparar entregas por dispositivo: ${error.message}`);
  }
}

async function fetchDeliveryRows(
  adminClient: UntypedSupabaseClient,
  notificationId: string,
  deviceTokenIds: string[],
) {
  const { data, error } = await adminClient
    .from('mobile_push_deliveries')
    .select(
      'id,notificationId,deviceTokenId,status,attempts,maxAttempts,nextAttemptAt',
    )
    .eq('notificationId', notificationId)
    .in('deviceTokenId', deviceTokenIds);

  if (error) {
    throw new Error(`Falha ao consultar entregas por dispositivo: ${error.message}`);
  }

  return (data ?? []) as MobilePushDelivery[];
}

async function updateDelivery(
  adminClient: UntypedSupabaseClient,
  id: string,
  fields: Record<string, unknown>,
) {
  const { error } = await adminClient
    .from('mobile_push_deliveries')
    .update(fields)
    .eq('id', id);

  if (error) {
    throw new Error(`Falha ao atualizar entrega ${id}: ${error.message}`);
  }
}

async function scheduleNotificationRetry(
  adminClient: UntypedSupabaseClient,
  notification: MobilePushNotification,
  workerId: string,
  errorMessage: string,
) {
  const attempt = Math.min(
    Number(notification.attempts ?? 0) + 1,
    Number(notification.maxAttempts ?? 5),
  );
  const canRetry = attempt < Number(notification.maxAttempts ?? 5);
  await markNotification(adminClient, notification.id, workerId, {
    status: canRetry ? 'pending' : 'failed',
    attempts: attempt,
    lastAttemptAt: new Date().toISOString(),
    nextAttemptAt: canRetry
      ? calculateNextAttemptAt(new Date(), attempt).toISOString()
      : null,
    errorMessage: errorMessage.slice(0, 1200),
  });
  return canRetry ? 'retry_scheduled' : 'failed';
}

async function authorizeDispatch(
  request: Request,
  adminClient: UntypedSupabaseClient,
) {
  const lease = request.headers.get('x-granith-dispatch-lease')?.trim();
  if (lease) {
    const { data, error } = await adminClient.rpc(
      'consume_mobile_push_dispatch_lease',
      { p_token: lease },
    );
    if (!error && data === true) return;
    throw new Error('Lease de despacho invalido, expirado ou ja utilizado.');
  }

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
  const permissions = Array.isArray(profile.permissions)
    ? profile.permissions.map((value) => String(value))
    : [];
  return (
    permissions.includes('settings.manage') ||
    permissions.includes('access.manage') ||
    permissions.includes('mobile.notifications.dispatch') ||
    permissions.includes('projects.write') ||
    permissions.includes('people.manage') ||
    permissions.includes('purchases.write') ||
    permissions.includes('purchases.approve') ||
    permissions.includes('purchases.consolidate') ||
    permissions.includes('fleet.manage') ||
    permissions.includes('logistics.manage') ||
    permissions.includes('obras') ||
    permissions.includes('rh') ||
    permissions.includes('compras') ||
    permissions.includes('suprimentos')
  );
}

async function fetchNotificationTokens(
  adminClient: UntypedSupabaseClient,
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
  adminClient: UntypedSupabaseClient,
  id: string,
  workerId: string,
  fields: {
    status: 'pending' | 'sent' | 'failed';
    sentAt?: string | null;
    errorMessage?: string;
    attempts?: number;
    lastAttemptAt?: string | null;
    nextAttemptAt?: string | null;
  },
) {
  const updateFields: Record<string, unknown> = {
    status: fields.status,
    errorMessage: fields.errorMessage ?? '',
    processingAt: null,
    processingBy: null,
  };

  if ('sentAt' in fields) {
    updateFields.sentAt = fields.sentAt ?? null;
  }
  if ('attempts' in fields) {
    updateFields.attempts = fields.attempts;
  }
  if ('lastAttemptAt' in fields) {
    updateFields.lastAttemptAt = fields.lastAttemptAt ?? null;
  }
  if ('nextAttemptAt' in fields) {
    updateFields.nextAttemptAt = fields.nextAttemptAt ?? null;
  }

  const { error } = await adminClient
    .from('mobile_push_notifications')
    .update(updateFields)
    .eq('id', id)
    .eq('status', 'processing')
    .eq('processingBy', workerId);

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
    return {
      ok: true,
      errorMessage: '',
      shouldDisableToken: false,
      retryable: false,
    };
  }

  const errorBody = await response.json().catch(() => ({}));
  const errorMessage = JSON.stringify(errorBody);
  const retryable =
    response.status === 408 ||
    response.status === 429 ||
    response.status >= 500;

  return {
    ok: false,
    errorMessage,
    shouldDisableToken:
      errorMessage.includes('UNREGISTERED') ||
      errorMessage.includes('Requested entity was not found'),
    retryable,
  };
}

function calculateNextAttemptAt(now: Date, attempt: number) {
  const backoffSeconds = Math.min(3600, 60 * 2 ** Math.max(0, attempt - 1));
  const jitterSeconds = Math.floor(Math.random() * 20);
  return new Date(now.getTime() + (backoffSeconds + jitterSeconds) * 1000);
}

function notificationData(notification: MobilePushNotification) {
  const raw = {
    notificationId: notification.id,
    recipientUserId: notification.recipientUserId ?? '',
    recipientEmployeeId: notification.recipientEmployeeId ?? '',
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
