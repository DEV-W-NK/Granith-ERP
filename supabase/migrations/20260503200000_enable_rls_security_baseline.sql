-- Granith ERP - Supabase security baseline.
-- This migration enables RLS on current public tables, removes broad access,
-- and installs policies aligned with the app roles: admin, employee, client.

create schema if not exists private;

revoke all on schema private from public, anon, authenticated;
grant usage on schema private to authenticated;

revoke all on schema public from public, anon;
grant usage on schema public to authenticated;

revoke all on all tables in schema public from public, anon;
grant select, insert, update, delete on all tables in schema public to authenticated;

alter default privileges in schema public revoke all on tables from public;
alter default privileges in schema public revoke all on tables from anon;
alter default privileges in schema public revoke all on tables from authenticated;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new."updatedAt" = now();
  return new;
end;
$$;

drop policy if exists "Acesso Total" on public.client_accounts;
drop policy if exists "Allow select for everyone" on storage.objects;

alter table if exists public.users
  add column if not exists "clientAccountId" text;
alter table if exists public.users
  add column if not exists client_account_id text;
alter table if exists public.users
  add column if not exists "clientAccountName" text;
alter table if exists public.users
  add column if not exists client_account_name text;

alter table if exists public.client_accounts
  add column if not exists "ownerEmail" text;
alter table if exists public.client_accounts
  add column if not exists owner_email text;
alter table if exists public.client_accounts
  add column if not exists "contactEmail" text;
alter table if exists public.client_accounts
  add column if not exists contact_email text;
alter table if exists public.client_accounts
  add column if not exists "contactPhone" text;
alter table if exists public.client_accounts
  add column if not exists contact_phone text;
alter table if exists public.client_accounts
  add column if not exists "portalAuthUserId" text;
alter table if exists public.client_accounts
  add column if not exists portal_auth_user_id text;

alter table if exists public.projects
  add column if not exists "clientAccountId" text;
alter table if exists public.projects
  add column if not exists client_account_id text;
alter table if exists public.projects
  add column if not exists "clientAccountName" text;
alter table if exists public.projects
  add column if not exists client_account_name text;

alter table if exists public.project_measurements
  add column if not exists "projectId" text;
alter table if exists public.project_measurements
  add column if not exists project_id text;

alter table if exists public.budgets
  add column if not exists "projectId" text;
alter table if exists public.budgets
  add column if not exists project_id text;
alter table if exists public.budgets
  add column if not exists "clientAccountId" text;
alter table if exists public.budgets
  add column if not exists client_account_id text;
alter table if exists public.budgets
  add column if not exists "clientAccountName" text;
alter table if exists public.budgets
  add column if not exists client_account_name text;

create or replace function private.jwt_email()
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select lower(coalesce(auth.jwt() ->> 'email', ''));
$$;

create or replace function private.current_user_role()
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select u.role
  from public.users u
  where u.id::text = (select auth.uid())::text
  limit 1;
$$;

create or replace function private.current_user_permissions()
returns text[]
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(u.permissions, '{}'::text[])
  from public.users u
  where u.id::text = (select auth.uid())::text
  limit 1;
$$;

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(private.current_user_role() = 'admin', false);
$$;

create or replace function private.is_internal_user()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(private.current_user_role() in ('admin', 'employee'), false);
$$;

create or replace function private.has_permission(required_permission text)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(required_permission = any(private.current_user_permissions()), false);
$$;

create or replace function private.can_manage_access()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.is_admin() or private.has_permission('access.manage');
$$;

create or replace function private.can_manage_people()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.is_admin() or private.has_permission('people.manage');
$$;

create or replace function private.can_manage_settings()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.is_admin() or private.has_permission('settings.manage');
$$;

create or replace function private.can_read_financial()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.is_admin() or private.has_permission('financial.read');
$$;

create or replace function private.can_write_financial()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.is_admin() or private.has_permission('financial.write');
$$;

create or replace function private.can_read_usage()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.is_admin()
    or private.has_permission('billing.manage')
    or private.has_permission('infra.sync_usage')
    or private.has_permission('settings.manage');
$$;

create or replace function private.employee_record_exists(user_email text)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.employees e
    where lower(e.email) = lower(coalesce(nullif(user_email, ''), private.jwt_email()))
  );
$$;

create or replace function private.client_account_exists_for_user(
  user_email text,
  account_id text default null
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.client_accounts ca
    where (
      lower(ca."ownerEmail") = lower(coalesce(nullif(user_email, ''), private.jwt_email()))
      or lower(coalesce(ca.owner_email, '')) = lower(coalesce(nullif(user_email, ''), private.jwt_email()))
      or ca."portalAuthUserId"::text = (select auth.uid())::text
      or ca.portal_auth_user_id::text = (select auth.uid())::text
    )
    and (
      nullif(account_id, '') is null
      or ca.id::text = nullif(account_id, '')
    )
  );
$$;

create or replace function private.client_can_access_account(account_id text)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select nullif(account_id, '') is not null
    and (
      exists (
        select 1
        from public.client_accounts ca
        where ca.id::text = nullif(account_id, '')
          and (
            ca."portalAuthUserId"::text = (select auth.uid())::text
            or ca.portal_auth_user_id::text = (select auth.uid())::text
            or lower(ca."ownerEmail") = private.jwt_email()
            or lower(coalesce(ca.owner_email, '')) = private.jwt_email()
          )
      )
      or exists (
        select 1
        from public.users u
        where u.id::text = (select auth.uid())::text
          and (
            u."clientAccountId"::text = nullif(account_id, '')
            or u.client_account_id::text = nullif(account_id, '')
          )
      )
    );
$$;

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
        and private.client_can_access_account(coalesce(p."clientAccountId"::text, p.client_account_id::text))
    );
$$;

create or replace function private.can_insert_own_user(
  profile_id text,
  profile_email text,
  profile_role text,
  profile_permissions text[],
  profile_client_account_id text default null
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select (select auth.uid()) is not null
    and profile_id::text = (select auth.uid())::text
    and lower(coalesce(profile_email, '')) = private.jwt_email()
    and coalesce(cardinality(profile_permissions), 0) = 0
    and profile_role in ('employee', 'client')
    and (
      (profile_role = 'employee' and private.employee_record_exists(profile_email))
      or (
        profile_role = 'client'
        and private.client_account_exists_for_user(profile_email, profile_client_account_id)
      )
    );
$$;

create or replace function private.can_update_own_user(
  profile_id text,
  profile_email text,
  profile_role text,
  profile_client_account_id text default null
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select (select auth.uid()) is not null
    and profile_id::text = (select auth.uid())::text
    and lower(coalesce(profile_email, '')) = private.jwt_email()
    and (
      profile_role = 'employee'
      or (
        profile_role = 'client'
        and (
          nullif(profile_client_account_id, '') is null
          or private.client_can_access_account(profile_client_account_id)
        )
      )
    );
$$;

create or replace function private.enable_rls_for_public_tables()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  table_record record;
begin
  for table_record in
    select schemaname, tablename
    from pg_tables
    where schemaname = 'public'
  loop
    execute format(
      'alter table %I.%I enable row level security',
      table_record.schemaname,
      table_record.tablename
    );
  end loop;
end;
$$;

create or replace function private.guard_user_profile_privileged_fields()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  new_client_account_id text;
begin
  if auth.role() = 'service_role' or auth.uid() is null or private.can_manage_access() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    if new.role = 'admin' or coalesce(cardinality(new.permissions), 0) > 0 then
      raise exception 'Only administrators can create privileged user profiles.';
    end if;

    return new;
  end if;

  if tg_op = 'UPDATE' then
    new_client_account_id := coalesce(new."clientAccountId"::text, new.client_account_id::text);

    if new.id is distinct from old.id
      or new.email is distinct from old.email
      or new.role is distinct from old.role
      or new.permissions is distinct from old.permissions
      or new.status is distinct from old.status then
      raise exception 'Only administrators can update privileged user fields.';
    end if;

    if new."clientAccountId" is distinct from old."clientAccountId"
      or new.client_account_id is distinct from old.client_account_id
      or new."clientAccountName" is distinct from old."clientAccountName"
      or new.client_account_name is distinct from old.client_account_name then
      if not (
        new.role = 'client'
        and private.client_can_access_account(new_client_account_id)
      ) then
        raise exception 'Only administrators can change client account bindings.';
      end if;
    end if;
  end if;

  return new;
end;
$$;

create or replace function private.guard_client_account_self_update()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.role() = 'service_role' or auth.uid() is null or private.can_manage_access() then
    return new;
  end if;

  if tg_op = 'UPDATE' then
    if new.id is distinct from old.id
      or new.name is distinct from old.name
      or new."ownerEmail" is distinct from old."ownerEmail"
      or new.owner_email is distinct from old.owner_email
      or new."contactEmail" is distinct from old."contactEmail"
      or new.contact_email is distinct from old.contact_email
      or new."contactPhone" is distinct from old."contactPhone"
      or new.contact_phone is distinct from old.contact_phone
      or new.status is distinct from old.status
      or new.notes is distinct from old.notes
      or new.created_at is distinct from old.created_at then
      raise exception 'Only administrators can update client account details.';
    end if;

    if new."portalAuthUserId" is distinct from old."portalAuthUserId"
      and new."portalAuthUserId"::text is distinct from (select auth.uid())::text then
      raise exception 'Invalid portal user binding.';
    end if;

    if new.portal_auth_user_id is distinct from old.portal_auth_user_id
      and new.portal_auth_user_id::text is distinct from (select auth.uid())::text then
      raise exception 'Invalid portal user binding.';
    end if;

    if new."portalAccessStatus" is distinct from old."portalAccessStatus"
      and new."portalAccessStatus" <> 'active' then
      raise exception 'Invalid portal access status transition.';
    end if;

    if new.portal_access_status is distinct from old.portal_access_status
      and new.portal_access_status <> 'active' then
      raise exception 'Invalid portal access status transition.';
    end if;
  end if;

  return new;
end;
$$;

revoke all on function private.jwt_email() from public, anon;
revoke all on function private.current_user_role() from public, anon;
revoke all on function private.current_user_permissions() from public, anon;
revoke all on function private.is_admin() from public, anon;
revoke all on function private.is_internal_user() from public, anon;
revoke all on function private.has_permission(text) from public, anon;
revoke all on function private.can_manage_access() from public, anon;
revoke all on function private.can_manage_people() from public, anon;
revoke all on function private.can_manage_settings() from public, anon;
revoke all on function private.can_read_financial() from public, anon;
revoke all on function private.can_write_financial() from public, anon;
revoke all on function private.can_read_usage() from public, anon;
revoke all on function private.employee_record_exists(text) from public, anon;
revoke all on function private.client_account_exists_for_user(text, text) from public, anon;
revoke all on function private.client_can_access_account(text) from public, anon;
revoke all on function private.client_can_access_project(text) from public, anon;
revoke all on function private.can_insert_own_user(text, text, text, text[], text) from public, anon;
revoke all on function private.can_update_own_user(text, text, text, text) from public, anon;
revoke all on function private.enable_rls_for_public_tables() from public, anon, authenticated;

grant execute on function private.jwt_email() to authenticated;
grant execute on function private.current_user_role() to authenticated;
grant execute on function private.current_user_permissions() to authenticated;
grant execute on function private.is_admin() to authenticated;
grant execute on function private.is_internal_user() to authenticated;
grant execute on function private.has_permission(text) to authenticated;
grant execute on function private.can_manage_access() to authenticated;
grant execute on function private.can_manage_people() to authenticated;
grant execute on function private.can_manage_settings() to authenticated;
grant execute on function private.can_read_financial() to authenticated;
grant execute on function private.can_write_financial() to authenticated;
grant execute on function private.can_read_usage() to authenticated;
grant execute on function private.employee_record_exists(text) to authenticated;
grant execute on function private.client_account_exists_for_user(text, text) to authenticated;
grant execute on function private.client_can_access_account(text) to authenticated;
grant execute on function private.client_can_access_project(text) to authenticated;
grant execute on function private.can_insert_own_user(text, text, text, text[], text) to authenticated;
grant execute on function private.can_update_own_user(text, text, text, text) to authenticated;

select private.enable_rls_for_public_tables();

drop trigger if exists trg_users_guard_privileged_fields on public.users;
create trigger trg_users_guard_privileged_fields
before insert or update on public.users
for each row execute function private.guard_user_profile_privileged_fields();

drop trigger if exists trg_client_accounts_guard_self_update on public.client_accounts;
create trigger trg_client_accounts_guard_self_update
before update on public.client_accounts
for each row execute function private.guard_client_account_self_update();

drop policy if exists "Acesso Total" on public.client_accounts;

drop policy if exists users_access_manage_all on public.users;
drop policy if exists users_select_own on public.users;
drop policy if exists users_insert_own on public.users;
drop policy if exists users_update_own on public.users;

create policy users_access_manage_all
on public.users
for all
to authenticated
using (private.can_manage_access())
with check (private.can_manage_access());

create policy users_select_own
on public.users
for select
to authenticated
using (id::text = (select auth.uid())::text);

create policy users_insert_own
on public.users
for insert
to authenticated
with check (
  private.can_insert_own_user(
    id::text,
    email,
    role,
    permissions,
    coalesce("clientAccountId"::text, client_account_id::text)
  )
);

create policy users_update_own
on public.users
for update
to authenticated
using (id::text = (select auth.uid())::text)
with check (
  private.can_update_own_user(
    id::text,
    email,
    role,
    coalesce("clientAccountId"::text, client_account_id::text)
  )
);

drop policy if exists client_accounts_manage_all on public.client_accounts;
drop policy if exists client_accounts_select_own on public.client_accounts;
drop policy if exists client_accounts_update_own_portal on public.client_accounts;

create policy client_accounts_manage_all
on public.client_accounts
for all
to authenticated
using (private.can_manage_access())
with check (private.can_manage_access());

create policy client_accounts_select_own
on public.client_accounts
for select
to authenticated
using (private.client_can_access_account(id::text));

create policy client_accounts_update_own_portal
on public.client_accounts
for update
to authenticated
using (private.client_can_access_account(id::text))
with check (private.client_can_access_account(id::text));

drop policy if exists projects_select_by_role on public.projects;
drop policy if exists projects_insert_internal on public.projects;
drop policy if exists projects_update_internal on public.projects;
drop policy if exists projects_delete_internal on public.projects;

create policy projects_select_by_role
on public.projects
for select
to authenticated
using (
  private.is_internal_user()
  or private.client_can_access_account(coalesce("clientAccountId"::text, client_account_id::text))
);

create policy projects_insert_internal
on public.projects
for insert
to authenticated
with check (private.is_internal_user());

create policy projects_update_internal
on public.projects
for update
to authenticated
using (private.is_internal_user())
with check (private.is_internal_user());

create policy projects_delete_internal
on public.projects
for delete
to authenticated
using (private.is_internal_user());

drop policy if exists project_measurements_select_by_role on public.project_measurements;
drop policy if exists project_measurements_insert_internal on public.project_measurements;
drop policy if exists project_measurements_update_internal on public.project_measurements;
drop policy if exists project_measurements_delete_internal on public.project_measurements;

create policy project_measurements_select_by_role
on public.project_measurements
for select
to authenticated
using (
  private.is_internal_user()
  or private.client_can_access_project(coalesce("projectId"::text, project_id::text))
);

create policy project_measurements_insert_internal
on public.project_measurements
for insert
to authenticated
with check (private.is_internal_user());

create policy project_measurements_update_internal
on public.project_measurements
for update
to authenticated
using (private.is_internal_user())
with check (private.is_internal_user());

create policy project_measurements_delete_internal
on public.project_measurements
for delete
to authenticated
using (private.is_internal_user());

drop policy if exists budgets_select_by_role on public.budgets;
drop policy if exists budgets_insert_internal on public.budgets;
drop policy if exists budgets_update_internal on public.budgets;
drop policy if exists budgets_delete_internal on public.budgets;

create policy budgets_select_by_role
on public.budgets
for select
to authenticated
using (
  private.is_internal_user()
  or private.client_can_access_account(coalesce("clientAccountId"::text, client_account_id::text))
  or private.client_can_access_project("projectId"::text)
);

create policy budgets_insert_internal
on public.budgets
for insert
to authenticated
with check (private.is_internal_user());

create policy budgets_update_internal
on public.budgets
for update
to authenticated
using (private.is_internal_user())
with check (private.is_internal_user());

create policy budgets_delete_internal
on public.budgets
for delete
to authenticated
using (private.is_internal_user());

drop policy if exists system_settings_select_authenticated on public.system_settings;
drop policy if exists system_settings_manage on public.system_settings;

create policy system_settings_select_authenticated
on public.system_settings
for select
to authenticated
using (true);

create policy system_settings_manage
on public.system_settings
for all
to authenticated
using (private.can_manage_settings())
with check (private.can_manage_settings());

drop policy if exists usage_stats_select_authorized on public.usage_stats;
drop policy if exists usage_stats_manage_authorized on public.usage_stats;

create policy usage_stats_select_authorized
on public.usage_stats
for select
to authenticated
using (private.can_read_usage());

create policy usage_stats_manage_authorized
on public.usage_stats
for all
to authenticated
using (private.can_read_usage())
with check (private.can_read_usage());

drop policy if exists financial_transactions_select_authorized on public.financial_transactions;
drop policy if exists financial_transactions_write_authorized on public.financial_transactions;

create policy financial_transactions_select_authorized
on public.financial_transactions
for select
to authenticated
using (private.can_read_financial());

create policy financial_transactions_write_authorized
on public.financial_transactions
for all
to authenticated
using (private.can_write_financial())
with check (private.can_write_financial());

drop policy if exists employees_select_authorized on public.employees;
drop policy if exists employees_write_authorized on public.employees;

create policy employees_select_authorized
on public.employees
for select
to authenticated
using (
  private.can_manage_people()
  or lower(email) = private.jwt_email()
);

create policy employees_write_authorized
on public.employees
for all
to authenticated
using (private.can_manage_people())
with check (private.can_manage_people());

do $$
declare
  table_name text;
  policy_name text;
begin
  foreach table_name in array array[
    'sectors',
    'benefit_categories',
    'benefits',
    'employee_benefits',
    'salary_history',
    'talent_candidates'
  ]
  loop
    if to_regclass(format('public.%I', table_name)) is not null then
      policy_name := table_name || '_people_manage_all';
      execute format('drop policy if exists %I on public.%I', policy_name, table_name);
      execute format(
        'create policy %I on public.%I for all to authenticated using (private.can_manage_people()) with check (private.can_manage_people())',
        policy_name,
        table_name
      );
    end if;
  end loop;
end $$;

do $$
declare
  table_name text;
  policy_name text;
begin
  foreach table_name in array array[
    'budget_types',
    'job_roles',
    'items',
    'suppliers',
    'purchases',
    'inventory',
    'inventory_movements',
    'vehicles',
    'vehicle_fuel_logs',
    'material_requisitions',
    'daily_logs',
    'teams'
  ]
  loop
    if to_regclass(format('public.%I', table_name)) is not null then
      policy_name := table_name || '_internal_crud';
      execute format('drop policy if exists %I on public.%I', policy_name, table_name);
      execute format(
        'create policy %I on public.%I for all to authenticated using (private.is_internal_user()) with check (private.is_internal_user())',
        policy_name,
        table_name
      );
    end if;
  end loop;
end $$;

drop policy if exists "Allow select for everyone" on storage.objects;
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
    private.is_internal_user()
    or private.client_can_access_project(split_part(name, '/', 1))
  )
);

create policy project_images_insert_internal
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'project-images'
  and private.is_internal_user()
);

create policy project_images_update_internal
on storage.objects
for update
to authenticated
using (
  bucket_id = 'project-images'
  and private.is_internal_user()
)
with check (
  bucket_id = 'project-images'
  and private.is_internal_user()
);

create policy project_images_delete_internal
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'project-images'
  and private.is_internal_user()
);
