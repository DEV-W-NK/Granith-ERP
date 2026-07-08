create table if not exists public.mobile_inventory_operations (
  id text primary key default gen_random_uuid()::text,
  "operationKind" text not null,
  "projectId" text references public.projects(id) on delete set null,
  "projectName" text not null default '',
  "itemName" text not null default '',
  quantity numeric(14,3) not null default 0,
  unit text not null default 'un',
  "fromLocation" text not null default '',
  "toLocation" text not null default '',
  notes text not null default '',
  "employeeId" text references public.employees(id) on delete set null,
  "employeeName" text not null default '',
  "userId" text not null default '',
  source text not null default 'mobile',
  status text not null default 'pending_review',
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint mobile_inventory_operations_kind_check check (
    "operationKind" in ('receipt', 'issue', 'transfer')
  )
);

create table if not exists public.mobile_vehicle_field_reports (
  id text primary key default gen_random_uuid()::text,
  "reportKind" text not null,
  "vehicleId" text references public.vehicles(id) on delete set null,
  "vehiclePlate" text not null default '',
  "vehicleLabel" text not null default '',
  "odometerKm" numeric(14,2) not null default 0,
  checklist jsonb not null default '{}'::jsonb,
  severity text not null default 'normal',
  description text not null default '',
  "employeeId" text references public.employees(id) on delete set null,
  "employeeName" text not null default '',
  "userId" text not null default '',
  source text not null default 'mobile',
  status text not null default 'pending_review',
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint mobile_vehicle_field_reports_kind_check check (
    "reportKind" in ('vehicleChecklist', 'vehicleMaintenance', 'vehicleOccurrence')
  ),
  constraint mobile_vehicle_field_reports_severity_check check (
    severity in ('normal', 'attention', 'critical')
  )
);

create table if not exists public.mobile_project_measurement_evidence (
  id text primary key default gen_random_uuid()::text,
  "projectId" text references public.projects(id) on delete set null,
  "projectName" text not null default '',
  "suggestedProgressPercent" numeric(7,3) not null default 0,
  "evidenceDescription" text not null default '',
  "photoDataUrl" text not null default '',
  "employeeId" text references public.employees(id) on delete set null,
  "employeeName" text not null default '',
  "userId" text not null default '',
  source text not null default 'mobile',
  status text not null default 'field_suggested',
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now()
);

create table if not exists public.mobile_project_documents (
  id text primary key default gen_random_uuid()::text,
  "projectId" text references public.projects(id) on delete cascade,
  "projectName" text not null default '',
  title text not null default '',
  content text not null default '',
  "isActive" boolean not null default true,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now()
);

create index if not exists idx_mobile_inventory_operations_project
  on public.mobile_inventory_operations ("projectId", "createdAt" desc);
create index if not exists idx_mobile_vehicle_reports_vehicle
  on public.mobile_vehicle_field_reports ("vehicleId", "createdAt" desc);
create index if not exists idx_mobile_measurement_evidence_project
  on public.mobile_project_measurement_evidence ("projectId", "createdAt" desc);
create index if not exists idx_mobile_project_documents_project
  on public.mobile_project_documents ("projectId", "updatedAt" desc);

alter table public.mobile_inventory_operations enable row level security;
alter table public.mobile_vehicle_field_reports enable row level security;
alter table public.mobile_project_measurement_evidence enable row level security;
alter table public.mobile_project_documents enable row level security;

drop policy if exists mobile_inventory_operations_internal_crud on public.mobile_inventory_operations;
create policy mobile_inventory_operations_internal_crud
on public.mobile_inventory_operations
for all
to authenticated
using (private.is_internal_user())
with check (private.is_internal_user());

drop policy if exists mobile_vehicle_field_reports_internal_crud on public.mobile_vehicle_field_reports;
create policy mobile_vehicle_field_reports_internal_crud
on public.mobile_vehicle_field_reports
for all
to authenticated
using (private.is_internal_user())
with check (private.is_internal_user());

drop policy if exists mobile_project_measurement_evidence_internal_crud on public.mobile_project_measurement_evidence;
create policy mobile_project_measurement_evidence_internal_crud
on public.mobile_project_measurement_evidence
for all
to authenticated
using (private.is_internal_user())
with check (private.is_internal_user());

drop policy if exists mobile_project_documents_internal_select on public.mobile_project_documents;
create policy mobile_project_documents_internal_select
on public.mobile_project_documents
for select
to authenticated
using (private.is_internal_user() and "isActive" = true);

drop policy if exists mobile_project_documents_internal_manage on public.mobile_project_documents;
create policy mobile_project_documents_internal_manage
on public.mobile_project_documents
for all
to authenticated
using (private.is_internal_user())
with check (private.is_internal_user());

grant select, insert, update on public.mobile_inventory_operations to authenticated;
grant select, insert, update on public.mobile_vehicle_field_reports to authenticated;
grant select, insert, update on public.mobile_project_measurement_evidence to authenticated;
grant select, insert, update on public.mobile_project_documents to authenticated;
