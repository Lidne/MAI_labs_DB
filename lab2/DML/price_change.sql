UPDATE products p
SET price = round((p.price * 1.10)::numeric, 2)::real
WHERE p.category_id = (SELECT id FROM categories WHERE name = 'Электроника' LIMIT 1);
