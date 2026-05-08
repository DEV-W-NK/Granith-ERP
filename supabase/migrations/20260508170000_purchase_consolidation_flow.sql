alter table public.material_requisitions
  add column if not exists "requesterSector" text not null default 'Geral';

alter table public.purchases
  add column if not exists "expectedDeliveryDate" timestamptz,
  add column if not exists "invoiceNumber" text not null default '',
  add column if not exists "invoiceAccessKey" text not null default '',
  add column if not exists notes text not null default '',
  add column if not exists "approvalSector" text not null default 'Geral',
  add column if not exists "quotedBy" text,
  add column if not exists "quotedByName" text,
  add column if not exists "quotedAt" timestamptz,
  add column if not exists "consolidatedBy" text,
  add column if not exists "consolidatedByName" text,
  add column if not exists "consolidatedAt" timestamptz;

create index if not exists idx_purchases_approval_sector_status
on public.purchases ("approvalSector", status);
