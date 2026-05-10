-- OAuth providers can create an auth.uid different from a seeded ERP user id.
-- Resolve the effective ERP profile by auth.uid or verified email, preserving
-- administrative profiles when a seeded ERP user signs in with Google.

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
     or lower(u.email) = private.jwt_email()
  order by
    case
      when u.role = 'admin' then 0
      when u.id::text = (select auth.uid())::text then 1
      else 2
    end
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
     or lower(u.email) = private.jwt_email()
  order by
    case
      when u.role = 'admin' then 0
      when u.id::text = (select auth.uid())::text then 1
      else 2
    end
  limit 1;
$$;

drop policy if exists users_select_own on public.users;
create policy users_select_own
on public.users
for select
to authenticated
using (
  id::text = (select auth.uid())::text
  or lower(email) = private.jwt_email()
);

drop policy if exists users_update_own_email on public.users;
create policy users_update_own_email
on public.users
for update
to authenticated
using (lower(email) = private.jwt_email())
with check (lower(email) = private.jwt_email());
