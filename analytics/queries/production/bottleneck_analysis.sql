-- Identify the lowest performing machine by OEE over the last 30 days
SELECT
    machine_name,
    line_code,
    AVG(oee_pct) AS avg_oee,
    AVG(availability_rate) AS avg_availability,
    AVG(performance_rate) AS avg_performance,
    AVG(quality_rate) AS avg_quality
FROM analytics_reporting.vw_prod_daily_machine_stats
WHERE date_key >= CAST(TO_CHAR(CURRENT_DATE - INTERVAL '30 days', 'YYYYMMDD') AS INT)
GROUP BY machine_name, line_code
ORDER BY avg_oee ASC
LIMIT 5;
