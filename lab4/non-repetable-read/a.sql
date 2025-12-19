BEGIN ISOLATION LEVEL READ COMMITTED;

SELECT quantity
FROM stock
WHERE product_id = :'prod' AND warehouse_id = :'wh';

SELECT quantity
FROM stock
WHERE product_id = :'prod' AND warehouse_id = :'wh';

COMMIT;