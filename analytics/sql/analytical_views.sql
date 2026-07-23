CREATE SCHEMA IF NOT EXISTS analytics_reporting;

-- ==============================================================================
-- ANALYTICAL VIEWS
-- Real-time lightweight views for dashboard drill-downs
-- ==============================================================================

-- 1. Current Inventory Status (Running Totals)
CREATE OR REPLACE VIEW analytics_reporting.vw_current_inventory_status AS
SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(CASE 
        WHEN i.movement_type = 'RECEIPT' THEN i.quantity
        WHEN i.movement_type = 'ISSUE' THEN -i.quantity
        WHEN i.movement_type = 'ADJUSTMENT' THEN i.quantity
        ELSE 0 
    END) AS current_stock_level,
    MAX(d.full_date) AS last_movement_date
FROM analytics.fact_inventory i
JOIN analytics.dim_product p ON i.product_key = p.product_key
JOIN analytics.dim_date d ON i.date_key = d.date_key
GROUP BY p.product_id, p.product_name, p.category;

-- 2. Active Workforce
CREATE OR REPLACE VIEW analytics_reporting.vw_active_workforce AS
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.role,
    e.shift_code,
    COUNT(q.inspection_id) AS total_inspections,
    SUM(CASE WHEN q.inspection_passed THEN 1 ELSE 0 END) AS passed_inspections
FROM analytics.dim_employee e
LEFT JOIN analytics.fact_quality q ON e.employee_key = q.inspector_key
WHERE e.is_current = true
GROUP BY e.employee_id, e.first_name, e.last_name, e.role, e.shift_code;
