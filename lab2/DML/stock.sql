BEGIN;

WITH target AS
  (SELECT ii.id,
          ii.product_id,
          i.warehouse_id,
          ii.quantity AS old_qty
   FROM incoming_items ii
   JOIN incoming i ON i.id = ii.incoming_id
   ORDER BY i.date DESC
   LIMIT 1),
     upd AS
  (UPDATE incoming_items ii
   SET quantity = ii.quantity + 5
   FROM target
   WHERE ii.id = target.id RETURNING target.product_id,
                                     target.warehouse_id,
                                     (5) AS delta)
INSERT INTO stock (product_id, warehouse_id, quantity)
SELECT product_id,
       warehouse_id,
       delta
FROM upd ON CONFLICT (product_id,
                      warehouse_id) DO
UPDATE
SET quantity = stock.quantity + EXCLUDED.quantity;


COMMIT;