create or replace function trg_outgoing_items_check_stock() returns trigger language plpgsql as $$
declare
  v_warehouse_id uuid;
  v_have int;
  v_need int;
begin
  if new.quantity <= 0 then
    raise exception 'quantity must be > 0';
  end if;

  select o.warehouse_id
    into v_warehouse_id
  from outgoing o
  where o.id = new.outgoing_id;

  if v_warehouse_id is null then
    raise exception 'Outgoing % not found', new.outgoing_id;
  end if;

  select coalesce(s.quantity, 0)
    into v_have
  from stock s
  where s.product_id = new.product_id
    and s.warehouse_id = v_warehouse_id;

  if tg_op = 'UPDATE'
     and old.product_id = new.product_id
     and old.outgoing_id = new.outgoing_id then
    v_need := new.quantity - old.quantity;
  else
    v_need := new.quantity;
  end if;

  if v_need > 0 and v_have < v_need then
    raise exception 'Not enough stock: have %, need %', v_have, v_need;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_outgoing_items_check_stock on outgoing_items;

create trigger trg_outgoing_items_check_stock
before
insert
or
update on outgoing_items
for each row execute function trg_outgoing_items_check_stock();

-- ---------------------------------------------
-- Сюда пишем все изменения в остатках

create table if not exists stock_audit (
    id bigserial primary key,
    changed_at timestamptz not null default now(),
    op text not null,
    product_id uuid,
    warehouse_id uuid,
    old_quantity int,
    new_quantity int,
    delta int
);

create or replace function trg_stock_audit() returns trigger language plpgsql as $$
begin
  if tg_op = 'INSERT' then
    insert into stock_audit(op, product_id, warehouse_id, old_quantity, new_quantity, delta)
    values ('INSERT', new.product_id, new.warehouse_id, null, new.quantity, new.quantity);
    return new;

  elsif tg_op = 'UPDATE' then
    insert into stock_audit(op, product_id, warehouse_id, old_quantity, new_quantity, delta)
    values ('UPDATE', new.product_id, new.warehouse_id, old.quantity, new.quantity, new.quantity - old.quantity);
    return new;

  else
    insert into stock_audit(op, product_id, warehouse_id, old_quantity, new_quantity, delta)
    values ('DELETE', old.product_id, old.warehouse_id, old.quantity, null, -old.quantity);
    return old;
  end if;
end;
$$;

drop trigger if exists trg_stock_audit on stock;

create trigger trg_stock_audit after
insert
or
update
or
delete on stock
for each row execute function trg_stock_audit();