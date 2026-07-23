CREATE SCHEMA IF NOT EXISTS analytics_reporting;

-- Executive Dashboard: Plant Performance summary
CREATE OR REPLACE VIEW analytics_reporting.vw_exec_plant_performance AS
SELECT
    d.year,
    d.month,
    SUM(fp.good_units) AS total_good_units,
    SUM(fp.scrap_units) AS total_scrap_units,
    ROUND((SUM(fp.good_units)::numeric / NULLIF(SUM(fp.actual_units), 0) * 100)::numeric, 2) AS plant_yield_pct,
    COUNT(DISTINCT fp.machine_key) AS active_machines
FROM analytics.fact_production fp
JOIN analytics.dim_date d ON fp.date_key = d.date_key
GROUP BY d.year, d.month
ORDER BY d.year DESC, d.month DESC;
