import { createClient } from 'npm:@supabase/supabase-js@2';

import { corsHeaders } from '../_shared/cors.ts';

type UsageBucket = {
  timestamp: string;
  total_auth_requests?: number;
  total_realtime_requests?: number;
  total_rest_requests?: number;
  total_storage_requests?: number;
};

type RpcMetricResult = {
  value: number;
  available: boolean;
  warning?: string;
};

const allowedPermissions = new Set([
  'billing.manage',
  'infra.sync_usage',
  'settings.manage',
]);

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return jsonResponse(
      { error: 'method_not_allowed', message: 'Use POST para sincronizar o uso.' },
      405,
    );
  }

  try {
    const supabaseUrl = requireEnv('SUPABASE_URL');
    const supabaseAnonKey = requireEnv('SUPABASE_ANON_KEY');
    const serviceRoleKey = requireEnv('SUPABASE_SERVICE_ROLE_KEY');
    const managementToken = requireEnv('GRANITH_MANAGEMENT_API_TOKEN');

    const authHeader = request.headers.get('Authorization');
    if (!authHeader) {
      return jsonResponse(
        {
          error: 'missing_authorization',
          message: 'Cabecalho Authorization ausente.',
        },
        401,
      );
    }

    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: {
          Authorization: authHeader,
        },
      },
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });

    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });

    const {
      data: { user },
      error: authError,
    } = await userClient.auth.getUser();

    if (authError || !user) {
      return jsonResponse(
        {
          error: 'invalid_session',
          message: 'Sessao invalida para sincronizar uso do Supabase.',
          details: authError?.message,
        },
        401,
      );
    }

    const { data: profile, error: profileError } = await adminClient
      .from('users')
      .select('role, permissions')
      .eq('id', user.id)
      .maybeSingle();

    if (profileError) {
      return jsonResponse(
        {
          error: 'profile_lookup_failed',
          message: 'Nao foi possivel validar o perfil do usuario.',
          details: profileError.message,
        },
        500,
      );
    }

    const role = String(profile?.role ?? '');
    const permissions = Array.isArray(profile?.permissions)
      ? profile.permissions.map((value: unknown) => String(value))
      : [];

    const isAllowed =
      role === 'admin' ||
      permissions.some((permission) => allowedPermissions.has(permission));

    if (!isAllowed) {
      return jsonResponse(
        {
          error: 'forbidden',
          message:
            'Somente administradores ou usuarios com permissao de billing podem sincronizar o uso.',
        },
        403,
      );
    }

    const body = await readBody(request);
    const projectRef =
      body.projectRef?.toString().trim() ||
      Deno.env.get('GRANITH_PROJECT_REF')?.trim() ||
      inferProjectRef(supabaseUrl);
    const interval = body.interval?.toString().trim() || '24h';
    const now = new Date();
    const fallbackPeriodStart = new Date(
      Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1),
    );
    const documentId = `${projectRef}_${now.getUTCMonth() + 1}_${now.getUTCFullYear()}`;

    const usageCounts = await fetchUsageCounts({
      managementToken,
      projectRef,
      interval,
    });

    const totalRestRequests = usageCounts.reduce(
      (sum, bucket) => sum + (bucket.total_rest_requests ?? 0),
      0,
    );
    const totalAuthRequests = usageCounts.reduce(
      (sum, bucket) => sum + (bucket.total_auth_requests ?? 0),
      0,
    );
    const totalStorageRequests = usageCounts.reduce(
      (sum, bucket) => sum + (bucket.total_storage_requests ?? 0),
      0,
    );
    const totalRealtimeRequests = usageCounts.reduce(
      (sum, bucket) => sum + (bucket.total_realtime_requests ?? 0),
      0,
    );
    const totalApiRequests =
      totalRestRequests +
      totalAuthRequests +
      totalStorageRequests +
      totalRealtimeRequests;

    const dailyOperations = aggregateDailyOperations(usageCounts);
    const peakDayOperations = Object.values(dailyOperations).reduce(
      (peak, current) => (current > peak ? current : peak),
      0,
    );
    const periodStart =
      usageCounts.length > 0
        ? usageCounts.reduce((earliest, bucket) => {
            const current = new Date(bucket.timestamp);
            return current.getTime() < earliest.getTime() ? current : earliest;
          }, new Date(usageCounts[0].timestamp))
        : fallbackPeriodStart;

    const warnings: string[] = [];

    const databaseUsage = await readRpcMetric(
      adminClient,
      'get_database_usage_mb',
      warnings,
      'medicao do banco',
    );
    const storageUsage = await readRpcMetric(
      adminClient,
      'get_storage_usage_mb',
      warnings,
      'medicao de arquivos',
    );

    const hasCompleteInfraMetrics =
      databaseUsage.available && storageUsage.available;
    const sourceLabel = hasCompleteInfraMetrics
      ? 'Dados completos de uso e armazenamento'
      : 'Dados parciais de uso';
    const successMessage = hasCompleteInfraMetrics
      ? 'Dados da plataforma atualizados com sucesso.'
      : 'Dados da plataforma atualizados com informacoes parciais.';

    const payload = {
      id: documentId,
      tenantId: projectRef,
      projectRef,
      totalReads: totalRestRequests,
      totalWrites:
        totalAuthRequests + totalStorageRequests + totalRealtimeRequests,
      totalApiRequests,
      totalRestRequests,
      totalAuthRequests,
      totalStorageRequests,
      totalRealtimeRequests,
      databaseUsedMB: databaseUsage.value,
      storageUsedMB: storageUsage.value,
      aiRequests: 0,
      periodStart: periodStart.toISOString(),
      periodEnd: now.toISOString(),
      dailyOperations,
      peakDayOperations,
      sourceLabel,
      lastSyncedAt: now.toISOString(),
    };

    const { error: upsertError } = await adminClient
      .from('usage_stats')
      .upsert(payload);

    if (upsertError) {
      throw new Error(`Falha ao salvar snapshot: ${upsertError.message}`);
    }

    return jsonResponse({
      ok: true,
      message: successMessage,
      documentId,
      projectRef,
      interval,
      warnings,
      totals: {
        totalApiRequests,
        totalRestRequests,
        totalAuthRequests,
        totalStorageRequests,
        totalRealtimeRequests,
        databaseUsedMB: databaseUsage.value,
        storageUsedMB: storageUsage.value,
      },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return jsonResponse(
      {
        error: 'sync_failed',
        message: 'Nao foi possivel sincronizar o uso do Supabase.',
        details: message,
      },
      500,
    );
  }
});

function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`Segredo/variavel obrigatoria ausente: ${name}`);
  }
  return value;
}

function inferProjectRef(supabaseUrl: string): string {
  const url = new URL(supabaseUrl);
  return url.host.split('.')[0] ?? 'granith';
}

async function readBody(request: Request): Promise<Record<string, unknown>> {
  try {
    const raw = await request.text();
    if (!raw.trim()) {
      return {};
    }
    return JSON.parse(raw) as Record<string, unknown>;
  } catch {
    return {};
  }
}

async function fetchUsageCounts({
  managementToken,
  projectRef,
  interval,
}: {
  managementToken: string;
  projectRef: string;
  interval: string;
}): Promise<UsageBucket[]> {
  const query = new URLSearchParams();
  if (interval.trim().isNotEmpty) {
    query.set('interval', interval.trim());
  }

  const response = await fetch(
    `https://api.supabase.com/v1/projects/${projectRef}/analytics/endpoints/usage.api-counts${
      query.toString().isEmpty ? '' : `?${query.toString()}`
    }`,
    {
      headers: {
        Authorization: `Bearer ${managementToken}`,
        'Content-Type': 'application/json',
      },
    },
  );

  const rawText = await response.text();
  let parsed: Record<string, unknown> = {};
  if (rawText) {
    try {
      parsed = JSON.parse(rawText) as Record<string, unknown>;
    } catch {
      parsed = { error: rawText };
    }
  }

  if (!response.ok) {
    throw new Error(
      `Management API respondeu ${response.status}: ${parsed.error ?? rawText}`,
    );
  }

  return Array.isArray(parsed.result) ? (parsed.result as UsageBucket[]) : [];
}

function aggregateDailyOperations(buckets: UsageBucket[]): Record<string, number> {
  const aggregated: Record<string, number> = {};

  for (const bucket of buckets) {
    if (!bucket.timestamp) {
      continue;
    }

    const dayKey = bucket.timestamp.slice(0, 10);
    const bucketTotal =
      (bucket.total_rest_requests ?? 0) +
      (bucket.total_auth_requests ?? 0) +
      (bucket.total_storage_requests ?? 0) +
      (bucket.total_realtime_requests ?? 0);

    aggregated[dayKey] = (aggregated[dayKey] ?? 0) + bucketTotal;
  }

  return aggregated;
}

async function readRpcMetric(
  adminClient: ReturnType<typeof createClient>,
  functionName: string,
  warnings: string[],
  label: string,
): Promise<RpcMetricResult> {
  const { data, error } = await adminClient.rpc(functionName);

  if (!error) {
    return {
      value: Number(data ?? 0),
      available: true,
    };
  }

  const errorText = `${error.message ?? ''} ${error.details ?? ''} ${error.hint ?? ''}`;
  const normalized = errorText.toLowerCase();
  const functionNameLower = functionName.toLowerCase();

  if (
    normalized.includes('schema cache') ||
    normalized.includes('could not find the function') ||
    normalized.includes(functionNameLower)
  ) {
    warnings.push(
      `${label} indisponivel no banco atual. A sincronizacao seguiu sem esse indicador.`,
    );
    return {
      value: 0,
      available: false,
      warning: error.message,
    };
  }

  throw new Error(`Falha ao consultar ${label}: ${error.message}`);
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}
