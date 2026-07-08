grant usage on schema public to authenticated;

grant select, insert, update, delete
  on public.purchase_delivery_routes
  to authenticated;

grant select, insert, update, delete
  on public.purchase_delivery_route_stops
  to authenticated;

grant select, insert, update, delete
  on public.material_requisition_supplier_quotes
  to authenticated;

alter table public.purchase_delivery_routes enable row level security;
alter table public.purchase_delivery_route_stops enable row level security;
alter table public.material_requisition_supplier_quotes enable row level security;

drop policy if exists purchase_delivery_routes_internal_crud
  on public.purchase_delivery_routes;
create policy purchase_delivery_routes_internal_crud
  on public.purchase_delivery_routes
  for all
  to authenticated
  using (private.is_internal_user())
  with check (private.is_internal_user());

drop policy if exists purchase_delivery_route_stops_internal_crud
  on public.purchase_delivery_route_stops;
create policy purchase_delivery_route_stops_internal_crud
  on public.purchase_delivery_route_stops
  for all
  to authenticated
  using (private.is_internal_user())
  with check (private.is_internal_user());

drop policy if exists material_requisition_supplier_quotes_internal_crud
  on public.material_requisition_supplier_quotes;
create policy material_requisition_supplier_quotes_internal_crud
  on public.material_requisition_supplier_quotes
  for all
  to authenticated
  using (private.is_internal_user())
  with check (private.is_internal_user());
