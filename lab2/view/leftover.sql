CREATE OR REPLACE VIEW vw_category_inventory_summary AS WITH inv AS
    (SELECT p.category_id,
            COUNT(DISTINCT p.id) AS products_cnt,
            COALESCE(SUM(s.quantity), 0) AS total_units,
            COALESCE(SUM(s.quantity * p.price), 0)::numeric(14, 2) AS total_stock_value
     FROM products p
     LEFT JOIN stock s ON s.product_id = p.id
     GROUP BY p.category_id),
                                                             last_in AS
    (SELECT p.category_id,
            MAX(i.date) AS last_incoming_date
     FROM products p
     JOIN incoming_items ii ON ii.product_id = p.id
     JOIN incoming i ON i.id = ii.incoming_id
     GROUP BY p.category_id)
SELECT c.id AS category_id,
       c.name AS category_name,
       COALESCE(inv.products_cnt, 0) AS products_cnt,
       COALESCE(inv.total_units, 0) AS total_units,
       COALESCE(inv.total_stock_value, 0)::numeric(14, 2) AS total_stock_value,
       last_in.last_incoming_date
FROM categories c
LEFT JOIN inv ON inv.category_id = c.id
LEFT JOIN last_in ON last_in.category_id = c.id;


SELECT *
FROM vw_category_inventory_summary;