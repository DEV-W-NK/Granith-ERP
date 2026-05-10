alter table public.purchases
  add column if not exists "fulfillmentType" text not null default 'delivery',
  add column if not exists "pickupAddress" text not null default '',
  add column if not exists "routeId" text;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'purchases_fulfillment_type_check'
  ) then
    alter table public.purchases
      add constraint purchases_fulfillment_type_check
      check ("fulfillmentType" in ('delivery', 'pickup'));
  end if;
end $$;

create table if not exists public.purchase_delivery_routes (
  id text primary key default gen_random_uuid()::text,
  name text not null default '',
  "driverId" text,
  "driverName" text not null default '',
  status text not null default 'planned',
  "scheduledDate" timestamptz,
  "startedAt" timestamptz,
  "completedAt" timestamptz,
  "estimatedDistanceKm" numeric(10,2) not null default 0,
  "actualDistanceKm" numeric(10,2) not null default 0,
  "kmRate" numeric(10,2) not null default 0,
  "bonusValue" numeric(12,2) not null default 0,
  notes text not null default '',
  "createdBy" text,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint purchase_delivery_routes_status_check check (
    status in ('planned', 'inProgress', 'completed', 'cancelled')
  )
);

create table if not exists public.purchase_delivery_route_stops (
  id text primary key default gen_random_uuid()::text,
  "routeId" text not null references public.purchase_delivery_routes(id) on delete cascade,
  "purchaseId" text not null references public.purchases(id) on delete cascade,
  "stopType" text not null,
  sequence integer not null default 0,
  address text not null default '',
  "supplierName" text not null default '',
  "projectName" text not null default '',
  status text not null default 'pending',
  notes text not null default '',
  "completedAt" timestamptz,
  "createdAt" timestamptz not null default now(),
  constraint purchase_delivery_route_stops_type_check check (
    "stopType" in ('pickup', 'delivery')
  ),
  constraint purchase_delivery_route_stops_status_check check (
    status in ('pending', 'completed', 'skipped')
  )
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'purchases_route_id_fkey'
  ) then
    alter table public.purchases
      add constraint purchases_route_id_fkey
      foreign key ("routeId")
      references public.purchase_delivery_routes(id)
      on delete set null;
  end if;
end $$;

create table if not exists public.material_requisition_supplier_quotes (
  id text primary key default gen_random_uuid()::text,
  "requisitionId" text not null references public.material_requisitions(id) on delete cascade,
  "supplierId" text references public.suppliers(id) on delete set null,
  "supplierName" text not null default '',
  "contactName" text not null default '',
  "totalValue" numeric(14,2) not null default 0,
  "freightValue" numeric(14,2) not null default 0,
  "deliveryDays" integer not null default 0,
  "paymentTerms" text not null default '',
  "validUntil" timestamptz,
  "quoteItems" jsonb not null default '[]'::jsonb,
  notes text not null default '',
  status text not null default 'received',
  "isSelected" boolean not null default false,
  "quotedAt" timestamptz not null default now(),
  "createdBy" text,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint material_requisition_supplier_quotes_status_check check (
    status in ('draft', 'sent', 'received', 'selected', 'rejected')
  )
);

create index if not exists idx_purchases_fulfillment_type
  on public.purchases ("fulfillmentType");
create index if not exists idx_purchases_route_id
  on public.purchases ("routeId");
create index if not exists idx_purchase_delivery_routes_status
  on public.purchase_delivery_routes (status);
create index if not exists idx_purchase_delivery_routes_scheduled_date
  on public.purchase_delivery_routes ("scheduledDate" desc);
create index if not exists idx_purchase_delivery_route_stops_route_id
  on public.purchase_delivery_route_stops ("routeId", sequence);
create index if not exists idx_purchase_delivery_route_stops_purchase_id
  on public.purchase_delivery_route_stops ("purchaseId");
create index if not exists idx_material_requisition_quotes_requisition_id
  on public.material_requisition_supplier_quotes ("requisitionId");
create index if not exists idx_material_requisition_quotes_supplier_id
  on public.material_requisition_supplier_quotes ("supplierId");
create index if not exists idx_material_requisition_quotes_selected
  on public.material_requisition_supplier_quotes ("requisitionId", "isSelected");

do $$
declare
  table_name text;
  policy_name text;
begin
  foreach table_name in array array[
    'purchase_delivery_routes',
    'purchase_delivery_route_stops',
    'material_requisition_supplier_quotes'
  ]
  loop
    execute format('alter table public.%I enable row level security', table_name);
    policy_name := table_name || '_internal_crud';
    execute format('drop policy if exists %I on public.%I', policy_name, table_name);
    execute format(
      'create policy %I on public.%I for all to authenticated using (private.is_internal_user()) with check (private.is_internal_user())',
      policy_name,
      table_name
    );
  end loop;
end $$;

drop trigger if exists trg_purchase_delivery_routes_updated_at on public.purchase_delivery_routes;
create trigger trg_purchase_delivery_routes_updated_at
before update on public.purchase_delivery_routes
for each row execute function public.set_updated_at();

drop trigger if exists trg_material_requisition_supplier_quotes_updated_at
on public.material_requisition_supplier_quotes;
create trigger trg_material_requisition_supplier_quotes_updated_at
before update on public.material_requisition_supplier_quotes
for each row execute function public.set_updated_at();
