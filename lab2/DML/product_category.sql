BEGIN;

WITH
    cat AS (
        INSERT INTO
            categories (name)
        VALUES ('Электроника')
        RETURNING
            id
    )
INSERT INTO
    products (name, price, category_id)
SELECT 'SSD 1TB NVMe', 7990.00, cat.id
FROM cat
RETURNING
    id,
    name,
    price,
    category_id;

COMMIT;