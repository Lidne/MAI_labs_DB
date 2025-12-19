do $$
declare
  v_wh uuid;
  v_product uuid;
  v_outgoing uuid;
begin
  select warehouse_id, product_id
    into v_wh, v_product
  from stock
  limit 1;

  call sp_post_outgoing_simple(
    v_wh,
    current_date,
    jsonb_build_array(jsonb_build_object('product_id', v_product, 'quantity', 1)),
    v_outgoing
  );

  update outgoing_items
     set quantity = quantity + 999999
   where outgoing_id = v_outgoing
     and product_id = v_product;

exception when others then
  perform fn_log_error('UPDATE (outgoing_items, expect trigger error)', sqlerrm);
  raise;
end $$;