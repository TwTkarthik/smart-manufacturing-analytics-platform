-- =============================================================================
-- 07_views.sql
-- SMAP Operational Database — Analytical Views
-- Provides pre-joined, pre-filtered views for common query patterns.
-- Run AFTER 06_indexes.sql.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- v_active_production_orders
-- All currently in-progress production orders with machine and product context.
-- Used by the real-time OEE dashboard to show live line status.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_active_production_orders AS
SELECT
    po.order_id,
    po.machine_id,
    m.machine_name,
    m.machine_type_code,
    m.line_code,
    m.plant_code,
    po.product_code,
    p.product_name,
    p.product_family,
    p.standard_cycle_time_sec,
    po.shift_code,
    po.operator_id,
    po.planned_start,
    po.actual_start,
    po.planned_units,
    po.actual_units,
    po.good_units,
    po.scrap_units,
    po.rework_units,
    -- Elapsed minutes since order started
    EXTRACT(EPOCH FROM (now() - po.actual_start)) / 60.0   AS elapsed_minutes,
    -- Real-time OEE Quality (partial — final quality set on completion)
    CASE
        WHEN po.actual_units > 0
        THEN ROUND((po.good_units::NUMERIC / po.actual_units), 5)
        ELSE NULL
    END AS oee_quality_realtime,
    -- Throughput rate (good units per hour so far)
    CASE
        WHEN po.actual_start IS NOT NULL AND po.actual_units > 0
        THEN ROUND(
            po.good_units::NUMERIC /
            NULLIF(EXTRACT(EPOCH FROM (now() - po.actual_start)) / 3600.0, 0),
            4)
        ELSE NULL
    END AS throughput_rate_per_hr_realtime
FROM production_orders po
JOIN machines m  ON m.machine_id   = po.machine_id
JOIN products p  ON p.product_code = po.product_code
WHERE po.status = 'In Progress';

COMMENT ON VIEW v_active_production_orders IS
    'Real-time view of in-progress production orders with machine and product context. '
    'Used by the live OEE dashboard. Refresh rate: poll every 30 seconds.';

-- ---------------------------------------------------------------------------
-- v_machine_downtime_summary
-- Rolling 30-day downtime summary per machine.
-- Used by the Maintenance & Reliability dashboard.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_machine_downtime_summary AS
SELECT
    de.machine_id,
    m.machine_name,
    m.machine_type_code,
    m.line_code,
    m.plant_code,
    COUNT(*)                                                AS total_events,
    COUNT(*) FILTER (WHERE de.is_planned = FALSE)          AS unplanned_events,
    COUNT(*) FILTER (WHERE de.is_planned = TRUE)           AS planned_events,
    COALESCE(SUM(de.downtime_minutes), 0)                  AS total_downtime_min,
    COALESCE(SUM(de.downtime_minutes) FILTER (WHERE de.is_planned = FALSE), 0)
                                                           AS unplanned_downtime_min,
    COALESCE(SUM(de.downtime_minutes) FILTER (WHERE de.is_planned = TRUE), 0)
                                                           AS planned_downtime_min,
    ROUND(
        COALESCE(SUM(de.downtime_minutes) FILTER (WHERE de.is_planned = FALSE), 0)
        / NULLIF(COUNT(*) FILTER (WHERE de.is_planned = FALSE), 0),
        2)                                                 AS avg_mttr_minutes,
    now() - INTERVAL '30 days'                             AS window_start,
    now()                                                  AS window_end
FROM downtime_events de
JOIN machines m ON m.machine_id = de.machine_id
WHERE de.downtime_start >= now() - INTERVAL '30 days'
GROUP BY de.machine_id, m.machine_name, m.machine_type_code, m.line_code, m.plant_code;

COMMENT ON VIEW v_machine_downtime_summary IS
    'Rolling 30-day downtime summary per machine. '
    'Used by Maintenance & Reliability dashboard. '
    'Includes MTTR, planned vs. unplanned split, and total downtime minutes.';

-- ---------------------------------------------------------------------------
-- v_sensor_anomaly_alerts
-- Most recent anomaly-flagged sensor readings per machine (last 24 hours).
-- Used by the real-time alert panel.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_sensor_anomaly_alerts AS
SELECT
    sr.machine_id,
    m.machine_name,
    m.line_code,
    sr.sensor_type,
    sr.sensor_unit,
    sr.value,
    sr.reading_timestamp,
    sr.data_quality_score,
    -- Rank most recent anomaly per machine per sensor type
    ROW_NUMBER() OVER (
        PARTITION BY sr.machine_id, sr.sensor_type
        ORDER BY sr.reading_timestamp DESC
    ) AS recency_rank
FROM sensor_readings sr
JOIN machines m ON m.machine_id = sr.machine_id
WHERE sr.is_anomaly_flagged = TRUE
  AND sr.reading_timestamp >= now() - INTERVAL '24 hours';

COMMENT ON VIEW v_sensor_anomaly_alerts IS
    'Anomaly-flagged sensor readings in the last 24 hours, ranked most recent first per machine+sensor. '
    'Consumers should filter WHERE recency_rank = 1 for the latest alert per sensor type.';

-- ---------------------------------------------------------------------------
-- v_quality_defect_summary
-- Rolling 7-day defect rate summary per machine.
-- Used by the Quality Control dashboard Pareto panel.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_quality_defect_summary AS
SELECT
    qi.machine_id,
    m.machine_name,
    m.line_code,
    qi.defect_type_code,
    dt.defect_type_name,
    dt.defect_category,
    dt.severity_level,
    COUNT(*)                                               AS inspection_count,
    SUM(qi.sample_size)                                    AS total_sampled,
    SUM(qi.defects_found)                                  AS total_defects,
    ROUND(
        SUM(qi.defects_found)::NUMERIC /
        NULLIF(SUM(qi.sample_size), 0) * 100,
        4)                                                 AS defect_rate_pct,
    ROUND(
        SUM(qi.defects_found)::NUMERIC /
        NULLIF(SUM(qi.sample_size), 0) * 1000000,
        2)                                                 AS defect_rate_ppm,
    COUNT(*) FILTER (WHERE qi.pass_fail = 'P')             AS lots_passed,
    COUNT(*) FILTER (WHERE qi.pass_fail = 'F')             AS lots_failed,
    now() - INTERVAL '7 days'                              AS window_start,
    now()                                                  AS window_end
FROM quality_inspections qi
JOIN machines m     ON m.machine_id       = qi.machine_id
LEFT JOIN defect_types dt ON dt.defect_type_code = qi.defect_type_code
WHERE qi.inspection_timestamp >= now() - INTERVAL '7 days'
GROUP BY qi.machine_id, m.machine_name, m.line_code,
         qi.defect_type_code, dt.defect_type_name, dt.defect_category, dt.severity_level;

COMMENT ON VIEW v_quality_defect_summary IS
    'Rolling 7-day quality defect rate summary per machine and defect type. '
    'Supports Pareto chart analysis on the Quality Control dashboard. '
    'NULL defect_type_code rows represent inspections with no assigned defect code.';

-- ---------------------------------------------------------------------------
-- v_pm_compliance_status
-- Current PM compliance status per machine — overdue, due, or compliant.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_pm_compliance_status AS
SELECT
    ps.pm_schedule_id,
    ps.machine_id,
    m.machine_name,
    m.line_code,
    ps.pm_type,
    ps.interval_days,
    ps.last_performed_date,
    ps.next_due_date,
    CURRENT_DATE - ps.next_due_date                        AS days_overdue,
    CASE
        WHEN ps.next_due_date IS NULL                       THEN 'Unknown'
        WHEN CURRENT_DATE > ps.next_due_date + 3            THEN 'Overdue'
        WHEN CURRENT_DATE >= ps.next_due_date - 3           THEN 'Due Soon'
        ELSE 'Compliant'
    END                                                    AS compliance_status,
    ps.is_active
FROM pm_schedules ps
JOIN machines m ON m.machine_id = ps.machine_id
WHERE ps.is_active = TRUE;

COMMENT ON VIEW v_pm_compliance_status IS
    'Current PM compliance status per active schedule. '
    'Overdue: past due date by more than 3 days. Due Soon: within 3 days of due date. '
    'Used by the Maintenance dashboard PM compliance KPI card.';
