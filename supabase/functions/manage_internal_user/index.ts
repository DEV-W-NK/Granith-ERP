import { createClient } from 'npm:@supabase/supabase-js@2';

import { corsHeaders } from '../_shared/cors.ts';

const internalLoginDomain = 'internal.granith.local';
const allowedPermissions = new Set(['access.manage', 'settings.manage']);
const allowedRoles = new Set(['admin', 'employee']);

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return jsonResponse(
      { error: 'method_not_allowed', message: 'Use POST para gerenciar usuarios internos.' },
      405,
    );
  }

  try {
    const supabaseUrl = requireEnv('SUPABASE_URL');
    const supabaseAnonKey = requireEnv('SUPABASE_ANON_KEY');
    const serviceRoleKey = requireEnv('SUPABASE_SERVICE_ROLE_KEY');
    const authHeader = request.headers.get('Authorization');

    if (!authHeader) {
      return jsonResponse(
        { error: 'missing_authorization', message: 'Sessao ausente.' },
        401,
      );
    }

    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const {
      data: { user: requester },
      error: authError,
    } = await userClient.auth.getUser();

    if (authError || !requester) {
      return jsonResponse(
        { error: 'invalid_session', message: 'Sessao invalida.' },
        401,
      );
    }

    const requesterProfile = await fetchRequesterProfile(adminClient, requester);
    if (!canManageAccess(requesterProfile)) {
      return jsonResponse(
        {
          error: 'forbidden',
          message: 'Somente usuarios com permissao de acessos podem gerenciar usuarios internos.',
        },
        403,
      );
    }

    const body = await readBody(request);
    const action = String(body.action ?? '').trim();

    if (action === 'create') {
      return await createInternalUser(adminClient, body);
    }

    if (action === 'reset_password') {
      return await resetInternalPassword(adminClient, body);
    }

    return jsonResponse(
      { error: 'invalid_action', message: 'Acao de usuario interno invalida.' },
      400,
    );
  } catch (error) {
    const details = error instanceof Error ? error.message : String(error);
    const body: Record<string, unknown> = {
      error: 'internal_user_failed',
      message: 'Nao foi possivel gerenciar o usuario interno.',
    };

    if (Deno.env.get('GRANITH_DEBUG_ERRORS') === 'true') {
      body.details = details;
    }

    return jsonResponse(body, 500);
  }
});

async function createInternalUser(adminClient: ReturnType<typeof createClient>, body: Record<string, unknown>) {
  const username = normalizeUsername(String(body.username ?? ''));
  const usernameError = validateUsername(username);
  if (usernameError) {
    return jsonResponse({ error: 'invalid_username', message: usernameError }, 400);
  }

  const password = String(body.password ?? '');
  if (password.trim().length < 8) {
    return jsonResponse(
      { error: 'weak_password', message: 'A senha precisa ter pelo menos 8 caracteres.' },
      400,
    );
  }

  const displayName = String(body.displayName ?? username).trim() || username;
  const role = normalizeRole(String(body.role ?? 'employee'));
  const permissions = normalizePermissions(body.permissions);
  let employeeBinding;
  try {
    employeeBinding = await resolveEmployeeBinding(adminClient, body);
  } catch (error) {
    return jsonResponse(
      {
        error: 'invalid_employee_binding',
        message: error instanceof Error ? error.message : 'Colaborador vinculado invalido.',
      },
      400,
    );
  }
  const loginEmail = internalLoginEmailForUsername(username);

  const existing = await adminClient
    .from('users')
    .select('id')
    .or(`username.eq.${username},login_username.eq.${username},internal_login_email.eq.${loginEmail},email.eq.${loginEmail}`)
    .maybeSingle();

  if (existing.data) {
    return jsonResponse(
      { error: 'username_exists', message: 'Esse usuario interno ja existe.' },
      409,
    );
  }

  const { data: created, error: createError } = await adminClient.auth.admin.createUser({
    email: loginEmail,
    password,
    email_confirm: true,
    user_metadata: {
      full_name: displayName,
      internal_username: username,
      auth_provider: 'internal',
    },
  });

  if (createError || !created.user) {
    return jsonResponse(
      {
        error: 'auth_create_failed',
        message: friendlyAuthError(createError?.message ?? 'Nao foi possivel criar o login.'),
      },
      400,
    );
  }

  const now = new Date().toISOString();
  const payload = {
    id: created.user.id,
    email: loginEmail,
    displayName,
    display_name: displayName,
    status: 'ativo',
    permissions,
    role,
    username,
    login_username: username,
    internalLoginEmail: loginEmail,
    internal_login_email: loginEmail,
    authProvider: 'internal',
    auth_provider: 'internal',
    employeeId: employeeBinding.employeeId,
    employee_id: employeeBinding.employeeId,
    employeeName: employeeBinding.employeeName,
    employee_name: employeeBinding.employeeName,
    created_at: now,
    updated_at: now,
  };

  const { data: profile, error: profileError } = await adminClient
    .from('users')
    .upsert(payload)
    .select('id,email,displayName,display_name,photoUrl,photo_url,status,permissions,role,clientAccountId,client_account_id,clientAccountName,client_account_name,username,login_username,internalLoginEmail,internal_login_email,authProvider,auth_provider,employeeId,employee_id,employeeName,employee_name')
    .single();

  if (profileError) {
    await adminClient.auth.admin.deleteUser(created.user.id);
    return jsonResponse(
      { error: 'profile_create_failed', message: 'Login criado, mas o perfil nao foi salvo.' },
      500,
    );
  }

  return jsonResponse({ ok: true, user: profile });
}

async function resolveEmployeeBinding(
  adminClient: ReturnType<typeof createClient>,
  body: Record<string, unknown>,
) {
  const requestedEmployeeId = String(body.employeeId ?? body.employee_id ?? '').trim();
  const requestedEmployeeName = String(body.employeeName ?? body.employee_name ?? '').trim();

  if (!requestedEmployeeId) {
    return {
      employeeId: null,
      employeeName: requestedEmployeeName || null,
    };
  }

  const { data: employee, error } = await adminClient
    .from('employees')
    .select('id,name,status')
    .eq('id', requestedEmployeeId)
    .maybeSingle();

  if (error || !employee) {
    throw new Error('Colaborador vinculado nao encontrado.');
  }

  if (employee.status === 'desligado') {
    throw new Error('Nao vincule usuario interno a colaborador desligado.');
  }

  return {
    employeeId: String(employee.id),
    employeeName: String(employee.name ?? requestedEmployeeName),
  };
}

async function resetInternalPassword(adminClient: ReturnType<typeof createClient>, body: Record<string, unknown>) {
  const userId = String(body.userId ?? '').trim();
  const password = String(body.password ?? '');

  if (!userId) {
    return jsonResponse({ error: 'missing_user', message: 'Usuario nao informado.' }, 400);
  }
  if (password.trim().length < 8) {
    return jsonResponse(
      { error: 'weak_password', message: 'A senha precisa ter pelo menos 8 caracteres.' },
      400,
    );
  }

  const { data: profile, error: profileError } = await adminClient
    .from('users')
    .select('id,username,internal_login_email,auth_provider')
    .eq('id', userId)
    .maybeSingle();

  if (profileError || !profile) {
    return jsonResponse(
      { error: 'profile_not_found', message: 'Usuario interno nao encontrado.' },
      404,
    );
  }

  if (profile.auth_provider !== 'internal' && !profile.username) {
    return jsonResponse(
      { error: 'not_internal_user', message: 'Apenas usuarios internos podem ter senha redefinida aqui.' },
      400,
    );
  }

  const { error: updateError } = await adminClient.auth.admin.updateUserById(userId, {
    password,
  });

  if (updateError) {
    return jsonResponse(
      { error: 'password_update_failed', message: friendlyAuthError(updateError.message) },
      400,
    );
  }

  await adminClient
    .from('users')
    .update({ updated_at: new Date().toISOString() })
    .eq('id', userId);

  return jsonResponse({ ok: true });
}

async function fetchRequesterProfile(adminClient: ReturnType<typeof createClient>, requester: { id: string; email?: string }) {
  const byId = await adminClient
    .from('users')
    .select('role,permissions')
    .eq('id', requester.id)
    .maybeSingle();

  if (byId.data) return byId.data;

  const email = requester.email?.trim().toLowerCase();
  if (!email) return null;

  const byEmail = await adminClient
    .from('users')
    .select('role,permissions')
    .ilike('email', email)
    .maybeSingle();

  return byEmail.data ?? null;
}

function canManageAccess(profile: { role?: unknown; permissions?: unknown } | null) {
  const role = String(profile?.role ?? '');
  const permissions = Array.isArray(profile?.permissions)
    ? profile.permissions.map((value) => String(value))
    : [];

  return role === 'admin' || permissions.some((permission) => allowedPermissions.has(permission));
}

async function readBody(request: Request): Promise<Record<string, unknown>> {
  try {
    const value = await request.json();
    return value && typeof value === 'object' ? value as Record<string, unknown> : {};
  } catch (_) {
    return {};
  }
}

function requireEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) {
    throw new Error(`Variavel ${name} nao configurada.`);
  }
  return value;
}

function normalizeUsername(value: string) {
  return value.trim().toLowerCase();
}

function validateUsername(value: string) {
  const username = normalizeUsername(value);
  if (!username) return 'Informe o usuario para prosseguir.';
  if (username.length < 3 || username.length > 32) {
    return 'O usuario precisa ter entre 3 e 32 caracteres.';
  }
  if (!/^[a-z0-9][a-z0-9._-]*[a-z0-9]$/.test(username)) {
    return 'Use apenas letras, numeros, ponto, hifen ou sublinhado, sem espacos.';
  }
  if (username.includes('..') || username.includes('__') || username.includes('--')) {
    return 'O usuario nao pode ter separadores repetidos.';
  }
  return null;
}

function internalLoginEmailForUsername(username: string) {
  return `${normalizeUsername(username)}@${internalLoginDomain}`;
}

function normalizeRole(value: string) {
  const role = value.trim();
  return allowedRoles.has(role) ? role : 'employee';
}

function normalizePermissions(value: unknown) {
  if (!Array.isArray(value)) return [];
  return [...new Set(value.map((item) => String(item).trim()).filter(Boolean))];
}

function friendlyAuthError(message: string) {
  const lower = message.toLowerCase();
  if (lower.includes('already') || lower.includes('registered')) {
    return 'Esse usuario interno ja existe.';
  }
  if (lower.includes('password')) {
    return 'A senha informada nao atende aos requisitos minimos.';
  }
  return message;
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
