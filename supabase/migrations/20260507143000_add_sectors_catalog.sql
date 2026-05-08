create table if not exists public.sectors (
  id text primary key default gen_random_uuid()::text,
  name text not null unique,
  description text not null default '',
  "isActive" boolean not null default true,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now()
);

create index if not exists idx_sectors_active_name
  on public.sectors ("isActive", name);

drop trigger if exists trg_sectors_updated_at on public.sectors;
create trigger trg_sectors_updated_at
before update on public.sectors
for each row execute function public.set_updated_at();

grant select, insert, update, delete on public.sectors to authenticated;

alter table public.sectors enable row level security;

drop policy if exists sectors_people_manage_all on public.sectors;
create policy sectors_people_manage_all
on public.sectors
for all
to authenticated
using (private.can_manage_people() or private.is_internal_user())
with check (private.can_manage_people() or private.is_internal_user());

insert into public.sectors (name, description)
select distinct source.name, 'Migrado dos cadastros existentes.'
from (
  select nullif(trim(sector), '') as name from public.employees
  union
  select nullif(trim(sector), '') as name from public.job_roles
) source
where source.name is not null
on conflict (name) do nothing;
