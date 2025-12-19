CREATE OR REPLACE VIEW vw_supplier_delivery_summary AS
SELECT
    s.id AS supplier_id,
    s.name AS supplier_name,
    s.contact,
    COUNT(DISTINCT i.id) AS incoming_docs_cnt,
    COUNT(DISTINCT i.warehouse_id) AS warehouses_cnt,
    COALESCE(SUM(ii.quantity), 0) AS total_units,
    COALESCE(SUM(ii.quantity * p.price), 0)::numeric(14, 2) AS total_amount,
    MAX(i.date) AS last_delivery_date
FROM
    suppliers s
    LEFT JOIN incoming i ON i.supplier_id = s.id
    LEFT JOIN incoming_items ii ON ii.incoming_id = i.id
    LEFT JOIN products p ON p.id = ii.product_id
GROUP BY
    s.id,
    s.name,
    s.contact;

SELECT * FROM vw_supplier_delivery_summary;