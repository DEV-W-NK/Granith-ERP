alter table public.projects
  add column if not exists "creationTimestamp" timestamptz default now();

update public.projects
set "creationTimestamp" = coalesce("creationTimestamp", "createdAt", created_at, now())
where "creationTimestamp" is null;

alter table public.purchases
  alter column "invoiceNumber" set default '',
  alter column "invoiceAccessKey" set default '',
  alter column notes set default '',
  alter column "approvalSector" set default 'Geral';

update public.purchases
set
  "invoiceNumber" = coalesce("invoiceNumber", ''),
  "invoiceAccessKey" = coalesce("invoiceAccessKey", ''),
  notes = coalesce(notes, ''),
  "approvalSector" = coalesce(nullif("approvalSector", ''), 'Geral');

alter table public.purchases
  alter column "invoiceNumber" set not null,
  alter column "invoiceAccessKey" set not null,
  alter column notes set not null,
  alter column "approvalSector" set not null;
