-- Keep the deployed employees.role check aligned with the app enum.
alter table if exists public.employees
  drop constraint if exists employees_role_check;

update public.employees
set role = 'funcionario'
where role is null
  or role not in ('funcionario', 'supervisor', 'coordenador', 'gerente');

alter table if exists public.employees
  add constraint employees_role_check check (
    role in ('funcionario', 'supervisor', 'coordenador', 'gerente')
  );
