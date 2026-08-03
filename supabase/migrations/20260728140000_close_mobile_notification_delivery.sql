-- Fecha o ciclo de notificacoes mobile:
-- - leitura/dispensa sincronizadas e controladas por RPC;
-- - claim concorrente e recuperacao de workers interrompidos;
-- - entrega e retry independentes por dispositivo;
-- - scheduler pg_cron autenticado por lease descartavel.

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;
create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron with schema pg_catalog;

alter table public.mobile_push_notifications
  add column if not exists "dismissedAt" timestamptz,
  add column if not exists "processingAt" timestamptz,
  add column if not exists "processingBy" text;

alter table public.mobile_push_notifications
  drop constraint if exists mobile_push_notifications_status_check;

alter table public.mobile_push_notifications
  add constraint mobile_push_notifications_status_check check (
    status in (
      'pending',
      'processing',
      'sent',
      'failed',
      'cancelled',
      'read'
    )
  );

create index if not exists idx_mobile_push_notifications_recipient_visible
  on public.mobile_push_notifications (
    "recipientUserId",
    "recipientEmployeeId",
    "createdAt" desc
  )
  where "dismissedAt" is null;

create table if not exists public.mobile_push_deliveries (
  id text primary key default gen_random_uuid()::text,
  "notificationId" text not null
    references public.mobile_push_notifications(id) on delete cascade,
  "deviceTokenId" text
    references public.mobile_device_tokens(id) on delete set null,
  status text not null default 'pending',
  attempts integer not null default 0,
  "maxAttempts" integer not null default 5,
  "nextAttemptAt" timestamptz not null default now(),
  "lastAttemptAt" timestamptz,
  "sentAt" timestamptz,
  "errorMessage" text not null default '',
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint mobile_push_deliveries_status_check check (
    status in ('pending', 'sent', 'failed')
  ),
  constraint mobile_push_deliveries_attempts_check check (
    attempts >= 0
    and "maxAttempts" between 1 and 20
    and attempts <= "maxAttempts"
  )
);

create unique index if not exists mobile_push_deliveries_notification_token_uq
  on public.mobile_push_deliveries ("notificationId", "deviceTokenId");

create index if not exists idx_mobile_push_deliveries_retry
  on public.mobile_push_deliveries (
    status,
    "nextAttemptAt",
    "notificationId"
  )
  where status = 'pending';

drop trigger if exists trg_mobile_push_deliveries_updated_at
  on public.mobile_push_deliveries;
create trigger trg_mobile_push_deliveries_updated_at
before update on public.mobile_push_deliveries
for each row execute function public.set_updated_at();

alter table public.mobile_push_deliveries enable row level security;
revoke all on public.mobile_push_deliveries from public, anon, authenticated;
grant select, insert, update, delete
  on public.mobile_push_deliveries to service_role;

drop policy if exists mobile_push_notifications_select_recipient
  on public.mobile_push_notifications;
create policy mobile_push_notifications_select_recipient
on public.mobile_push_notifications
for select
to authenticated
using (
  "dismissedAt" is null
  and (
    "recipientUserId"::text = (select auth.uid())::text
    or "recipientEmployeeId"::text = private.current_user_employee_id()
  )
);

drop policy if exists mobile_push_notifications_update_read_recipient
  on public.mobile_push_notifications;
drop policy if exists mobile_push_notifications_update_authorized
  on public.mobile_push_notifications;
revoke update on public.mobile_push_notifications from authenticated;

create or replace function public.set_mobile_push_notification_state(
  p_notification_id text,
  p_action text
)
returns boolean
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_user_id text := (select auth.uid())::text;
  v_employee_id text := private.current_user_employee_id();
  v_updated integer;
  v_action text := lower(trim(coalesce(p_action, '')));
begin
  if v_user_id is null or v_user_id = '' then
    raise exception 'Authenticated user is required.'
      using errcode = '42501';
  end if;

  if v_action not in ('read', 'dismiss') then
    raise exception 'Unsupported notification action.'
      using errcode = '22023';
  end if;

  update public.mobile_push_notifications notification
     set "readAt" = coalesce(notification."readAt", clock_timestamp()),
         "dismissedAt" = case
           when v_action = 'dismiss'
             then coalesce(notification."dismissedAt", clock_timestamp())
           else notification."dismissedAt"
         end,
         status = case
           when notification.status in ('pending', 'processing', 'sent')
             then 'read'
           else notification.status
         end,
         "processingAt" = null,
         "processingBy" = null,
         "nextAttemptAt" = case
           when notification.status in ('pending', 'processing')
             then null
           else notification."nextAttemptAt"
         end,
         "updatedAt" = clock_timestamp()
   where notification.id = p_notification_id
     and (
       notification."recipientUserId"::text = v_user_id
       or (
         v_employee_id is not null
         and notification."recipientEmployeeId"::text = v_employee_id
       )
     );

  get diagnostics v_updated = row_count;
  return v_updated > 0;
end;
$$;

revoke all on function public.set_mobile_push_notification_state(text, text)
  from public, anon;
grant execute on function public.set_mobile_push_notification_state(text, text)
  to authenticated;

create or replace function public.mark_all_mobile_push_notifications_read()
returns integer
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_user_id text := (select auth.uid())::text;
  v_employee_id text := private.current_user_employee_id();
  v_updated integer;
begin
  if v_user_id is null or v_user_id = '' then
    raise exception 'Authenticated user is required.'
      using errcode = '42501';
  end if;

  update public.mobile_push_notifications notification
     set "readAt" = coalesce(notification."readAt", clock_timestamp()),
         status = case
           when notification.status in ('pending', 'processing', 'sent')
             then 'read'
           else notification.status
         end,
         "processingAt" = null,
         "processingBy" = null,
         "nextAttemptAt" = case
           when notification.status in ('pending', 'processing')
             then null
           else notification."nextAttemptAt"
         end,
         "updatedAt" = clock_timestamp()
   where notification."dismissedAt" is null
     and notification."readAt" is null
     and (
       notification."recipientUserId"::text = v_user_id
       or (
         v_employee_id is not null
         and notification."recipientEmployeeId"::text = v_employee_id
       )
     );

  get diagnostics v_updated = row_count;
  return v_updated;
end;
$$;

revoke all on function public.mark_all_mobile_push_notifications_read()
  from public, anon;
grant execute on function public.mark_all_mobile_push_notifications_read()
  to authenticated;

create or replace function public.claim_mobile_push_notifications(
  p_limit integer default 25,
  p_worker_id text default null
)
returns setof public.mobile_push_notifications
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_limit integer := greatest(1, least(coalesce(p_limit, 25), 100));
  v_worker_id text := coalesce(
    nullif(trim(p_worker_id), ''),
    gen_random_uuid()::text
  );
begin
  update public.mobile_push_notifications
     set status = 'pending',
         "processingAt" = null,
         "processingBy" = null,
         "nextAttemptAt" = least(
           coalesce("nextAttemptAt", clock_timestamp()),
           clock_timestamp()
         ),
         "updatedAt" = clock_timestamp()
   where status = 'processing'
     and "processingAt" < clock_timestamp() - interval '5 minutes'
     and "dismissedAt" is null;

  return query
  with candidates as (
    select notification.id
      from public.mobile_push_notifications notification
     where notification.status = 'pending'
       and notification."dismissedAt" is null
       and coalesce(
         notification."nextAttemptAt",
         notification."createdAt"
       ) <= clock_timestamp()
     order by
       case notification.priority
         when 'high' then 0
         when 'normal' then 1
         else 2
       end,
       notification."createdAt"
     for update skip locked
     limit v_limit
  )
  update public.mobile_push_notifications notification
     set status = 'processing',
         "processingAt" = clock_timestamp(),
         "processingBy" = v_worker_id,
         "updatedAt" = clock_timestamp()
    from candidates
   where notification.id = candidates.id
  returning notification.*;
end;
$$;

revoke all on function public.claim_mobile_push_notifications(integer, text)
  from public, anon, authenticated;
grant execute on function public.claim_mobile_push_notifications(integer, text)
  to service_role;

create table if not exists private.mobile_push_dispatch_leases (
  "tokenHash" text primary key,
  "expiresAt" timestamptz not null,
  "consumedAt" timestamptz,
  "createdAt" timestamptz not null default now()
);

create index if not exists idx_mobile_push_dispatch_leases_expiry
  on private.mobile_push_dispatch_leases ("expiresAt");

create table if not exists private.mobile_push_dispatch_runtime (
  id boolean primary key default true check (id),
  "functionUrl" text not null,
  "updatedAt" timestamptz not null default now()
);

revoke all on private.mobile_push_dispatch_leases
  from public, anon, authenticated;
revoke all on private.mobile_push_dispatch_runtime
  from public, anon, authenticated;

create or replace function private.create_mobile_push_dispatch_lease()
returns text
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_token text := encode(gen_random_bytes(32), 'hex');
begin
  delete from private.mobile_push_dispatch_leases
   where "expiresAt" < clock_timestamp() - interval '1 hour'
      or "consumedAt" < clock_timestamp() - interval '1 hour';

  insert into private.mobile_push_dispatch_leases (
    "tokenHash",
    "expiresAt"
  )
  values (
    encode(digest(v_token, 'sha256'), 'hex'),
    clock_timestamp() + interval '2 minutes'
  );

  return v_token;
end;
$$;

revoke all on function private.create_mobile_push_dispatch_lease()
  from public, anon, authenticated;

create or replace function public.consume_mobile_push_dispatch_lease(
  p_token text
)
returns boolean
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_consumed integer;
begin
  if nullif(trim(coalesce(p_token, '')), '') is null then
    return false;
  end if;

  update private.mobile_push_dispatch_leases lease
     set "consumedAt" = clock_timestamp()
   where lease."tokenHash" = encode(digest(trim(p_token), 'sha256'), 'hex')
     and lease."consumedAt" is null
     and lease."expiresAt" >= clock_timestamp();

  get diagnostics v_consumed = row_count;
  return v_consumed = 1;
end;
$$;

revoke all on function public.consume_mobile_push_dispatch_lease(text)
  from public, anon, authenticated;
grant execute on function public.consume_mobile_push_dispatch_lease(text)
  to service_role;

create or replace function private.invoke_mobile_push_dispatch()
returns bigint
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  v_function_url text;
  v_lease text;
  v_request_id bigint;
begin
  select runtime."functionUrl"
    into v_function_url
    from private.mobile_push_dispatch_runtime runtime
   where runtime.id
   limit 1;

  if v_function_url is null then
    return null;
  end if;

  v_lease := private.create_mobile_push_dispatch_lease();

  select net.http_post(
    url := v_function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-granith-dispatch-lease', v_lease
    ),
    body := jsonb_build_object(
      'limit', 100,
      'source', 'pg_cron'
    ),
    timeout_milliseconds := 25000
  )
  into v_request_id;

  return v_request_id;
end;
$$;

revoke all on function private.invoke_mobile_push_dispatch()
  from public, anon, authenticated;

create or replace function public.configure_mobile_push_dispatch_cron(
  p_function_url text,
  p_schedule text default '* * * * *'
)
returns bigint
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $function$
declare
  v_url text := trim(coalesce(p_function_url, ''));
  v_schedule text := trim(coalesce(p_schedule, ''));
  v_job_id bigint;
begin
  if v_url !~ '^https://[^/]+/functions/v1/dispatch_mobile_push$' then
    raise exception 'A valid HTTPS dispatch_mobile_push Function URL is required.'
      using errcode = '22023';
  end if;

  if v_schedule = ''
    or v_schedule !~ '^[0-9*/,\- ]+$'
    or array_length(regexp_split_to_array(v_schedule, '\s+'), 1) <> 5
  then
    raise exception 'A five-field cron schedule is required.'
      using errcode = '22023';
  end if;

  insert into private.mobile_push_dispatch_runtime (
    id,
    "functionUrl",
    "updatedAt"
  )
  values (true, v_url, clock_timestamp())
  on conflict (id) do update
  set
    "functionUrl" = excluded."functionUrl",
    "updatedAt" = excluded."updatedAt";

  begin
    perform cron.unschedule('granith-mobile-push-dispatch');
  exception when others then
    null;
  end;

  select cron.schedule(
    'granith-mobile-push-dispatch',
    v_schedule,
    'select private.invoke_mobile_push_dispatch();'
  )
  into v_job_id;

  return v_job_id;
end;
$function$;

revoke all on function public.configure_mobile_push_dispatch_cron(text, text)
  from public, anon, authenticated;
grant execute on function public.configure_mobile_push_dispatch_cron(text, text)
  to service_role;

comment on function public.configure_mobile_push_dispatch_cron(text, text) is
  'Configure from SQL Editor/service_role after deploy; never expose to authenticated clients.';
