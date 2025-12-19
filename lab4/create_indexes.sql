create index idx_categories_name on categories (name);

create index idx_products_name on products (name);

create index idx_products_category_id on products (category_id);

create index idx_suppliers_name on suppliers (name);

create index idx_warehouses_name on warehouses (name);

create index idx_incoming_supplier_id on incoming (supplier_id);

create index idx_incoming_warehouse_id on incoming (warehouse_id);

create index idx_incoming_date on incoming (date);

create index idx_incoming_items_incoming_id on incoming_items (incoming_id);

create index idx_incoming_items_product_id on incoming_items (product_id);

create index idx_outgoing_warehouse_id on outgoing (warehouse_id);

create index idx_outgoing_date on outgoing (date);

create index idx_outgoing_items_outgoing_id on outgoing_items (outgoing_id);

create index idx_outgoing_items_product_id on outgoing_items (product_id);

create index idx_stock_warehouse_id on stock (warehouse_id);

-- триграмм
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- GIN + trigram
CREATE INDEX IF NOT EXISTS idx_categories_name_trgm ON categories USING gin (name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_products_name_trgm ON products USING gin (name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_products_article_trgm ON products USING gin (article gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_products_description_trgm ON products USING gin (description gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_suppliers_name_trgm ON suppliers USING gin (name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_suppliers_contact_trgm ON suppliers USING gin (contact gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_warehouses_name_trgm ON warehouses USING gin (name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_warehouses_address_trgm ON warehouses USING gin (address gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_stock_location_code_trgm ON stock USING gin (location_code gin_trgm_ops);

-- продукты: фильтры/сортировка по цене и габаритам
CREATE INDEX IF NOT EXISTS idx_products_price ON products (price);

CREATE INDEX IF NOT EXISTS idx_products_weight_kg ON products (weight_kg)
WHERE
    weight_kg IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_products_volume_m3 ON products (volume_m3)
WHERE
    volume_m3 IS NOT NULL;

-- склады: фильтр/сортировка по ёмкости
CREATE INDEX IF NOT EXISTS idx_warehouses_capacity_m3 ON warehouses (capacity_m3)
WHERE
    capacity_m3 IS NOT NULL;

-- stock: быстрый поиск дефицитов
CREATE INDEX IF NOT EXISTS idx_stock_low_balance ON stock (warehouse_id, product_id)
WHERE
    quantity < min_balance;

-- ускоряет join/группировку позиций внутри документа
CREATE INDEX IF NOT EXISTS idx_incoming_items_incoming_product ON incoming_items (incoming_id, product_id);

CREATE INDEX IF NOT EXISTS idx_outgoing_items_outgoing_product ON outgoing_items (outgoing_id, product_id);

-- ускоряет агрегации "по товару" (когда входящий/исходящий документ — вторичный фильтр)
CREATE INDEX IF NOT EXISTS idx_incoming_items_product_incoming ON incoming_items (product_id, incoming_id);

CREATE INDEX IF NOT EXISTS idx_outgoing_items_product_outgoing ON outgoing_items (product_id, outgoing_id);

-- incoming: выборки по складу/поставщику + сортировка по дате
CREATE INDEX IF NOT EXISTS idx_incoming_warehouse_date_desc ON incoming (warehouse_id, date DESC);

CREATE INDEX IF NOT EXISTS idx_incoming_supplier_date_desc ON incoming (supplier_id, date DESC);

-- outgoing: выборки по складу + сортировка по дате
CREATE INDEX IF NOT EXISTS idx_outgoing_warehouse_date_desc ON outgoing (warehouse_id, date DESC);