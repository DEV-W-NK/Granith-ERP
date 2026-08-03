-- Granith P0 transactional workflows.
-- Critical multi-table operations are executed atomically in PostgreSQL.

create or replace function private.jsonb_number(
  payload jsonb,
  candidate_keys text[],
  fallback numeric default 0
)
returns numeric
language plpgsql
immutable
set search_path = public, pg_temp
as $$
declare
  candidate_key text;
  raw_value text;
begin
  foreach candidate_key in array candidate_keys
  loop
    raw_value := nullif(trim(payload ->> candidate_key), '');
    if raw_value is not null then
      begin
        if position(',' in raw_value) > 0 and position('.' in raw_value) > 0 then
          if strpos(reverse(raw_value), ',') < strpos(reverse(raw_value), '.') then
            return replace(replace(raw_value, '.', ''), ',', '.')::numeric;
          end if;
          return replace(raw_value, ',', '')::numeric;
        elsif position(',' in raw_value) > 0 then
          return replace(raw_value, ',', '.')::numeric;
        end if;
        return raw_value::numeric;
      exception when invalid_text_representation then
        null;
      end;
    end if;
  end loop;
  return fallback;
end;
$$;

create or replace function private.jsonb_text(
  payload jsonb,
  candidate_keys text[]
)
returns text
language plpgsql
immutable
set search_path = public, pg_temp
as $$
declare
  candidate_key text;
  raw_value text;
begin
  foreach candidate_key in array candidate_keys
  loop
    raw_value := nullif(trim(payload ->> candidate_key), '');
    if raw_value is not null then
      return raw_value;
    end if;
  end loop;
  return '';
end;
$$;

create or replace function public.approve_budget_atomic(p_budget_id text)
returns text
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_budget public.budgets%rowtype;
  v_project_id text;
  v_now timestamptz := now();
  v_end_date timestamptz;
  v_project_key text;
begin
  if not private.can_write_budgets() or not private.can_write_projects() then
    raise exception 'Budget and project write permissions are required.'
      using errcode = '42501';
  end if;

  select * into v_budget
  from public.budgets
  where id = p_budget_id
    and "archivedAt" is null
  for update;

  if not found then
    raise exception 'Budget not found.';
  end if;

  if v_budget.status = 1 and nullif(v_budget."projectId", '') is not null then
    return v_budget."projectId";
  end if;

  select id into v_project_id
  from public.projects
  where "sourceBudgetId" = v_budget.id
    and "archivedAt" is null
  order by "createdAt"
  limit 1;

  if v_project_id is null then
    v_project_key :=
      lower(trim(v_budget."projectName")) || '_' ||
      lower(trim(v_budget."clientName"));
    v_end_date := case
      when v_budget."expirationDate" is null then null
      else to_timestamp(v_budget."expirationDate" / 1000.0)
    end;

    insert into public.projects (
      name,
      client,
      description,
      status,
      "startDate",
      "endDate",
      budget,
      "currentCost",
      location,
      tags,
      "teamSize",
      "sourceBudgetId",
      "creationTimestamp",
      "createdAt",
      created_at,
      "createdBy",
      created_by,
      "updatedAt",
      updated_at,
      "updatedBy",
      updated_by,
      "projectKey",
      "clientAccountId",
      client_account_id,
      "clientAccountName",
      client_account_name
    )
    values (
      trim(v_budget."projectName"),
      trim(v_budget."clientName"),
      coalesce(v_budget.description, ''),
      'planning',
      v_now,
      v_end_date,
      v_budget."totalValue",
      0,
      '',
      array['Gerado por orcamento'],
      0,
      v_budget.id,
      v_now,
      v_now,
      v_now,
      (select auth.uid())::text,
      (select auth.uid())::text,
      v_now,
      v_now,
      (select auth.uid())::text,
      (select auth.uid())::text,
      v_project_key,
      v_budget."clientAccountId",
      v_budget.client_account_id,
      v_budget."clientAccountName",
      v_budget.client_account_name
    )
    returning id into v_project_id;
  end if;

  update public.budgets
  set
    status = 1,
    "projectId" = v_project_id,
    project_id = v_project_id
  where id = v_budget.id;

  return v_project_id;
end;
$$;

create or replace function public.convert_quote_to_purchases_atomic(
  p_requisition_id text,
  p_quote_id text,
  p_created_by text,
  p_created_by_name text default null,
  p_approval_sector text default null
)
returns text[]
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_requisition public.material_requisitions%rowtype;
  v_quote public.material_requisition_supplier_quotes%rowtype;
  v_items jsonb;
  v_item jsonb;
  v_purchase_ids text[];
  v_purchase_id text;
  v_item_count integer;
  v_index integer := 0;
  v_negotiated_total numeric;
  v_explicit_total numeric := 0;
  v_weight_total numeric := 0;
  v_running_total numeric := 0;
  v_line_base numeric;
  v_weight numeric;
  v_line_value numeric;
  v_quantity numeric;
  v_item_name text;
  v_item_id text;
  v_sector text;
  v_expected_delivery timestamptz;
  v_now timestamptz := now();
begin
  if not private.can_write_purchases() then
    raise exception 'Purchase write permission is required.'
      using errcode = '42501';
  end if;

  select * into v_requisition
  from public.material_requisitions
  where id = p_requisition_id
    and "archivedAt" is null
  for update;

  if not found then
    raise exception 'Material requisition not found.';
  end if;
  if v_requisition.status in ('rejected', 'delivered') then
    raise exception 'The requisition cannot be converted in its current status.';
  end if;

  select * into v_quote
  from public.material_requisition_supplier_quotes
  where id = p_quote_id
    and "requisitionId" = p_requisition_id
    and "archivedAt" is null
  for update;

  if not found then
    raise exception 'Supplier quote not found for this requisition.';
  end if;

  select coalesce(array_agg(id order by "purchaseDate" desc), '{}'::text[])
  into v_purchase_ids
  from public.purchases
  where "requisitionId" = p_requisition_id
    and status <> 4
    and "archivedAt" is null;

  if cardinality(v_purchase_ids) > 0 then
    update public.material_requisition_supplier_quotes
    set
      "isSelected" = (id = p_quote_id),
      status = case when id = p_quote_id then 'selected' else 'rejected' end
    where "requisitionId" = p_requisition_id
      and "archivedAt" is null;

    update public.material_requisitions
    set status = 'purchased', "purchaseId" = v_purchase_ids[1]
    where id = p_requisition_id;

    return v_purchase_ids;
  end if;

  if trim(v_quote."supplierName") = '' then
    raise exception 'The supplier quote has no supplier.';
  end if;

  v_negotiated_total := v_quote."totalValue" + v_quote."freightValue";
  if v_negotiated_total <= 0 then
    raise exception 'The negotiated quote total must be positive.';
  end if;

  v_items := case
    when jsonb_typeof(v_quote."quoteItems") = 'array'
      and jsonb_array_length(v_quote."quoteItems") > 0
      then v_quote."quoteItems"
    else v_requisition.items
  end;

  if jsonb_typeof(v_items) <> 'array' or jsonb_array_length(v_items) = 0 then
    raise exception 'The requisition has no items.';
  end if;

  v_item_count := jsonb_array_length(v_items);
  for v_item in select value from jsonb_array_elements(v_items)
  loop
    v_line_base := private.jsonb_number(
      v_item,
      array['totalValue', 'lineTotal', 'subtotal', 'total', 'priceTotal'],
      0
    );
    if v_line_base <= 0 then
      v_line_base := private.jsonb_number(
        v_item,
        array['unitPrice', 'price', 'unitValue'],
        0
      ) * greatest(private.jsonb_number(v_item, array['quantity'], 1), 0);
    end if;
    v_explicit_total := v_explicit_total + greatest(v_line_base, 0);
  end loop;

  for v_item in select value from jsonb_array_elements(v_items)
  loop
    if v_explicit_total > 0 then
      v_weight := private.jsonb_number(
        v_item,
        array['totalValue', 'lineTotal', 'subtotal', 'total', 'priceTotal'],
        0
      );
      if v_weight <= 0 then
        v_weight := private.jsonb_number(
          v_item,
          array['unitPrice', 'price', 'unitValue'],
          0
        ) * greatest(private.jsonb_number(v_item, array['quantity'], 1), 0);
      end if;
    else
      v_weight := greatest(private.jsonb_number(v_item, array['quantity'], 1), 1);
    end if;
    v_weight_total := v_weight_total + greatest(v_weight, 0);
  end loop;

  v_sector := coalesce(
    nullif(trim(p_approval_sector), ''),
    nullif(trim(v_requisition."requesterSector"), ''),
    'Geral'
  );
  v_expected_delivery := case
    when v_quote."deliveryDays" > 0
      then v_now + make_interval(days => v_quote."deliveryDays")
    else null
  end;

  for v_item in select value from jsonb_array_elements(v_items)
  loop
    v_index := v_index + 1;
    v_item_name := coalesce(
      nullif(private.jsonb_text(v_item, array['itemName', 'name']), ''),
      'Item da requisicao'
    );
    v_item_id := nullif(private.jsonb_text(
      v_item,
      array['itemId', 'item_id', 'inventoryItemId', 'catalogItemId']
    ), '');
    v_quantity := greatest(private.jsonb_number(v_item, array['quantity'], 1), 0.001);

    if v_explicit_total > 0 then
      v_weight := private.jsonb_number(
        v_item,
        array['totalValue', 'lineTotal', 'subtotal', 'total', 'priceTotal'],
        0
      );
      if v_weight <= 0 then
        v_weight := private.jsonb_number(
          v_item,
          array['unitPrice', 'price', 'unitValue'],
          0
        ) * v_quantity;
      end if;
    else
      v_weight := greatest(v_quantity, 1);
    end if;

    if v_index = v_item_count then
      v_line_value := round(v_negotiated_total - v_running_total, 2);
    else
      v_line_value := round(
        v_negotiated_total * (greatest(v_weight, 0) / nullif(v_weight_total, 0)),
        2
      );
      v_running_total := v_running_total + v_line_value;
    end if;

    insert into public.purchases (
      "itemId",
      "itemName",
      "supplierId",
      "supplierName",
      "projectId",
      "projectName",
      "requisitionId",
      "deliveryAddress",
      quantity,
      "totalValue",
      status,
      "purchaseDate",
      "expectedDeliveryDate",
      "invoiceNumber",
      "invoiceAccessKey",
      notes,
      "approvalSector",
      "quotedBy",
      "quotedByName",
      "quotedAt"
    )
    values (
      v_item_id,
      v_item_name,
      v_quote."supplierId",
      v_quote."supplierName",
      v_requisition."projectId",
      v_requisition."projectName",
      v_requisition.id,
      v_requisition."projectName",
      v_quantity,
      v_line_value,
      0,
      v_now,
      v_expected_delivery,
      '',
      '',
      concat_ws(
        E'\n',
        'Pedido gerado a partir da cotacao ' || v_quote.id || '.',
        case
          when trim(v_quote."paymentTerms") <> ''
            then 'Condicao: ' || trim(v_quote."paymentTerms") || '.'
        end,
        case
          when v_quote."freightValue" > 0
            then 'Frete rateado no valor total negociado.'
        end,
        nullif(trim(v_quote.notes), '')
      ),
      v_sector,
      coalesce(nullif(trim(p_created_by), ''), (select auth.uid())::text),
      nullif(trim(p_created_by_name), ''),
      v_quote."quotedAt"
    )
    returning id into v_purchase_id;

    v_purchase_ids := array_append(coalesce(v_purchase_ids, '{}'::text[]), v_purchase_id);
  end loop;

  update public.material_requisition_supplier_quotes
  set
    "isSelected" = (id = p_quote_id),
    status = case when id = p_quote_id then 'selected' else 'rejected' end
  where "requisitionId" = p_requisition_id
    and "archivedAt" is null;

  update public.material_requisitions
  set status = 'purchased', "purchaseId" = v_purchase_ids[1]
  where id = p_requisition_id;

  return v_purchase_ids;
end;
$$;

create or replace function public.convert_requisition_to_purchases_atomic(
  p_requisition_id text,
  p_supplier_id text,
  p_supplier_name text,
  p_item_prices jsonb,
  p_created_by text,
  p_approval_sector text default null
)
returns text[]
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_requisition public.material_requisitions%rowtype;
  v_item jsonb;
  v_purchase_ids text[] := '{}'::text[];
  v_purchase_id text;
  v_item_name text;
  v_quantity numeric;
  v_price numeric;
  v_sector text;
  v_now timestamptz := now();
begin
  if not private.can_write_purchases() then
    raise exception 'Purchase write permission is required.'
      using errcode = '42501';
  end if;

  select * into v_requisition
  from public.material_requisitions
  where id = p_requisition_id
    and "archivedAt" is null
  for update;

  if not found then
    raise exception 'Material requisition not found.';
  end if;
  if v_requisition.status not in ('pending', 'approved') then
    raise exception 'The requisition cannot be converted in its current status.';
  end if;
  if trim(coalesce(p_supplier_name, '')) = '' then
    raise exception 'Supplier is required.';
  end if;

  v_sector := coalesce(
    nullif(trim(p_approval_sector), ''),
    nullif(trim(v_requisition."requesterSector"), ''),
    'Geral'
  );

  for v_item in select value from jsonb_array_elements(v_requisition.items)
  loop
    v_item_name := coalesce(
      nullif(private.jsonb_text(v_item, array['itemName', 'name']), ''),
      'Item da requisicao'
    );
    v_quantity := greatest(private.jsonb_number(v_item, array['quantity'], 1), 0.001);
    v_price := coalesce(
      nullif(p_item_prices ->> v_item_name, '')::numeric,
      0
    );

    insert into public.purchases (
      "itemName",
      "supplierId",
      "supplierName",
      "projectId",
      "projectName",
      "requisitionId",
      "deliveryAddress",
      quantity,
      "totalValue",
      status,
      "purchaseDate",
      "invoiceNumber",
      "invoiceAccessKey",
      notes,
      "approvalSector",
      "quotedBy",
      "quotedAt"
    )
    values (
      v_item_name,
      nullif(trim(p_supplier_id), ''),
      trim(p_supplier_name),
      v_requisition."projectId",
      v_requisition."projectName",
      v_requisition.id,
      v_requisition."projectName",
      v_quantity,
      v_price,
      0,
      v_now,
      '',
      '',
      'Pedido gerado diretamente a partir da requisicao.',
      v_sector,
      coalesce(nullif(trim(p_created_by), ''), (select auth.uid())::text),
      v_now
    )
    returning id into v_purchase_id;

    v_purchase_ids := array_append(v_purchase_ids, v_purchase_id);
  end loop;

  if cardinality(v_purchase_ids) = 0 then
    raise exception 'The requisition has no items.';
  end if;

  update public.material_requisitions
  set status = 'purchased', "purchaseId" = v_purchase_ids[1]
  where id = p_requisition_id;

  return v_purchase_ids;
end;
$$;

create or replace function private.ensure_purchase_payable(
  purchase_row public.purchases,
  actor_id text,
  transaction_notes text
)
returns text
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_transaction_id text;
begin
  if nullif(purchase_row."financialTransactionId", '') is not null then
    return purchase_row."financialTransactionId";
  end if;

  select id into v_transaction_id
  from public.financial_transactions
  where origin = 'purchase'
    and "referenceId" = purchase_row.id
    and status <> 'cancelled'
    and "archivedAt" is null
  order by "createdAt"
  limit 1
  for update;

  if v_transaction_id is null then
    insert into public.financial_transactions (
      description,
      amount,
      type,
      status,
      origin,
      category,
      "dueDate",
      "projectId",
      "supplierId",
      "referenceId",
      "createdBy",
      "createdAt",
      notes
    )
    values (
      'Compra: ' || purchase_row."itemName" || ' - ' || purchase_row."supplierName" ||
        case
          when trim(coalesce(purchase_row."invoiceNumber", '')) <> ''
            then ' - NF ' || trim(purchase_row."invoiceNumber")
          else ''
        end,
      purchase_row."totalValue",
      'expense',
      'pending',
      'purchase',
      'material',
      coalesce(purchase_row."expectedDeliveryDate", now()),
      nullif(purchase_row."projectId", ''),
      nullif(purchase_row."supplierId", ''),
      purchase_row.id,
      coalesce(nullif(actor_id, ''), (select auth.uid())::text, ''),
      now(),
      concat_ws(E'\n', nullif(trim(transaction_notes), ''), nullif(trim(purchase_row.notes), ''))
    )
    returning id into v_transaction_id;
  end if;

  return v_transaction_id;
end;
$$;

create or replace function public.consolidate_purchase_atomic(
  p_purchase_id text,
  p_actor_id text,
  p_actor_name text,
  p_invoice_number text,
  p_invoice_access_key text default '',
  p_expected_delivery_date timestamptz default null,
  p_notes text default ''
)
returns text
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_purchase public.purchases%rowtype;
  v_transaction_id text;
  v_invoice_number text := trim(coalesce(p_invoice_number, ''));
begin
  if not private.has_any_permission(array[
    'purchases.consolidate', 'purchases.write', 'compras'
  ]) then
    raise exception 'Purchase consolidation permission is required.'
      using errcode = '42501';
  end if;
  if v_invoice_number = '' then
    raise exception 'Invoice number is required.';
  end if;

  select * into v_purchase
  from public.purchases
  where id = p_purchase_id
    and "archivedAt" is null
  for update;

  if not found then
    raise exception 'Purchase not found.';
  end if;
  if v_purchase.status <> 1 then
    raise exception 'The purchase must be approved before consolidation.';
  end if;

  v_purchase."invoiceNumber" := v_invoice_number;
  v_purchase."expectedDeliveryDate" := p_expected_delivery_date;
  v_purchase.notes := trim(coalesce(p_notes, ''));

  v_transaction_id := private.ensure_purchase_payable(
    v_purchase,
    p_actor_id,
    'Conta a pagar gerada na consolidacao da compra #' || v_purchase.id ||
      '. NF: ' || v_invoice_number || '. ' || trim(coalesce(p_notes, ''))
  );

  update public.purchases
  set
    status = 2,
    "financialTransactionId" = v_transaction_id,
    "invoiceNumber" = v_invoice_number,
    "invoiceAccessKey" = trim(coalesce(p_invoice_access_key, '')),
    "expectedDeliveryDate" = p_expected_delivery_date,
    notes = trim(coalesce(p_notes, '')),
    "consolidatedBy" = coalesce(nullif(trim(p_actor_id), ''), (select auth.uid())::text),
    "consolidatedByName" = nullif(trim(p_actor_name), ''),
    "consolidatedAt" = now()
  where id = p_purchase_id;

  return v_transaction_id;
end;
$$;

create or replace function public.confirm_purchase_delivery_atomic(
  p_purchase_id text,
  p_received_by text
)
returns text
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_purchase public.purchases%rowtype;
  v_transaction_id text;
  v_inventory_id text;
  v_normalized_name text;
  v_now timestamptz := now();
begin
  if not private.has_any_permission(array[
    'purchases.consolidate',
    'purchases.write',
    'inventory.write',
    'compras',
    'estoque'
  ]) then
    raise exception 'Purchase delivery permission is required.'
      using errcode = '42501';
  end if;

  select * into v_purchase
  from public.purchases
  where id = p_purchase_id
    and "archivedAt" is null
  for update;

  if not found then
    raise exception 'Purchase not found.';
  end if;
  if v_purchase.status = 3 then
    return v_purchase."financialTransactionId";
  end if;
  if v_purchase.status <> 2 then
    raise exception 'The purchase must be consolidated before delivery.';
  end if;

  v_transaction_id := private.ensure_purchase_payable(
    v_purchase,
    p_received_by,
    'Conta a pagar criada automaticamente no recebimento da compra #' ||
      v_purchase.id || '.'
  );

  v_normalized_name := lower(trim(v_purchase."itemName"));
  select id into v_inventory_id
  from public.inventory
  where name_normalized = v_normalized_name
    and "archivedAt" is null
  for update;

  if v_inventory_id is null then
    insert into public.inventory (
      name,
      name_normalized,
      unit,
      quantity,
      "minQuantity",
      "updatedAt",
      "lastEntryDate",
      "lastPurchaseId",
      "createdAt"
    )
    values (
      v_purchase."itemName",
      v_normalized_name,
      'un',
      v_purchase.quantity,
      5,
      v_now,
      v_now,
      v_purchase.id,
      v_now
    )
    returning id into v_inventory_id;
  else
    update public.inventory
    set
      quantity = quantity + v_purchase.quantity,
      "lastEntryDate" = v_now,
      "updatedAt" = v_now,
      "lastPurchaseId" = v_purchase.id
    where id = v_inventory_id;
  end if;

  if not exists (
    select 1
    from public.inventory_movements
    where "purchaseId" = v_purchase.id
      and type = 'inbound'
  ) then
    insert into public.inventory_movements (
      "itemId",
      "itemName",
      quantity,
      type,
      "projectId",
      "projectName",
      "purchaseId",
      date,
      notes,
      "userId"
    )
    values (
      v_inventory_id,
      v_purchase."itemName",
      v_purchase.quantity,
      'inbound',
      nullif(v_purchase."projectId", ''),
      nullif(v_purchase."projectName", ''),
      v_purchase.id,
      v_now,
      'Entrada automatica - compra #' || v_purchase.id,
      coalesce(nullif(trim(p_received_by), ''), (select auth.uid())::text)
    );
  end if;

  update public.purchases
  set
    status = 3,
    "deliveryDate" = v_now,
    "receivedBy" = coalesce(nullif(trim(p_received_by), ''), (select auth.uid())::text),
    "financialTransactionId" = v_transaction_id
  where id = v_purchase.id;

  return v_transaction_id;
end;
$$;

create or replace function public.cancel_purchase_atomic(
  p_purchase_id text,
  p_cancelled_by text
)
returns boolean
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_purchase public.purchases%rowtype;
begin
  if not private.can_write_purchases() then
    raise exception 'Purchase write permission is required.'
      using errcode = '42501';
  end if;

  select * into v_purchase
  from public.purchases
  where id = p_purchase_id
    and "archivedAt" is null
  for update;

  if not found then
    raise exception 'Purchase not found.';
  end if;
  if v_purchase.status = 3 then
    raise exception 'Delivered purchases cannot be cancelled.';
  end if;

  update public.purchases
  set
    status = 4,
    "rejectionReason" = coalesce(
      nullif("rejectionReason", ''),
      'Cancelada por ' || coalesce(nullif(trim(p_cancelled_by), ''), 'usuario')
    )
  where id = v_purchase.id;

  if nullif(v_purchase."financialTransactionId", '') is not null then
    update public.financial_transactions
    set status = 'cancelled', "updatedAt" = now()
    where id = v_purchase."financialTransactionId"
      and status <> 'paid';
  end if;

  return true;
end;
$$;

create or replace function public.create_purchase_route_atomic(
  p_name text,
  p_driver_id text,
  p_driver_name text,
  p_scheduled_date timestamptz,
  p_notes text,
  p_created_by text,
  p_stops jsonb
)
returns text
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_route_id text;
  v_stop jsonb;
  v_purchase_id text;
  v_driver_name text;
  v_stop_count integer := 0;
  v_sequence integer := 0;
begin
  if not private.can_manage_fleet() then
    raise exception 'Logistics management permission is required.'
      using errcode = '42501';
  end if;
  if trim(coalesce(p_driver_id, '')) = '' then
    raise exception 'A valid driver is required.';
  end if;

  select employee.name
    into v_driver_name
    from public.employees employee
   where employee.id::text = trim(p_driver_id)
     and employee.status = 'ativo'
     and employee."archivedAt" is null
     and exists (
       select 1
         from public.vehicles vehicle
        where vehicle."assignedEmployeeId"::text = employee.id::text
          and vehicle.status = 'active'
          and vehicle."archivedAt" is null
     )
   limit 1;
  if v_driver_name is null then
    raise exception 'Driver must be an active employee assigned to an active vehicle.';
  end if;

  if jsonb_typeof(p_stops) <> 'array' or jsonb_array_length(p_stops) = 0 then
    raise exception 'At least one route stop is required.';
  end if;

  insert into public.purchase_delivery_routes (
    name,
    "driverId",
    "driverName",
    status,
    "scheduledDate",
    notes,
    "createdBy",
    "createdAt",
    "updatedAt"
  )
  values (
    coalesce(
      nullif(trim(p_name), ''),
      'Rota de ' || v_driver_name
    ),
    trim(p_driver_id),
    v_driver_name,
    'planned',
    p_scheduled_date,
    trim(coalesce(p_notes, '')),
    coalesce(nullif(trim(p_created_by), ''), (select auth.uid())::text),
    now(),
    now()
  )
  returning id into v_route_id;

  for v_stop in select value from jsonb_array_elements(p_stops)
  loop
    v_purchase_id := nullif(trim(v_stop ->> 'purchaseId'), '');
    if v_purchase_id is null
      or nullif(trim(v_stop ->> 'address'), '') is null
      or coalesce(v_stop ->> 'stopType', '') not in ('pickup', 'delivery')
    then
      raise exception 'Invalid route stop payload.';
    end if;

    perform 1
    from public.purchases
    where id = v_purchase_id
      and status = 2
      and "archivedAt" is null
    for update;
    if not found then
      raise exception 'Purchase % is not available for routing.', v_purchase_id;
    end if;

    v_sequence := v_sequence + 1;
    insert into public.purchase_delivery_route_stops (
      "routeId",
      "purchaseId",
      "stopType",
      sequence,
      address,
      "supplierName",
      "projectName",
      status,
      notes,
      "createdAt"
    )
    values (
      v_route_id,
      v_purchase_id,
      v_stop ->> 'stopType',
      v_sequence,
      trim(v_stop ->> 'address'),
      coalesce(v_stop ->> 'supplierName', ''),
      coalesce(v_stop ->> 'projectName', ''),
      'pending',
      coalesce(v_stop ->> 'notes', ''),
      now()
    );
    v_stop_count := v_stop_count + 1;
  end loop;

  if v_stop_count = 0 then
    raise exception 'At least one valid route stop is required.';
  end if;

  update public.purchases
  set "routeId" = v_route_id
  where id in (
    select distinct value ->> 'purchaseId'
    from jsonb_array_elements(p_stops)
  );

  return v_route_id;
end;
$$;

revoke all on function public.approve_budget_atomic(text) from public, anon;
revoke all on function public.convert_quote_to_purchases_atomic(text, text, text, text, text) from public, anon;
revoke all on function public.convert_requisition_to_purchases_atomic(text, text, text, jsonb, text, text) from public, anon;
revoke all on function public.consolidate_purchase_atomic(text, text, text, text, text, timestamptz, text) from public, anon;
revoke all on function public.confirm_purchase_delivery_atomic(text, text) from public, anon;
revoke all on function public.cancel_purchase_atomic(text, text) from public, anon;
revoke all on function public.create_purchase_route_atomic(text, text, text, timestamptz, text, text, jsonb) from public, anon;

grant execute on function public.approve_budget_atomic(text) to authenticated;
grant execute on function public.convert_quote_to_purchases_atomic(text, text, text, text, text) to authenticated;
grant execute on function public.convert_requisition_to_purchases_atomic(text, text, text, jsonb, text, text) to authenticated;
grant execute on function public.consolidate_purchase_atomic(text, text, text, text, text, timestamptz, text) to authenticated;
grant execute on function public.confirm_purchase_delivery_atomic(text, text) to authenticated;
grant execute on function public.cancel_purchase_atomic(text, text) to authenticated;
grant execute on function public.create_purchase_route_atomic(text, text, text, timestamptz, text, text, jsonb) to authenticated;
