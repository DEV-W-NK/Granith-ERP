create table if not exists public.vehicles (
  id text primary key default gen_random_uuid()::text,
  plate text not null unique,
  brand text not null default '',
  model text not null default '',
  version text not null default '',
  "manufactureYear" integer not null,
  "modelYear" integer not null,
  "fuelType" text not null default 'flex',
  status text not null default 'active',
  "odometerKm" numeric(14,2) not null default 0,
  "expectedCityKmPerLiter" numeric(8,2) not null default 0,
  "expectedHighwayKmPerLiter" numeric(8,2) not null default 0,
  "tankCapacityLiters" numeric(8,2) not null default 0,
  "assignedEmployeeId" text references public.employees(id) on delete set null,
  "assignedEmployeeName" text not null default '',
  "acquisitionDate" timestamptz,
  "acquisitionValue" numeric(14,2) not null default 0,
  "fipeCode" text,
  "fipeValue" numeric(14,2),
  "fipeReferenceMonth" text,
  "lastMeasuredKmPerLiter" numeric(8,2),
  "lastFuelLogAt" timestamptz,
  notes text not null default '',
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint vehicles_fuel_type_check check (
    "fuelType" in ('gasoline', 'ethanol', 'flex', 'diesel', 'hybrid', 'electric', 'other')
  ),
  constraint vehicles_status_check check (
    status in ('active', 'maintenance', 'inactive')
  ),
  constraint vehicles_years_check check (
    "manufactureYear" between 1970 and extract(year from now())::integer + 1
    and "modelYear" between 1970 and extract(year from now())::integer + 1
  )
);

create index if not exists idx_vehicles_status on public.vehicles (status);
create index if not exists idx_vehicles_model_year on public.vehicles ("modelYear" desc);
create index if not exists idx_vehicles_assigned_employee on public.vehicles ("assignedEmployeeId");

drop trigger if exists trg_vehicles_updated_at on public.vehicles;
create trigger trg_vehicles_updated_at
before update on public.vehicles
for each row execute function public.set_updated_at();

create table if not exists public.vehicle_fuel_logs (
  id text primary key default gen_random_uuid()::text,
  "vehicleId" text not null references public.vehicles(id) on delete cascade,
  "vehiclePlate" text not null default '',
  "employeeId" text not null default '',
  "employeeName" text not null default '',
  liters numeric(10,3) not null default 0,
  "totalAmount" numeric(14,2) not null default 0,
  "unitPrice" numeric(10,4) not null default 0,
  "odometerKm" numeric(14,2) not null default 0,
  "previousOdometerKm" numeric(14,2),
  "kmTraveled" numeric(14,2),
  "kmPerLiter" numeric(8,2),
  "fuelingDate" timestamptz not null default now(),
  "financialTransactionId" text references public.financial_transactions(id) on delete set null,
  "invoiceNumber" text not null default '',
  notes text not null default '',
  "createdAt" timestamptz not null default now()
);

create index if not exists idx_vehicle_fuel_logs_vehicle_id on public.vehicle_fuel_logs ("vehicleId");
create index if not exists idx_vehicle_fuel_logs_date on public.vehicle_fuel_logs ("fuelingDate" desc);
create index if not exists idx_vehicle_fuel_logs_financial_transaction on public.vehicle_fuel_logs ("financialTransactionId");

alter table public.vehicles enable row level security;
alter table public.vehicle_fuel_logs enable row level security;

drop policy if exists vehicles_internal_crud on public.vehicles;
create policy vehicles_internal_crud
on public.vehicles
for all
to authenticated
using (private.is_internal_user())
with check (private.is_internal_user());

drop policy if exists vehicle_fuel_logs_internal_crud on public.vehicle_fuel_logs;
create policy vehicle_fuel_logs_internal_crud
on public.vehicle_fuel_logs
for all
to authenticated
using (private.is_internal_user())
with check (private.is_internal_user());
