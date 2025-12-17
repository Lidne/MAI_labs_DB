import random
from decimal import Decimal

import psycopg2
from faker import Faker

DB_CONFIG = {
    "dbname": "main",
    "user": "postgres",
    "password": "1111",
    "host": "localhost",
    "port": "5432",
}


COUNTS = {
    "categories": 10,
    "warehouses": 5,
    "suppliers": 20,
    "products": 100,
    "stock_entries": 300,
    "incoming": 50,
    "outgoing": 50,
}

fake = Faker("ru_RU")


def get_conn():
    conn = psycopg2.connect(**DB_CONFIG)
    conn.autocommit = False
    return conn


def populate_categories(cur):
    print("Генерация категорий...")
    categories = []

    names = [
        "Электроника",
        "Бытовая техника",
        "Мебель",
        "Одежда",
        "Инструменты",
        "Сад и огород",
        "Автотовары",
        "Спорт",
        "Книги",
        "Продукты",
    ]

    sql = "INSERT INTO categories (name) VALUES (%s) RETURNING id;"
    ids = []
    for name in names:
        cur.execute(sql, (name,))
        ids.append(cur.fetchone()[0])
    return ids


def populate_warehouses(cur):
    print("Генерация складов...")
    ids = []
    sql = """
        INSERT INTO warehouses (name, address, capacity_m3) 
        VALUES (%s, %s, %s) RETURNING id;
    """
    for _ in range(COUNTS["warehouses"]):
        name = f"Склад {fake.city()}"
        address = fake.address()
        capacity = random.uniform(500, 5000)
        cur.execute(sql, (name, address, capacity))
        ids.append(cur.fetchone()[0])
    return ids


def populate_suppliers(cur):
    print("Генерация поставщиков...")
    ids = []
    sql = "INSERT INTO suppliers (name, contact) VALUES (%s, %s) RETURNING id;"
    for _ in range(COUNTS["suppliers"]):
        name = fake.company()
        contact = f"{fake.name()}, {fake.phone_number()}"
        cur.execute(sql, (name, contact))
        ids.append(cur.fetchone()[0])
    return ids


def populate_products(cur, category_ids):
    print("Генерация товаров...")
    ids = []
    sql = """
        INSERT INTO products (name, article, description, weight_kg, volume_m3, price, category_id) 
        VALUES (%s, %s, %s, %s, %s, %s, %s) RETURNING id;
    """
    for _ in range(COUNTS["products"]):
        name = fake.catch_phrase()
        article = fake.unique.ean13()
        desc = fake.sentence(nb_words=10)
        weight = round(random.uniform(0.1, 50.0), 3)

        volume = round(weight * random.uniform(0.001, 0.01), 4)
        price = round(random.uniform(100, 50000), 2)
        cat_id = random.choice(category_ids)

        cur.execute(sql, (name, article, desc, weight, volume, price, cat_id))
        ids.append(cur.fetchone()[0])
    return ids


def populate_stock(cur, product_ids, warehouse_ids):
    print("Генерация остатков...")

    pairs = set()
    while len(pairs) < COUNTS["stock_entries"]:
        pairs.add((random.choice(product_ids), random.choice(warehouse_ids)))

    sql = """
        INSERT INTO stock (product_id, warehouse_id, quantity, min_balance, location_code)
        VALUES (%s, %s, %s, %s, %s);
    """
    data = []
    for pid, wid in pairs:
        qty = random.randint(0, 500)
        min_bal = random.randint(10, 50)

        loc = f"{random.choice('ABCDEF')}-{random.randint(1, 20):02d}-{random.randint(1, 5):02d}"
        data.append((pid, wid, qty, min_bal, loc))

    cur.executemany(sql, data)


def populate_movements(cur, supplier_ids, warehouse_ids, product_ids):
    print("Генерация поступлений и отгрузок...")

    for _ in range(COUNTS["incoming"]):
        sql_head = "INSERT INTO incoming (supplier_id, warehouse_id, date) VALUES (%s, %s, %s) RETURNING id;"
        cur.execute(
            sql_head,
            (
                random.choice(supplier_ids),
                random.choice(warehouse_ids),
                fake.date_between(start_date="-1y", end_date="today"),
            ),
        )
        incoming_id = cur.fetchone()[0]

        items = []
        for _ in range(random.randint(1, 10)):
            items.append((incoming_id, random.choice(product_ids), random.randint(1, 100)))

        cur.executemany("INSERT INTO incoming_items (incoming_id, product_id, quantity) VALUES (%s, %s, %s)", items)

    for _ in range(COUNTS["outgoing"]):
        sql_head = "INSERT INTO outgoing (warehouse_id, date) VALUES (%s, %s) RETURNING id;"
        cur.execute(sql_head, (random.choice(warehouse_ids), fake.date_between(start_date="-1y", end_date="today")))
        outgoing_id = cur.fetchone()[0]

        items = []
        for _ in range(random.randint(1, 5)):
            items.append((outgoing_id, random.choice(product_ids), random.randint(1, 20)))

        cur.executemany("INSERT INTO outgoing_items (outgoing_id, product_id, quantity) VALUES (%s, %s, %s)", items)


def main():
    conn = None
    try:
        conn = get_conn()
        cur = conn.cursor()

        cat_ids = populate_categories(cur)
        wh_ids = populate_warehouses(cur)
        supp_ids = populate_suppliers(cur)
        prod_ids = populate_products(cur, cat_ids)

        populate_stock(cur, prod_ids, wh_ids)
        populate_movements(cur, supp_ids, wh_ids, prod_ids)

        conn.commit()
        print("Успешно заполнено!")

    except (Exception, psycopg2.DatabaseError) as error:
        print(f"Ошибка: {error}")
        if conn:
            conn.rollback()
    finally:
        if conn:
            cur.close()
            conn.close()


if __name__ == "__main__":
    main()
