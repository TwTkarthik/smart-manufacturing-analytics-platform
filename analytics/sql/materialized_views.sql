CREATE SCHEMA IF NOT EXISTS analytics_reporting;

-- ==============================================================================
-- MATERIALIZED VIEWS
-- Heavy aggregations pre-calculated for dashboard performance
-- ==============================================================================

-- 1. Daily Machine Performance (OEE Components)
CREATE MATERIALIZED VIEW IF NOT EXISTS analytics_reporting.mvw_daily_machine_performance AS
WITH prod_agg AS (
    SELECT
        date_key,
        machine_key,
        SUM(planned_units) AS total_planned_units,
        SUM(actual_units) AS total_actual_units,
        SUM(good_units) AS total_good_units,
        SUM(scrap_units) AS total_scrap_units
    FROM analytics.fact_production
    GROUP BY date_key, machine_key
),
maint_agg AS (
    SELECT
        date_key,
        machine_key,
        SUM(downtime_minutes) AS total_downtime_minutes
    FROM analytics.fact_maintenance
    GROUP BY date_key, machine_key
)
SELECT
    p.date_key,
    p.machine_key,
    m.machine_id,
    m.machine_name,
    m.line_code,
    p.total_planned_units,
    p.total_actual_units,
    p.total_good_units,
    p.total_scrap_units,
    COALESCE(ma.total_downtime_minutes, 0) AS total_downtime_minutes,
    -- Simple Availability (assuming 24h = 1440m available time per day)
    GREATEST(0, (1440.0 - COALESCE(ma.total_downtime_minutes, 0)) / 1440.0) AS availability_pct,
    -- Simple Performance
    CASE WHEN p.total_planned_units > 0 THEN (p.total_actual_units::numeric / p.total_planned_units::numeric) ELSE 0 END AS performance_pct,
    -- Simple Quality
    CASE WHEN p.total_actual_units > 0 THEN (p.total_good_units::numeric / p.total_actual_units::numeric) ELSE 0 END AS quality_pct
FROM prod_agg p
JOIN analytics.dim_machine m ON p.machine_key = m.machine_key
LEFT JOIN maint_agg ma ON p.date_key = ma.date_key AND p.machine_key = ma.machine_key;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mvw_dmp ON analytics_reporting.mvw_daily_machine_performance (date_key, machine_key);


-- 2. Monthly Financial Summary
CREATE MATERIALIZED VIEW IF NOT EXISTS analytics_reporting.mvw_monthly_financial_summary AS
SELECT
    d.year,
    d.month,
    SUM(p.total_good_units * pr.unit_price) AS estimated_revenue,
    SUM(p.total_actual_units * (pr.unit_price * 0.6)) AS estimated_production_cost, -- Mocking base production cost as 60% of price
    SUM(COALESCE(m.total_parts_cost, 0)) AS total_maintenance_cost,
    (SUM(p.total_good_units * pr.unit_price) - SUM(p.total_actual_units * (pr.unit_price * 0.6)) - SUM(COALESCE(m.total_parts_cost, 0))) AS gross_margin
FROM analytics_reporting.mvw_daily_machine_performance p
JOIN analytics.dim_date d ON p.date_key = d.date_key
-- Note: We need a product relationship, this aggregates across all products per machine per day.
-- To be precise financially, we should aggregate fact_production directly with dim_product.
-- Let's do it correctly below:
WITH prod_rev AS (
    SELECT
        fp.date_key,
        SUM(fp.good_units * dp.unit_price) AS revenue,
        SUM(fp.actual_units * (dp.unit_price * 0.6)) AS production_cost
    FROM analytics.fact_production fp
    JOIN analytics.dim_product dp ON fp.product_key = dp.product_key
    GROUP BY fp.date_key
),
maint_cost AS (
    SELECT
        date_key,
        SUM(parts_cost) AS maintenance_cost
    FROM analytics.fact_maintenance
    GROUP BY date_key
)
SELECT
    d.year,
    d.month,
    SUM(pr.revenue) AS total_revenue,
    SUM(pr.production_cost) AS total_production_cost,
    SUM(COALESCE(mc.maintenance_cost, 0)) AS total_maintenance_cost,
    SUM(pr.revenue - pr.production_cost - COALESCE(mc.maintenance_cost, 0)) AS gross_margin
FROM prod_rev pr
JOIN analytics.dim_date d ON pr.date_key = d.date_key
LEFT JOIN maint_cost mc ON pr.date_key = mc.date_key
GROUP BY d.year, d.month;
