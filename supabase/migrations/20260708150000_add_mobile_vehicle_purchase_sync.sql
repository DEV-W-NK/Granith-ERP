-- Extra ERP -> Mobile sync signals for vehicle assignments and delivered
-- purchases linked to material requisitions.

create or replace function private.notify_vehicle_assignment_change()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_old_employee_id text;
  v_new_employee_id text := nullif(new."assignedEmployeeId", '');
  v_vehicle_label text := trim(
    concat_ws(
      ' ',
      nullif(new.plate, ''),
      nullif(new.brand, ''),
      nullif(new.model, '')
    )
  );
begin
  if v_vehicle_label = '' then
    v_vehicle_label := 'veiculo';
  end if;

  if tg_op = 'UPDATE' then
    v_old_employee_id := nullif(old."assignedEmployeeId", '');

    if v_old_employee_id is not null
      and v_old_employee_id is distinct from v_new_employee_id then
      perform private.enqueue_mobile_push_notification(
        null,
        v_old_employee_id,
        'Veiculo removido',
        'O ' || v_vehicle_label || ' nao esta mais vinculado a voce.',
        'vehicle',
        'vehicles',
        jsonb_build_object(
          'sync', true,
          'syncReason', 'vehicle_assignment_removed',
          'syncTargets', jsonb_build_array('workspace', 'vehicles', 'routes'),
          'vehicleId', new.id,
          'vehiclePlate', new.plate,
          'assignedEmployeeId', v_old_employee_id
        ),
        'high'
      );
    end if;
  end if;

  if v_new_employee_id is null then
    return new;
  end if;

  if tg_op = 'INSERT'
    or v_new_employee_id is distinct from v_old_employee_id then
    perform private.enqueue_mobile_push_notification(
      null,
      v_new_employee_id,
      'Veiculo atribuido',
      'O ' || v_vehicle_label || ' foi vinculado ao seu cadastro.',
      'vehicle',
      'vehicles',
      jsonb_build_object(
        'sync', true,
        'syncReason', 'vehicle_assignment_changed',
        'syncTargets', jsonb_build_array('workspace', 'vehicles', 'routes'),
        'vehicleId', new.id,
        'vehiclePlate', new.plate,
        'assignedEmployeeId', v_new_employee_id
      ),
      'high'
    );
  elsif tg_op = 'UPDATE' and new.status is distinct from old.status then
    perform private.enqueue_mobile_push_notification(
      null,
      v_new_employee_id,
      'Veiculo atualizado',
      'O status do ' || v_vehicle_label || ' foi atualizado no ERP.',
      'vehicle',
      'vehicles',
      jsonb_build_object(
        'sync', true,
        'syncReason', 'vehicle_status_changed',
        'syncTargets', jsonb_build_array('workspace', 'vehicles', 'routes'),
        'vehicleId', new.id,
        'vehiclePlate', new.plate,
        'status', new.status
      ),
      'normal'
    );
  end if;

  return new;
end;
$$;

drop trigger if exists trg_notify_vehicle_assignment_change
  on public.vehicles;
create trigger trg_notify_vehicle_assignment_change
after insert or update of "assignedEmployeeId", status
on public.vehicles
for each row execute function private.notify_vehicle_assignment_change();

create or replace function private.sync_material_requisition_from_purchase()
returns trigger
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_requisition_id text := nullif(new."requisitionId", '');
  v_purchase_status text := coalesce(new.status::text, '');
  v_all_linked_purchases_closed boolean := false;
begin
  if v_requisition_id is null then
    return new;
  end if;

  if v_purchase_status in ('3', 'delivered') then
    select not exists (
      select 1
      from public.purchases purchase
      where purchase."requisitionId" = v_requisition_id
        and purchase.id is distinct from new.id
        and coalesce(purchase.status::text, '') not in ('3', '4', 'delivered', 'cancelled')
    )
    into v_all_linked_purchases_closed;

    if v_all_linked_purchases_closed then
      update public.material_requisitions
      set
        status = 'delivered',
        "purchaseId" = coalesce("purchaseId", new.id)
      where id = v_requisition_id
        and status is distinct from 'delivered';
    end if;
  elsif v_purchase_status in ('1', '2', 'pending', 'ordered') then
    update public.material_requisitions
    set
      status = 'purchased',
      "purchaseId" = coalesce("purchaseId", new.id)
    where id = v_requisition_id
      and status not in ('delivered', 'rejected');
  end if;

  return new;
end;
$$;

drop trigger if exists trg_sync_material_requisition_from_purchase
  on public.purchases;
create trigger trg_sync_material_requisition_from_purchase
after insert or update of status
on public.purchases
for each row execute function private.sync_material_requisition_from_purchase();
