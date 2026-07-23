-- Track rework impact (assuming 'REWORK' is a defect type or failure mode)
SELECT
    p.product_name,
    COUNT(q.inspection_id) AS total_inspections,
    COUNT(CASE WHEN q.defect_type_code = 'REWORK' THEN 1 END) AS rework_instances,
    ROUND((COUNT(CASE WHEN q.defect_type_code = 'REWORK' THEN 1 END)::numeric / NULLIF(COUNT(q.inspection_id), 0) * 100)::numeric, 2) AS rework_pct
FROM analytics.fact_quality q
JOIN analytics.dim_product p ON q.product_key = p.product_key
GROUP BY p.product_name
ORDER BY rework_pct DESC;
