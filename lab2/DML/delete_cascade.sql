BEGIN;

WITH s AS (
  INSERT INTO suppliers (name, contact)
  VALUES ('ООО "Поставка-Сервис"', '+7 900 000-00-00, sales@postavka.example')
  RETURNING id
),
w AS (
  INSERT INTO warehouses (name, address)
  VALUES ('Склад Москва-1', 'Москва, ул. Складская, 1')
  RETURNING id
),
p1 AS (
  -- Берём любой существующий товар (для демо).
  SELECT id AS product_id FROM products ORDER BY name LIMIT 1
),
p2 AS (
  SELECT id AS product_id FROM products ORDER BY name OFFSET 1 LIMIT 1
),
inc AS (
  INSERT INTO incoming (supplier_id, warehouse_id, date)
  SELECT s.id, w.id, CURRENT_DATE
  FROM s, w
  RETURNING id, warehouse_id
),
items AS (
  INSERT INTO incoming_items (incoming_id, product_id, quantity)
  SELECT inc.id, p1.product_id, 30 FROM inc, p1
  UNION ALL
  SELECT inc.id, p2.product_id, 12 FROM inc, p2
  RETURNING product_id, quantity
)
INSERT INTO stock (product_id, warehouse_id, quantity)
SELECT items.product_id, inc.warehouse_id, items.quantity
FROM items
CROSS JOIN inc
ON CONFLICT (product_id, warehouse_id)
DO UPDATE SET quantity = stock.quantity + EXCLUDED.quantity;

COMMIT;
