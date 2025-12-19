SELECT
    w.name AS warehouse_name,
    w.capacity_m3,
    SUM(
        s.quantity * COALESCE(p.volume_m3, 0)
    ) AS occupied_m3,
    COUNT(*) FILTER (
        WHERE
            s.quantity < s.min_balance
    ) AS below_min_cnt
FROM
    warehouses w
    LEFT JOIN stock s ON s.warehouse_id = w.id
    LEFT JOIN products p ON p.id = s.product_id
GROUP BY
    w.id,
    w.name,
    w.capacity_m3
ORDER BY occupied_m3 DESC NULLS LAST;