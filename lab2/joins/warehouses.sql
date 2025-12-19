SELECT
    w.name AS warehouse_name,
    COUNT(DISTINCT o.id) AS outgoing_docs_cnt,
    COALESCE(SUM(oi.quantity), 0) AS total_shipped_units,
    MAX(o.date) AS last_outgoing_date
FROM
    warehouses w
    LEFT JOIN outgoing o ON o.warehouse_id = w.id
    LEFT JOIN outgoing_items oi ON oi.outgoing_id = o.id
GROUP BY
    w.id,
    w.name
ORDER BY
    total_shipped_units DESC,
    warehouse_name;