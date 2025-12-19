-- сбрасывает кэшированные планы в сессии [web:28]
DISCARD PLANS;

SET track_io_timing = on;

CREATE TABLE IF NOT EXISTS explain_bench_log (
    id bigserial PRIMARY KEY,
    logged_at timestamptz NOT NULL DEFAULT now(),
    label text NOT NULL,
    plan_json jsonb NOT NULL
);

-- Универсальная обёртка: выполняет EXPLAIN ANALYZE и пишет JSON-план в лог [web:26]
CREATE OR REPLACE FUNCTION bench_explain_json(p_label text, p_query text)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  j json;
BEGIN
  EXECUTE 'EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) ' || p_query INTO j; -- FORMAT JSON: машинно-читаемый вывод [web:26]
  INSERT INTO explain_bench_log(label, plan_json) VALUES (p_label, j::jsonb);
END;
$$;

----------------------------------------------------------------------
-- 1) INCOMING: удалить индексы -> EXPLAIN -> создать индекс -> EXPLAIN
----------------------------------------------------------------------

-- Удаляем вторичные индексы incoming из вашего DDL [file:1]
DROP INDEX IF EXISTS idx_incoming_supplier_id;
-- [file:1]
DROP INDEX IF EXISTS idx_incoming_warehouse_id;
-- [file:1]
DROP INDEX IF EXISTS idx_incoming_date;
-- [file:1]

-- Обновить статистику (важно для честного плана) [web:32]
ANALYZE incoming;
-- [web:32]
ANALYZE incoming_items;
-- [web:32]
ANALYZE products;
-- [web:32]
ANALYZE suppliers;
-- [web:32]

-- “Сложный” запрос: фильтр по складу+периоду, join, агрегации, сортировка топа
SELECT bench_explain_json (
        'incoming:no_index', $q$
  WITH w AS (
    SELECT warehouse_id
    FROM incoming
    WHERE warehouse_id IS NOT NULL
    LIMIT 1
  ),
  b AS (
    SELECT max(date) AS d2, (max(date) - 30) AS d1
    FROM incoming
  )
  SELECT
    i.warehouse_id,
    i.supplier_id,
    p.id          AS product_id,
    p.name        AS product_name,
    sum(ii.quantity)                     AS total_qty,
    sum(ii.quantity * p.price::numeric)  AS total_amount
  FROM incoming i
  JOIN incoming_items ii ON ii.incoming_id = i.id
  JOIN products p        ON p.id = ii.product_id
  WHERE i.warehouse_id = (SELECT warehouse_id FROM w)
    AND i.date BETWEEN (SELECT d1 FROM b) AND (SELECT d2 FROM b)
  GROUP BY i.warehouse_id, i.supplier_id, p.id, p.name
  HAVING sum(ii.quantity) > 0
  ORDER BY total_amount DESC, total_qty DESC
  LIMIT 50
  $q$
    );

-- Создаём целевой индекс под типичный паттерн WHERE warehouse_id = ? AND date BETWEEN ... [web:26]
CREATE INDEX IF NOT EXISTS idx_incoming_warehouse_date ON incoming (warehouse_id, date);

ANALYZE incoming;
-- чтобы планировщик “увидел” индекс [web:32]
DISCARD PLANS;
-- на случай prepared statements [web:28]

SELECT bench_explain_json (
        'incoming:with_idx_incoming_warehouse_date', $q$
  WITH w AS (
    SELECT warehouse_id
    FROM incoming
    WHERE warehouse_id IS NOT NULL
    LIMIT 1
  ),
  b AS (
    SELECT max(date) AS d2, (max(date) - 30) AS d1
    FROM incoming
  )
  SELECT
    i.warehouse_id,
    i.supplier_id,
    p.id          AS product_id,
    p.name        AS product_name,
    sum(ii.quantity)                     AS total_qty,
    sum(ii.quantity * p.price::numeric)  AS total_amount
  FROM incoming i
  JOIN incoming_items ii ON ii.incoming_id = i.id
  JOIN products p        ON p.id = ii.product_id
  WHERE i.warehouse_id = (SELECT warehouse_id FROM w)
    AND i.date BETWEEN (SELECT d1 FROM b) AND (SELECT d2 FROM b)
  GROUP BY i.warehouse_id, i.supplier_id, p.id, p.name
  HAVING sum(ii.quantity) > 0
  ORDER BY total_amount DESC, total_qty DESC
  LIMIT 50
  $q$
    );

----------------------------------------------------------------------
-- 2) OUTGOING: удалить индексы -> EXPLAIN -> создать индекс -> EXPLAIN
----------------------------------------------------------------------

-- Удаляем вторичные индексы outgoing из вашего DDL [file:1]
DROP INDEX IF EXISTS idx_outgoing_warehouse_id;
-- [file:1]
DROP INDEX IF EXISTS idx_outgoing_date;
-- [file:1]

ANALYZE outgoing;
-- [web:32]
ANALYZE outgoing_items;
-- [web:32]
ANALYZE products;
-- [web:32]
ANALYZE warehouses;
-- [web:32]

SELECT bench_explain_json (
        'outgoing:no_index', $q$
  WITH w AS (
    SELECT warehouse_id
    FROM outgoing
    WHERE warehouse_id IS NOT NULL
    LIMIT 1
  ),
  b AS (
    SELECT max(date) AS d2, (max(date) - 30) AS d1
    FROM outgoing
  )
  SELECT
    o.warehouse_id,
    p.id     AS product_id,
    p.name   AS product_name,
    sum(oi.quantity)                    AS total_qty,
    sum(oi.quantity * p.price::numeric) AS total_amount
  FROM outgoing o
  JOIN outgoing_items oi ON oi.outgoing_id = o.id
  JOIN products p        ON p.id = oi.product_id
  WHERE o.warehouse_id = (SELECT warehouse_id FROM w)
    AND o.date BETWEEN (SELECT d1 FROM b) AND (SELECT d2 FROM b)
  GROUP BY o.warehouse_id, p.id, p.name
  ORDER BY total_qty DESC, total_amount DESC
  LIMIT 50
  $q$
    );

CREATE INDEX IF NOT EXISTS idx_outgoing_warehouse_date ON outgoing (warehouse_id, date);

ANALYZE outgoing;
-- [web:32]
DISCARD PLANS;
-- [web:28]

SELECT bench_explain_json (
        'outgoing:with_idx_outgoing_warehouse_date', $q$
  WITH w AS (
    SELECT warehouse_id
    FROM outgoing
    WHERE warehouse_id IS NOT NULL
    LIMIT 1
  ),
  b AS (
    SELECT max(date) AS d2, (max(date) - 30) AS d1
    FROM outgoing
  )
  SELECT
    o.warehouse_id,
    p.id     AS product_id,
    p.name   AS product_name,
    sum(oi.quantity)                    AS total_qty,
    sum(oi.quantity * p.price::numeric) AS total_amount
  FROM outgoing o
  JOIN outgoing_items oi ON oi.outgoing_id = o.id
  JOIN products p        ON p.id = oi.product_id
  WHERE o.warehouse_id = (SELECT warehouse_id FROM w)
    AND o.date BETWEEN (SELECT d1 FROM b) AND (SELECT d2 FROM b)
  GROUP BY o.warehouse_id, p.id, p.name
  ORDER BY total_qty DESC, total_amount DESC
  LIMIT 50
  $q$
    );

-- Посмотреть, что сохранилось (сравнивайте Execution Time / Planning Time внутри JSON)
-- SELECT id, logged_at, label, plan_json FROM explain_bench_log ORDER BY id;