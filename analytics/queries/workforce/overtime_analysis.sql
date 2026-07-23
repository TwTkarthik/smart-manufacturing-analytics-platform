-- Overtime is a derived metric. We can look at shift end times vs actual timestamps if available.
-- Given our schema, we'll approximate workforce capacity limits (e.g. > X inspections = highly utilized)
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.shift_code,
    w.total_inspections,
    -- Assume > 500 inspections a month implies overtime or high utilization
    CASE WHEN w.total_inspections > 500 THEN 'HIGH/OVERTIME' ELSE 'NORMAL' END AS utilization_status
FROM analytics_reporting.vw_active_workforce w
JOIN analytics.dim_employee e ON w.employee_id = e.employee_id
ORDER BY w.total_inspections DESC;
