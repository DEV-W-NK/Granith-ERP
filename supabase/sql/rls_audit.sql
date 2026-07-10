-- Auditoria RLS do Granith ERP.
-- Execute no SQL Editor do Supabase. Este arquivo nao altera dados.

with table_status as (
  select
    n.nspname as schema_name,
    c.relname as table_name,
    c.relrowsecurity as rls_enabled,
    c.relforcerowsecurity as force_rls,
    count(p.policyname) filter (where p.policyname is not null) as policy_count
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  left join pg_policies p
    on p.schemaname = n.nspname
   and p.tablename = c.relname
  where n.nspname = 'public'
    and c.relkind = 'r'
  group by n.nspname, c.relname, c.relrowsecurity, c.relforcerowsecurity
)
select *
from table_status
order by
  case when rls_enabled then 1 else 0 end,
  policy_count,
  table_name;

with critical_tables(table_name) as (
  values
    ('employees'),
    ('user_profiles'),
    ('projects'),
    ('project_team_members'),
    ('employee_benefits'),
    ('vehicle_fleet'),
    ('purchase_delivery_routes'),
    ('purchase_delivery_route_stops'),
    ('purchase_delivery_route_tracking_points'),
    ('time_clock_afd_events'),
    ('mobile_device_tokens'),
    ('mobile_push_notifications'),
    ('mobile_work_hour_entries'),
    ('mobile_geofence_events'),
    ('mobile_geofence_service_events')
)
select
  ct.table_name,
  coalesce(c.relrowsecurity, false) as rls_enabled,
  coalesce(c.relforcerowsecurity, false) as force_rls,
  count(p.policyname) filter (where p.policyname is not null) as policy_count,
  string_agg(distinct p.policyname, ', ' order by p.policyname) as policies
from critical_tables ct
left join pg_class c
  on c.relname = ct.table_name
left join pg_namespace n
  on n.oid = c.relnamespace
 and n.nspname = 'public'
left join pg_policies p
  on p.schemaname = 'public'
 and p.tablename = ct.table_name
group by ct.table_name, c.relrowsecurity, c.relforcerowsecurity
order by ct.table_name;

select
  table_schema,
  table_name,
  grantee,
  privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and grantee in ('anon', 'authenticated')
order by table_name, grantee, privilege_type;

select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_userbyid(p.proowner) as owner_name,
  case
    when p.prosecdef then 'SECURITY DEFINER'
    else 'SECURITY INVOKER'
  end as security_mode,
  coalesce(array_to_string(p.proconfig, ', '), '') as config
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname in ('public', 'private')
order by security_mode desc, schema_name, function_name;
