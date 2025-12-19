BEGIN;

UPDATE stock
SET
    quantity = quantity + 30
WHERE
    product_id =:'prod'
    AND warehouse_id =:'wh';

COMMIT;