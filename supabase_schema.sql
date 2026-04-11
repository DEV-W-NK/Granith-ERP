-- Granith ERP - schema base para Supabase
-- Compatível com os nomes de colunas usados hoje no app Flutter.
-- Observação: várias colunas estão em camelCase porque o código atual já
-- serializa dessa forma. Por isso elas precisam ser criadas entre aspas.

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new."updatedAt" = now();
  return new;
end;
$$;

create table if not exists public.users (
  id text primary key,
  email text not null unique,
  "displayName" text,
  "photoUrl" text,
  status text not null default 'ativo',
  permissions text[] not null default '{}',
  "lastLogin" timestamptz,
  display_name text,
  photo_url text,
  last_login timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.users add column if not exists role text not null default 'employee';
alter table public.users add column if not exists "clientAccountId" text;
alter table public.users add column if not exists client_account_id text;
alter table public.users add column if not exists "clientAccountName" text;
alter table public.users add column if not exists client_account_name text;

create table if not exists public.client_accounts (
  id text primary key default gen_random_uuid()::text,
  name text not null,
  "ownerEmail" text not null unique,
  owner_email text,
  "contactEmail" text not null default '',
  contact_email text,
  "contactPhone" text not null default '',
  contact_phone text,
  status text not null default 'ativo',
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_client_accounts_owner_email on public.client_accounts ("ownerEmail");

create table if not exists public.budget_types (
  id text primary key default gen_random_uuid()::text,
  name text not null unique,
  description text not null default '',
  category text not null default '',
  "isActive" boolean not null default true,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  "iconName" text,
  color text
);

create table if not exists public.job_roles (
  id text primary key default gen_random_uuid()::text,
  title text not null unique,
  sector text not null default '',
  description text not null default '',
  "hourlyRate" numeric(14,2) not null default 0,
  requirements text[] not null default '{}',
  "isActive" boolean not null default true,
  "createdAt" timestamptz not null default now()
);

create table if not exists public.items (
  id text primary key default gen_random_uuid()::text,
  name text not null unique,
  description text not null default '',
  unit text not null default 'un',
  weight numeric(14,3),
  width numeric(14,3),
  height numeric(14,3),
  length numeric(14,3),
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now()
);

create table if not exists public.projects (
  id text primary key default gen_random_uuid()::text,
  name text not null,
  client text not null,
  description text not null default '',
  status text not null default 'planning',
  "startDate" timestamptz not null default now(),
  "endDate" timestamptz,
  budget numeric(14,2) not null default 0,
  "currentCost" numeric(14,2) not null default 0,
  location text not null default '',
  tags text[] not null default '{}',
  "teamSize" integer not null default 0,
  "imageUrl" text,
  "projectKey" text,
  "contentHash" text,
  "sourceBudgetId" text,
  "creationTimestamp" timestamptz,
  "createdAt" timestamptz not null default now(),
  created_at timestamptz default now(),
  "createdBy" text,
  created_by text,
  "updatedAt" timestamptz not null default now(),
  updated_at timestamptz default now(),
  "updatedBy" text,
  updated_by text,
  "clientAccountId" text references public.client_accounts(id) on delete set null,
  client_account_id text,
  "clientAccountName" text,
  client_account_name text,
  constraint projects_status_check check (
    status in ('planning', 'inProgress', 'completed')
  ),
  constraint projects_nonnegative_budget check (budget >= 0),
  constraint projects_nonnegative_current_cost check ("currentCost" >= 0),
  constraint projects_nonnegative_team_size check ("teamSize" >= 0)
);

create unique index if not exists idx_projects_project_key
  on public.projects ("projectKey");
create index if not exists idx_projects_status on public.projects (status);
create index if not exists idx_projects_client on public.projects (client);
create index if not exists idx_projects_created_at on public.projects ("createdAt" desc);

create table if not exists public.budgets (
  id text primary key default gen_random_uuid()::text,
  "clientName" text not null,
  "projectName" text not null,
  "totalValue" numeric(14,2) not null default 0,
  "creationDate" bigint not null,
  "expirationDate" bigint,
  status integer not null default 0,
  description text not null default '',
  items jsonb not null default '[]'::jsonb,
  "projectId" text references public.projects(id) on delete set null,
  "budgetTypeId" text references public.budget_types(id) on delete set null,
  "clientAccountId" text references public.client_accounts(id) on delete set null,
  client_account_id text,
  "clientAccountName" text,
  client_account_name text,
  created_at timestamptz default now(),
  constraint budgets_status_check check (status between 0 and 3)
);

create index if not exists idx_budgets_status on public.budgets (status);
create index if not exists idx_budgets_project_id on public.budgets ("projectId");
create index if not exists idx_budgets_budget_type_id on public.budgets ("budgetTypeId");

create table if not exists public.employees (
  id text primary key default gen_random_uuid()::text,
  name text not null,
  email text not null unique,
  phone text not null default '',
  "photoUrl" text not null default '',
  "jobTitle" text not null default '',
  "jobRoleId" text references public.job_roles(id) on delete set null,
  sector text not null default 'Geral',
  role text not null default 'funcionario',
  status text not null default 'ativo',
  "admissionDate" timestamptz not null default now(),
  "dismissalDate" timestamptz,
  cpf text not null default '',
  ctps text not null default '',
  "baseSalary" numeric(14,2) not null default 0,
  "educationLevel" text not null default '',
  courses text not null default '',
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint employees_role_check check (
    role in ('funcionario', 'supervisor', 'coordenador')
  ),
  constraint employees_status_check check (
    status in ('ativo', 'ferias', 'afastado', 'desligado')
  )
);

create index if not exists idx_employees_job_role_id on public.employees ("jobRoleId");
create index if not exists idx_employees_status on public.employees (status);
create unique index if not exists idx_employees_cpf_unique
  on public.employees (cpf)
  where cpf <> '';

create table if not exists public.teams (
  id text primary key default gen_random_uuid()::text,
  name text not null unique,
  description text not null default '',
  "memberIds" text[] not null default '{}',
  "leaderId" text references public.employees(id) on delete set null,
  "projectId" text references public.projects(id) on delete set null,
  "isActive" boolean not null default true,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now()
);

create index if not exists idx_teams_project_id on public.teams ("projectId");
create index if not exists idx_teams_leader_id on public.teams ("leaderId");

create table if not exists public.suppliers (
  id text primary key default gen_random_uuid()::text,
  name text not null,
  cnpj text not null unique,
  "isActive" boolean not null default true,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now()
);

create index if not exists idx_suppliers_name on public.suppliers (name);

create table if not exists public.purchases (
  id text primary key default gen_random_uuid()::text,
  "itemId" text,
  "itemName" text not null,
  "supplierId" text references public.suppliers(id) on delete set null,
  "supplierName" text not null default '',
  "projectId" text references public.projects(id) on delete set null,
  "projectName" text not null default '',
  "requisitionId" text,
  "financialTransactionId" text,
  "deliveryAddress" text not null default '',
  quantity numeric(14,3) not null default 1,
  "totalValue" numeric(14,2) not null default 0,
  status integer not null default 1,
  "purchaseDate" timestamptz not null default now(),
  "deliveryDate" timestamptz,
  "receivedBy" text,
  "approvedBy" text,
  "approvedByName" text,
  "approvedAt" timestamptz,
  "rejectionReason" text,
  constraint purchases_status_check check (status between 0 and 4)
);

create index if not exists idx_purchases_project_id on public.purchases ("projectId");
create index if not exists idx_purchases_supplier_id on public.purchases ("supplierId");
create index if not exists idx_purchases_status on public.purchases (status);
create index if not exists idx_purchases_purchase_date on public.purchases ("purchaseDate" desc);

create table if not exists public.inventory (
  id text primary key default gen_random_uuid()::text,
  name text not null,
  name_normalized text not null unique,
  unit text not null default 'un',
  quantity numeric(14,3) not null default 0,
  "minQuantity" numeric(14,3) not null default 0,
  "updatedAt" timestamptz not null default now(),
  "lastEntryDate" timestamptz,
  "lastPurchaseId" text references public.purchases(id) on delete set null,
  "createdAt" timestamptz default now()
);

create index if not exists idx_inventory_name on public.inventory (name);
create index if not exists idx_inventory_last_purchase on public.inventory ("lastPurchaseId");

create table if not exists public.inventory_movements (
  id text primary key default gen_random_uuid()::text,
  "itemId" text not null references public.inventory(id) on delete cascade,
  "itemName" text not null,
  quantity numeric(14,3) not null default 0,
  type text not null,
  "projectId" text references public.projects(id) on delete set null,
  "projectName" text,
  "purchaseId" text references public.purchases(id) on delete set null,
  "referenceId" text,
  date timestamptz not null default now(),
  notes text,
  "userId" text,
  constraint inventory_movements_type_check check (
    type in ('inbound', 'outbound', 'transfer', 'adjustment')
  )
);

create index if not exists idx_inventory_movements_item_id on public.inventory_movements ("itemId");
create index if not exists idx_inventory_movements_project_id on public.inventory_movements ("projectId");
create index if not exists idx_inventory_movements_date on public.inventory_movements (date desc);

create table if not exists public.material_requisitions (
  id text primary key default gen_random_uuid()::text,
  "projectId" text references public.projects(id) on delete set null,
  "projectName" text not null default '',
  "requesterName" text not null default '',
  "requesterId" text,
  "requestDate" timestamptz not null default now(),
  status text not null default 'pending',
  items jsonb not null default '[]'::jsonb,
  priority text not null default 'Media',
  "approvedBy" text,
  "approvedByName" text,
  "approvedAt" timestamptz,
  "rejectionReason" text,
  "purchaseId" text references public.purchases(id) on delete set null,
  "createdAt" timestamptz not null default now(),
  constraint material_requisitions_status_check check (
    status in ('pending', 'approved', 'rejected', 'purchased', 'delivered')
  )
);

create index if not exists idx_material_requisitions_project_id on public.material_requisitions ("projectId");
create index if not exists idx_material_requisitions_status on public.material_requisitions (status);
create index if not exists idx_material_requisitions_request_date on public.material_requisitions ("requestDate" desc);

create table if not exists public.daily_logs (
  id text primary key default gen_random_uuid()::text,
  "projectId" text not null references public.projects(id) on delete cascade,
  "projectName" text not null default '',
  date timestamptz not null,
  "weatherMorning" text not null default 'sol',
  "weatherAfternoon" text not null default 'sol',
  manpower jsonb not null default '{}'::jsonb,
  "activitiesDescription" text not null default '',
  impediments text not null default '',
  "photoUrls" text[] not null default '{}',
  "createdByUserId" text not null default '',
  status text not null default 'draft',
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint daily_logs_status_check check (
    status in ('draft', 'finalized', 'synced', 'pendente')
  )
);

create index if not exists idx_daily_logs_project_id on public.daily_logs ("projectId");
create index if not exists idx_daily_logs_date on public.daily_logs (date desc);

create table if not exists public.financial_transactions (
  id text primary key default gen_random_uuid()::text,
  description text not null,
  amount numeric(14,2) not null default 0,
  type text not null,
  status text not null default 'pending',
  origin text not null default 'manual',
  category text not null default 'other',
  "dueDate" timestamptz not null,
  "paymentDate" timestamptz,
  "projectId" text references public.projects(id) on delete set null,
  "supplierId" text references public.suppliers(id) on delete set null,
  "referenceId" text,
  "createdBy" text not null default '',
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz,
  notes text,
  constraint financial_transactions_type_check check (
    type in ('income', 'expense')
  ),
  constraint financial_transactions_status_check check (
    status in ('pending', 'paid', 'overdue', 'cancelled')
  ),
  constraint financial_transactions_origin_check check (
    origin in ('manual', 'purchase', 'laborCost', 'materialUsage', 'budget')
  ),
  constraint financial_transactions_category_check check (
    category in ('material', 'labor', 'equipment', 'administrative', 'measurement', 'tax', 'other')
  )
);

create index if not exists idx_financial_transactions_project_id
  on public.financial_transactions ("projectId");
create index if not exists idx_financial_transactions_supplier_id
  on public.financial_transactions ("supplierId");
create index if not exists idx_financial_transactions_due_date
  on public.financial_transactions ("dueDate" desc);
create index if not exists idx_financial_transactions_status
  on public.financial_transactions (status);
create index if not exists idx_financial_transactions_type
  on public.financial_transactions (type);

create table if not exists public.benefits (
  id text primary key default gen_random_uuid()::text,
  name text not null unique,
  type text not null default 'other',
  description text not null default '',
  "isActive" boolean not null default true,
  "createdAt" timestamptz not null default now(),
  constraint benefits_type_check check (
    type in ('vt', 'vr', 'health', 'dental', 'lifeInsurance', 'other')
  )
);

create table if not exists public.employee_benefits (
  id text primary key default gen_random_uuid()::text,
  "employeeId" text not null references public.employees(id) on delete cascade,
  "benefitId" text not null references public.benefits(id) on delete cascade,
  "benefitName" text not null default '',
  "monthlyValue" numeric(14,2) not null default 0,
  "startDate" timestamptz not null default now(),
  "endDate" timestamptz,
  "isActive" boolean not null default true,
  history jsonb not null default '[]'::jsonb
);

create index if not exists idx_employee_benefits_employee_id
  on public.employee_benefits ("employeeId");
create index if not exists idx_employee_benefits_benefit_id
  on public.employee_benefits ("benefitId");

create table if not exists public.salary_history (
  id text primary key default gen_random_uuid()::text,
  "employeeId" text not null references public.employees(id) on delete cascade,
  "previousSalary" numeric(14,2) not null default 0,
  "newSalary" numeric(14,2) not null default 0,
  "effectiveDate" timestamptz not null,
  reason text not null default '',
  "updatedBy" text not null default '',
  "createdAt" timestamptz not null default now()
);

create index if not exists idx_salary_history_employee_id
  on public.salary_history ("employeeId");
create index if not exists idx_salary_history_effective_date
  on public.salary_history ("effectiveDate" desc);

create table if not exists public.usage_stats (
  id text primary key,
  "tenantId" text not null,
  "totalReads" integer not null default 0,
  "totalWrites" integer not null default 0,
  "storageUsedMB" numeric(14,3) not null default 0,
  "aiRequests" integer not null default 0,
  "periodStart" timestamptz not null,
  "periodEnd" timestamptz not null,
  "dailyOperations" jsonb not null default '{}'::jsonb,
  "peakDayOperations" integer not null default 0
);

create index if not exists idx_usage_stats_tenant_id on public.usage_stats ("tenantId");

create table if not exists public.talent_candidates (
  id text primary key default gen_random_uuid()::text,
  name text not null,
  email text,
  phone text,
  status text not null default 'pending',
  "jobRoleId" text references public.job_roles(id) on delete set null,
  notes text,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now()
);

create index if not exists idx_talent_candidates_status
  on public.talent_candidates (status);

drop trigger if exists trg_budget_types_updated_at on public.budget_types;
create trigger trg_budget_types_updated_at
before update on public.budget_types
for each row execute function public.set_updated_at();

drop trigger if exists trg_items_updated_at on public.items;
create trigger trg_items_updated_at
before update on public.items
for each row execute function public.set_updated_at();

drop trigger if exists trg_projects_updated_at on public.projects;
create trigger trg_projects_updated_at
before update on public.projects
for each row execute function public.set_updated_at();

drop trigger if exists trg_employees_updated_at on public.employees;
create trigger trg_employees_updated_at
before update on public.employees
for each row execute function public.set_updated_at();

drop trigger if exists trg_teams_updated_at on public.teams;
create trigger trg_teams_updated_at
before update on public.teams
for each row execute function public.set_updated_at();

drop trigger if exists trg_suppliers_updated_at on public.suppliers;
create trigger trg_suppliers_updated_at
before update on public.suppliers
for each row execute function public.set_updated_at();

drop trigger if exists trg_daily_logs_updated_at on public.daily_logs;
create trigger trg_daily_logs_updated_at
before update on public.daily_logs
for each row execute function public.set_updated_at();

drop trigger if exists trg_talent_candidates_updated_at on public.talent_candidates;
create trigger trg_talent_candidates_updated_at
before update on public.talent_candidates
for each row execute function public.set_updated_at();

do $$
begin
  if not exists (
    select 1
    from storage.buckets
    where id = 'project-images'
  ) then
    insert into storage.buckets (id, name, public)
    values ('project-images', 'project-images', true);
  end if;
exception
  when undefined_table then
    null;
end $$;
