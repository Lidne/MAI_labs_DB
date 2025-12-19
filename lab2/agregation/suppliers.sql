SELECT sup.name AS supplier_name,
       COUNT(DISTINCT i.id) AS incoming_docs_cnt,
       COUNT(DISTINCT ii.product_id) AS unique_products_cnt,
       SUM(ii.quantity) AS total_units,
       MAX(i.date) AS last_delivery_date,
       MIN(i.date) AS first_delivery_date
FROM suppliers sup
JOIN incoming i ON i.supplier_id = sup.id
JOIN incoming_items ii ON ii.incoming_id = i.id
GROUP BY sup.id,
         sup.name
HAVING SUM(ii.quantity) >= 500
ORDER BY total_units DESC,
         last_delivery_date DESC;