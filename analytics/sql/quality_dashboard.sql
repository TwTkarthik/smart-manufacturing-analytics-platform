CREATE SCHEMA IF NOT EXISTS analytics_reporting;

-- Quality Dashboard: Defect Rates and Trends
CREATE OR REPLACE VIEW analytics_reporting.vw_qual_defect_analysis AS
SELECT
    p.product_name,
    p.category,
    d.year,
    d.month,
    COUNT(q.inspection_id) AS total_inspections,
    SUM(CASE WHEN q.inspection_passed = false THEN 1 ELSE 0 END) AS total_defects,
    ROUND((SUM(CASE WHEN q.inspection_passed = false THEN 1 ELSE 0 END)::numeric / NULLIF(COUNT(q.inspection_id), 0) * 100)::numeric, 2) AS defect_rate_pct,
    -- Top defect reason for this month/product
    MODE() WITHIN GROUP (ORDER BY q.defect_type_code) AS most_common_defect
FROM analytics.fact_quality q
JOIN analytics.dim_product p ON q.product_key = p.product_key
JOIN analytics.dim_date d ON q.date_key = d.date_key
GROUP BY p.product_name, p.category, d.year, d.month;
