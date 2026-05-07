alter table public.projects
  add column if not exists "coordinatorId" text references public.employees(id) on delete set null;
alter table public.projects
  add column if not exists coordinator_id text;
alter table public.projects
  add column if not exists "coordinatorName" text;
alter table public.projects
  add column if not exists coordinator_name text;

create index if not exists idx_projects_coordinator_id
  on public.projects ("coordinatorId");

alter table public.daily_logs
  add column if not exists "coordinatorId" text references public.employees(id) on delete set null;
alter table public.daily_logs
  add column if not exists "coordinatorName" text;
alter table public.daily_logs
  add column if not exists "signatureRequestedAt" timestamptz;
alter table public.daily_logs
  add column if not exists "signedAt" timestamptz;
alter table public.daily_logs
  add column if not exists "signedByCoordinatorId" text references public.employees(id) on delete set null;
alter table public.daily_logs
  add column if not exists "signedByCoordinatorName" text;

alter table public.daily_logs
  drop constraint if exists daily_logs_status_check;

alter table public.daily_logs
  add constraint daily_logs_status_check check (
    status in (
      'draft',
      'finalized',
      'pendingSignature',
      'signed',
      'synced',
      'pendente'
    )
  );

create index if not exists idx_daily_logs_coordinator_id
  on public.daily_logs ("coordinatorId");

create index if not exists idx_daily_logs_status
  on public.daily_logs (status);
