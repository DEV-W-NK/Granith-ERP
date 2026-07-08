-- Base para push notifications entre Granith ERP e Granith Mobile.
-- O app registra o token FCM do aparelho e o ERP/Edge Functions usam os
-- tokens ativos para enviar notificacoes operacionais.

create or replace function private.current_user_employee_id()
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(
    nullif(u.employee_id, ''),
    nullif(u."employeeId", ''),
    (
      select e.id::text
      from public.employees e
      where lower(e.email) = lower(u.email)
      limit 1
    )
  )
  from public.users u
  where u.id::text = (select auth.uid())::text
  limit 1;
$$;

grant execute on function private.current_user_employee_id() to authenticated;

create table if not exists public.mobile_device_tokens (
  id text primary key default gen_random_uuid()::text,
  "userId" text not null references public.users(id) on delete cascade,
  "employeeId" text references public.employees(id) on delete set null,
  "fcmToken" text not null,
  platform text not null default 'android',
  "deviceId" text not null default '',
  "deviceName" text not null default '',
  "appVersion" text not null default '',
  "buildNumber" text not null default '',
  "permissionStatus" text not null default 'unknown',
  "isActive" boolean not null default true,
  "lastSeenAt" timestamptz not null default now(),
  "revokedAt" timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint mobile_device_tokens_platform_check check (
    platform in ('android', 'ios', 'web', 'desktop', 'unknown')
  ),
  constraint mobile_device_tokens_permission_check check (
    "permissionStatus" in (
      'authorized',
      'denied',
      'provisional',
      'not_determined',
      'unknown'
    )
  )
);

create unique index if not exists mobile_device_tokens_fcm_token_unique
  on public.mobile_device_tokens ("fcmToken");

create index if not exists idx_mobile_device_tokens_user_active
  on public.mobile_device_tokens ("userId", "isActive", "lastSeenAt" desc);

create index if not exists idx_mobile_device_tokens_employee_active
  on public.mobile_device_tokens ("employeeId", "isActive", "lastSeenAt" desc)
  where "employeeId" is not null;

create index if not exists idx_mobile_device_tokens_last_seen
  on public.mobile_device_tokens ("lastSeenAt" desc);

drop trigger if exists trg_mobile_device_tokens_updated_at
  on public.mobile_device_tokens;
create trigger trg_mobile_device_tokens_updated_at
before update on public.mobile_device_tokens
for each row execute function public.set_updated_at();

alter table public.mobile_device_tokens enable row level security;

drop policy if exists mobile_device_tokens_select_own
  on public.mobile_device_tokens;
create policy mobile_device_tokens_select_own
on public.mobile_device_tokens
for select
to authenticated
using (
  "userId"::text = (select auth.uid())::text
  or private.can_manage_access()
);

drop policy if exists mobile_device_tokens_insert_own
  on public.mobile_device_tokens;
create policy mobile_device_tokens_insert_own
on public.mobile_device_tokens
for insert
to authenticated
with check (
  "userId"::text = (select auth.uid())::text
  and (
    "employeeId" is null
    or "employeeId"::text = private.current_user_employee_id()
    or private.can_manage_access()
  )
);

drop policy if exists mobile_device_tokens_update_own
  on public.mobile_device_tokens;
create policy mobile_device_tokens_update_own
on public.mobile_device_tokens
for update
to authenticated
using (
  "userId"::text = (select auth.uid())::text
  or private.can_manage_access()
)
with check (
  private.can_manage_access()
  or (
    "userId"::text = (select auth.uid())::text
    and (
      "employeeId" is null
      or "employeeId"::text = private.current_user_employee_id()
    )
  )
);

drop policy if exists mobile_device_tokens_delete_own
  on public.mobile_device_tokens;
create policy mobile_device_tokens_delete_own
on public.mobile_device_tokens
for delete
to authenticated
using (
  "userId"::text = (select auth.uid())::text
  or private.can_manage_access()
);

grant select, insert, update, delete
on public.mobile_device_tokens
to authenticated;

create table if not exists public.mobile_push_notifications (
  id text primary key default gen_random_uuid()::text,
  "recipientUserId" text references public.users(id) on delete cascade,
  "recipientEmployeeId" text references public.employees(id) on delete set null,
  title text not null,
  body text not null default '',
  category text not null default 'system',
  "actionRoute" text not null default '',
  payload jsonb not null default '{}'::jsonb,
  priority text not null default 'normal',
  status text not null default 'pending',
  "createdByUserId" text references public.users(id) on delete set null,
  "sentAt" timestamptz,
  "readAt" timestamptz,
  "errorMessage" text not null default '',
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint mobile_push_notifications_recipient_check check (
    "recipientUserId" is not null or "recipientEmployeeId" is not null
  ),
  constraint mobile_push_notifications_category_check check (
    category in (
      'route',
      'project',
      'material',
      'requisition',
      'purchase',
      'timeClock',
      'measurement',
      'vehicle',
      'system'
    )
  ),
  constraint mobile_push_notifications_priority_check check (
    priority in ('low', 'normal', 'high')
  ),
  constraint mobile_push_notifications_status_check check (
    status in ('pending', 'sent', 'failed', 'cancelled', 'read')
  )
);

create index if not exists idx_mobile_push_notifications_user_status
  on public.mobile_push_notifications (
    "recipientUserId",
    status,
    "createdAt" desc
  )
  where "recipientUserId" is not null;

create index if not exists idx_mobile_push_notifications_employee_status
  on public.mobile_push_notifications (
    "recipientEmployeeId",
    status,
    "createdAt" desc
  )
  where "recipientEmployeeId" is not null;

create index if not exists idx_mobile_push_notifications_dispatch
  on public.mobile_push_notifications (status, priority, "createdAt")
  where status = 'pending';

drop trigger if exists trg_mobile_push_notifications_updated_at
  on public.mobile_push_notifications;
create trigger trg_mobile_push_notifications_updated_at
before update on public.mobile_push_notifications
for each row execute function public.set_updated_at();

alter table public.mobile_push_notifications enable row level security;

drop policy if exists mobile_push_notifications_select_recipient
  on public.mobile_push_notifications;
create policy mobile_push_notifications_select_recipient
on public.mobile_push_notifications
for select
to authenticated
using (
  "recipientUserId"::text = (select auth.uid())::text
  or "recipientEmployeeId"::text = private.current_user_employee_id()
  or private.can_manage_access()
);

drop policy if exists mobile_push_notifications_update_read_recipient
  on public.mobile_push_notifications;
create policy mobile_push_notifications_update_read_recipient
on public.mobile_push_notifications
for update
to authenticated
using (
  "recipientUserId"::text = (select auth.uid())::text
  or "recipientEmployeeId"::text = private.current_user_employee_id()
  or private.can_manage_access()
)
with check (
  "recipientUserId"::text = (select auth.uid())::text
  or "recipientEmployeeId"::text = private.current_user_employee_id()
  or private.can_manage_access()
);

drop policy if exists mobile_push_notifications_insert_managers
  on public.mobile_push_notifications;
create policy mobile_push_notifications_insert_managers
on public.mobile_push_notifications
for insert
to authenticated
with check (private.can_manage_access());

drop policy if exists mobile_push_notifications_delete_managers
  on public.mobile_push_notifications;
create policy mobile_push_notifications_delete_managers
on public.mobile_push_notifications
for delete
to authenticated
using (private.can_manage_access());

grant select, insert, update, delete
on public.mobile_push_notifications
to authenticated;

create or replace function public.register_mobile_fcm_token(
  p_fcm_token text,
  p_platform text default 'android',
  p_device_id text default '',
  p_device_name text default '',
  p_app_version text default '',
  p_build_number text default '',
  p_permission_status text default 'unknown',
  p_metadata jsonb default '{}'::jsonb
)
returns public.mobile_device_tokens
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_user_id text := (select auth.uid())::text;
  v_employee_id text := private.current_user_employee_id();
  v_token public.mobile_device_tokens;
begin
  if v_user_id is null or v_user_id = '' then
    raise exception 'Usuario autenticado obrigatorio para registrar token FCM.';
  end if;

  if nullif(trim(p_fcm_token), '') is null then
    raise exception 'Token FCM obrigatorio.';
  end if;

  insert into public.mobile_device_tokens (
    "userId",
    "employeeId",
    "fcmToken",
    platform,
    "deviceId",
    "deviceName",
    "appVersion",
    "buildNumber",
    "permissionStatus",
    "isActive",
    "lastSeenAt",
    "revokedAt",
    metadata
  )
  values (
    v_user_id,
    v_employee_id,
    trim(p_fcm_token),
    coalesce(nullif(p_platform, ''), 'android'),
    coalesce(p_device_id, ''),
    coalesce(p_device_name, ''),
    coalesce(p_app_version, ''),
    coalesce(p_build_number, ''),
    coalesce(nullif(p_permission_status, ''), 'unknown'),
    true,
    now(),
    null,
    coalesce(p_metadata, '{}'::jsonb)
  )
  on conflict ("fcmToken") do update
  set
    "userId" = excluded."userId",
    "employeeId" = excluded."employeeId",
    platform = excluded.platform,
    "deviceId" = excluded."deviceId",
    "deviceName" = excluded."deviceName",
    "appVersion" = excluded."appVersion",
    "buildNumber" = excluded."buildNumber",
    "permissionStatus" = excluded."permissionStatus",
    "isActive" = true,
    "lastSeenAt" = now(),
    "revokedAt" = null,
    metadata = excluded.metadata,
    "updatedAt" = now()
  returning * into v_token;

  return v_token;
end;
$$;

grant execute on function public.register_mobile_fcm_token(
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  jsonb
) to authenticated;

create or replace function public.revoke_mobile_fcm_token(p_fcm_token text)
returns void
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_user_id text := (select auth.uid())::text;
begin
  if v_user_id is null or v_user_id = '' then
    raise exception 'Usuario autenticado obrigatorio para revogar token FCM.';
  end if;

  update public.mobile_device_tokens
  set
    "isActive" = false,
    "revokedAt" = now(),
    "updatedAt" = now()
  where "fcmToken" = p_fcm_token
    and "userId" = v_user_id;
end;
$$;

grant execute on function public.revoke_mobile_fcm_token(text) to authenticated;
