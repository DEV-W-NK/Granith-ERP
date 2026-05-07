-- Clients should not read the raw projects table because RLS is row-level,
-- not column-level. Expose a sanitized view for the client portal and keep
-- direct projects reads for internal users only.

create or replace view public.client_portal_projects
with (security_barrier = true)
as
select
  p.id,
  p.name,
  p.client,
  p.description,
  p.status,
  p."startDate",
  p."endDate",
  p.location,
  p.tags,
  p."teamSize",
  p."imageUrl",
  p."clientAccountId",
  p.client_account_id,
  p."clientAccountName",
  p.client_account_name,
  p."estimatedProgress",
  p.estimated_progress,
  p."measurementCount",
  p.measurement_count,
  p."lastMeasurementAt",
  p.last_measurement_at
from public.projects p
where private.client_can_access_account(
  coalesce(p."clientAccountId"::text, p.client_account_id::text)
);

revoke all on public.client_portal_projects from public, anon;
grant select on public.client_portal_projects to authenticated;

drop policy if exists projects_select_by_role on public.projects;
drop policy if exists projects_select_internal on public.projects;

create policy projects_select_internal
on public.projects
for select
to authenticated
using (private.is_internal_user());
