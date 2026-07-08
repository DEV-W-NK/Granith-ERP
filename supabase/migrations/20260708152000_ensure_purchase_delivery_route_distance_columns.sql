-- Repairs older databases where purchase_delivery_routes already existed before
-- the logistics migration and CREATE TABLE IF NOT EXISTS skipped new columns.

do $$
begin
  if to_regclass('public.purchase_delivery_routes') is null then
    return;
  end if;

  alter table public.purchase_delivery_routes
    add column if not exists "estimatedDistanceKm" numeric(10,2) not null default 0,
    add column if not exists "actualDistanceKm" numeric(10,2) not null default 0,
    add column if not exists "kmRate" numeric(10,2) not null default 0,
    add column if not exists "bonusValue" numeric(12,2) not null default 0;

  update public.purchase_delivery_routes
  set
    "estimatedDistanceKm" = coalesce("estimatedDistanceKm", 0),
    "actualDistanceKm" = coalesce("actualDistanceKm", 0),
    "kmRate" = coalesce("kmRate", 0),
    "bonusValue" = coalesce("bonusValue", 0);

  alter table public.purchase_delivery_routes
    alter column "estimatedDistanceKm" set default 0,
    alter column "estimatedDistanceKm" set not null,
    alter column "actualDistanceKm" set default 0,
    alter column "actualDistanceKm" set not null,
    alter column "kmRate" set default 0,
    alter column "kmRate" set not null,
    alter column "bonusValue" set default 0,
    alter column "bonusValue" set not null;

  grant select, insert, update, delete
    on public.purchase_delivery_routes
    to authenticated;
end $$;

notify pgrst, 'reload schema';
