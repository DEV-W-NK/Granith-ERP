-- Granith Mobile role hierarchy and self-service access.
-- Levels: colaborador/funcionario < supervisao < coordenacao < gerencia.

alter table if exists public.employees
  drop constraint if exists employees_role_check;

alter table if exists public.employees
  add constraint employees_role_check check (
    role in ('funcionario', 'supervisor', 'coordenador', 'gerente')
  );

create or replace function private.current_employee_id()
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select e.id::text
  from public.employees e
  where lower(e.email) = private.jwt_email()
  limit 1;
$$;

create or replace function private.current_employee_role_rank()
returns integer
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
    when private.current_user_role() = 'admin' then 5
    else coalesce((
      select case e.role
        when 'gerente' then 4
        when 'coordenador' then 3
        when 'supervisor' then 2
        when 'funcionario' then 1
        else 0
      end
      from public.employees e
      where lower(e.email) = private.jwt_email()
      limit 1
    ), 0)
  end;
$$;

create or replace function private.has_min_employee_role(required_rank integer)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.current_employee_role_rank() >= required_rank;
$$;

create or replace function private.can_manage_mobile_hierarchy()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.is_admin()
    or private.has_min_employee_role(3);
$$;

create or replace function private.can_request_mobile_materials()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.has_min_employee_role(2);
$$;

create or replace function private.can_submit_mobile_daily_logs()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.has_min_employee_role(2);
$$;

create or replace function private.can_manage_mobile_teams()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select private.has_min_employee_role(2);
$$;

create or replace function private.team_has_current_employee(
  member_ids text[],
  leader_id text
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select current_employee.employee_id is not null
    and (
      current_employee.employee_id = coalesce(leader_id, '')
      or current_employee.employee_id = any(coalesce(member_ids, '{}'::text[]))
    )
  from (select private.current_employee_id() as employee_id) current_employee;
$$;

create or replace function private.employee_shares_team_with_current(
  target_employee_id text
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.teams t,
      (select private.current_employee_id() as employee_id) current_employee
    where current_employee.employee_id is not null
      and (
        current_employee.employee_id = coalesce(t."leaderId", '')
        or current_employee.employee_id = any(coalesce(t."memberIds", '{}'::text[]))
      )
      and (
        target_employee_id = coalesce(t."leaderId", '')
        or target_employee_id = any(coalesce(t."memberIds", '{}'::text[]))
      )
  );
$$;

grant execute on function private.current_employee_id() to authenticated;
grant execute on function private.current_employee_role_rank() to authenticated;
grant execute on function private.has_min_employee_role(integer) to authenticated;
grant execute on function private.can_manage_mobile_hierarchy() to authenticated;
grant execute on function private.can_request_mobile_materials() to authenticated;
grant execute on function private.can_submit_mobile_daily_logs() to authenticated;
grant execute on function private.can_manage_mobile_teams() to authenticated;
grant execute on function private.team_has_current_employee(text[], text) to authenticated;
grant execute on function private.employee_shares_team_with_current(text) to authenticated;

drop policy if exists employees_select_authorized on public.employees;

create policy employees_select_authorized
on public.employees
for select
to authenticated
using (
  private.can_manage_people()
  or lower(email) = private.jwt_email()
  or (
    private.has_min_employee_role(2)
    and private.employee_shares_team_with_current(id::text)
  )
);

drop policy if exists benefits_select_mobile_authenticated on public.benefits;
create policy benefits_select_mobile_authenticated
on public.benefits
for select
to authenticated
using (private.is_internal_user());

do $$
begin
  if to_regclass('public.benefit_categories') is not null then
    execute 'drop policy if exists benefit_categories_select_mobile_authenticated on public.benefit_categories';
    execute 'create policy benefit_categories_select_mobile_authenticated on public.benefit_categories for select to authenticated using (private.is_internal_user())';
  end if;
end $$;

drop policy if exists employee_benefits_select_self on public.employee_benefits;
create policy employee_benefits_select_self
on public.employee_benefits
for select
to authenticated
using (
  private.can_manage_people()
  or "employeeId" = private.current_employee_id()
);

drop policy if exists salary_history_select_self on public.salary_history;
create policy salary_history_select_self
on public.salary_history
for select
to authenticated
using (
  private.can_manage_people()
  or "employeeId" = private.current_employee_id()
);

drop policy if exists teams_internal_crud on public.teams;
drop policy if exists teams_select_mobile_team on public.teams;
drop policy if exists teams_insert_supervisor_up on public.teams;
drop policy if exists teams_update_supervisor_up on public.teams;
drop policy if exists teams_delete_people_manage on public.teams;

create policy teams_select_mobile_team
on public.teams
for select
to authenticated
using (
  private.can_manage_people()
  or private.team_has_current_employee("memberIds", "leaderId")
);

create policy teams_insert_supervisor_up
on public.teams
for insert
to authenticated
with check (
  private.can_manage_people()
  or (
    private.can_manage_mobile_teams()
    and private.team_has_current_employee("memberIds", "leaderId")
  )
);

create policy teams_update_supervisor_up
on public.teams
for update
to authenticated
using (
  private.can_manage_people()
  or (
    private.can_manage_mobile_teams()
    and private.team_has_current_employee("memberIds", "leaderId")
  )
)
with check (
  private.can_manage_people()
  or (
    private.can_manage_mobile_teams()
    and private.team_has_current_employee("memberIds", "leaderId")
  )
);

create policy teams_delete_people_manage
on public.teams
for delete
to authenticated
using (private.can_manage_people());

drop policy if exists material_requisitions_internal_crud on public.material_requisitions;
drop policy if exists material_requisitions_select_internal on public.material_requisitions;
drop policy if exists material_requisitions_insert_supervisor_up on public.material_requisitions;
drop policy if exists material_requisitions_update_supervisor_up on public.material_requisitions;
drop policy if exists material_requisitions_delete_people_manage on public.material_requisitions;

create policy material_requisitions_select_internal
on public.material_requisitions
for select
to authenticated
using (private.is_internal_user());

create policy material_requisitions_insert_supervisor_up
on public.material_requisitions
for insert
to authenticated
with check (
  private.can_manage_people()
  or (
    private.can_request_mobile_materials()
    and "requesterId" in (
      private.current_employee_id(),
      (select auth.uid())::text
    )
  )
);

create policy material_requisitions_update_supervisor_up
on public.material_requisitions
for update
to authenticated
using (
  private.can_manage_people()
  or private.can_request_mobile_materials()
)
with check (
  private.can_manage_people()
  or private.can_request_mobile_materials()
);

create policy material_requisitions_delete_people_manage
on public.material_requisitions
for delete
to authenticated
using (private.can_manage_people());

drop policy if exists daily_logs_internal_crud on public.daily_logs;
drop policy if exists daily_logs_select_internal on public.daily_logs;
drop policy if exists daily_logs_insert_supervisor_up on public.daily_logs;
drop policy if exists daily_logs_update_supervisor_up on public.daily_logs;
drop policy if exists daily_logs_delete_people_manage on public.daily_logs;

create policy daily_logs_select_internal
on public.daily_logs
for select
to authenticated
using (private.is_internal_user());

create policy daily_logs_insert_supervisor_up
on public.daily_logs
for insert
to authenticated
with check (
  private.can_manage_people()
  or (
    private.can_submit_mobile_daily_logs()
    and "createdByUserId" in (
      private.current_employee_id(),
      (select auth.uid())::text
    )
  )
);

create policy daily_logs_update_supervisor_up
on public.daily_logs
for update
to authenticated
using (
  private.can_manage_people()
  or (
    private.can_submit_mobile_daily_logs()
    and "createdByUserId" in (
      private.current_employee_id(),
      (select auth.uid())::text
    )
  )
)
with check (
  private.can_manage_people()
  or (
    private.can_submit_mobile_daily_logs()
    and "createdByUserId" in (
      private.current_employee_id(),
      (select auth.uid())::text
    )
  )
);

create policy daily_logs_delete_people_manage
on public.daily_logs
for delete
to authenticated
using (private.can_manage_people());
