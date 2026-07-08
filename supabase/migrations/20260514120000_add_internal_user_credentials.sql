alter table public.users
  add column if not exists username text,
  add column if not exists login_username text,
  add column if not exists "internalLoginEmail" text,
  add column if not exists internal_login_email text,
  add column if not exists "authProvider" text not null default 'email',
  add column if not exists auth_provider text;

update public.users
set
  auth_provider = coalesce(auth_provider, "authProvider", 'email'),
  "authProvider" = coalesce("authProvider", auth_provider, 'email')
where auth_provider is null
   or "authProvider" is null;

create unique index if not exists users_username_unique
  on public.users (lower(username))
  where username is not null and trim(username) <> '';

create unique index if not exists users_login_username_unique
  on public.users (lower(login_username))
  where login_username is not null and trim(login_username) <> '';

create unique index if not exists users_internal_login_email_unique
  on public.users (lower(internal_login_email))
  where internal_login_email is not null and trim(internal_login_email) <> '';

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
      or new.auth_provider is distinct from old.auth_provider then
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
