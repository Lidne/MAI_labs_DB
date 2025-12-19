BEGIN;

INSERT INTO
    products (
        name,
        article,
        price,
        category_id
    )
VALUES (
        'Demo product 2',
        'SKU-DEMO-2',
        12.0,
:'cat'
    )
RETURNING
    id;

INSERT INTO
    stock (
        product_id,
        warehouse_id,
        quantity,
        min_balance,
        location_code
    )
VALUES (:'prod2',:'wh', 60, 0, 'A-02');

COMMIT;