CREATE SCHEMA IF NOT EXISTS analytics_reporting;

-- Maintenance Dashboard: Machine Reliability
CREATE OR REPLACE VIEW analytics_reporting.vw_maint_reliability_trends AS
SELECT
    m.machine_id,
    m.machine_name,
    d.year,
    d.month,
    COUNT(fm.log_id) AS breakdown_frequency,
    SUM(fm.downtime_minutes) AS total_downtime,
    SUM(fm.parts_cost) AS total_maintenance_cost,
    -- MTTR calculation per machine per month
    ROUND((SUM(fm.downtime_minutes)::numeric / NULLIF(COUNT(fm.log_id), 0)) / 60.0, 2) AS avg_mttr_hours
FROM analytics.fact_maintenance fm
JOIN analytics.dim_machine m ON fm.machine_key = m.machine_key
JOIN analytics.dim_date d ON fm.date_key = d.date_key
GROUP BY m.machine_id, m.machine_name, d.year, d.month;
