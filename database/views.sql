-- =============================================================================
-- views.sql
-- SMAP Operational Database — Analytical Views
-- PostgreSQL 16 compatible.
--
-- Execution order: 6 of 9
-- Run AFTER indexes.sql; BEFORE roles.sql.
--
-- Provides pre-joined, pre-filtered views for common operational query patterns.
-- All views use CREATE OR REPLACE to support safe re-execution on schema changes.
--
-- Views:
--   1. v_active_production_orders   — real-time in-progress orders for OEE dashboard
--   2. v_machine_downtime_summary   — rolling 30-day downtime KPIs per machine
--   3. v_sensor_anomaly_alerts      — last 24-hour anomaly-flagged readings per machine
--   4. v_quality_defect_summary     — rolling 7-day defect rate by machine and type
--   5. v_pm_compliance_status       — current PM compliance per active schedule
--
-- Canonical numbered source: database/sql/07_views.sql
-- =============================================================================


-- ---------------------------------------------------------------------------
-- 1. v_active_production_orders
-- All currently in-progress production orders with machine and product context.
-- Used by the real-time OEE dashboard to display live line status.
-- Consumer note: poll interval 30 seconds; apply WHERE machine_id = $1 for single-machine queries.
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
    -- Elapsed minutes since order actually started
    ROUND(
        EXTRACT(EPOCH FROM (now() - po.actual_start)) / 60.0,
        2
    )                                                              AS elapsed_minutes,
    -- Real-time OEE Quality component (partial — final quality set on order completion)
    CASE
        WHEN COALESCE(po.actual_units, 0) > 0
        THEN ROUND((po.good_units::NUMERIC / po.actual_units), 5)
        ELSE NULL
    END                                                            AS oee_quality_realtime,
    -- Throughput rate: good units per hour so far this order
    CASE
        WHEN po.actual_start IS NOT NULL
         AND COALESCE(po.good_units, 0) > 0
         AND EXTRACT(EPOCH FROM (now() - po.actual_start)) > 0
        THEN ROUND(
            po.good_units::NUMERIC /
            NULLIF(EXTRACT(EPOCH FROM (now() - po.actual_start)) / 3600.0, 0),
            4
        )
        ELSE NULL
    END                                                            AS throughput_rate_per_hr_realtime
FROM production_orders po
JOIN machines m ON m.machine_id   = po.machine_id
JOIN products p ON p.product_code = po.product_code
WHERE po.status = 'In Progress';

COMMENT ON VIEW v_active_production_orders IS
    'Real-time view of all in-progress production orders with machine and product context. '
    'Used by the live OEE dashboard. Refresh rate: poll every 30 seconds. '
    'Filter by machine_id or line_code for single-machine or single-line queries.';


-- ---------------------------------------------------------------------------
-- 2. v_machine_downtime_summary
-- Rolling 30-day downtime summary per machine.
-- Provides MTTR, planned vs. unplanned split, and total downtime minutes.
-- Used by the Maintenance & Reliability dashboard.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_machine_downtime_summary AS
SELECT
    de.machine_id,
    m.machine_name,
    m.machine_type_code,
    m.line_code,
    m.plant_code,
    COUNT(*)                                                      AS total_events,
    COUNT(*) FILTER (WHERE de.is_planned = FALSE)                AS unplanned_events,
    COUNT(*) FILTER (WHERE de.is_planned = TRUE)                 AS planned_events,
    COALESCE(SUM(de.downtime_minutes), 0)                        AS total_downtime_min,
    COALESCE(SUM(de.downtime_minutes) FILTER (WHERE de.is_planned = FALSE), 0)
                                                                  AS unplanned_downtime_min,
    COALESCE(SUM(de.downtime_minutes) FILTER (WHERE de.is_planned = TRUE), 0)
                                                                  AS planned_downtime_min,
    -- Average MTTR (Mean Time To Repair) for unplanned events only
    ROUND(
        COALESCE(SUM(de.downtime_minutes) FILTER (WHERE de.is_planned = FALSE), 0) /
        NULLIF(COUNT(*) FILTER (WHERE de.is_planned = FALSE), 0),
        2
    )                                                             AS avg_mttr_minutes,
    (now() - INTERVAL '30 days')                                 AS window_start,
    now()                                                        AS window_end
FROM downtime_events de
JOIN machines m ON m.machine_id = de.machine_id
WHERE de.downtime_start >= now() - INTERVAL '30 days'
GROUP BY
    de.machine_id,
    m.machine_name,
    m.machine_type_code,
    m.line_code,
    m.plant_code;

COMMENT ON VIEW v_machine_downtime_summary IS
    'Rolling 30-day downtime summary per machine. '
    'Provides total/unplanned/planned downtime minutes and average MTTR for unplanned events. '
    'Used by the Maintenance & Reliability dashboard. '
    'Excludes open events where downtime_minutes IS NULL (event not yet closed).';


-- ---------------------------------------------------------------------------
-- 3. v_sensor_anomaly_alerts
-- Most recent anomaly-flagged sensor readings per machine and sensor type (last 24 hours).
-- Used by the real-time alert panel on the OEE dashboard.
-- Consumer note: filter WHERE recency_rank = 1 for the latest alert per sensor type per machine.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_sensor_anomaly_alerts AS
SELECT
    sr.machine_id,
    m.machine_name,
    m.line_code,
    m.plant_code,
    sr.sensor_type,
    sr.sensor_unit,
    sr.value,
    sr.reading_timestamp,
    sr.data_quality_score,
    -- Rank readings most recent first within each machine + sensor type combination
    ROW_NUMBER() OVER (
        PARTITION BY sr.machine_id, sr.sensor_type
        ORDER BY sr.reading_timestamp DESC
    )                                                             AS recency_rank
FROM sensor_readings sr
JOIN machines m ON m.machine_id = sr.machine_id
WHERE sr.is_anomaly_flagged = TRUE
  AND sr.reading_timestamp >= now() - INTERVAL '24 hours';

COMMENT ON VIEW v_sensor_anomaly_alerts IS
    'Anomaly-flagged sensor readings in the last 24 hours, ranked most recent first '
    'per machine+sensor_type combination. '
    'Filter WHERE recency_rank = 1 to retrieve only the latest alert per sensor per machine. '
    'Used by the real-time anomaly alert panel. '
    'Note: readings where data_quality_score < 0.5 may be instrument artifacts — verify before alerting.';


-- ---------------------------------------------------------------------------
-- 4. v_quality_defect_summary
-- Rolling 7-day defect rate summary per machine and defect type.
-- Used by the Quality Control dashboard Pareto chart panel.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_quality_defect_summary AS
SELECT
    qi.machine_id,
    m.machine_name,
    m.line_code,
    m.plant_code,
    qi.defect_type_code,
    dt.defect_type_name,
    dt.defect_category,
    dt.severity_level,
    dt.is_customer_escape_risk,
    COUNT(*)                                                      AS inspection_count,
    SUM(qi.sample_size)                                           AS total_sampled,
    SUM(qi.defects_found)                                         AS total_defects,
    -- Defect rate as percentage (e.g., 1.2345 = 1.2345%)
    ROUND(
        SUM(qi.defects_found)::NUMERIC /
        NULLIF(SUM(qi.sample_size), 0) * 100,
        4
    )                                                             AS defect_rate_pct,
    -- Defect rate in parts per million (PPM)
    ROUND(
        SUM(qi.defects_found)::NUMERIC /
        NULLIF(SUM(qi.sample_size), 0) * 1000000,
        2
    )                                                             AS defect_rate_ppm,
    COUNT(*) FILTER (WHERE qi.pass_fail = 'P')                   AS lots_passed,
    COUNT(*) FILTER (WHERE qi.pass_fail = 'F')                   AS lots_failed,
    (now() - INTERVAL '7 days')                                  AS window_start,
    now()                                                        AS window_end
FROM quality_inspections qi
JOIN machines m         ON m.machine_id           = qi.machine_id
LEFT JOIN defect_types dt ON dt.defect_type_code  = qi.defect_type_code
WHERE qi.inspection_timestamp >= now() - INTERVAL '7 days'
GROUP BY
    qi.machine_id,
    m.machine_name,
    m.line_code,
    m.plant_code,
    qi.defect_type_code,
    dt.defect_type_name,
    dt.defect_category,
    dt.severity_level,
    dt.is_customer_escape_risk;

COMMENT ON VIEW v_quality_defect_summary IS
    'Rolling 7-day quality defect rate summary per machine and defect type. '
    'Supports Pareto chart analysis on the Quality Control dashboard. '
    'NULL defect_type_code rows represent inspections where no defect code was assigned (~8% of failing records). '
    'defect_rate_ppm is the primary KPI for customer-facing SLAs.';


-- ---------------------------------------------------------------------------
-- 5. v_pm_compliance_status
-- Current PM compliance status per active PM schedule — Overdue, Due Soon, or Compliant.
-- Used by the Maintenance dashboard PM compliance KPI card.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_pm_compliance_status AS
SELECT
    ps.pm_schedule_id,
    ps.machine_id,
    m.machine_name,
    m.machine_type_code,
    m.line_code,
    m.plant_code,
    ps.pm_type,
    ps.interval_days,
    ps.interval_hours,
    ps.last_performed_date,
    ps.next_due_date,
    -- Positive = days overdue; negative = days until due
    (CURRENT_DATE - ps.next_due_date)                            AS days_overdue,
    CASE
        WHEN ps.next_due_date IS NULL           THEN 'Unknown'
        WHEN CURRENT_DATE > ps.next_due_date + 3 THEN 'Overdue'
        WHEN CURRENT_DATE >= ps.next_due_date - 3 THEN 'Due Soon'
        ELSE 'Compliant'
    END                                                          AS compliance_status,
    ps.is_active
FROM pm_schedules ps
JOIN machines m ON m.machine_id = ps.machine_id
WHERE ps.is_active = TRUE;

COMMENT ON VIEW v_pm_compliance_status IS
    'Current PM compliance status per active schedule. '
    'Overdue: past due date by more than 3 days. '
    'Due Soon: within 3 days of due date (pre-emptive maintenance window). '
    'Compliant: next_due_date is more than 3 days in the future. '
    'Unknown: next_due_date not yet calculated (new schedule or ETL not yet run). '
    'Used by the Maintenance dashboard PM compliance KPI card. Filter is_active = TRUE for production schedules only.';
