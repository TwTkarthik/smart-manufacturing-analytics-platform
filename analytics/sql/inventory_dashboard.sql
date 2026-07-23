CREATE SCHEMA IF NOT EXISTS analytics_reporting;

-- Inventory Dashboard: Turnover and Stock Levels
CREATE OR REPLACE VIEW analytics_reporting.vw_inv_turnover_analysis AS
WITH monthly_issues AS (
    SELECT
        p.product_id,
        d.year,
        d.month,
        SUM(i.quantity) AS total_issued
    FROM analytics.fact_inventory i
    JOIN analytics.dim_product p ON i.product_key = p.product_key
    JOIN analytics.dim_date d ON i.date_key = d.date_key
    WHERE i.movement_type = 'ISSUE'
    GROUP BY p.product_id, d.year, d.month
),
current_stock AS (
    SELECT product_id, current_stock_level
    FROM analytics_reporting.vw_current_inventory_status
)
SELECT
    m.product_id,
    m.year,
    m.month,
    m.total_issued,
    c.current_stock_level,
    CASE 
        WHEN m.total_issued > 0 THEN ROUND((c.current_stock_level::numeric / m.total_issued) * 30, 1)
        ELSE 999 
    END AS estimated_days_of_inventory
FROM monthly_issues m
JOIN current_stock c ON m.product_id = c.product_id;
