-- RLS/grants for route GPS tracking sent by Granith Mobile.
-- The mobile app persists tracking locally first, then syncs rows here.

grant usage on schema public to authenticated;

create or replace function private.can_manage_mobile_routes()
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select private.is_admin()
    or private.can_manage_people()
    or private.has_permission('purchases.consolidate')
    or private.has_permission('purchases.approve')
    or private.has_permission('compras')
    or private.has_permission('suprimentos')
    or private.has_permission('mobile.team.manage');
$$;

grant execute on function private.can_manage_mobile_routes() to authenticated;

alter table public.purchase_delivery_route_stops
  add column if not exists latitude double precision,
  add column if not exists longitude double precision;

create table if not exists public.purchase_delivery_route_tracking_points (
  id text primary key default gen_random_uuid()::text,
  "routeId" text not null references public.purchase_delivery_routes(id) on delete cascade,
  "stopId" text references public.purchase_delivery_route_stops(id) on delete set null,
  "employeeId" text,
  "employeeName" text not null default '',
  "userId" text,
  latitude double precision not null,
  longitude double precision not null,
  "accuracyMeters" numeric(10,2) not null default 0,
  "speedMetersPerSecond" numeric(10,2) not null default 0,
  "recordedAt" timestamptz not null,
  "distanceFromPreviousMeters" numeric(10,2) not null default 0,
  source text not null default 'mobile',
  "syncedAt" timestamptz not null default now(),
  "createdAt" timestamptz not null default now()
);

create index if not exists idx_purchase_delivery_tracking_route_recorded
  on public.purchase_delivery_route_tracking_points ("routeId", "recordedAt");

create index if not exists idx_purchase_delivery_tracking_employee
  on public.purchase_delivery_route_tracking_points ("employeeId", "recordedAt");

create index if not exists idx_purchase_delivery_tracking_user_recorded
  on public.purchase_delivery_route_tracking_points ("userId", "recordedAt");

grant select, insert, update, delete
  on public.purchase_delivery_route_tracking_points
  to authenticated;

alter table public.purchase_delivery_route_tracking_points
  enable row level security;

drop policy if exists purchase_delivery_route_tracking_points_internal_crud
  on public.purchase_delivery_route_tracking_points;
drop policy if exists purchase_delivery_route_tracking_points_select_assigned
  on public.purchase_delivery_route_tracking_points;
drop policy if exists purchase_delivery_route_tracking_points_insert_assigned
  on public.purchase_delivery_route_tracking_points;
drop policy if exists purchase_delivery_route_tracking_points_update_assigned
  on public.purchase_delivery_route_tracking_points;
drop policy if exists purchase_delivery_route_tracking_points_delete_managers
  on public.purchase_delivery_route_tracking_points;

create policy purchase_delivery_route_tracking_points_select_assigned
on public.purchase_delivery_route_tracking_points
for select
to authenticated
using (
  private.can_manage_mobile_routes()
  or "userId"::text = (select auth.uid())::text
  or "employeeId"::text in (
    coalesce(private.current_user_employee_id(), ''),
    coalesce(private.current_employee_id(), '')
  )
  or exists (
    select 1
    from public.purchase_delivery_routes route
    where route.id = "routeId"
      and route."driverId" in (
        coalesce(private.current_user_employee_id(), ''),
        coalesce(private.current_employee_id(), '')
      )
  )
);

create policy purchase_delivery_route_tracking_points_insert_assigned
on public.purchase_delivery_route_tracking_points
for insert
to authenticated
with check (
  private.can_manage_mobile_routes()
  or (
    "userId"::text = (select auth.uid())::text
    and (
      "employeeId" is null
      or "employeeId"::text in (
        coalesce(private.current_user_employee_id(), ''),
        coalesce(private.current_employee_id(), '')
      )
    )
    and exists (
      select 1
      from public.purchase_delivery_routes route
      where route.id = "routeId"
        and route."driverId" in (
          coalesce(private.current_user_employee_id(), ''),
          coalesce(private.current_employee_id(), '')
        )
    )
  )
);

create policy purchase_delivery_route_tracking_points_update_assigned
on public.purchase_delivery_route_tracking_points
for update
to authenticated
using (
  private.can_manage_mobile_routes()
  or (
    "userId"::text = (select auth.uid())::text
    and exists (
      select 1
      from public.purchase_delivery_routes route
      where route.id = "routeId"
        and route."driverId" in (
          coalesce(private.current_user_employee_id(), ''),
          coalesce(private.current_employee_id(), '')
        )
    )
  )
)
with check (
  private.can_manage_mobile_routes()
  or (
    "userId"::text = (select auth.uid())::text
    and (
      "employeeId" is null
      or "employeeId"::text in (
        coalesce(private.current_user_employee_id(), ''),
        coalesce(private.current_employee_id(), '')
      )
    )
    and exists (
      select 1
      from public.purchase_delivery_routes route
      where route.id = "routeId"
        and route."driverId" in (
          coalesce(private.current_user_employee_id(), ''),
          coalesce(private.current_employee_id(), '')
        )
    )
  )
);

create policy purchase_delivery_route_tracking_points_delete_managers
on public.purchase_delivery_route_tracking_points
for delete
to authenticated
using (private.can_manage_mobile_routes());
