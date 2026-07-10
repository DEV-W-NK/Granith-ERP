alter table public.mobile_inventory_operations
  add column if not exists "itemId" text references public.items(id) on delete set null,
  add column if not exists "inventoryId" text references public.inventory(id) on delete set null,
  add column if not exists "newItemRequested" boolean not null default false,
  add column if not exists "availableQuantity" numeric(14,3);

create index if not exists idx_mobile_inventory_operations_item
  on public.mobile_inventory_operations ("itemId", "createdAt" desc);

create index if not exists idx_mobile_inventory_operations_inventory
  on public.mobile_inventory_operations ("inventoryId", "createdAt" desc);

grant select on public.items to authenticated;
grant select on public.inventory to authenticated;
