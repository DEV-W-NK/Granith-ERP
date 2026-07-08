alter table public.users
  add column if not exists "employeeId" text,
  add column if not exists employee_id text,
  add column if not exists "employeeName" text,
  add column if not exists employee_name text;

update public.users
set
  employee_id = coalesce(employee_id, "employeeId"),
  "employeeId" = coalesce("employeeId", employee_id),
  employee_name = coalesce(employee_name, "employeeName"),
  "employeeName" = coalesce("employeeName", employee_name)
where employee_id is null
   or "employeeId" is null
   or employee_name is null
   or "employeeName" is null;

create index if not exists users_employee_id_idx
  on public.users (employee_id)
  where employee_id is not null and trim(employee_id) <> '';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'users_employee_id_fkey'
  ) then
    alter table public.users
      add constraint users_employee_id_fkey
      foreign key (employee_id)
      references public.employees(id)
      on delete set null;
  end if;
end $$;

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
    if exists (
      select 1
      from public.users existing_user
      where existing_user.id::text = new.id::text
    ) then
      return new;
    end if;

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
      or new.employee_name is distinct from old.employee_name then
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
