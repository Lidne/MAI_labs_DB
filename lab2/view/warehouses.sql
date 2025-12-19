CREATE OR REPLACE VIEW vw_warehouse_utilization_activity AS
WITH
    stock_agg AS (
        SELECT
            s.warehouse_id,
            COALESCE(SUM(s.quantity), 0) AS total_units,
            COALESCE(
                SUM(
                    s.quantity * COALESCE(p.volume_m3, 0)
                ),
                0
            )::numeric(14, 4) AS occupied_m3,
            COUNT(*) FILTER (
                WHERE
                    s.quantity < s.min_balance
            ) AS below_min_cnt
        FROM stock s
            LEFT JOIN products p ON p.id = s.product_id
        GROUP BY
            s.warehouse_id
    ),
    in_agg AS (
        SELECT
            warehouse_id,
            MAX(date) AS last_incoming_date
        FROM incoming
        GROUP BY
            warehouse_id
    ),
    out_agg AS (
        SELECT
            warehouse_id,
            MAX(date) AS last_outgoing_date
        FROM outgoing
        GROUP BY
            warehouse_id
    )
SELECT
    w.id AS warehouse_id,
    w.name AS warehouse_name,
    w.capacity_m3,
    COALESCE(sa.total_units, 0) AS total_units,
    COALESCE(sa.occupied_m3, 0)::numeric(14, 4) AS occupied_m3,
    CASE
        WHEN w.capacity_m3 IS NULL
        OR w.capacity_m3 = 0 THEN NULL
        ELSE (
            COALESCE(sa.occupied_m3, 0) / w.capacity_m3 * 100
        )::numeric(7, 2)
    END AS fill_percent,
    COALESCE(sa.below_min_cnt, 0) AS below_min_cnt,
    ia.last_incoming_date,
    oa.last_outgoing_date
FROM
    warehouses w
    LEFT JOIN stock_agg sa ON sa.warehouse_id = w.id
    LEFT JOIN in_agg ia ON ia.warehouse_id = w.id
    LEFT JOIN out_agg oa ON oa.warehouse_id = w.id;

SELECT * FROM vw_warehouse_utilization_activity;