do $$
declare
  v_supplier uuid;
  v_wh uuid;
  v_product uuid;
  v_incoming uuid;
begin
  select id into v_supplier from suppliers limit 1;
  select id into v_wh from warehouses limit 1;
  select id into v_product from products limit 1;

  call sp_post_incoming_simple(
    v_supplier,
    v_wh,
    current_date,
    jsonb_build_array(jsonb_build_object('product_id', v_product, 'quantity', 10)),
    v_incoming
  );

  raise notice 'Incoming=%; stock=%', v_incoming, fn_stock_qty(v_product, v_wh);

exception when others then
  perform fn_log_error('INSERT (incoming via procedure)', sqlerrm);
  raise;
end $$;