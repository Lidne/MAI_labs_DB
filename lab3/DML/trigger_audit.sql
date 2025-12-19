with
    picked as (
        select product_id, warehouse_id
        from stock
        limit 1
    )
update stock s
set
    quantity = s.quantity + 1
from picked p
where
    s.product_id = p.product_id
    and s.warehouse_id = p.warehouse_id;

select * from stock_audit order by changed_at desc limit 5;