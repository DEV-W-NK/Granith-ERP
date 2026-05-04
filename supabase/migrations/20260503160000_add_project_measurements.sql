alter table public.projects
  add column if not exists "estimatedProgress" numeric(7,3) not null default 0;
alter table public.projects
  add column if not exists estimated_progress numeric(7,3);
alter table public.projects
  add column if not exists "measuredAmount" numeric(14,2) not null default 0;
alter table public.projects
  add column if not exists measured_amount numeric(14,2);
alter table public.projects
  add column if not exists "measurementCount" integer not null default 0;
alter table public.projects
  add column if not exists measurement_count integer;
alter table public.projects
  add column if not exists "lastMeasurementAt" timestamptz;
alter table public.projects
  add column if not exists last_measurement_at timestamptz;

create table if not exists public.project_measurements (
  id text primary key default gen_random_uuid()::text,
  "projectId" text not null references public.projects(id) on delete cascade,
  project_id text,
  "projectName" text not null default '',
  project_name text,
  "projectClient" text not null default '',
  project_client text,
  title text not null default '',
  sequence integer not null default 1,
  status text not null default 'pending',
  "measurementDate" timestamptz not null default now(),
  measurement_date timestamptz,
  "grossAmount" numeric(14,2) not null default 0,
  gross_amount numeric(14,2),
  "discountAmount" numeric(14,2) not null default 0,
  discount_amount numeric(14,2),
  "netAmount" numeric(14,2) not null default 0,
  net_amount numeric(14,2),
  "accumulatedGrossAmount" numeric(14,2) not null default 0,
  accumulated_gross_amount numeric(14,2),
  "measurementPercentage" numeric(7,3) not null default 0,
  measurement_percentage numeric(7,3),
  "accumulatedPercentage" numeric(7,3) not null default 0,
  accumulated_percentage numeric(7,3),
  "contractBalance" numeric(14,2) not null default 0,
  contract_balance numeric(14,2),
  notes text not null default '',
  "createdBy" text,
  created_by text,
  "createdAt" timestamptz not null default now(),
  created_at timestamptz default now(),
  "updatedAt" timestamptz not null default now(),
  updated_at timestamptz default now(),
  constraint project_measurements_status_check check (
    status in ('pending', 'approved', 'paid')
  ),
  constraint project_measurements_nonnegative_gross check ("grossAmount" >= 0),
  constraint project_measurements_nonnegative_discount check ("discountAmount" >= 0)
);

alter table public.project_measurements
  add column if not exists "createdBy" text;
alter table public.project_measurements
  add column if not exists created_by text;

create index if not exists idx_project_measurements_project_id
  on public.project_measurements ("projectId");
create index if not exists idx_project_measurements_sequence
  on public.project_measurements ("projectId", sequence);
create index if not exists idx_project_measurements_measurement_date
  on public.project_measurements ("measurementDate" desc);

drop trigger if exists trg_project_measurements_updated_at on public.project_measurements;
create trigger trg_project_measurements_updated_at
before update on public.project_measurements
for each row execute function public.set_updated_at();
