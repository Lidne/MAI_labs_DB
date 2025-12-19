do $$
declare
  v_wh uuid;
  v_prod uuid;
  v_out uuid;
begin
  select warehouse_id, product_id
    into v_wh, v_prod
  from stock
  limit 1;

  insert into outgoing(warehouse_id, date)
  values (v_wh, current_date)
  returning id into v_out;

  -- Должно упасть с ошибкой от триггера проверки остатков
  insert into outgoing_items(outgoing_id, product_id, quantity)
  values (v_out, v_prod, 999999);

exception when others then
  raise notice 'Trigger check fired: %', sqlerrm;
end $$;