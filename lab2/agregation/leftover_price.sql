SELECT c.name AS category_name,
       COUNT(DISTINCT p.id) AS products_cnt,
       SUM(s.quantity) AS total_units,
       SUM(s.quantity * p.price)::numeric(14, 2) AS total_stock_value
FROM stock s
JOIN products p ON p.id = s.product_id
LEFT JOIN categories c ON c.id = p.category_id
GROUP BY c.name
ORDER BY total_stock_value DESC,
         total_units DESC;