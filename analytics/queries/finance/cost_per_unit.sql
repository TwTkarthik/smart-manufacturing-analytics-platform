-- Calculate Cost per Unit produced (monthly)
SELECT
    year,
    month,
    total_production_cost,
    (SELECT SUM(total_actual_units) FROM analytics_reporting.mvw_daily_machine_performance p JOIN analytics.dim_date d ON p.date_key = d.date_key WHERE d.year = f.year AND d.month = f.month) AS total_units_produced,
    ROUND((total_production_cost / NULLIF((SELECT SUM(total_actual_units) FROM analytics_reporting.mvw_daily_machine_performance p JOIN analytics.dim_date d ON p.date_key = d.date_key WHERE d.year = f.year AND d.month = f.month), 0))::numeric, 2) AS cost_per_unit
FROM analytics_reporting.mvw_monthly_financial_summary f
ORDER BY year DESC, month DESC;
