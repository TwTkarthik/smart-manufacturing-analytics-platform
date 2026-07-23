CREATE SCHEMA IF NOT EXISTS analytics_reporting;

-- Workforce Dashboard: Operator Performance
CREATE OR REPLACE VIEW analytics_reporting.vw_workforce_performance AS
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.shift_code,
    d.year,
    d.month,
    COUNT(q.inspection_id) AS inspections_performed,
    SUM(CASE WHEN q.inspection_passed THEN 1 ELSE 0 END) AS passed_inspections,
    ROUND((SUM(CASE WHEN q.inspection_passed THEN 1 ELSE 0 END)::numeric / NULLIF(COUNT(q.inspection_id), 0) * 100)::numeric, 2) AS quality_yield_by_operator
FROM analytics.fact_quality q
JOIN analytics.dim_employee e ON q.inspector_key = e.employee_key
JOIN analytics.dim_date d ON q.date_key = d.date_key
GROUP BY e.employee_id, e.first_name, e.last_name, e.shift_code, d.year, d.month;
