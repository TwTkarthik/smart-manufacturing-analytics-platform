CREATE SCHEMA IF NOT EXISTS analytics_reporting;

-- Production Dashboard: Daily Machine OEE and Throughput
CREATE OR REPLACE VIEW analytics_reporting.vw_prod_daily_machine_stats AS
SELECT
    p.date_key,
    p.machine_id,
    p.machine_name,
    p.line_code,
    p.total_good_units AS throughput,
    p.total_scrap_units AS scrap,
    ROUND((p.quality_pct * 100)::numeric, 2) AS quality_rate,
    ROUND((p.performance_pct * 100)::numeric, 2) AS performance_rate,
    ROUND((p.availability_pct * 100)::numeric, 2) AS availability_rate,
    ROUND((p.quality_pct * p.performance_pct * p.availability_pct * 100)::numeric, 2) AS oee_pct,
    SUM(p.total_good_units) OVER (PARTITION BY p.machine_id ORDER BY p.date_key ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_7d_throughput
FROM analytics_reporting.mvw_daily_machine_performance p;
