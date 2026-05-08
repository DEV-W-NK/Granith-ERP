-- Let benign profile upserts reach the UPDATE guard when the row already exists.
-- PostgreSQL fires BEFORE INSERT triggers before ON CONFLICT DO UPDATE, so
-- existing non-admin profiles with permissions were being blocked during login.

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
