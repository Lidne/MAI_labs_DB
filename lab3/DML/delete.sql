do $$
declare
  v_incoming uuid;
begin
  select i.id into v_incoming
  from incoming i
  order by i.date desc
  limit 1;

  delete from incoming where id = v_incoming;

exception when others then
  perform fn_log_error('DELETE (incoming header)', sqlerrm);
  raise;
end $$;