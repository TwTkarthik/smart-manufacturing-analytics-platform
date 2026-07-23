-- Breakdown frequency and PM (Preventive Maintenance) Compliance
-- Assumes 'PM' is a maintenance type.
SELECT
    m.machine_id,
    m.machine_name,
    COUNT(CASE WHEN fm.maintenance_type = 'PREVENTIVE' THEN 1 END) AS pm_count,
    COUNT(CASE WHEN fm.maintenance_type = 'BREAKDOWN' THEN 1 END) AS breakdown_count,
    ROUND((COUNT(CASE WHEN fm.maintenance_type = 'PREVENTIVE' THEN 1 END)::numeric / NULLIF(COUNT(fm.log_id), 0) * 100)::numeric, 2) AS pm_compliance_pct
FROM analytics.fact_maintenance fm
JOIN analytics.dim_machine m ON fm.machine_key = m.machine_key
GROUP BY m.machine_id, m.machine_name
ORDER BY pm_compliance_pct ASC;
