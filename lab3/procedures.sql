create or replace procedure sp_post_incoming_simple(p_supplier_id uuid, p_warehouse_id uuid, p_date date, p_items jsonb, inout p_incoming_id uuid default null) language plpgsql as $$
declare
  r record;
begin
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'p_items must be a non-empty JSON array';
  end if;

  insert into incoming (supplier_id, warehouse_id, date)
  values (p_supplier_id, p_warehouse_id, p_date)
  returning id into p_incoming_id;

  for r in
    select *
    from jsonb_to_recordset(p_items) as x(product_id uuid, quantity int)
  loop
    insert into incoming_items (incoming_id, product_id, quantity)
    values (p_incoming_id, r.product_id, r.quantity);

    insert into stock (product_id, warehouse_id, quantity)
    values (r.product_id, p_warehouse_id, r.quantity)
    on conflict (product_id, warehouse_id)
    do update set quantity = stock.quantity + excluded.quantity;
  end loop;
end;
$$;


create or replace procedure sp_post_outgoing_simple(p_warehouse_id uuid, p_date date, p_items jsonb, inout p_outgoing_id uuid default null) language plpgsql as $$
declare
  r record;
begin
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'p_items must be a non-empty JSON array';
  end if;

  insert into outgoing (warehouse_id, date)
  values (p_warehouse_id, p_date)
  returning id into p_outgoing_id;

  for r in
    select *
    from jsonb_to_recordset(p_items) as x(product_id uuid, quantity int)
  loop
    update stock s
       set quantity = s.quantity - r.quantity
     where s.product_id = r.product_id
       and s.warehouse_id = p_warehouse_id
       and s.quantity >= r.quantity;

    if not found then
      raise exception 'Not enough stock (product=%, warehouse=%, need=%)',
        r.product_id, p_warehouse_id, r.quantity;
    end if;

    insert into outgoing_items (outgoing_id, product_id, quantity)
    values (p_outgoing_id, r.product_id, r.quantity);
  end loop;
end;
$$;