create table categories (
    id uuid primary key default gen_random_uuid (),
    name text not null
);

create index idx_categories_name on categories (name);

create table products (
    id uuid primary key default gen_random_uuid (),
    name text not null,
    article text unique,
    description text,
    weight_kg numeric(10, 3),
    volume_m3 numeric(10, 4),
    price real not null,
    category_id uuid references categories (id)
);

create index idx_products_name on products (name);

create index idx_products_category_id on products (category_id);

create table suppliers (
    id uuid primary key default gen_random_uuid (),
    name text not null,
    contact text
);

create index idx_suppliers_name on suppliers (name);

create table warehouses (
    id uuid primary key default gen_random_uuid (),
    name text not null,
    address text,
    capacity_m3 numeric(12, 2)
);

create index idx_warehouses_name on warehouses (name);

create table incoming (
    id uuid primary key default gen_random_uuid (),
    supplier_id uuid references suppliers (id),
    warehouse_id uuid references warehouses (id),
    date date not null
);

create index idx_incoming_supplier_id on incoming (supplier_id);

create index idx_incoming_warehouse_id on incoming (warehouse_id);

create index idx_incoming_date on incoming (date);

create table incoming_items (
    id uuid primary key default gen_random_uuid (),
    incoming_id uuid references incoming (id) on delete cascade,
    product_id uuid references products (id),
    quantity int not null
);

create index idx_incoming_items_incoming_id on incoming_items (incoming_id);

create index idx_incoming_items_product_id on incoming_items (product_id);

create table outgoing (
    id uuid primary key default gen_random_uuid (),
    warehouse_id uuid references warehouses (id),
    date date not null
);

create index idx_outgoing_warehouse_id on outgoing (warehouse_id);

create index idx_outgoing_date on outgoing (date);

create table outgoing_items (
    id uuid primary key default gen_random_uuid (),
    outgoing_id uuid references outgoing (id) on delete cascade,
    product_id uuid references products (id),
    quantity int not null
);

create index idx_outgoing_items_outgoing_id on outgoing_items (outgoing_id);

create index idx_outgoing_items_product_id on outgoing_items (product_id);

create table stock (
    product_id uuid references products (id),
    warehouse_id uuid references warehouses (id),
    quantity int not null,
    min_balance int default 0,
    location_code text,
    
    primary key (product_id, warehouse_id)
);

create index idx_stock_product_id on stock (product_id);

create index idx_stock_warehouse_id on stock (warehouse_id);