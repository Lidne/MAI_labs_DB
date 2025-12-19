create or replace function fn_stock_qty(p_product_id uuid, p_warehouse_id uuid) returns int language sql stable as $$
  select coalesce(
    (select s.quantity
     from stock s
     where s.product_id = p_product_id
       and s.warehouse_id = p_warehouse_id),
    0
  );
$$;


create or replace function fn_warehouse_used_volume_m3(p_warehouse_id uuid) returns numeric(18, 4) language sql stable as $$
  select coalesce(
    sum(s.quantity * coalesce(p.volume_m3, 0)),
    0
  )::numeric(18,4)
  from stock s
  join products p on p.id = s.product_id
  where s.warehouse_id = p_warehouse_id;
$$;