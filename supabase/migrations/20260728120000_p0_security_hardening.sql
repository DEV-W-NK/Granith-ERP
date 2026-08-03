-- Granith P0 security hardening.
-- Applies least-privilege RLS, private project media, immutable audit events,
-- and soft deletion for business records.

create schema if not exists private;

create table if not exists private.edge_rate_limits (
  principal_id uuid not null,
  scope text not null,
  window_start timestamptz not null,
  request_count integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (principal_id, scope, window_start),
  constraint edge_rate_limits_request_count_check check (request_count > 0)
);

revoke all on private.edge_rate_limits from public, anon, authenticated;

create or replace function public.consume_edge_rate_limit(p_scope text)
returns boolean
language plpgsql
volatile
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_scope text := trim(coalesce(p_scope, ''));
  v_window_seconds integer;
  v_max_requests integer;
  v_window_start timestamptz;
  v_count integer;
begin
  if v_user_id is null then
    return false;
  end if;

  select limits.window_seconds, limits.max_requests
    into v_window_seconds, v_max_requests
    from (
      values
        ('gemini_generate'::text, 300::integer, 30::integer)
    ) as limits(scope, window_seconds, max_requests)
   where limits.scope = v_scope;

  if v_window_seconds is null then
    return false;
  end if;

  v_window_start := to_timestamp(
    floor(extract(epoch from clock_timestamp()) / v_window_seconds)
      * v_window_seconds
  );

  insert into private.edge_rate_limits (
    principal_id,
    scope,
    window_start,
    request_count,
    updated_at
  )
  values (
    v_user_id,
    v_scope,
    v_window_start,
    1,
    clock_timestamp()
  )
  on conflict (principal_id, scope, window_start)
  do update
    set request_count = private.edge_rate_limits.request_count + 1,
        updated_at = clock_timestamp()
  where private.edge_rate_limits.request_count < v_max_requests
  returning request_count into v_count;

  delete from private.edge_rate_limits
   where principal_id = v_user_id
     and window_start < clock_timestamp() - interval '2 days';

  return v_count is not null;
end;
$$;

revoke all on function public.consume_edge_rate_limit(text)
  from public, anon;
grant execute on function public.consume_edge_rate_limit(text)
  to authenticated;

-- Internal username accounts are linked by users.employee_id and must not
-- fall back exclusively to the Google e-mail stored in the JWT.
create or replace function private.current_employee_id()
returns text
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select private.current_user_employee_id();
$$;

create or replace function private.current_employee_role_rank()
returns integer
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select case
    when private.current_user_role() = 'admin' then 5
    else coalesce((
      select case e.role
        when 'gerente' then 4
        when 'coordenador' then 3
        when 'supervisor' then 2
        when 'funcionario' then 1
        else 0
      end
      from public.employees e
      where e.id::text = private.current_user_employee_id()
        and e.status <> 'desligado'
      limit 1
    ), 0)
  end;
$$;

create or replace function private.has_any_permission(required_permissions text[])
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.is_admin()
    or coalesce(private.current_user_permissions() && required_permissions, false);
$$;

create or replace function private.current_employee_assigned_to_project(
  project_id text
)
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select nullif(trim(project_id), '') is not null
    and private.current_user_employee_id() is not null
    and (
      exists (
        select 1
          from public.projects project
         where project.id::text = trim(project_id)
           and coalesce(
             nullif(project."coordinatorId"::text, ''),
             nullif(project.coordinator_id::text, '')
           ) = private.current_user_employee_id()
      )
      or exists (
        select 1
          from public.teams team
         where team."projectId"::text = trim(project_id)
           and team."isActive" = true
           and (
             team."leaderId"::text = private.current_user_employee_id()
             or private.current_user_employee_id()
               = any(coalesce(team."memberIds", '{}'::text[]))
           )
      )
    );
$$;

create or replace function private.can_submit_mobile_fuel_log(
  vehicle_id text
)
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select private.current_user_employee_id() is not null
    and (
      private.has_min_employee_role(2)
      or private.has_any_permission(array['mobile.fuel_logs.write'])
      or exists (
        select 1
          from public.vehicles vehicle
         where vehicle.id::text = trim(vehicle_id)
           and vehicle.status = 'active'
           and vehicle."assignedEmployeeId"::text
             = private.current_user_employee_id()
      )
    );
$$;

create or replace function private.can_read_projects()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.has_any_permission(array[
    'projects.read', 'projects.write', 'obras', 'diario', 'medicoes'
  ]);
$$;

create or replace function private.can_write_projects()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.has_any_permission(array['projects.write', 'obras']);
$$;

create or replace function private.can_read_budgets()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.has_any_permission(array[
    'budgets.read', 'budgets.write', 'orcamentos', 'obras'
  ]);
$$;

create or replace function private.can_write_budgets()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.has_any_permission(array['budgets.write', 'orcamentos']);
$$;

create or replace function private.can_read_inventory()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.has_min_employee_role(2)
    or private.has_any_permission(array[
      'inventory.read',
      'inventory.write',
      'mobile.materials.request',
      'estoque',
      'suprimentos',
      'compras'
    ]);
$$;

create or replace function private.can_write_inventory()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.has_any_permission(array[
    'inventory.write', 'estoque', 'suprimentos'
  ]);
$$;

create or replace function private.can_read_purchases()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.has_any_permission(array[
    'purchases.read',
    'purchases.write',
    'purchases.approve',
    'purchases.consolidate',
    'purchase_finance.read',
    'purchase_finance.write',
    'compras',
    'suprimentos'
  ]);
$$;

create or replace function private.can_write_purchases()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.has_any_permission(array[
    'purchases.write',
    'purchases.approve',
    'purchases.consolidate',
    'compras',
    'suprimentos'
  ]);
$$;

create or replace function private.can_read_fleet()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.has_any_permission(array[
    'fleet.read', 'fleet.manage', 'logistics.read', 'logistics.manage',
    'frota', 'compras', 'suprimentos'
  ]);
$$;

create or replace function private.can_manage_fleet()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.has_any_permission(array[
    'fleet.manage', 'logistics.manage', 'frota', 'compras'
  ]);
$$;

create or replace function private.can_read_audit()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.has_any_permission(array['audit.read', 'access.manage']);
$$;

create or replace function private.can_read_financial()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.has_any_permission(array[
    'financial.read',
    'financial.write',
    'purchase_finance.read',
    'purchase_finance.write',
    'financeiro',
    'relatorios'
  ]);
$$;

create or replace function private.can_write_financial()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.has_any_permission(array[
    'financial.write', 'purchase_finance.write', 'financeiro'
  ]);
$$;

create or replace function private.can_read_time_clock()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.can_manage_people()
    or private.has_any_permission(array[
      'time_clock.read', 'time_clock.manage'
    ]);
$$;

create or replace function private.can_manage_time_clock()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.can_manage_people()
    or private.has_any_permission(array['time_clock.manage']);
$$;

revoke all on function private.has_any_permission(text[]) from public, anon;
revoke all on function private.current_employee_id() from public, anon;
revoke all on function private.current_employee_role_rank() from public, anon;
revoke all on function private.current_employee_assigned_to_project(text)
  from public, anon;
revoke all on function private.can_submit_mobile_fuel_log(text)
  from public, anon;
revoke all on function private.can_read_projects() from public, anon;
revoke all on function private.can_write_projects() from public, anon;
revoke all on function private.can_read_budgets() from public, anon;
revoke all on function private.can_write_budgets() from public, anon;
revoke all on function private.can_read_inventory() from public, anon;
revoke all on function private.can_write_inventory() from public, anon;
revoke all on function private.can_read_purchases() from public, anon;
revoke all on function private.can_write_purchases() from public, anon;
revoke all on function private.can_read_fleet() from public, anon;
revoke all on function private.can_manage_fleet() from public, anon;
revoke all on function private.can_read_audit() from public, anon;
revoke all on function private.can_read_time_clock() from public, anon;
revoke all on function private.can_manage_time_clock() from public, anon;

grant execute on function private.has_any_permission(text[]) to authenticated;
grant execute on function private.current_employee_id() to authenticated;
grant execute on function private.current_employee_role_rank() to authenticated;
grant execute on function private.current_employee_assigned_to_project(text)
  to authenticated;
grant execute on function private.can_submit_mobile_fuel_log(text)
  to authenticated;
grant execute on function private.can_read_projects() to authenticated;
grant execute on function private.can_write_projects() to authenticated;
grant execute on function private.can_read_budgets() to authenticated;
grant execute on function private.can_write_budgets() to authenticated;
grant execute on function private.can_read_inventory() to authenticated;
grant execute on function private.can_write_inventory() to authenticated;
grant execute on function private.can_read_purchases() to authenticated;
grant execute on function private.can_write_purchases() to authenticated;
grant execute on function private.can_read_fleet() to authenticated;
grant execute on function private.can_manage_fleet() to authenticated;
grant execute on function private.can_read_audit() to authenticated;
grant execute on function private.can_read_time_clock() to authenticated;
grant execute on function private.can_manage_time_clock() to authenticated;

-- Private media: URLs no longer bypass storage RLS.
update storage.buckets
set
  public = false,
  file_size_limit = 10485760,
  allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']::text[]
where id = 'project-images';

drop policy if exists project_images_select_by_access on storage.objects;
drop policy if exists project_images_insert_internal on storage.objects;
drop policy if exists project_images_update_internal on storage.objects;
drop policy if exists project_images_delete_internal on storage.objects;

create policy project_images_select_by_access
on storage.objects
for select
to authenticated
using (
  bucket_id = 'project-images'
  and (
    private.can_read_projects()
    or private.current_employee_assigned_to_project(
      case
        when split_part(name, '/', 1) = 'daily_logs'
          then split_part(name, '/', 2)
        else split_part(name, '/', 1)
      end
    )
    or private.client_can_access_project(
      case
        when split_part(name, '/', 1) = 'daily_logs'
          then split_part(name, '/', 2)
        else split_part(name, '/', 1)
      end
    )
  )
);

create policy project_images_insert_authorized
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'project-images'
  and (
    private.can_write_projects()
    or (
      private.can_submit_mobile_daily_logs()
      and split_part(name, '/', 2) = 'daily-logs'
      and private.current_employee_assigned_to_project(
        split_part(name, '/', 1)
      )
    )
  )
);

create policy project_images_update_authorized
on storage.objects
for update
to authenticated
using (
  bucket_id = 'project-images'
  and private.can_write_projects()
)
with check (
  bucket_id = 'project-images'
  and private.can_write_projects()
);

create policy project_images_delete_authorized
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'project-images'
  and private.can_write_projects()
);

-- Critical tables retain records and expose only active rows.
do $$
declare
  table_name text;
  policy_name text;
begin
  foreach table_name in array array[
    'projects',
    'project_measurements',
    'budgets',
    'budget_types',
    'job_roles',
    'items',
    'suppliers',
    'purchases',
    'inventory',
    'material_requisitions',
    'daily_logs',
    'teams',
    'vehicles',
    'vehicle_fuel_logs',
    'financial_transactions',
    'purchase_delivery_routes',
    'material_requisition_supplier_quotes',
    'employees',
    'benefits',
    'benefit_categories',
    'employee_benefits',
    'salary_history',
    'sectors',
    'talent_candidates',
    'granith_tasks'
  ]
  loop
    if to_regclass(format('public.%I', table_name)) is not null then
      execute format(
        'alter table public.%I add column if not exists "archivedAt" timestamptz',
        table_name
      );
      execute format(
        'alter table public.%I add column if not exists "archivedBy" text',
        table_name
      );
      execute format(
        'alter table public.%I add column if not exists "archivedReason" text',
        table_name
      );

      policy_name := table_name || '_active_rows_only';
      execute format('drop policy if exists %I on public.%I', policy_name, table_name);
      execute format(
        'create policy %I on public.%I as restrictive for select to authenticated using ("archivedAt" is null)',
        policy_name,
        table_name
      );
    end if;
  end loop;
end $$;

create or replace function private.client_can_access_project(project_id text)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select nullif(project_id, '') is not null
    and exists (
      select 1
      from public.projects p
      where p.id::text = nullif(project_id, '')
        and p."archivedAt" is null
        and private.client_can_access_account(
          coalesce(p."clientAccountId"::text, p.client_account_id::text)
        )
    );
$$;

create or replace function private.guard_user_profile_privileged_fields()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_client_account_id text;
  v_employee_id text;
  v_employee_name text;
  v_auth_provider text;
begin
  if auth.role() = 'service_role'
    or (select auth.uid()) is null
    or private.can_manage_access()
  then
    return new;
  end if;

  if tg_op = 'INSERT' then
    if new.id::text <> (select auth.uid())::text
      or lower(new.email) <> private.jwt_email()
      or new.role not in ('employee', 'client')
      or coalesce(cardinality(new.permissions), 0) > 0
      or new.status <> 'ativo'
    then
      raise exception 'Self-service profile contains privileged values.'
        using errcode = '42501';
    end if;

    new.username := null;
    new.login_username := null;
    new."internalLoginEmail" := null;
    new.internal_login_email := null;
    v_auth_provider := coalesce(
      (select auth.jwt()) -> 'app_metadata' ->> 'provider',
      'email'
    );
    new."authProvider" := case
      when v_auth_provider = 'google' then 'google'
      else 'email'
    end;
    new.auth_provider := new."authProvider";

    if new.role = 'employee' then
      select employee.id::text, employee.name
        into v_employee_id, v_employee_name
        from public.employees employee
       where lower(employee.email) = private.jwt_email()
         and employee.status <> 'desligado'
         and employee."archivedAt" is null
       limit 1;

      if v_employee_id is null then
        raise exception 'No active employee matches the authenticated email.'
          using errcode = '42501';
      end if;

      new."employeeId" := v_employee_id;
      new.employee_id := v_employee_id;
      new."employeeName" := v_employee_name;
      new.employee_name := v_employee_name;
      new."clientAccountId" := null;
      new.client_account_id := null;
      new."clientAccountName" := null;
      new.client_account_name := null;
    else
      v_client_account_id := coalesce(
        new."clientAccountId"::text,
        new.client_account_id::text
      );
      if not private.client_can_access_account(v_client_account_id) then
        raise exception 'Invalid client account binding.'
          using errcode = '42501';
      end if;
      new."employeeId" := null;
      new.employee_id := null;
      new."employeeName" := null;
      new.employee_name := null;
    end if;

    return new;
  end if;

  v_client_account_id := coalesce(
    new."clientAccountId"::text,
    new.client_account_id::text
  );

  if new.id is distinct from old.id
    or new.email is distinct from old.email
    or new.role is distinct from old.role
    or new.permissions is distinct from old.permissions
    or new.status is distinct from old.status
    or new.username is distinct from old.username
    or new.login_username is distinct from old.login_username
    or new."internalLoginEmail" is distinct from old."internalLoginEmail"
    or new.internal_login_email is distinct from old.internal_login_email
    or new."authProvider" is distinct from old."authProvider"
    or new.auth_provider is distinct from old.auth_provider
    or new."employeeId" is distinct from old."employeeId"
    or new.employee_id is distinct from old.employee_id
    or new."employeeName" is distinct from old."employeeName"
    or new.employee_name is distinct from old.employee_name
    or new.created_at is distinct from old.created_at
  then
    raise exception 'Only access managers can update identity or authorization fields.'
      using errcode = '42501';
  end if;

  if new."clientAccountId" is distinct from old."clientAccountId"
    or new.client_account_id is distinct from old.client_account_id
    or new."clientAccountName" is distinct from old."clientAccountName"
    or new.client_account_name is distinct from old.client_account_name
  then
    if not (
      new.role = 'client'
      and private.client_can_access_account(v_client_account_id)
    ) then
      raise exception 'Only access managers can change client account bindings.'
        using errcode = '42501';
    end if;
  end if;

  return new;
end;
$$;

revoke all on function private.guard_user_profile_privileged_fields()
  from public, anon, authenticated;

-- Immutable audit ledger.
create table if not exists public.audit_events (
  id bigint generated always as identity primary key,
  occurred_at timestamptz not null default now(),
  actor_user_id text,
  actor_email text,
  actor_role text,
  action text not null,
  entity_table text not null,
  entity_id text,
  old_data jsonb,
  new_data jsonb,
  metadata jsonb not null default '{}'::jsonb,
  request_id text,
  source text not null default 'database',
  constraint audit_events_action_check check (
    action in ('INSERT', 'UPDATE', 'ARCHIVE', 'RESTORE', 'DELETE')
  )
);

create index if not exists idx_audit_events_entity
  on public.audit_events (entity_table, entity_id, occurred_at desc);
create index if not exists idx_audit_events_actor
  on public.audit_events (actor_user_id, occurred_at desc);
create index if not exists idx_audit_events_occurred_at
  on public.audit_events (occurred_at desc);

alter table public.audit_events enable row level security;

drop policy if exists audit_events_select_authorized on public.audit_events;
create policy audit_events_select_authorized
on public.audit_events
for select
to authenticated
using (private.can_read_audit());

revoke insert, update, delete on public.audit_events from authenticated;
grant select on public.audit_events to authenticated;

create or replace function private.block_audit_event_mutation()
returns trigger
language plpgsql
set search_path = public, private, pg_temp
as $$
begin
  raise exception 'Audit events are immutable.'
    using errcode = '42501';
end;
$$;

drop trigger if exists trg_audit_events_immutable on public.audit_events;
create trigger trg_audit_events_immutable
before update or delete on public.audit_events
for each row execute function private.block_audit_event_mutation();

create or replace function private.redact_audit_payload(payload jsonb)
returns jsonb
language sql
immutable
set search_path = public, pg_temp
as $$
  select coalesce(payload, '{}'::jsonb)
    - 'password'
    - 'password_hash'
    - 'token'
    - 'access_token'
    - 'refresh_token'
    - 'private_key'
    - 'service_role_key';
$$;

create or replace function private.capture_audit_event()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_old jsonb;
  v_new jsonb;
  v_action text := tg_op;
  v_entity_id text;
begin
  if tg_op <> 'INSERT' then
    v_old := private.redact_audit_payload(to_jsonb(old));
    v_entity_id := v_old ->> 'id';
  end if;

  if tg_op <> 'DELETE' then
    v_new := private.redact_audit_payload(to_jsonb(new));
    v_entity_id := coalesce(v_new ->> 'id', v_entity_id);
  end if;

  if tg_op = 'UPDATE' then
    if (v_old ->> 'archivedAt') is null and (v_new ->> 'archivedAt') is not null then
      v_action := 'ARCHIVE';
    elsif (v_old ->> 'archivedAt') is not null and (v_new ->> 'archivedAt') is null then
      v_action := 'RESTORE';
    end if;
  end if;

  insert into public.audit_events (
    actor_user_id,
    actor_email,
    actor_role,
    action,
    entity_table,
    entity_id,
    old_data,
    new_data,
    request_id,
    source
  )
  values (
    (select auth.uid())::text,
    private.jwt_email(),
    private.current_user_role(),
    v_action,
    tg_table_name,
    v_entity_id,
    case when tg_op = 'INSERT' then null else v_old end,
    case when tg_op = 'DELETE' then null else v_new end,
    nullif(
      coalesce(
        nullif(current_setting('request.headers', true), ''),
        '{}'
      )::jsonb ->> 'x-request-id',
      ''
    ),
    'database'
  );

  return case when tg_op = 'DELETE' then old else new end;
end;
$$;

create or replace function private.block_authenticated_delete()
returns trigger
language plpgsql
set search_path = public, private, pg_temp
as $$
begin
  if (select auth.uid()) is not null then
    raise exception 'Direct deletion is disabled. Archive the record instead.'
      using errcode = '42501';
  end if;
  return old;
end;
$$;

create or replace function private.guard_archive_fields()
returns trigger
language plpgsql
set search_path = public, private, pg_temp
as $$
begin
  if (select auth.uid()) is not null
    and coalesce(current_setting('granith.archive_operation', true), '') <> 'on'
    and (
      new."archivedAt" is distinct from old."archivedAt"
      or new."archivedBy" is distinct from old."archivedBy"
      or new."archivedReason" is distinct from old."archivedReason"
    )
  then
    raise exception 'Archive fields can only be changed through the archive RPC.'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

do $$
declare
  v_table_name text;
begin
  foreach v_table_name in array array[
    'projects',
    'project_measurements',
    'budgets',
    'budget_types',
    'job_roles',
    'items',
    'suppliers',
    'purchases',
    'inventory',
    'inventory_movements',
    'material_requisitions',
    'daily_logs',
    'teams',
    'vehicles',
    'vehicle_fuel_logs',
    'financial_transactions',
    'purchase_delivery_routes',
    'purchase_delivery_route_stops',
    'material_requisition_supplier_quotes',
    'employees',
    'benefits',
    'benefit_categories',
    'employee_benefits',
    'salary_history',
    'sectors',
    'talent_candidates',
    'granith_tasks',
    'granith_task_time_entries',
    'users',
    'client_accounts',
    'system_settings',
    'time_clock_establishments',
    'mobile_work_hour_entries',
    'mobile_inventory_operations',
    'mobile_vehicle_field_reports',
    'mobile_project_measurement_evidence',
    'mobile_project_documents'
  ]
  loop
    if to_regclass(format('public.%I', v_table_name)) is not null then
      execute format(
        'drop trigger if exists %I on public.%I',
        'trg_audit_' || v_table_name,
        v_table_name
      );
      execute format(
        'create trigger %I after insert or update or delete on public.%I for each row execute function private.capture_audit_event()',
        'trg_audit_' || v_table_name,
        v_table_name
      );
      execute format(
        'drop trigger if exists %I on public.%I',
        'trg_block_delete_' || v_table_name,
        v_table_name
      );
      execute format(
        'create trigger %I before delete on public.%I for each row execute function private.block_authenticated_delete()',
        'trg_block_delete_' || v_table_name,
        v_table_name
      );
      if exists (
        select 1
        from information_schema.columns c
        where c.table_schema = 'public'
          and c.table_name = v_table_name
          and c.column_name = 'archivedAt'
      ) then
        execute format(
          'drop trigger if exists %I on public.%I',
          'trg_guard_archive_' || v_table_name,
          v_table_name
        );
        execute format(
          'create trigger %I before update on public.%I for each row execute function private.guard_archive_fields()',
          'trg_guard_archive_' || v_table_name,
          v_table_name
        );
      end if;
    end if;
  end loop;
end $$;

create or replace function private.can_archive_table(table_name text)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
    when table_name in ('projects', 'project_measurements', 'daily_logs')
      then private.can_write_projects()
    when table_name in ('budgets', 'budget_types')
      then private.can_write_budgets()
    when table_name in ('items', 'inventory')
      then private.can_write_inventory()
    when table_name in (
      'suppliers',
      'purchases',
      'material_requisitions',
      'material_requisition_supplier_quotes'
    )
      then private.can_write_purchases()
    when table_name in ('vehicles', 'vehicle_fuel_logs', 'purchase_delivery_routes')
      then private.can_manage_fleet()
    when table_name = 'financial_transactions'
      then private.can_write_financial()
    when table_name in (
      'job_roles',
      'employees',
      'teams',
      'benefits',
      'benefit_categories',
      'employee_benefits',
      'salary_history',
      'sectors',
      'talent_candidates'
    )
      then private.can_manage_people()
    when table_name = 'granith_tasks'
      then private.is_admin()
        or private.has_min_employee_role(2)
    else false
  end;
$$;

create or replace function public.archive_record(
  p_table text,
  p_id text,
  p_reason text default null
)
returns boolean
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_count integer;
  v_actor text := (select auth.uid())::text;
begin
  if p_table is null
    or p_id is null
    or not private.can_archive_table(p_table)
  then
    raise exception 'Not authorized to archive this record.'
      using errcode = '42501';
  end if;

  perform set_config('granith.archive_operation', 'on', true);
  execute format(
    'update public.%I
       set "archivedAt" = now(),
           "archivedBy" = $1,
           "archivedReason" = nullif(trim($2), '''')
     where id::text = $3
       and "archivedAt" is null',
    p_table
  )
  using v_actor, p_reason, p_id;

  get diagnostics v_count = row_count;

  if v_count = 1 and p_table = 'employees' then
    update public.teams
    set
      "memberIds" = array_remove(coalesce("memberIds", '{}'::text[]), p_id),
      "leaderId" = case when "leaderId" = p_id then null else "leaderId" end,
      "updatedAt" = now()
    where "archivedAt" is null
      and (
        p_id = any(coalesce("memberIds", '{}'::text[]))
        or "leaderId" = p_id
      );
  end if;

  perform set_config('granith.archive_operation', 'off', true);
  return v_count = 1;
end;
$$;

create or replace function public.restore_archived_record(
  p_table text,
  p_id text
)
returns boolean
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_count integer;
begin
  if not private.is_admin() then
    raise exception 'Only administrators can restore archived records.'
      using errcode = '42501';
  end if;

  if p_table not in (
    'projects',
    'project_measurements',
    'budgets',
    'budget_types',
    'job_roles',
    'items',
    'suppliers',
    'purchases',
    'inventory',
    'material_requisitions',
    'daily_logs',
    'teams',
    'vehicles',
    'vehicle_fuel_logs',
    'financial_transactions',
    'purchase_delivery_routes',
    'material_requisition_supplier_quotes',
    'employees',
    'benefits',
    'benefit_categories',
    'employee_benefits',
    'salary_history',
    'granith_tasks'
  ) then
    raise exception 'Unsupported archive table.';
  end if;

  perform set_config('granith.archive_operation', 'on', true);
  execute format(
    'update public.%I
       set "archivedAt" = null,
           "archivedBy" = null,
           "archivedReason" = null
     where id::text = $1
       and "archivedAt" is not null',
    p_table
  )
  using p_id;

  get diagnostics v_count = row_count;
  perform set_config('granith.archive_operation', 'off', true);
  return v_count = 1;
end;
$$;

revoke all on function public.archive_record(text, text, text) from public, anon;
revoke all on function public.restore_archived_record(text, text) from public, anon;
grant execute on function public.archive_record(text, text, text) to authenticated;
grant execute on function public.restore_archived_record(text, text) to authenticated;

-- Replace broad ERP policies with explicit capabilities.
drop policy if exists projects_insert_internal on public.projects;
drop policy if exists projects_update_internal on public.projects;
drop policy if exists projects_delete_internal on public.projects;
drop policy if exists projects_select_internal on public.projects;
create policy projects_select_authorized
on public.projects for select to authenticated
using (
  private.can_read_projects()
  or private.current_employee_assigned_to_project(id::text)
);
create policy projects_insert_authorized
on public.projects for insert to authenticated
with check (private.can_write_projects());
create policy projects_update_authorized
on public.projects for update to authenticated
using (private.can_write_projects())
with check (private.can_write_projects());

drop policy if exists project_measurements_select_by_role on public.project_measurements;
drop policy if exists project_measurements_insert_internal on public.project_measurements;
drop policy if exists project_measurements_update_internal on public.project_measurements;
drop policy if exists project_measurements_delete_internal on public.project_measurements;
create policy project_measurements_select_authorized
on public.project_measurements for select to authenticated
using (
  private.can_read_projects()
  or private.current_employee_assigned_to_project(
    coalesce("projectId"::text, project_id::text)
  )
  or private.client_can_access_project(coalesce("projectId"::text, project_id::text))
);
create policy project_measurements_insert_authorized
on public.project_measurements for insert to authenticated
with check (private.can_write_projects());
create policy project_measurements_update_authorized
on public.project_measurements for update to authenticated
using (private.can_write_projects())
with check (private.can_write_projects());

drop policy if exists budgets_select_by_role on public.budgets;
drop policy if exists budgets_insert_internal on public.budgets;
drop policy if exists budgets_update_internal on public.budgets;
drop policy if exists budgets_delete_internal on public.budgets;
create policy budgets_select_authorized
on public.budgets for select to authenticated
using (private.can_read_budgets());
create policy budgets_insert_authorized
on public.budgets for insert to authenticated
with check (private.can_write_budgets());
create policy budgets_update_authorized
on public.budgets for update to authenticated
using (private.can_write_budgets())
with check (private.can_write_budgets());

do $$
declare
  table_name text;
begin
  foreach table_name in array array['budget_types']
  loop
    if to_regclass(format('public.%I', table_name)) is not null then
      execute format('drop policy if exists %I on public.%I', table_name || '_internal_crud', table_name);
      execute format('create policy %I on public.%I for select to authenticated using (private.can_read_budgets())', table_name || '_select_authorized', table_name);
      execute format('create policy %I on public.%I for insert to authenticated with check (private.can_write_budgets())', table_name || '_insert_authorized', table_name);
      execute format('create policy %I on public.%I for update to authenticated using (private.can_write_budgets()) with check (private.can_write_budgets())', table_name || '_update_authorized', table_name);
    end if;
  end loop;

  foreach table_name in array array['job_roles']
  loop
    if to_regclass(format('public.%I', table_name)) is not null then
      execute format('drop policy if exists %I on public.%I', table_name || '_internal_crud', table_name);
      execute format('create policy %I on public.%I for select to authenticated using (private.can_manage_people())', table_name || '_select_authorized', table_name);
      execute format('create policy %I on public.%I for insert to authenticated with check (private.can_manage_people())', table_name || '_insert_authorized', table_name);
      execute format('create policy %I on public.%I for update to authenticated using (private.can_manage_people()) with check (private.can_manage_people())', table_name || '_update_authorized', table_name);
    end if;
  end loop;

  foreach table_name in array array['items', 'inventory', 'inventory_movements']
  loop
    if to_regclass(format('public.%I', table_name)) is not null then
      execute format('drop policy if exists %I on public.%I', table_name || '_internal_crud', table_name);
      execute format('create policy %I on public.%I for select to authenticated using (private.can_read_inventory())', table_name || '_select_authorized', table_name);
      execute format('create policy %I on public.%I for insert to authenticated with check (private.can_write_inventory())', table_name || '_insert_authorized', table_name);
      execute format('create policy %I on public.%I for update to authenticated using (private.can_write_inventory()) with check (private.can_write_inventory())', table_name || '_update_authorized', table_name);
    end if;
  end loop;

  foreach table_name in array array[
    'suppliers',
    'purchases',
    'material_requisition_supplier_quotes'
  ]
  loop
    if to_regclass(format('public.%I', table_name)) is not null then
      execute format('drop policy if exists %I on public.%I', table_name || '_internal_crud', table_name);
      execute format('create policy %I on public.%I for select to authenticated using (private.can_read_purchases())', table_name || '_select_authorized', table_name);
      execute format('create policy %I on public.%I for insert to authenticated with check (private.can_write_purchases())', table_name || '_insert_authorized', table_name);
      execute format('create policy %I on public.%I for update to authenticated using (private.can_write_purchases()) with check (private.can_write_purchases())', table_name || '_update_authorized', table_name);
    end if;
  end loop;

  foreach table_name in array array[
    'vehicles',
    'vehicle_fuel_logs',
    'purchase_delivery_routes',
    'purchase_delivery_route_stops'
  ]
  loop
    if to_regclass(format('public.%I', table_name)) is not null then
      execute format('drop policy if exists %I on public.%I', table_name || '_internal_crud', table_name);
      execute format('create policy %I on public.%I for select to authenticated using (private.can_read_fleet())', table_name || '_select_authorized', table_name);
      execute format('create policy %I on public.%I for insert to authenticated with check (private.can_manage_fleet())', table_name || '_insert_authorized', table_name);
      execute format('create policy %I on public.%I for update to authenticated using (private.can_manage_fleet()) with check (private.can_manage_fleet())', table_name || '_update_authorized', table_name);
    end if;
  end loop;
end $$;

-- Mobile fuel entries are accepted only for an assigned/authorized vehicle.
-- Identity and calculated fields are canonicalized by the database.
do $$
begin
  if not exists (
    select 1
      from pg_constraint
     where conrelid = 'public.vehicle_fuel_logs'::regclass
       and conname = 'vehicle_fuel_logs_positive_values_check'
  ) then
    alter table public.vehicle_fuel_logs
      add constraint vehicle_fuel_logs_positive_values_check check (
        liters > 0
        and liters <= 1000
        and "totalAmount" > 0
        and "totalAmount" <= 1000000
        and "unitPrice" >= 0
        and "odometerKm" >= 0
        and coalesce("previousOdometerKm", 0) >= 0
        and coalesce("kmTraveled", 0) >= 0
        and coalesce("kmPerLiter", 0) >= 0
      ) not valid;
  end if;
end $$;

create or replace function private.enforce_mobile_fuel_log()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_employee_id text := private.current_user_employee_id();
  v_employee_name text;
  v_vehicle public.vehicles%rowtype;
begin
  if (select auth.uid()) is null or private.can_manage_fleet() then
    return new;
  end if;

  if not private.can_submit_mobile_fuel_log(new."vehicleId"::text) then
    raise exception 'Vehicle is not assigned or authorized for this employee.'
      using errcode = '42501';
  end if;

  select *
    into v_vehicle
    from public.vehicles
   where id::text = new."vehicleId"::text
     and status = 'active'
     and "archivedAt" is null
   for update;

  if not found then
    raise exception 'Active vehicle was not found.'
      using errcode = '23503';
  end if;

  select employee.name
    into v_employee_name
    from public.employees employee
   where employee.id::text = v_employee_id
     and employee.status <> 'desligado'
     and employee."archivedAt" is null
   limit 1;

  if v_employee_name is null then
    raise exception 'Active employee binding was not found.'
      using errcode = '42501';
  end if;

  if new.liters <= 0
    or new.liters > 1000
    or new."totalAmount" <= 0
    or new."totalAmount" > 1000000
    or new."odometerKm" < v_vehicle."odometerKm"
    or new."fuelingDate" > clock_timestamp() + interval '15 minutes'
    or new."fuelingDate" < clock_timestamp() - interval '366 days'
  then
    raise exception 'Invalid fuel entry values.'
      using errcode = '22023';
  end if;

  new."vehiclePlate" := v_vehicle.plate;
  new."employeeId" := v_employee_id;
  new."employeeName" := v_employee_name;
  new."unitPrice" := round(new."totalAmount" / new.liters, 4);
  new."previousOdometerKm" := v_vehicle."odometerKm";
  new."kmTraveled" := new."odometerKm" - v_vehicle."odometerKm";
  new."kmPerLiter" := case
    when new."kmTraveled" > 0
      then round(new."kmTraveled" / new.liters, 2)
    else null
  end;
  new."financialTransactionId" := null;
  new."invoiceNumber" := left(trim(coalesce(new."invoiceNumber", '')), 120);
  new.notes := left(trim(coalesce(new.notes, '')), 2000);
  new."createdAt" := clock_timestamp();

  return new;
end;
$$;

create or replace function private.enforce_mobile_vehicle_update()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_latest public.vehicle_fuel_logs%rowtype;
begin
  if (select auth.uid()) is null or private.can_manage_fleet() then
    return new;
  end if;

  if not private.can_submit_mobile_fuel_log(old.id::text) then
    raise exception 'Vehicle update is not authorized.'
      using errcode = '42501';
  end if;

  if (
    to_jsonb(new)
      - 'odometerKm'
      - 'lastMeasuredKmPerLiter'
      - 'lastFuelLogAt'
      - 'updatedAt'
  ) is distinct from (
    to_jsonb(old)
      - 'odometerKm'
      - 'lastMeasuredKmPerLiter'
      - 'lastFuelLogAt'
      - 'updatedAt'
  ) then
    raise exception 'Mobile users can only refresh vehicle telemetry.'
      using errcode = '42501';
  end if;

  select fuel_log.*
    into v_latest
    from public.vehicle_fuel_logs fuel_log
   where fuel_log."vehicleId"::text = old.id::text
     and fuel_log."archivedAt" is null
   order by fuel_log."odometerKm" desc, fuel_log."createdAt" desc
   limit 1;

  if not found then
    raise exception 'A validated fuel entry is required before vehicle telemetry update.'
      using errcode = '42501';
  end if;

  new."odometerKm" := greatest(old."odometerKm", v_latest."odometerKm");
  new."lastFuelLogAt" := case
    when v_latest."odometerKm" >= old."odometerKm"
      then v_latest."fuelingDate"
    else old."lastFuelLogAt"
  end;
  new."lastMeasuredKmPerLiter" := case
    when v_latest."odometerKm" >= old."odometerKm"
      then coalesce(v_latest."kmPerLiter", old."lastMeasuredKmPerLiter")
    else old."lastMeasuredKmPerLiter"
  end;
  new."updatedAt" := clock_timestamp();

  return new;
end;
$$;

create or replace function private.apply_fuel_log_to_vehicle()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
begin
  update public.vehicles
     set "odometerKm" = greatest("odometerKm", new."odometerKm"),
         "lastFuelLogAt" = case
           when new."odometerKm" >= "odometerKm"
             then new."fuelingDate"
           else "lastFuelLogAt"
         end,
         "lastMeasuredKmPerLiter" = case
           when new."odometerKm" >= "odometerKm"
             then coalesce(new."kmPerLiter", "lastMeasuredKmPerLiter")
           else "lastMeasuredKmPerLiter"
         end,
         "updatedAt" = clock_timestamp()
   where id::text = new."vehicleId"::text
     and "archivedAt" is null;

  return new;
end;
$$;

revoke all on function private.enforce_mobile_fuel_log()
  from public, anon, authenticated;
revoke all on function private.enforce_mobile_vehicle_update()
  from public, anon, authenticated;
revoke all on function private.apply_fuel_log_to_vehicle()
  from public, anon, authenticated;

drop trigger if exists trg_enforce_mobile_fuel_log
  on public.vehicle_fuel_logs;
create trigger trg_enforce_mobile_fuel_log
before insert on public.vehicle_fuel_logs
for each row execute function private.enforce_mobile_fuel_log();

drop trigger if exists trg_enforce_mobile_vehicle_update
  on public.vehicles;
create trigger trg_enforce_mobile_vehicle_update
before update on public.vehicles
for each row execute function private.enforce_mobile_vehicle_update();

drop trigger if exists trg_apply_fuel_log_to_vehicle
  on public.vehicle_fuel_logs;
create trigger trg_apply_fuel_log_to_vehicle
after insert on public.vehicle_fuel_logs
for each row execute function private.apply_fuel_log_to_vehicle();

drop policy if exists vehicles_select_authorized on public.vehicles;
drop policy if exists vehicles_insert_authorized on public.vehicles;
drop policy if exists vehicles_update_authorized on public.vehicles;
create policy vehicles_select_authorized
on public.vehicles for select to authenticated
using (
  private.can_read_fleet()
  or private.can_submit_mobile_fuel_log(id::text)
);
create policy vehicles_insert_authorized
on public.vehicles for insert to authenticated
with check (private.can_manage_fleet());
create policy vehicles_update_authorized
on public.vehicles for update to authenticated
using (
  private.can_manage_fleet()
  or private.can_submit_mobile_fuel_log(id::text)
)
with check (
  private.can_manage_fleet()
  or private.can_submit_mobile_fuel_log(id::text)
);

drop policy if exists vehicle_fuel_logs_select_authorized
  on public.vehicle_fuel_logs;
drop policy if exists vehicle_fuel_logs_insert_authorized
  on public.vehicle_fuel_logs;
drop policy if exists vehicle_fuel_logs_update_authorized
  on public.vehicle_fuel_logs;
create policy vehicle_fuel_logs_select_authorized
on public.vehicle_fuel_logs for select to authenticated
using (
  private.can_read_fleet()
  or "employeeId"::text = private.current_user_employee_id()
);
create policy vehicle_fuel_logs_insert_authorized
on public.vehicle_fuel_logs for insert to authenticated
with check (
  private.can_manage_fleet()
  or (
    private.can_submit_mobile_fuel_log("vehicleId"::text)
    and "employeeId"::text = private.current_user_employee_id()
    and "financialTransactionId" is null
  )
);
create policy vehicle_fuel_logs_update_authorized
on public.vehicle_fuel_logs for update to authenticated
using (private.can_manage_fleet())
with check (private.can_manage_fleet());

create or replace function private.enforce_mobile_material_requisition()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_employee_id text := private.current_user_employee_id();
  v_employee_name text;
  v_employee_sector text;
  v_project_name text;
begin
  if (select auth.uid()) is null or private.can_write_purchases() then
    return new;
  end if;

  if not private.can_request_mobile_materials()
    or not private.current_employee_assigned_to_project(new."projectId"::text)
  then
    raise exception 'Material requisition is not authorized for this project.'
      using errcode = '42501';
  end if;

  if jsonb_typeof(new.items) <> 'array'
    or jsonb_array_length(new.items) < 1
    or jsonb_array_length(new.items) > 100
    or pg_column_size(new.items) > 100000
  then
    raise exception 'Material requisition items are invalid.'
      using errcode = '22023';
  end if;

  select employee.name, employee.sector
    into v_employee_name, v_employee_sector
    from public.employees employee
   where employee.id::text = v_employee_id
     and employee.status <> 'desligado'
     and employee."archivedAt" is null
   limit 1;

  select project.name
    into v_project_name
    from public.projects project
   where project.id::text = new."projectId"::text
     and project."archivedAt" is null
   limit 1;

  if v_employee_name is null or v_project_name is null then
    raise exception 'Active employee or project was not found.'
      using errcode = '42501';
  end if;

  if tg_op = 'INSERT' then
    new."projectName" := v_project_name;
    new."requesterId" := v_employee_id;
    new."requesterName" := v_employee_name;
    new."requesterSector" := coalesce(v_employee_sector, 'Geral');
    new.status := 'pending';
    new."approvedBy" := null;
    new."approvedByName" := null;
    new."approvedAt" := null;
    new."rejectionReason" := null;
    new."purchaseId" := null;
    new."requestDate" := least(
      coalesce(new."requestDate", clock_timestamp()),
      clock_timestamp() + interval '5 minutes'
    );
    new."createdAt" := clock_timestamp();
    new.priority := left(trim(coalesce(new.priority, 'Media')), 40);
    return new;
  end if;

  if old."requesterId"::text <> v_employee_id
    or old.status <> 'pending'
    or new."projectId" is distinct from old."projectId"
  then
    raise exception 'Only a pending requisition owned by the employee can be edited.'
      using errcode = '42501';
  end if;

  new."projectId" := old."projectId";
  new."projectName" := old."projectName";
  new."requesterId" := old."requesterId";
  new."requesterName" := old."requesterName";
  new."requesterSector" := old."requesterSector";
  new."requestDate" := old."requestDate";
  new.status := old.status;
  new."approvedBy" := old."approvedBy";
  new."approvedByName" := old."approvedByName";
  new."approvedAt" := old."approvedAt";
  new."rejectionReason" := old."rejectionReason";
  new."purchaseId" := old."purchaseId";
  new."createdAt" := old."createdAt";
  new.priority := left(trim(coalesce(new.priority, old.priority)), 40);
  return new;
end;
$$;

revoke all on function private.enforce_mobile_material_requisition()
  from public, anon, authenticated;

drop trigger if exists trg_enforce_mobile_material_requisition
  on public.material_requisitions;
create trigger trg_enforce_mobile_material_requisition
before insert or update on public.material_requisitions
for each row execute function private.enforce_mobile_material_requisition();

drop policy if exists material_requisitions_select_internal
  on public.material_requisitions;
drop policy if exists material_requisitions_insert_supervisor_up
  on public.material_requisitions;
drop policy if exists material_requisitions_update_supervisor_up
  on public.material_requisitions;
drop policy if exists material_requisitions_delete_people_manage
  on public.material_requisitions;
create policy material_requisitions_select_authorized
on public.material_requisitions for select to authenticated
using (
  private.can_read_purchases()
  or "requesterId" in (private.current_employee_id(), (select auth.uid())::text)
);
create policy material_requisitions_insert_authorized
on public.material_requisitions for insert to authenticated
with check (
  private.can_write_purchases()
  or (
    private.can_request_mobile_materials()
    and "requesterId"::text = private.current_user_employee_id()
    and status = 'pending'
    and private.current_employee_assigned_to_project("projectId"::text)
  )
);
create policy material_requisitions_update_authorized
on public.material_requisitions for update to authenticated
using (
  private.can_write_purchases()
  or (
    private.can_request_mobile_materials()
    and "requesterId"::text = private.current_user_employee_id()
    and status = 'pending'
    and private.current_employee_assigned_to_project("projectId"::text)
  )
)
with check (
  private.can_write_purchases()
  or (
    private.can_request_mobile_materials()
    and "requesterId"::text = private.current_user_employee_id()
    and status = 'pending'
    and private.current_employee_assigned_to_project("projectId"::text)
  )
);

create or replace function private.enforce_mobile_daily_log()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_employee_id text := private.current_user_employee_id();
  v_project_name text;
  v_coordinator_id text;
  v_coordinator_name text;
begin
  if (select auth.uid()) is null or private.can_write_projects() then
    return new;
  end if;

  if tg_op = 'UPDATE'
    and new.status = 'signed'
    and old.status <> 'signed'
    and old."coordinatorId"::text = v_employee_id
  then
    if new."projectId" is distinct from old."projectId"
      or new."projectName" is distinct from old."projectName"
      or new.date is distinct from old.date
      or new."weatherMorning" is distinct from old."weatherMorning"
      or new."weatherAfternoon" is distinct from old."weatherAfternoon"
      or new.manpower is distinct from old.manpower
      or new."activitiesDescription" is distinct from old."activitiesDescription"
      or new.impediments is distinct from old.impediments
      or new."photoUrls" is distinct from old."photoUrls"
      or new."createdByUserId" is distinct from old."createdByUserId"
      or new."coordinatorId" is distinct from old."coordinatorId"
      or new."coordinatorName" is distinct from old."coordinatorName"
      or new."signatureRequestedAt" is distinct from old."signatureRequestedAt"
    then
      raise exception 'Signing cannot modify daily log business fields.'
        using errcode = '42501';
    end if;
    return new;
  end if;

  if not private.can_submit_mobile_daily_logs()
    or not private.current_employee_assigned_to_project(new."projectId"::text)
  then
    raise exception 'Daily log is not authorized for this project.'
      using errcode = '42501';
  end if;

  select
    project.name,
    coalesce(
      nullif(project."coordinatorId"::text, ''),
      nullif(project.coordinator_id::text, '')
    ),
    coalesce(
      nullif(project."coordinatorName", ''),
      nullif(project.coordinator_name, ''),
      coordinator.name
    )
  into v_project_name, v_coordinator_id, v_coordinator_name
  from public.projects project
  left join public.employees coordinator
    on coordinator.id::text = coalesce(
      nullif(project."coordinatorId"::text, ''),
      nullif(project.coordinator_id::text, '')
    )
  where project.id::text = new."projectId"::text
    and project."archivedAt" is null
  limit 1;

  if v_project_name is null then
    raise exception 'Active project was not found.'
      using errcode = '23503';
  end if;

  if tg_op = 'INSERT' then
    if new.status not in ('draft', 'finalized', 'pendingSignature', 'pendente') then
      raise exception 'Invalid initial daily log status.'
        using errcode = '22023';
    end if;
    new."projectName" := v_project_name;
    new."createdByUserId" := v_employee_id;
    new."coordinatorId" := v_coordinator_id;
    new."coordinatorName" := v_coordinator_name;
    new."signedAt" := null;
    new."signedByCoordinatorId" := null;
    new."signedByCoordinatorName" := null;
    new."createdAt" := clock_timestamp();
    new."updatedAt" := clock_timestamp();
    return new;
  end if;

  if old."createdByUserId"::text <> v_employee_id
    or old.status = 'signed'
    or new."projectId" is distinct from old."projectId"
    or new.status not in ('draft', 'finalized', 'pendingSignature', 'pendente')
  then
    raise exception 'Employee cannot perform this daily log transition.'
      using errcode = '42501';
  end if;

  new."projectId" := old."projectId";
  new."projectName" := old."projectName";
  new."createdByUserId" := old."createdByUserId";
  new."coordinatorId" := old."coordinatorId";
  new."coordinatorName" := old."coordinatorName";
  new."signedAt" := old."signedAt";
  new."signedByCoordinatorId" := old."signedByCoordinatorId";
  new."signedByCoordinatorName" := old."signedByCoordinatorName";
  new."createdAt" := old."createdAt";
  new."updatedAt" := clock_timestamp();
  return new;
end;
$$;

revoke all on function private.enforce_mobile_daily_log()
  from public, anon, authenticated;

drop trigger if exists trg_enforce_mobile_daily_log on public.daily_logs;
create trigger trg_enforce_mobile_daily_log
before insert or update on public.daily_logs
for each row execute function private.enforce_mobile_daily_log();

drop policy if exists daily_logs_select_internal on public.daily_logs;
drop policy if exists daily_logs_insert_supervisor_up on public.daily_logs;
drop policy if exists daily_logs_update_supervisor_up on public.daily_logs;
drop policy if exists daily_logs_delete_people_manage on public.daily_logs;
create policy daily_logs_select_authorized
on public.daily_logs for select to authenticated
using (
  private.can_read_projects()
  or private.current_employee_assigned_to_project("projectId"::text)
  or "createdByUserId" in (private.current_employee_id(), (select auth.uid())::text)
);
create policy daily_logs_insert_authorized
on public.daily_logs for insert to authenticated
with check (
  private.can_write_projects()
  or (
    private.can_submit_mobile_daily_logs()
    and "createdByUserId"::text = private.current_user_employee_id()
    and private.current_employee_assigned_to_project("projectId"::text)
  )
);
create policy daily_logs_update_authorized
on public.daily_logs for update to authenticated
using (
  private.can_write_projects()
  or (
    private.can_submit_mobile_daily_logs()
    and "createdByUserId"::text = private.current_user_employee_id()
    and private.current_employee_assigned_to_project("projectId"::text)
  )
)
with check (
  private.can_write_projects()
  or (
    private.can_submit_mobile_daily_logs()
    and "createdByUserId"::text = private.current_user_employee_id()
    and private.current_employee_assigned_to_project("projectId"::text)
  )
);

drop policy if exists financial_transactions_write_authorized on public.financial_transactions;
create policy financial_transactions_insert_authorized
on public.financial_transactions for insert to authenticated
with check (private.can_write_financial());
create policy financial_transactions_update_authorized
on public.financial_transactions for update to authenticated
using (private.can_write_financial())
with check (private.can_write_financial());

drop policy if exists employees_select_authorized on public.employees;
create policy employees_select_authorized
on public.employees
for select to authenticated
using (
  private.can_manage_people()
  or id::text = private.current_user_employee_id()
  or (
    private.has_min_employee_role(2)
    and private.employee_shares_team_with_current(id::text)
  )
);

create or replace function private.guard_team_assignment()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_employee_id text := private.current_user_employee_id();
begin
  if new."projectId" is not null
    and not exists (
      select 1
        from public.projects project
       where project.id::text = new."projectId"::text
         and project."archivedAt" is null
    )
  then
    raise exception 'Team project must be active.'
      using errcode = '23503';
  end if;

  if new."leaderId" is not null
    and not exists (
      select 1
        from public.employees employee
       where employee.id::text = new."leaderId"::text
         and employee.status <> 'desligado'
         and employee."archivedAt" is null
    )
  then
    raise exception 'Team leader must be active.'
      using errcode = '23503';
  end if;

  if exists (
    select 1
      from unnest(coalesce(new."memberIds", '{}'::text[])) member_id
     where not exists (
       select 1
         from public.employees employee
        where employee.id::text = member_id
          and employee.status <> 'desligado'
          and employee."archivedAt" is null
     )
  ) then
    raise exception 'Every team member must be active.'
      using errcode = '23503';
  end if;

  select coalesce(array_agg(distinct member_id), '{}'::text[])
    into new."memberIds"
    from unnest(coalesce(new."memberIds", '{}'::text[])) member_id;

  if (select auth.uid()) is null
    or private.can_manage_people()
    or private.can_write_projects()
  then
    return new;
  end if;

  if tg_op <> 'UPDATE'
    or old."leaderId"::text <> v_employee_id
    or new."leaderId" is distinct from old."leaderId"
    or new."projectId" is distinct from old."projectId"
    or new."createdAt" is distinct from old."createdAt"
  then
    raise exception 'Team leaders can only maintain members of their assigned team.'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

revoke all on function private.guard_team_assignment()
  from public, anon, authenticated;

drop trigger if exists trg_guard_team_assignment on public.teams;
create trigger trg_guard_team_assignment
before insert or update on public.teams
for each row execute function private.guard_team_assignment();

drop policy if exists teams_select_mobile_team on public.teams;
drop policy if exists teams_insert_supervisor_up on public.teams;
drop policy if exists teams_update_supervisor_up on public.teams;
drop policy if exists teams_delete_people_manage on public.teams;
create policy teams_select_authorized
on public.teams for select to authenticated
using (
  private.can_manage_people()
  or private.current_employee_assigned_to_project("projectId"::text)
  or private.team_has_current_employee("memberIds", "leaderId")
);
create policy teams_insert_authorized
on public.teams for insert to authenticated
with check (
  private.can_manage_people()
  or private.can_write_projects()
);
create policy teams_update_authorized
on public.teams for update to authenticated
using (
  private.can_manage_people()
  or private.can_write_projects()
  or (
    private.can_manage_mobile_teams()
    and "leaderId"::text = private.current_user_employee_id()
  )
)
with check (
  private.can_manage_people()
  or private.can_write_projects()
  or (
    private.can_manage_mobile_teams()
    and "leaderId"::text = private.current_user_employee_id()
  )
);

drop policy if exists sectors_people_manage_all on public.sectors;
create policy sectors_select_internal
on public.sectors
for select to authenticated
using (private.is_internal_user());
create policy sectors_insert_authorized
on public.sectors
for insert to authenticated
with check (private.can_manage_people());
create policy sectors_update_authorized
on public.sectors
for update to authenticated
using (private.can_manage_people())
with check (private.can_manage_people());

-- Task timers are server-owned. Direct task edits cannot rewrite accumulated
-- time, interval state, authorship, or completion timestamps.
create or replace function private.guard_granith_task_integrity()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_current_employee_id text := private.current_user_employee_id();
  v_supervisor_role text;
  v_assignee_active boolean;
  v_elapsed bigint;
begin
  if (select auth.uid()) is null then
    return new;
  end if;

  select employee.role
    into v_supervisor_role
    from public.employees employee
   where employee.id::text = new."supervisorId"::text
     and employee.status <> 'desligado'
     and employee."archivedAt" is null
   limit 1;

  select exists (
    select 1
      from public.employees employee
     where employee.id::text = new."assigneeId"::text
       and employee.status <> 'desligado'
       and employee."archivedAt" is null
  ) into v_assignee_active;

  if v_supervisor_role is null
    or v_supervisor_role not in ('supervisor', 'coordenador', 'gerente')
    or not coalesce(v_assignee_active, false)
  then
    raise exception 'Task participants must be active and the responsible person must be a supervisor.'
      using errcode = '22023';
  end if;

  if tg_op = 'INSERT' then
    new.status := 'pending';
    new."startedAt" := null;
    new."activeTimerStartedAt" := null;
    new."accumulatedSeconds" := 0;
    new."completedAt" := null;
    new."createdByUserId" := (select auth.uid())::text;
    new."createdByEmployeeId" := v_current_employee_id;
    new."createdAt" := clock_timestamp();
    return new;
  end if;

  if new."createdByUserId" is distinct from old."createdByUserId"
    or new."createdByEmployeeId" is distinct from old."createdByEmployeeId"
    or new."createdAt" is distinct from old."createdAt"
  then
    raise exception 'Task authorship is immutable.'
      using errcode = '42501';
  end if;

  if old.status in ('completed', 'cancelled')
    and coalesce(current_setting('granith.task_timer_operation', true), '') <> 'on'
  then
    raise exception 'Closed tasks cannot be edited.'
      using errcode = '42501';
  end if;

  if new.status = 'cancelled'
    and old.status is distinct from 'cancelled'
    and coalesce(current_setting('granith.task_timer_operation', true), '') <> 'on'
  then
    v_elapsed := case
      when old."activeTimerStartedAt" is null then 0
      else greatest(
        0,
        floor(
          extract(epoch from (clock_timestamp() - old."activeTimerStartedAt"))
        )::bigint
      )
    end;

    if old."activeTimerStartedAt" is not null then
      update public.granith_task_time_entries
         set "endedAt" = clock_timestamp(),
             "durationSeconds" = v_elapsed
       where "taskId" = old.id
         and "endedAt" is null;
    end if;

    new."startedAt" := old."startedAt";
    new."activeTimerStartedAt" := null;
    new."accumulatedSeconds" := old."accumulatedSeconds" + v_elapsed;
    new."completedAt" := null;
    return new;
  end if;

  if coalesce(current_setting('granith.task_timer_operation', true), '') <> 'on'
    and (
      new."startedAt" is distinct from old."startedAt"
      or new."activeTimerStartedAt" is distinct from old."activeTimerStartedAt"
      or new."accumulatedSeconds" is distinct from old."accumulatedSeconds"
      or new."completedAt" is distinct from old."completedAt"
      or (
        new.status is distinct from old.status
        and new.status <> 'cancelled'
      )
    )
  then
    raise exception 'Task timer fields can only be changed through the timer RPC.'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

revoke all on function private.guard_granith_task_integrity()
  from public, anon, authenticated;

drop trigger if exists trg_guard_granith_task_integrity
  on public.granith_tasks;
create trigger trg_guard_granith_task_integrity
before insert or update on public.granith_tasks
for each row execute function private.guard_granith_task_integrity();

create or replace function public.set_granith_task_timer(
  p_task_id text,
  p_action text,
  p_source text default 'web',
  p_occurred_at timestamptz default null
)
returns public.granith_tasks
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_task public.granith_tasks%rowtype;
  v_employee_id text := private.current_user_employee_id();
  v_now timestamptz := clock_timestamp();
  v_event_at timestamptz;
  v_elapsed bigint := 0;
  v_source text;
begin
  if (select auth.uid()) is null then
    raise exception 'Authentication required.'
      using errcode = '42501';
  end if;

  select *
    into v_task
    from public.granith_tasks
   where id::text = p_task_id
     and "archivedAt" is null
   for update;

  if not found then
    raise exception 'Task not found.'
      using errcode = 'P0002';
  end if;

  if v_employee_id is null then
    raise exception 'Authenticated user is not linked to an employee.'
      using errcode = '42501';
  end if;

  if v_task."assigneeId"::text <> v_employee_id
    and not private.can_manage_people()
  then
    raise exception 'Only the assignee can control this timer.'
      using errcode = '42501';
  end if;

  v_event_at := coalesce(p_occurred_at, v_now);
  v_event_at := least(v_now, greatest(v_now - interval '7 days', v_event_at));
  v_source := case
    when p_source in ('web', 'mobile', 'mobile_offline', 'system') then p_source
    else 'web'
  end;

  perform set_config('granith.task_timer_operation', 'on', true);

  if p_action = 'start' then
    if v_task.status in ('completed', 'cancelled') then
      raise exception 'Completed or cancelled tasks cannot be started.'
        using errcode = '22023';
    end if;

    if v_task."activeTimerStartedAt" is null then
      insert into public.granith_task_time_entries (
        "taskId",
        "employeeId",
        "startedAt",
        source,
        "clientOccurredAt",
        "createdByUserId"
      )
      values (
        v_task.id,
        v_task."assigneeId",
        v_event_at,
        v_source,
        p_occurred_at,
        (select auth.uid())::text
      );

      update public.granith_tasks
         set status = 'inProgress',
             "startedAt" = coalesce("startedAt", v_event_at),
             "activeTimerStartedAt" = v_event_at
       where id = v_task.id;
    end if;
  elsif p_action in ('pause', 'complete') then
    if v_task."activeTimerStartedAt" is not null then
      v_event_at := greatest(v_event_at, v_task."activeTimerStartedAt");
      v_elapsed := greatest(
        0,
        floor(
          extract(epoch from (v_event_at - v_task."activeTimerStartedAt"))
        )::bigint
      );

      update public.granith_task_time_entries
         set "endedAt" = v_event_at,
             "durationSeconds" = v_elapsed,
             "clientOccurredAt" = coalesce(
               p_occurred_at,
               "clientOccurredAt"
             )
       where "taskId" = v_task.id
         and "endedAt" is null;
    end if;

    update public.granith_tasks
       set status = case
             when p_action = 'complete' then 'completed'
             else 'paused'
           end,
           "accumulatedSeconds" = "accumulatedSeconds" + v_elapsed,
           "activeTimerStartedAt" = null,
           "completedAt" = case
             when p_action = 'complete' then v_event_at
             else null
           end
     where id = v_task.id;
  else
    raise exception 'Unsupported timer action.'
      using errcode = '22023';
  end if;

  perform set_config('granith.task_timer_operation', 'off', true);

  select *
    into v_task
    from public.granith_tasks
   where id::text = p_task_id;
  return v_task;
end;
$$;

revoke all on function public.set_granith_task_timer(
  text,
  text,
  text,
  timestamptz
) from public, anon;
grant execute on function public.set_granith_task_timer(
  text,
  text,
  text,
  timestamptz
) to authenticated, service_role;

-- REP-P records contain CPF and precise location. Employees only access and
-- create their own events; authorized managers retain operational visibility.
create or replace function private.enforce_time_clock_event_owner()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_employee_id text;
  v_employee_name text;
  v_employee_cpf text;
  v_candidate_project_id text;
  v_project_name text;
  v_project_latitude numeric;
  v_project_longitude numeric;
  v_geofence_side_meters numeric;
  v_geofence_required boolean;
  v_time_clock_enabled boolean;
  v_latitude_distance_meters double precision;
  v_longitude_distance_meters double precision;
  v_inside boolean := false;
  v_location_reliable boolean := false;
  v_project_authorized boolean := false;
  v_last_punch_type text;
  v_sequence_valid boolean := false;
begin
  if (select auth.uid()) is null or private.can_manage_time_clock() then
    return new;
  end if;

  v_employee_id := private.current_user_employee_id();
  if v_employee_id is null then
    raise exception 'Authenticated user is not linked to an employee.'
      using errcode = '42501';
  end if;

  if new."eventKind" not in ('punch', 'rejected_punch') then
    raise exception 'Employees can only submit their own punch events.'
      using errcode = '42501';
  end if;

  select e.name, e.cpf
    into v_employee_name, v_employee_cpf
    from public.employees e
   where e.id::text = v_employee_id
     and e.status <> 'desligado'
     and e."archivedAt" is null
   limit 1;

  if v_employee_name is null then
    raise exception 'Linked employee is not active.'
      using errcode = '42501';
  end if;

  new."userId" := (select auth.uid())::text;
  new."employeeId" := v_employee_id;
  new."employeeName" := v_employee_name;
  new."employeeCpf" := coalesce(v_employee_cpf, '');
  new."eventSource" := 'mobile';
  new."eventAt" := least(
    clock_timestamp() + interval '5 minutes',
    greatest(
      clock_timestamp() - interval '7 days',
      coalesce(new."eventAt", clock_timestamp())
    )
  );
  new."createdAt" := clock_timestamp();

  if new."punchType" not in ('entry', 'exit') then
    raise exception 'Mobile employees can only submit entry or exit punches.'
      using errcode = '22023';
  end if;

  if jsonb_typeof(new."rawPayload") <> 'object'
    or pg_column_size(new."rawPayload") > 100000
  then
    raise exception 'Invalid time clock payload.'
      using errcode = '22023';
  end if;

  select
    settings.time_clock_enabled,
    settings.time_clock_geofence_required
  into v_time_clock_enabled, v_geofence_required
  from public.system_settings settings
  where settings.id = 'default'
  limit 1;

  if not coalesce(v_time_clock_enabled, true) then
    raise exception 'Time clock is disabled.'
      using errcode = '42501';
  end if;

  v_candidate_project_id := coalesce(
    nullif(new."projectId"::text, ''),
    nullif(new."geofenceId"::text, '')
  );
  v_project_authorized :=
    private.current_employee_assigned_to_project(v_candidate_project_id);

  if v_project_authorized then
    select
      project.name,
      project.latitude,
      project.longitude,
      coalesce(
        project."geofenceSideMeters",
        project.geofence_side_meters,
        120
      )
    into
      v_project_name,
      v_project_latitude,
      v_project_longitude,
      v_geofence_side_meters
    from public.projects project
    where project.id::text = v_candidate_project_id
      and project.status <> 'completed'
      and project."archivedAt" is null
    limit 1;
  end if;

  v_location_reliable :=
    new.latitude is not null
    and new.longitude is not null
    and new."accuracyMeters" is not null
    and new."accuracyMeters" between 0 and 80
    and v_project_latitude is not null
    and v_project_longitude is not null
    and coalesce(v_geofence_side_meters, 0) > 0;

  if v_location_reliable then
    v_latitude_distance_meters :=
      abs(new.latitude - v_project_latitude) * 111320.0;
    v_longitude_distance_meters :=
      abs(new.longitude - v_project_longitude)
      * 111320.0
      * greatest(0.01, cos(radians(v_project_latitude)));
    v_inside :=
      v_latitude_distance_meters <= v_geofence_side_meters / 2.0
      and v_longitude_distance_meters <= v_geofence_side_meters / 2.0;
  end if;

  select event."punchType"
    into v_last_punch_type
    from public.time_clock_afd_events event
   where event."employeeId"::text = v_employee_id
     and event."eventKind" = 'punch'
     and event."eventAt" <= new."eventAt"
   order by event."eventAt" desc, event.nsr desc
   limit 1;

  v_sequence_valid := case new."punchType"
    when 'entry' then coalesce(v_last_punch_type, 'exit') = 'exit'
    when 'exit' then v_last_punch_type = 'entry'
    else false
  end;

  if not coalesce(v_geofence_required, true) then
    new."geofenceStatus" := 'disabled';
    v_inside := true;
  elsif not v_project_authorized or v_project_name is null then
    new."geofenceStatus" := 'unknown';
    new.reason := 'Obra nao atribuida ao funcionario.';
  elsif not v_location_reliable then
    new."geofenceStatus" := 'unknown';
    new.reason := 'Localizacao sem precisao suficiente para validar a cerca.';
  elsif v_inside then
    new."geofenceStatus" := 'inside';
  else
    new."geofenceStatus" := 'outside';
    new.reason := 'Ponto fora da cerca da obra.';
  end if;

  if v_inside and v_sequence_valid then
    new."eventKind" := 'punch';
    new."projectId" := case
      when v_project_authorized then v_candidate_project_id
      else null
    end;
    new."projectName" := coalesce(v_project_name, '');
    new."geofenceId" := new."projectId";
    new."geofenceName" := new."projectName";
    new.reason := '';
  else
    new."eventKind" := 'rejected_punch';
    if not v_sequence_valid then
      new.reason := case new."punchType"
        when 'entry' then 'Ja existe uma entrada sem saida.'
        else 'Nao existe uma entrada aberta para registrar a saida.'
      end;
    end if;
    new."projectId" := case
      when v_project_authorized then v_candidate_project_id
      else null
    end;
    new."projectName" := case
      when v_project_authorized then coalesce(v_project_name, '')
      else ''
    end;
    new."geofenceId" := new."projectId";
    new."geofenceName" := new."projectName";
  end if;

  new."rawPayload" := new."rawPayload" || jsonb_build_object(
    'serverValidated', true,
    'serverProjectAuthorized', v_project_authorized,
    'serverLocationReliable', v_location_reliable,
    'serverInsideGeofence', v_inside,
    'serverSequenceValid', v_sequence_valid
  );
  return new;
end;
$$;

drop trigger if exists trg_enforce_time_clock_event_owner
  on public.time_clock_afd_events;
create trigger trg_enforce_time_clock_event_owner
before insert on public.time_clock_afd_events
for each row execute function private.enforce_time_clock_event_owner();

drop policy if exists time_clock_afd_events_select_internal
  on public.time_clock_afd_events;
drop policy if exists time_clock_afd_events_insert_internal
  on public.time_clock_afd_events;
create policy time_clock_afd_events_select_authorized
on public.time_clock_afd_events
for select to authenticated
using (
  private.can_read_time_clock()
  or "userId"::text = (select auth.uid())::text
  or "employeeId"::text = private.current_user_employee_id()
);
create policy time_clock_afd_events_insert_authorized
on public.time_clock_afd_events
for insert to authenticated
with check (
  private.can_manage_time_clock()
  or (
    "userId"::text = (select auth.uid())::text
    and "employeeId"::text = private.current_user_employee_id()
    and "eventKind" in ('punch', 'rejected_punch')
    and "eventSource" = 'mobile'
  )
);

create or replace function private.enforce_mobile_work_hour_owner()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_employee_id text;
  v_employee_name text;
  v_project_name text;
begin
  if (select auth.uid()) is null or private.can_manage_time_clock() then
    return new;
  end if;

  if not private.has_any_permission(array['mobile.work_hours.manual']) then
    raise exception 'User cannot submit manual work hours.'
      using errcode = '42501';
  end if;

  v_employee_id := private.current_user_employee_id();
  select e.name
    into v_employee_name
    from public.employees e
   where e.id::text = v_employee_id
     and e."archivedAt" is null
   limit 1;

  if v_employee_name is null then
    raise exception 'Authenticated user is not linked to an active employee.'
      using errcode = '42501';
  end if;

  if not private.current_employee_assigned_to_project(new."projectId"::text) then
    raise exception 'Manual work hours require an assigned project.'
      using errcode = '42501';
  end if;

  select project.name
    into v_project_name
    from public.projects project
   where project.id::text = new."projectId"::text
     and project."archivedAt" is null
   limit 1;

  if v_project_name is null
    or new."endAt" <= new."startAt"
    or new."endAt" - new."startAt" > interval '24 hours'
    or new."startAt" < clock_timestamp() - interval '30 days'
    or new."endAt" > clock_timestamp() + interval '5 minutes'
  then
    raise exception 'Invalid manual work-hour interval.'
      using errcode = '22023';
  end if;

  new."userId" := (select auth.uid())::text;
  new."employeeId" := v_employee_id;
  new."employeeName" := v_employee_name;
  new."projectName" := v_project_name;
  new."durationMinutes" := floor(
    extract(epoch from (new."endAt" - new."startAt")) / 60
  )::integer;
  new.reason := left(trim(coalesce(new.reason, '')), 2000);
  new.status := 'pending';
  new."approvedBy" := null;
  new."approvedAt" := null;
  new."createdAt" := clock_timestamp();
  new."updatedAt" := clock_timestamp();
  return new;
end;
$$;

drop trigger if exists trg_enforce_mobile_work_hour_owner
  on public.mobile_work_hour_entries;
create trigger trg_enforce_mobile_work_hour_owner
before insert on public.mobile_work_hour_entries
for each row execute function private.enforce_mobile_work_hour_owner();

drop policy if exists mobile_work_hour_entries_select_internal
  on public.mobile_work_hour_entries;
drop policy if exists mobile_work_hour_entries_insert_internal
  on public.mobile_work_hour_entries;
drop policy if exists mobile_work_hour_entries_manage_people
  on public.mobile_work_hour_entries;
create policy mobile_work_hour_entries_select_authorized
on public.mobile_work_hour_entries
for select to authenticated
using (
  private.can_read_time_clock()
  or "userId"::text = (select auth.uid())::text
  or "employeeId"::text = private.current_user_employee_id()
);
create policy mobile_work_hour_entries_insert_authorized
on public.mobile_work_hour_entries
for insert to authenticated
with check (
  private.can_manage_time_clock()
  or (
    private.has_any_permission(array['mobile.work_hours.manual'])
    and "userId"::text = (select auth.uid())::text
    and "employeeId"::text = private.current_user_employee_id()
    and private.current_employee_assigned_to_project("projectId"::text)
    and status = 'pending'
    and "approvedBy" is null
    and "approvedAt" is null
  )
);
create policy mobile_work_hour_entries_update_authorized
on public.mobile_work_hour_entries
for update to authenticated
using (private.can_manage_time_clock())
with check (private.can_manage_time_clock());

-- Field submissions are owned by the authenticated employee and always enter
-- a review state. Only the responsible module can review or change them.
create or replace function private.enforce_mobile_field_operation_owner()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_can_review boolean;
  v_can_submit boolean;
  v_employee_id text;
  v_employee_name text;
  v_project_name text;
  v_vehicle_plate text;
  v_vehicle_label text;
begin
  v_can_review := case tg_table_name
    when 'mobile_inventory_operations' then private.can_write_inventory()
    when 'mobile_vehicle_field_reports' then private.can_manage_fleet()
    when 'mobile_project_measurement_evidence' then private.can_write_projects()
    else false
  end;

  if (select auth.uid()) is null or v_can_review then
    return new;
  end if;

  v_employee_id := private.current_user_employee_id();
  select e.name
    into v_employee_name
    from public.employees e
   where e.id::text = v_employee_id
     and e."archivedAt" is null
   limit 1;

  if v_employee_name is null then
    raise exception 'Authenticated user is not linked to an active employee.'
      using errcode = '42501';
  end if;

  v_can_submit := case tg_table_name
    when 'mobile_inventory_operations' then
      private.has_any_permission(array['mobile.inventory.operate'])
      and (
        new."projectId" is null
        or private.current_employee_assigned_to_project(new."projectId"::text)
      )
    when 'mobile_vehicle_field_reports' then
      private.has_any_permission(array['mobile.vehicle_checklist.write'])
      and private.can_submit_mobile_fuel_log(new."vehicleId"::text)
    when 'mobile_project_measurement_evidence' then
      private.has_any_permission(array['mobile.measurements.evidence.write'])
      and private.current_employee_assigned_to_project(new."projectId"::text)
    else false
  end;

  if not coalesce(v_can_submit, false) then
    raise exception 'User is not authorized for this mobile field operation.'
      using errcode = '42501';
  end if;

  if tg_table_name in (
    'mobile_inventory_operations',
    'mobile_project_measurement_evidence'
  ) and new."projectId" is not null then
    select project.name
      into v_project_name
      from public.projects project
     where project.id::text = new."projectId"::text
       and project."archivedAt" is null
     limit 1;
    if v_project_name is null then
      raise exception 'Active project was not found.'
        using errcode = '23503';
    end if;
    new."projectName" := v_project_name;
  end if;

  if tg_table_name = 'mobile_inventory_operations' then
    if new.quantity <= 0
      or length(trim(new."itemName")) > 250
      or length(new.notes) > 4000
    then
      raise exception 'Invalid inventory operation payload.'
        using errcode = '22023';
    end if;
  elsif tg_table_name = 'mobile_vehicle_field_reports' then
    select
      vehicle.plate,
      trim(concat_ws(' ', vehicle.brand, vehicle.model))
    into v_vehicle_plate, v_vehicle_label
    from public.vehicles vehicle
    where vehicle.id::text = new."vehicleId"::text
      and vehicle.status = 'active'
      and vehicle."archivedAt" is null
    limit 1;

    if v_vehicle_plate is null
      or new."odometerKm" < 0
      or pg_column_size(new.checklist) > 100000
      or length(new.description) > 4000
    then
      raise exception 'Invalid vehicle field report payload.'
        using errcode = '22023';
    end if;
    new."vehiclePlate" := v_vehicle_plate;
    new."vehicleLabel" := v_vehicle_label;
  elsif tg_table_name = 'mobile_project_measurement_evidence' then
    if new."suggestedProgressPercent" not between 0 and 100
      or length(new."evidenceDescription") > 8000
      or octet_length(new."photoDataUrl") > 10485760
    then
      raise exception 'Invalid measurement evidence payload.'
        using errcode = '22023';
    end if;
  end if;

  new."userId" := (select auth.uid())::text;
  new."employeeId" := v_employee_id;
  new."employeeName" := v_employee_name;
  new.source := 'mobile';
  new."createdAt" := clock_timestamp();
  new."updatedAt" := clock_timestamp();
  if tg_table_name = 'mobile_project_measurement_evidence' then
    new.status := 'field_suggested';
  else
    new.status := 'pending_review';
  end if;
  return new;
end;
$$;

do $$
declare
  v_table_name text;
begin
  foreach v_table_name in array array[
    'mobile_inventory_operations',
    'mobile_vehicle_field_reports',
    'mobile_project_measurement_evidence'
  ]
  loop
    execute format(
      'drop trigger if exists %I on public.%I',
      'trg_enforce_owner_' || v_table_name,
      v_table_name
    );
    execute format(
      'create trigger %I before insert on public.%I for each row execute function private.enforce_mobile_field_operation_owner()',
      'trg_enforce_owner_' || v_table_name,
      v_table_name
    );
  end loop;
end $$;

drop policy if exists mobile_inventory_operations_internal_crud
  on public.mobile_inventory_operations;
create policy mobile_inventory_operations_select_authorized
on public.mobile_inventory_operations
for select to authenticated
using (
  private.can_read_inventory()
  or "userId"::text = (select auth.uid())::text
  or "employeeId"::text = private.current_user_employee_id()
);
create policy mobile_inventory_operations_insert_authorized
on public.mobile_inventory_operations
for insert to authenticated
with check (
  private.can_write_inventory()
  or (
    private.has_any_permission(array['mobile.inventory.operate'])
    and
    "userId"::text = (select auth.uid())::text
    and "employeeId"::text = private.current_user_employee_id()
    and (
      "projectId" is null
      or private.current_employee_assigned_to_project("projectId"::text)
    )
    and status = 'pending_review'
  )
);
create policy mobile_inventory_operations_update_authorized
on public.mobile_inventory_operations
for update to authenticated
using (private.can_write_inventory())
with check (private.can_write_inventory());

drop policy if exists mobile_vehicle_field_reports_internal_crud
  on public.mobile_vehicle_field_reports;
create policy mobile_vehicle_field_reports_select_authorized
on public.mobile_vehicle_field_reports
for select to authenticated
using (
  private.can_read_fleet()
  or "userId"::text = (select auth.uid())::text
  or "employeeId"::text = private.current_user_employee_id()
);
create policy mobile_vehicle_field_reports_insert_authorized
on public.mobile_vehicle_field_reports
for insert to authenticated
with check (
  private.can_manage_fleet()
  or (
    private.has_any_permission(array['mobile.vehicle_checklist.write'])
    and private.can_submit_mobile_fuel_log("vehicleId"::text)
    and
    "userId"::text = (select auth.uid())::text
    and "employeeId"::text = private.current_user_employee_id()
    and status = 'pending_review'
  )
);
create policy mobile_vehicle_field_reports_update_authorized
on public.mobile_vehicle_field_reports
for update to authenticated
using (private.can_manage_fleet())
with check (private.can_manage_fleet());

drop policy if exists mobile_project_measurement_evidence_internal_crud
  on public.mobile_project_measurement_evidence;
create policy mobile_project_measurement_evidence_select_authorized
on public.mobile_project_measurement_evidence
for select to authenticated
using (
  private.can_read_projects()
  or "userId"::text = (select auth.uid())::text
  or "employeeId"::text = private.current_user_employee_id()
);
create policy mobile_project_measurement_evidence_insert_authorized
on public.mobile_project_measurement_evidence
for insert to authenticated
with check (
  private.can_write_projects()
  or (
    private.has_any_permission(array['mobile.measurements.evidence.write'])
    and private.current_employee_assigned_to_project("projectId"::text)
    and
    "userId"::text = (select auth.uid())::text
    and "employeeId"::text = private.current_user_employee_id()
    and status = 'field_suggested'
  )
);
create policy mobile_project_measurement_evidence_update_authorized
on public.mobile_project_measurement_evidence
for update to authenticated
using (private.can_write_projects())
with check (private.can_write_projects());

drop policy if exists mobile_project_documents_internal_select
  on public.mobile_project_documents;
drop policy if exists mobile_project_documents_internal_manage
  on public.mobile_project_documents;
create policy mobile_project_documents_select_authorized
on public.mobile_project_documents
for select to authenticated
using (
  "isActive" = true
  and (
    private.can_read_projects()
    or private.current_employee_assigned_to_project("projectId"::text)
  )
);
create policy mobile_project_documents_insert_authorized
on public.mobile_project_documents
for insert to authenticated
with check (private.can_write_projects());
create policy mobile_project_documents_update_authorized
on public.mobile_project_documents
for update to authenticated
using (private.can_write_projects())
with check (private.can_write_projects());

-- Drivers can operate only their assigned route. Financial and assignment
-- fields stay server-controlled, while actual distance is derived from the
-- append-only tracking ledger.
create or replace function private.enforce_driver_route_update()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_employee_id text := private.current_user_employee_id();
  v_distance_km numeric(10,2);
begin
  if (select auth.uid()) is null or private.can_manage_fleet() then
    return new;
  end if;

  if v_employee_id is null or old."driverId"::text <> v_employee_id then
    raise exception 'Only the assigned driver can operate this route.'
      using errcode = '42501';
  end if;

  if row(
    new.id,
    new.name,
    new."driverId",
    new."driverName",
    new."scheduledDate",
    new."estimatedDistanceKm",
    new."kmRate",
    new.notes,
    new."createdBy",
    new."createdAt"
  ) is distinct from row(
    old.id,
    old.name,
    old."driverId",
    old."driverName",
    old."scheduledDate",
    old."estimatedDistanceKm",
    old."kmRate",
    old.notes,
    old."createdBy",
    old."createdAt"
  ) then
    raise exception 'Driver cannot change route assignment or financial fields.'
      using errcode = '42501';
  end if;

  if old.status = 'planned' and new.status not in ('planned', 'inProgress') then
    raise exception 'Invalid route status transition.'
      using errcode = '42501';
  elsif old.status = 'inProgress'
    and new.status not in ('inProgress', 'completed') then
    raise exception 'Invalid route status transition.'
      using errcode = '42501';
  elsif old.status in ('completed', 'cancelled')
    and new.status <> old.status then
    raise exception 'Closed routes cannot change status.'
      using errcode = '42501';
  end if;

  if new."startedAt" is distinct from old."startedAt"
    and not (
      old.status = 'planned'
      and new.status = 'inProgress'
      and old."startedAt" is null
      and new."startedAt" is not null
    ) then
    raise exception 'Route start timestamp is immutable.'
      using errcode = '42501';
  end if;
  if new."completedAt" is distinct from old."completedAt"
    and not (
      old.status = 'inProgress'
      and new.status = 'completed'
      and old."completedAt" is null
      and new."completedAt" is not null
    ) then
    raise exception 'Route completion timestamp is immutable.'
      using errcode = '42501';
  end if;
  if old.status = 'planned'
    and new.status = 'inProgress'
    and (
      new."startedAt" is null
      or new."startedAt" > now() + interval '5 minutes'
    ) then
    raise exception 'A valid route start timestamp is required.'
      using errcode = '22007';
  end if;
  if old.status = 'inProgress'
    and new.status = 'completed'
    and (
      new."completedAt" is null
      or new."completedAt" < coalesce(new."startedAt", old."startedAt")
      or new."completedAt" > now() + interval '5 minutes'
    ) then
    raise exception 'A valid route completion timestamp is required.'
      using errcode = '22007';
  end if;

  select round(
    coalesce(sum(point."distanceFromPreviousMeters"), 0) / 1000.0,
    2
  )
    into v_distance_km
    from public.purchase_delivery_route_tracking_points point
   where point."routeId" = old.id;

  new."actualDistanceKm" := coalesce(v_distance_km, 0);
  new."kmRate" := old."kmRate";
  new."bonusValue" := round(new."actualDistanceKm" * old."kmRate", 2);
  new."updatedAt" := now();

  if old.status in ('completed', 'cancelled')
    and row(
      new.status,
      new."startedAt",
      new."completedAt",
      new."encodedPolyline",
      new."routeDistanceMeters",
      new."routeDurationSeconds",
      new."optimizedStopIds"
    ) is distinct from row(
      old.status,
      old."startedAt",
      old."completedAt",
      old."encodedPolyline",
      old."routeDistanceMeters",
      old."routeDurationSeconds",
      old."optimizedStopIds"
    ) then
    raise exception 'Closed routes are immutable.'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_enforce_driver_route_update
  on public.purchase_delivery_routes;
create trigger trg_enforce_driver_route_update
before update on public.purchase_delivery_routes
for each row execute function private.enforce_driver_route_update();

create or replace function private.enforce_driver_route_stop_update()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_employee_id text := private.current_user_employee_id();
begin
  if (select auth.uid()) is null or private.can_manage_fleet() then
    return new;
  end if;

  if v_employee_id is null or not exists (
    select 1
      from public.purchase_delivery_routes route
     where route.id = old."routeId"
       and route."driverId"::text = v_employee_id
       and route."archivedAt" is null
  ) then
    raise exception 'Only the assigned driver can update this stop.'
      using errcode = '42501';
  end if;

  if row(
    new.id,
    new."routeId",
    new."purchaseId",
    new."stopType",
    new.sequence,
    new.address,
    new."supplierName",
    new."projectName",
    new.notes,
    new."createdAt"
  ) is distinct from row(
    old.id,
    old."routeId",
    old."purchaseId",
    old."stopType",
    old.sequence,
    old.address,
    old."supplierName",
    old."projectName",
    old.notes,
    old."createdAt"
  ) then
    raise exception 'Driver cannot change stop planning fields.'
      using errcode = '42501';
  end if;

  if old.status = 'pending'
    and new.status not in ('pending', 'completed', 'skipped') then
    raise exception 'Invalid stop status transition.'
      using errcode = '42501';
  elsif old.status in ('completed', 'skipped')
    and row(
      new.status,
      new.latitude,
      new.longitude,
      new."completedLatitude",
      new."completedLongitude",
      new."completedAccuracyMeters",
      new."proofPhotoDataUrl",
      new."signatureDataUrl",
      new."signedByName",
      new."occurrenceNotes",
      new."completedAt"
    ) is distinct from row(
      old.status,
      old.latitude,
      old.longitude,
      old."completedLatitude",
      old."completedLongitude",
      old."completedAccuracyMeters",
      old."proofPhotoDataUrl",
      old."signatureDataUrl",
      old."signedByName",
      old."occurrenceNotes",
      old."completedAt"
    ) then
    raise exception 'Completed stops are immutable.'
      using errcode = '42501';
  end if;

  if old.status = 'pending'
    and new.status = 'pending'
    and new."completedAt" is distinct from old."completedAt" then
    raise exception 'Pending stops cannot have a completion timestamp.'
      using errcode = '42501';
  end if;
  if old.status = 'pending'
    and new.status = 'completed'
    and (
      new."completedAt" is null
      or new."completedAt" > now() + interval '5 minutes'
    ) then
    raise exception 'A valid stop completion timestamp is required.'
      using errcode = '22007';
  end if;

  if length(new."proofPhotoDataUrl") > 14000000
    or length(new."signatureDataUrl") > 4000000
    or length(new."occurrenceNotes") > 5000 then
    raise exception 'Stop evidence exceeds the allowed size.'
      using errcode = '22001';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_enforce_driver_route_stop_update
  on public.purchase_delivery_route_stops;
create trigger trg_enforce_driver_route_stop_update
before update on public.purchase_delivery_route_stops
for each row execute function private.enforce_driver_route_stop_update();

create or replace function private.enforce_route_tracking_point()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_employee_id text := private.current_user_employee_id();
  v_employee_name text;
  v_previous_latitude double precision;
  v_previous_longitude double precision;
  v_previous_recorded_at timestamptz;
  v_latitude_delta double precision;
  v_longitude_delta double precision;
  v_haversine double precision;
  v_distance_meters numeric(10,2);
  v_elapsed_seconds double precision;
  v_route_driver_id text;
  v_route_status text;
  v_route_started_at timestamptz;
  v_route_completed_at timestamptz;
begin
  select
    route."driverId"::text,
    route.status,
    route."startedAt",
    route."completedAt"
    into
      v_route_driver_id,
      v_route_status,
      v_route_started_at,
      v_route_completed_at
    from public.purchase_delivery_routes route
   where route.id = new."routeId"
     and route."archivedAt" is null
   limit 1;

  if v_route_status is null then
    raise exception 'Route is not available for tracking.'
      using errcode = '42501';
  end if;

  if (select auth.uid()) is not null and not private.can_manage_fleet() then
    if v_employee_id is null or v_route_driver_id <> v_employee_id then
      raise exception 'Only the assigned driver can append route tracking.'
        using errcode = '42501';
    end if;

    select e.name
      into v_employee_name
      from public.employees e
     where e.id::text = v_employee_id
       and e."archivedAt" is null
     limit 1;

    if v_employee_name is null then
      raise exception 'Assigned driver is not active.'
        using errcode = '42501';
    end if;

    new."userId" := (select auth.uid())::text;
    new."employeeId" := v_employee_id;
    new."employeeName" := v_employee_name;
    new.source := 'mobile';
  end if;

  if v_route_status not in ('inProgress', 'completed')
    or new."recordedAt" > now() + interval '5 minutes'
    or (
      v_route_started_at is not null
      and new."recordedAt" < v_route_started_at - interval '5 minutes'
    )
    or (
      v_route_completed_at is not null
      and new."recordedAt" > v_route_completed_at + interval '5 minutes'
    ) then
    raise exception 'Tracking timestamp is outside the route execution window.'
      using errcode = '22007';
  end if;

  select point.latitude, point.longitude, point."recordedAt"
    into v_previous_latitude, v_previous_longitude, v_previous_recorded_at
    from public.purchase_delivery_route_tracking_points point
   where point."routeId" = new."routeId"
     and point."recordedAt" <= new."recordedAt"
   order by point."recordedAt" desc, point."createdAt" desc
   limit 1;

  if v_previous_latitude is null or v_previous_longitude is null then
    new."distanceFromPreviousMeters" := 0;
  else
    v_latitude_delta := radians(new.latitude - v_previous_latitude);
    v_longitude_delta := radians(new.longitude - v_previous_longitude);
    v_haversine :=
      power(sin(v_latitude_delta / 2), 2)
      + cos(radians(v_previous_latitude))
        * cos(radians(new.latitude))
        * power(sin(v_longitude_delta / 2), 2);
    v_distance_meters := round(
      (
        2 * 6371000
        * asin(sqrt(least(1.0, greatest(0.0, v_haversine))))
      )::numeric,
      2
    );
    v_elapsed_seconds := extract(
      epoch from new."recordedAt" - v_previous_recorded_at
    );

    if v_elapsed_seconds <= 0
      or coalesce(new."accuracyMeters", 0) > 100
      or v_distance_meters / v_elapsed_seconds > 60 then
      new."distanceFromPreviousMeters" := 0;
    else
      new."distanceFromPreviousMeters" := v_distance_meters;
    end if;
  end if;

  new."syncedAt" := now();
  new."createdAt" := now();
  return new;
end;
$$;

drop trigger if exists trg_enforce_route_tracking_point
  on public.purchase_delivery_route_tracking_points;
create trigger trg_enforce_route_tracking_point
before insert on public.purchase_delivery_route_tracking_points
for each row execute function private.enforce_route_tracking_point();

drop policy if exists purchase_delivery_routes_select_authorized
  on public.purchase_delivery_routes;
drop policy if exists purchase_delivery_routes_update_authorized
  on public.purchase_delivery_routes;
create policy purchase_delivery_routes_select_authorized
on public.purchase_delivery_routes
for select to authenticated
using (
  private.can_read_fleet()
  or "driverId"::text = private.current_user_employee_id()
);
create policy purchase_delivery_routes_update_authorized
on public.purchase_delivery_routes
for update to authenticated
using (
  private.can_manage_fleet()
  or "driverId"::text = private.current_user_employee_id()
)
with check (
  private.can_manage_fleet()
  or "driverId"::text = private.current_user_employee_id()
);

drop policy if exists purchase_delivery_route_stops_select_authorized
  on public.purchase_delivery_route_stops;
drop policy if exists purchase_delivery_route_stops_update_authorized
  on public.purchase_delivery_route_stops;
create policy purchase_delivery_route_stops_select_authorized
on public.purchase_delivery_route_stops
for select to authenticated
using (
  private.can_read_fleet()
  or exists (
    select 1
      from public.purchase_delivery_routes route
     where route.id = "routeId"
       and route."driverId"::text = private.current_user_employee_id()
  )
);
create policy purchase_delivery_route_stops_update_authorized
on public.purchase_delivery_route_stops
for update to authenticated
using (
  private.can_manage_fleet()
  or exists (
    select 1
      from public.purchase_delivery_routes route
     where route.id = "routeId"
       and route."driverId"::text = private.current_user_employee_id()
  )
)
with check (
  private.can_manage_fleet()
  or exists (
    select 1
      from public.purchase_delivery_routes route
     where route.id = "routeId"
       and route."driverId"::text = private.current_user_employee_id()
  )
);

drop policy if exists purchase_delivery_route_tracking_points_update_assigned
  on public.purchase_delivery_route_tracking_points;
drop policy if exists purchase_delivery_route_tracking_points_delete_managers
  on public.purchase_delivery_route_tracking_points;
revoke update, delete on public.purchase_delivery_route_tracking_points
  from authenticated;

-- Keep the client view sanitized and hide archived projects explicitly.
create or replace view public.client_portal_projects
with (security_barrier = true)
as
select
  p.id,
  p.name,
  p.client,
  p.description,
  p.status,
  p."startDate",
  p."endDate",
  p.location,
  p.tags,
  p."teamSize",
  p."imageUrl",
  p."clientAccountId",
  p.client_account_id,
  p."clientAccountName",
  p.client_account_name,
  p."estimatedProgress",
  p.estimated_progress,
  p."measurementCount",
  p.measurement_count,
  p."lastMeasurementAt",
  p.last_measurement_at
from public.projects p
where p."archivedAt" is null
  and private.client_can_access_account(
    coalesce(p."clientAccountId"::text, p.client_account_id::text)
  );

revoke all on public.client_portal_projects from public, anon;
grant select on public.client_portal_projects to authenticated;
