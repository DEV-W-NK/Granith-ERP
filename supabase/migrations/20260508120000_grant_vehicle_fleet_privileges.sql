-- Vehicle fleet tables are created after the security baseline migration.
-- The baseline revokes default table privileges, so new tables need grants.

grant select, insert, update, delete on public.vehicles to authenticated;
grant select, insert, update, delete on public.vehicle_fuel_logs to authenticated;
