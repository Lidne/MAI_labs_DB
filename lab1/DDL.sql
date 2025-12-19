create table categories (
    id uuid primary key default gen_random_uuid (),
    name text not null
);

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

create table suppliers (
    id uuid primary key default gen_random_uuid (),
    name text not null,
    contact text
);

create table warehouses (
    id uuid primary key default gen_random_uuid (),
    name text not null,
    address text,
    capacity_m3 numeric(12, 2)
);

create table incoming (
    id uuid primary key default gen_random_uuid (),
    supplier_id uuid references suppliers (id),
    warehouse_id uuid references warehouses (id),
    date date not null
);

create table incoming_items (
    id uuid primary key default gen_random_uuid (),
    incoming_id uuid references incoming (id) on delete cascade,
    product_id uuid references products (id),
    quantity int not null
);

create table outgoing (
    id uuid primary key default gen_random_uuid (),
    warehouse_id uuid references warehouses (id),
    date date not null
);

create table outgoing_items (
    id uuid primary key default gen_random_uuid (),
    outgoing_id uuid references outgoing (id) on delete cascade,
    product_id uuid references products (id),
    quantity int not null
);

create table stock (
    product_id uuid references products (id),
    warehouse_id uuid references warehouses (id),
    quantity int not null,
    min_balance int default 0,
    location_code text,
    primary key (product_id, warehouse_id)
);