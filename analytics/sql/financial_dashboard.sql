CREATE SCHEMA IF NOT EXISTS analytics_reporting;

-- Financial Dashboard: Profitability Trends
CREATE OR REPLACE VIEW analytics_reporting.vw_fin_profitability_trend AS
SELECT
    year,
    month,
    total_revenue,
    total_production_cost,
    total_maintenance_cost,
    gross_margin,
    ROUND((gross_margin / NULLIF(total_revenue, 0) * 100)::numeric, 2) AS gross_margin_pct,
    SUM(gross_margin) OVER (PARTITION BY year ORDER BY month) AS ytd_gross_margin
FROM analytics_reporting.mvw_monthly_financial_summary;
