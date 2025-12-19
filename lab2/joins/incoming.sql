SELECT i.id,
       i.date,
       s.name AS supplier_name,
       w.name AS warehouse_name,
       COUNT(ii.id) AS lines_cnt,
       SUM(ii.quantity) AS total_units
FROM incoming i
JOIN suppliers s ON s.id = i.supplier_id
JOIN warehouses w ON w.id = i.warehouse_id
JOIN incoming_items ii ON ii.incoming_id = i.id
GROUP BY i.id,
         i.date,
         s.name,
         w.name
ORDER BY i.date DESC
LIMIT 20;