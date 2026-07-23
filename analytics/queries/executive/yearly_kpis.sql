-- Aggregated Yearly KPIs for Executive Review
SELECT
    d.year,
    SUM(fp.good_units) AS total_production,
    ROUND((SUM(fp.good_units)::numeric / NULLIF(SUM(fp.actual_units), 0) * 100)::numeric, 2) AS yearly_yield_pct,
    -- Need to grab from financials view for revenue
    MAX(f.ytd_gross_margin) AS total_gross_margin
FROM analytics.fact_production fp
JOIN analytics.dim_date d ON fp.date_key = d.date_key
LEFT JOIN analytics_reporting.vw_fin_profitability_trend f ON d.year = f.year AND d.month = f.month
GROUP BY d.year
ORDER BY d.year DESC;
