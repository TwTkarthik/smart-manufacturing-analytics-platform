-- Estimate stockout risk based on current inventory and moving average of usage
WITH daily_usage AS (
    SELECT
        product_key,
        date_key,
        SUM(quantity) AS daily_qty_issued
    FROM analytics.fact_inventory
    WHERE movement_type = 'ISSUE'
    GROUP BY product_key, date_key
),
avg_usage AS (
    SELECT
        product_key,
        AVG(daily_qty_issued) AS avg_daily_usage
    FROM daily_usage
    WHERE date_key >= CAST(TO_CHAR(CURRENT_DATE - INTERVAL '30 days', 'YYYYMMDD') AS INT)
    GROUP BY product_key
)
SELECT
    p.product_id,
    p.product_name,
    c.current_stock_level,
    u.avg_daily_usage,
    CASE 
        WHEN u.avg_daily_usage > 0 THEN ROUND((c.current_stock_level / u.avg_daily_usage)::numeric, 1)
        ELSE 999 
    END AS estimated_days_until_stockout
FROM analytics_reporting.vw_current_inventory_status c
JOIN analytics.dim_product p ON c.product_id = p.product_id
JOIN avg_usage u ON p.product_key = u.product_key
ORDER BY estimated_days_until_stockout ASC;
