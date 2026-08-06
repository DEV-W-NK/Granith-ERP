import { createClient } from 'npm:@supabase/supabase-js@2.101.1';

import { corsHeaders, withCors } from '../_shared/cors.ts';

type JsonRecord = Record<string, unknown>;
type UntypedSupabaseClient = ReturnType<typeof createClient<any, 'public'>>;
type FleetManagerAuth =
  | {
    admin: UntypedSupabaseClient;
    requester: { id: string };
    error: null;
  }
  | {
    admin: null;
    requester: null;
    error: Response;
  };

const hardwareIdPattern = /^[0-9a-f]{12}$/;
const projectIdPattern = /^[A-Za-z0-9-]{8,96}$/;
const deviceKindPattern = /^[A-Za-z0-9_-]{3,48}$/;
const tokenLifetimeHours = 24;

Deno.serve((request) => withCors(request, async () => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return jsonResponse(
      { error: 'method_not_allowed', message: 'Use POST para provisionar sensores IoT.' },
      405,
    );
  }

  try {
    const body = await readBody(request);
    const action = String(body.action ?? '').trim();
    if (action === 'claim') {
      return await claimDevice(body);
    }
    if (action === 'create' || action === 'reissue') {
      return await manageProvisioningToken(request, body, action);
    }
    return jsonResponse(
      { error: 'invalid_action', message: 'Acao de provisionamento invalida.' },
      400,
    );
  } catch (error) {
    if (error instanceof HttpError) {
      return jsonResponse({ error: error.code, message: error.message }, error.status);
    }
    const response: JsonRecord = {
      error: 'iot_provisioning_failed',
      message: 'Nao foi possivel provisionar o sensor IoT.',
    };
    if (Deno.env.get('GRANITH_DEBUG_ERRORS') === 'true') {
      response.details = error instanceof Error ? error.message : String(error);
    }
    return jsonResponse(response, 500);
  }
}));

async function manageProvisioningToken(
  request: Request,
  body: JsonRecord,
  action: 'create' | 'reissue',
) {
  const auth = await requireFleetManager(request);
  if (auth.error) return auth.error;
  const { admin, requester } = auth;

  const deviceId = action === 'reissue'
    ? requiredText(body.deviceId, 'deviceId', /^[A-Za-z0-9_-]{3,96}$/)
    : null;
  let projectId = requiredText(body.projectId, 'projectId', projectIdPattern);
  let deviceName = action === 'create'
    ? normalizeDeviceName(body.name ?? body.deviceName)
    : '';
  let kind = action === 'create' ? normalizeKind(body.kind) : 'siteSensor';
  let interval = action === 'create'
    ? normalizeInterval(body.telemetryIntervalSeconds)
    : 900;
  let hardwareId: string | null = null;

  if (deviceId) {
    const { data: device, error: deviceError } = await admin
      .from('iot_devices')
      .select('id, projectId, name, kind, hardwareId, telemetryIntervalSeconds')
      .eq('id', deviceId)
      .maybeSingle();
    if (deviceError || !device) {
      return jsonResponse(
        { error: 'device_not_found', message: 'Sensor IoT nao encontrado.' },
        404,
      );
    }
    projectId = String(device.projectId);
    deviceName = normalizeDeviceName(device.name);
    kind = normalizeKind(device.kind);
    interval = normalizeInterval(device.telemetryIntervalSeconds);
    hardwareId = normalizeHardwareIdOrNull(device.hardwareId);

    await admin
      .from('iot_device_provisioning_tokens')
      .update({ revokedAt: new Date().toISOString() })
      .eq('deviceId', deviceId)
      .is('claimedAt', null)
      .is('revokedAt', null);
  } else {
    const { data: project, error: projectError } = await admin
      .from('projects')
      .select('id')
      .eq('id', projectId)
      .maybeSingle();
    if (projectError || !project) {
      return jsonResponse(
        { error: 'project_not_found', message: 'Obra nao encontrada.' },
        404,
      );
    }
  }

  const secret = createProvisioningSecret();
  const tokenHash = await sha256(secret);
  const expiresAt = new Date(Date.now() + tokenLifetimeHours * 60 * 60 * 1000);
  const { data: token, error: tokenError } = await admin
    .from('iot_device_provisioning_tokens')
    .insert({
      projectId,
      deviceId,
      deviceName,
      kind,
      telemetryIntervalSeconds: interval,
      tokenHash,
      hardwareId,
      issuedBy: requester.id,
      expiresAt: expiresAt.toISOString(),
    })
    .select('id, projectId, deviceId, deviceName, expiresAt')
    .single();

  if (tokenError || !token) {
    throw new Error(`Falha ao gerar segredo de provisionamento: ${tokenError?.message ?? 'desconhecida'}`);
  }

  return jsonResponse({
    ok: true,
    provisioningSecret: secret,
    token: {
      id: token.id,
      projectId: token.projectId,
      deviceId: token.deviceId,
      deviceName: token.deviceName,
      expiresAt: token.expiresAt,
    },
  });
}

async function claimDevice(body: JsonRecord) {
  const secret = String(body.secret ?? body.provisioningSecret ?? '').trim();
  if (!/^grn_iot_[A-Za-z0-9_-]{32,160}$/.test(secret)) {
    return jsonResponse(
      { error: 'invalid_secret', message: 'Segredo de provisionamento invalido.' },
      401,
    );
  }
  const hardwareId = requiredText(body.hardwareId, 'hardwareId', hardwareIdPattern).toLowerCase();
  const admin = serviceClient();
  const tokenHash = await sha256(secret);
  const { data: token, error: tokenError } = await admin
    .from('iot_device_provisioning_tokens')
    .select('*')
    .eq('tokenHash', tokenHash)
    .is('claimedAt', null)
    .is('revokedAt', null)
    .maybeSingle();

  if (tokenError || !token) {
    return jsonResponse(
      { error: 'secret_unavailable', message: 'Segredo expirado, utilizado ou revogado.' },
      401,
    );
  }
  if (new Date(String(token.expiresAt)).getTime() <= Date.now()) {
    return jsonResponse(
      { error: 'secret_expired', message: 'Segredo de provisionamento expirado.' },
      401,
    );
  }
  if (token.hardwareId && String(token.hardwareId).toLowerCase() !== hardwareId) {
    return jsonResponse(
      { error: 'hardware_mismatch', message: 'Segredo vinculado a outro dispositivo.' },
      409,
    );
  }

  const deviceId = String(token.deviceId ?? `site-sensor-${hardwareId}`);
  const { data: existing } = await admin
    .from('iot_devices')
    .select('id, projectId, hardwareId')
    .eq('id', deviceId)
    .maybeSingle();

  if (existing && String(existing.projectId) !== String(token.projectId)) {
    return jsonResponse(
      { error: 'device_conflict', message: 'Identidade do sensor ja pertence a outra obra.' },
      409,
    );
  }
  if (existing?.hardwareId && String(existing.hardwareId).toLowerCase() !== hardwareId) {
    return jsonResponse(
      { error: 'hardware_conflict', message: 'Identidade do sensor ja pertence a outro hardware.' },
      409,
    );
  }

  const { data: registeredHardware, error: registeredHardwareError } = await admin
    .from('iot_devices')
    .select('id, projectId')
    .eq('hardwareId', hardwareId)
    .maybeSingle();
  if (registeredHardwareError) {
    throw new Error(`Falha ao verificar hardware: ${registeredHardwareError.message}`);
  }
  if (registeredHardware && String(registeredHardware.id) !== deviceId) {
    return jsonResponse(
      { error: 'hardware_registered', message: 'Este hardware ja esta vinculado a outro sensor.' },
      409,
    );
  }

  // Claim first, before the device becomes active. A second request using the
  // same secret cannot create an active orphan sensor while this request is
  // still completing the database write below.
  const now = new Date().toISOString();
  const { data: claimed, error: claimError } = await admin
    .from('iot_device_provisioning_tokens')
    .update({ deviceId, hardwareId, claimedAt: now })
    .eq('id', token.id)
    .is('claimedAt', null)
    .is('revokedAt', null)
    .select('id')
    .maybeSingle();
  if (claimError || !claimed) {
    return jsonResponse(
      { error: 'claim_conflict', message: 'Segredo ja foi utilizado por outra tentativa.' },
      409,
    );
  }

  const devicePayload = {
    id: deviceId,
    projectId: String(token.projectId),
    name: normalizeDeviceName(token.deviceName),
    kind: normalizeKind(token.kind),
    status: 'active',
    mqttClientId: deviceId,
    hardwareId,
    telemetryIntervalSeconds: normalizeInterval(token.telemetryIntervalSeconds),
    provisionedAt: new Date().toISOString(),
    notes: 'Registrado por provisionamento seguro.',
  };
  const { error: deviceError } = await admin
    .from('iot_devices')
    .upsert(devicePayload, { onConflict: 'id' });
  if (deviceError) {
    throw new Error(`Falha ao registrar sensor: ${deviceError.message}`);
  }

  return jsonResponse({
    ok: true,
    device: {
      id: deviceId,
      projectId: String(token.projectId),
      telemetryIntervalSeconds: normalizeInterval(token.telemetryIntervalSeconds),
    },
  });
}

async function requireFleetManager(request: Request): Promise<FleetManagerAuth> {
  const authHeader = request.headers.get('Authorization');
  if (!authHeader) {
    return {
      admin: null,
      requester: null,
      error: jsonResponse({ error: 'missing_authorization', message: 'Sessao ausente.' }, 401),
    };
  }
  const supabaseUrl = requireEnv('SUPABASE_URL');
  const userClient = createClient(supabaseUrl, requireEnv('SUPABASE_ANON_KEY'), {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const {
    data: { user },
    error: authError,
  } = await userClient.auth.getUser();
  if (authError || !user) {
    return {
      admin: null,
      requester: null,
      error: jsonResponse({ error: 'invalid_session', message: 'Sessao invalida.' }, 401),
    };
  }

  const admin = serviceClient();
  const { data: profile, error: profileError } = await admin
    .from('users')
    .select('id, role, permissions, status')
    .eq('id', user.id)
    .maybeSingle();
  if (profileError || !profile || !canManageFleet(profile)) {
    return {
      admin: null,
      requester: null,
      error: jsonResponse(
        { error: 'forbidden', message: 'Permissao de gestao de frota e necessaria.' },
        403,
      ),
    };
  }
  return { admin, requester: user, error: null };
}

function canManageFleet(profile: JsonRecord) {
  if (String(profile.role ?? '').toLowerCase() === 'admin') return true;
  const permissions = Array.isArray(profile.permissions)
    ? profile.permissions.map((permission) => String(permission))
    : [];
  return permissions.some((permission) => [
    'admin', 'fleet.manage', 'logistics.manage', 'frota', 'compras',
  ].includes(permission));
}

function serviceClient(): UntypedSupabaseClient {
  return createClient(requireEnv('SUPABASE_URL'), requireEnv('SUPABASE_SERVICE_ROLE_KEY'), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function normalizeDeviceName(value: unknown) {
  const text = String(value ?? '').trim().replace(/\s+/g, ' ');
  if (text.length < 3 || text.length > 120) {
    throw new HttpError(400, 'invalid_device_name', 'Informe um nome entre 3 e 120 caracteres.');
  }
  return text;
}

function normalizeKind(value: unknown) {
  const kind = String(value ?? 'siteSensor').trim() || 'siteSensor';
  if (!deviceKindPattern.test(kind)) {
    throw new HttpError(400, 'invalid_device_kind', 'Tipo de sensor invalido.');
  }
  return kind;
}

function normalizeInterval(value: unknown) {
  const interval = Number(value ?? 900);
  if (!Number.isSafeInteger(interval) || interval < 60 || interval > 86400) {
    throw new HttpError(400, 'invalid_interval', 'Intervalo deve estar entre 60 e 86400 segundos.');
  }
  return interval;
}

function normalizeHardwareIdOrNull(value: unknown) {
  const text = String(value ?? '').trim().toLowerCase();
  return hardwareIdPattern.test(text) ? text : null;
}

function requiredText(value: unknown, field: string, pattern: RegExp) {
  const text = String(value ?? '').trim();
  if (!pattern.test(text)) {
    throw new HttpError(400, 'invalid_input', `${field} invalido.`);
  }
  return text;
}

function createProvisioningSecret() {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  const token = Array.from(bytes, (value) => value.toString(16).padStart(2, '0')).join('');
  return `grn_iot_${token}`;
}

async function sha256(value: string) {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest('SHA-256', bytes);
  return Array.from(new Uint8Array(digest), (value) => value.toString(16).padStart(2, '0')).join('');
}

async function readBody(request: Request): Promise<JsonRecord> {
  const raw = await request.text();
  if (!raw.trim()) return {};
  try {
    const value = JSON.parse(raw);
    return value && typeof value === 'object' && !Array.isArray(value)
      ? value as JsonRecord
      : {};
  } catch (_) {
    throw new HttpError(400, 'invalid_json', 'Corpo JSON invalido.');
  }
}

function requireEnv(name: string) {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Variavel de ambiente ausente: ${name}`);
  return value;
}

function jsonResponse(body: JsonRecord, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
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
