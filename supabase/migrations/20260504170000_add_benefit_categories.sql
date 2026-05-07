create table if not exists public.benefit_categories (
  id text primary key default gen_random_uuid()::text,
  name text not null unique,
  description text not null default '',
  "isActive" boolean not null default true,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now()
);

alter table public.benefits
  add column if not exists "categoryId" text references public.benefit_categories(id) on delete set null,
  add column if not exists "categoryName" text not null default '';

create index if not exists idx_benefits_category_id
  on public.benefits ("categoryId");

grant select, insert, update, delete on public.benefit_categories to authenticated;

alter table public.benefit_categories enable row level security;

drop policy if exists benefit_categories_people_manage_all on public.benefit_categories;
create policy benefit_categories_people_manage_all
on public.benefit_categories
for all
to authenticated
using (private.can_manage_people())
with check (private.can_manage_people());

drop policy if exists benefit_categories_select_internal on public.benefit_categories;
create policy benefit_categories_select_internal
on public.benefit_categories
for select
to authenticated
using (private.is_internal_user());
