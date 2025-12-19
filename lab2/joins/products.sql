SELECT
    p.id,
    p.name,
    c.name AS category_name,
    COALESCE(SUM(st.quantity), 0) AS total_stock_units
FROM
    products p
    LEFT JOIN categories c ON c.id = p.category_id
    LEFT JOIN stock st ON st.product_id = p.id
GROUP BY
    p.id,
    p.name,
    c.name
ORDER BY total_stock_units DESC, p.name;