alter table public.client_accounts
  add column if not exists "portalAccessStatus" text not null default 'pending';

alter table public.client_accounts
  add column if not exists portal_access_status text;

alter table public.client_accounts
  add column if not exists "portalAuthUserId" text;

alter table public.client_accounts
  add column if not exists portal_auth_user_id text;

alter table public.client_accounts
  add column if not exists "portalInvitedAt" timestamptz;

alter table public.client_accounts
  add column if not exists portal_invited_at timestamptz;

alter table public.client_accounts
  add column if not exists "portalLastAccessAt" timestamptz;

alter table public.client_accounts
  add column if not exists portal_last_access_at timestamptz;

update public.client_accounts
set
  portal_access_status = coalesce(portal_access_status, "portalAccessStatus"),
  "portalAccessStatus" = coalesce("portalAccessStatus", portal_access_status, 'pending')
where portal_access_status is null
   or "portalAccessStatus" is null;
