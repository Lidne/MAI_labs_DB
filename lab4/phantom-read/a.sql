BEGIN ISOLATION LEVEL READ COMMITTED;

SELECT count(*)
FROM stock
WHERE warehouse_id = :'wh' AND quantity >= 50;

SELECT count(*)
FROM stock
WHERE warehouse_id = :'wh' AND quantity >= 50;

COMMIT;