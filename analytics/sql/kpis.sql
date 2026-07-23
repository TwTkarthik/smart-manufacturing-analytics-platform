CREATE SCHEMA IF NOT EXISTS analytics_reporting;

-- ==============================================================================
-- STANDARDIZED KPIs
-- Functions / Views for top-level business metrics
-- ==============================================================================

-- KPI: Overall Equipment Effectiveness (OEE) YTD
CREATE OR REPLACE VIEW analytics_reporting.kpi_oee_ytd AS
WITH ytd_data AS (
    SELECT
        SUM(availability_pct * total_planned_units) / NULLIF(SUM(total_planned_units), 0) AS avg_availability,
        SUM(performance_pct * total_planned_units) / NULLIF(SUM(total_planned_units), 0) AS avg_performance,
        SUM(quality_pct * total_planned_units) / NULLIF(SUM(total_planned_units), 0) AS avg_quality
    FROM analytics_reporting.mvw_daily_machine_performance p
    JOIN analytics.dim_date d ON p.date_key = d.date_key
    WHERE d.year = EXTRACT(YEAR FROM CURRENT_DATE)
)
SELECT
    ROUND((avg_availability * avg_performance * avg_quality * 100)::numeric, 2) AS oee_ytd_pct,
    ROUND((avg_availability * 100)::numeric, 2) AS availability_ytd_pct,
    ROUND((avg_performance * 100)::numeric, 2) AS performance_ytd_pct,
    ROUND((avg_quality * 100)::numeric, 2) AS quality_ytd_pct
FROM ytd_data;

-- KPI: Plant First Pass Yield (FPY) YTD
CREATE OR REPLACE VIEW analytics_reporting.kpi_fpy_ytd AS
SELECT
    ROUND((SUM(good_units)::numeric / NULLIF(SUM(actual_units), 0) * 100)::numeric, 2) AS first_pass_yield_pct
FROM analytics.fact_production p
JOIN analytics.dim_date d ON p.date_key = d.date_key
WHERE d.year = EXTRACT(YEAR FROM CURRENT_DATE);

-- KPI: Mean Time Between Failures (MTBF) & Mean Time To Repair (MTTR) YTD
-- Approximation based on downtime instances vs available time
CREATE OR REPLACE VIEW analytics_reporting.kpi_reliability_ytd AS
WITH metrics AS (
    SELECT
        COUNT(log_id) AS failure_count,
        SUM(downtime_minutes) AS total_downtime_minutes,
        (COUNT(DISTINCT machine_key) * 365 * 24 * 60) AS total_operational_minutes_approx
    FROM analytics.fact_maintenance m
    JOIN analytics.dim_date d ON m.date_key = d.date_key
    WHERE d.year = EXTRACT(YEAR FROM CURRENT_DATE)
)
SELECT
    -- MTBF in hours
    ROUND(((total_operational_minutes_approx - total_downtime_minutes) / NULLIF(failure_count, 0) / 60.0)::numeric, 2) AS mtbf_hours,
    -- MTTR in hours
    ROUND((total_downtime_minutes / NULLIF(failure_count, 0) / 60.0)::numeric, 2) AS mttr_hours
FROM metrics;
