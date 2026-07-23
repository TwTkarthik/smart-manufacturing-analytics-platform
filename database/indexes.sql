-- =============================================================================
-- indexes.sql
-- SMAP Operational Database — Indexes
-- PostgreSQL 16 compatible.
--
-- Execution order: 5 of 9
-- Run AFTER constraints.sql; BEFORE views.sql.
--
-- Implements all indexes per docs/DB_INDEXING_STRATEGY.md §2 (Operational DB).
-- Index types used:
--   - B-tree  : default for equality lookups, range queries, ORDER BY
--   - BRIN    : append-only time-series tables (sensor_readings, material_movements)
--   - Partial : small active subsets (in-progress orders, failed inspections, unplanned events)
--
-- Naming convention: idx_{table}_{column(s)}[_partial]
--
-- Canonical numbered source: database/sql/06_indexes.sql
-- =============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- machines
-- Note: scada_tag_name and asset_tag_number are already B-tree indexed via
-- the UNIQUE constraints added in constraints.sql. Separate named indexes are
-- documented here as aliases to make the indexing strategy explicit.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_machines_line_code
    ON machines (line_code);
COMMENT ON INDEX idx_machines_line_code IS 'ETL and API queries filter machines by production line.';

CREATE INDEX IF NOT EXISTS idx_machines_plant_code
    ON machines (plant_code);
COMMENT ON INDEX idx_machines_plant_code IS 'Multi-facility queries filter machines by plant code.';

-- scada_tag_name: covered by uq_machines_scada_tag_name constraint index.
-- asset_tag_number: covered by uq_machines_asset_tag_number constraint index.
-- Both resolve ETL SCADA-to-machine-ID and CMMS-to-machine-ID lookups.


-- ─────────────────────────────────────────────────────────────────────────────
-- production_orders
-- ─────────────────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_prod_orders_machine_id
    ON production_orders (machine_id);
COMMENT ON INDEX idx_prod_orders_machine_id IS 'FK lookup; frequent join target from downtime_events and quality_inspections for OEE calculation.';

CREATE INDEX IF NOT EXISTS idx_prod_orders_product_code
    ON production_orders (product_code);
COMMENT ON INDEX idx_prod_orders_product_code IS 'FK lookup; product-level OEE and throughput reporting queries.';

CREATE INDEX IF NOT EXISTS idx_prod_orders_actual_end
    ON production_orders (actual_end);
COMMENT ON INDEX idx_prod_orders_actual_end IS 'Watermark-based incremental ETL extraction — finds orders completed since last pipeline run.';

-- Partial index: only in-progress orders (~5% of all rows at any given time)
CREATE INDEX IF NOT EXISTS idx_prod_orders_status_partial
    ON production_orders (machine_id, planned_start)
    WHERE status = 'In Progress';
COMMENT ON INDEX idx_prod_orders_status_partial IS 'Partial index: active orders only. Powers real-time OEE dashboard live order lookup without full table scan.';

CREATE INDEX IF NOT EXISTS idx_prod_orders_machine_shift
    ON production_orders (machine_id, shift_code);
COMMENT ON INDEX idx_prod_orders_machine_shift IS 'Composite index for shift-level OEE queries filtered by machine.';


-- ─────────────────────────────────────────────────────────────────────────────
-- downtime_events
-- ─────────────────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_downtime_machine_start
    ON downtime_events (machine_id, downtime_start);
COMMENT ON INDEX idx_downtime_machine_start IS 'MTBF calculation: retrieve all events for a machine in chronological order.';

CREATE INDEX IF NOT EXISTS idx_downtime_order_id
    ON downtime_events (order_id);
COMMENT ON INDEX idx_downtime_order_id IS 'FK join from production_orders for OEE Availability calculation.';

CREATE INDEX IF NOT EXISTS idx_downtime_start
    ON downtime_events (downtime_start);
COMMENT ON INDEX idx_downtime_start IS 'Watermark-based ETL extraction.';

-- Partial index: unplanned events only (~40% of all rows)
CREATE INDEX IF NOT EXISTS idx_downtime_unplanned_partial
    ON downtime_events (machine_id, downtime_start)
    WHERE is_planned = FALSE;
COMMENT ON INDEX idx_downtime_unplanned_partial IS 'Partial index: unplanned events only. Used for MTBF/MTTR calculation — avoids scanning planned PM stops.';


-- ─────────────────────────────────────────────────────────────────────────────
-- sensor_readings
-- High-volume table (~200–400M rows/year). Index choices minimize write overhead
-- while supporting the two primary read patterns:
--   1. ML feature engineering: all readings of one type for one machine in a window.
--   2. Time-range ETL extraction: all readings since last watermark.
-- Indexes on the parent table propagate automatically to all monthly partitions.
-- ─────────────────────────────────────────────────────────────────────────────

-- Primary ML feature query index (B-tree, composite)
CREATE INDEX IF NOT EXISTS idx_sensor_machine_type_ts
    ON sensor_readings (machine_id, sensor_type, reading_timestamp);
COMMENT ON INDEX idx_sensor_machine_type_ts IS 'Primary ML feature engineering index: fetches all readings of one sensor_type for one machine in a time window. machine_id first (highest cardinality).';

-- Watermark/range-scan index (BRIN — tiny footprint on append-only, time-ordered data)
CREATE INDEX IF NOT EXISTS idx_sensor_timestamp_brin
    ON sensor_readings USING BRIN (reading_timestamp);
COMMENT ON INDEX idx_sensor_timestamp_brin IS 'BRIN index for time-range scans on time-ordered append-only data. ~1% of B-tree maintenance overhead; near-equivalent range-scan performance for this access pattern.';

-- Partial index: anomaly-flagged readings only (small subset — estimated < 2% of all rows)
CREATE INDEX IF NOT EXISTS idx_sensor_anomaly_partial
    ON sensor_readings (machine_id, reading_timestamp)
    WHERE is_anomaly_flagged = TRUE;
COMMENT ON INDEX idx_sensor_anomaly_partial IS 'Partial index: anomalous readings only. Used by anomaly investigation queries and the v_sensor_anomaly_alerts view.';


-- ─────────────────────────────────────────────────────────────────────────────
-- quality_inspections
-- ─────────────────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_quality_order_id
    ON quality_inspections (order_id);
COMMENT ON INDEX idx_quality_order_id IS 'FK join from production_orders.';

CREATE INDEX IF NOT EXISTS idx_quality_machine_id
    ON quality_inspections (machine_id);
COMMENT ON INDEX idx_quality_machine_id IS 'Machine-level defect rate and First Pass Yield reporting.';

CREATE INDEX IF NOT EXISTS idx_quality_timestamp
    ON quality_inspections (inspection_timestamp);
COMMENT ON INDEX idx_quality_timestamp IS 'Watermark-based ETL extraction.';

-- Partial index: failed inspections only (~20% of all inspections)
CREATE INDEX IF NOT EXISTS idx_quality_failed_partial
    ON quality_inspections (machine_id, inspection_timestamp)
    WHERE pass_fail = 'F';
COMMENT ON INDEX idx_quality_failed_partial IS 'Partial index: failed inspections only. Powers the defect rate dashboard query path — avoids scanning passing lots.';


-- ─────────────────────────────────────────────────────────────────────────────
-- maintenance_logs
-- ─────────────────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_maintenance_machine_id
    ON maintenance_logs (machine_id);
COMMENT ON INDEX idx_maintenance_machine_id IS 'Machine-level MTTR/MTBF reporting and FK join.';

CREATE INDEX IF NOT EXISTS idx_maintenance_downtime_start
    ON maintenance_logs (downtime_start);
COMMENT ON INDEX idx_maintenance_downtime_start IS 'Watermark-based ETL extraction; chronological MTBF analysis across all machines.';

-- Partial index: failure events only — unplanned and emergency events
CREATE INDEX IF NOT EXISTS idx_maintenance_unplanned_partial
    ON maintenance_logs (machine_id, downtime_start)
    WHERE event_type IN ('Unplanned', 'Emergency');
COMMENT ON INDEX idx_maintenance_unplanned_partial IS 'Partial index: failure events only. Used for per-machine MTBF calculation — excludes scheduled PM events.';


-- ─────────────────────────────────────────────────────────────────────────────
-- material_movements
-- Append-only inventory transaction log. BRIN on movement_date is appropriate
-- because records are inserted in roughly chronological order.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_movements_date_brin
    ON material_movements USING BRIN (movement_date);
COMMENT ON INDEX idx_movements_date_brin IS 'BRIN index on append-only transaction log. Date-range queries for parts cost and consumption reporting.';

CREATE INDEX IF NOT EXISTS idx_movements_work_order
    ON material_movements (work_order_id);
COMMENT ON INDEX idx_movements_work_order IS 'FK join to maintenance_logs for per-work-order parts cost calculation.';

CREATE INDEX IF NOT EXISTS idx_movements_part_code
    ON material_movements (part_code);
COMMENT ON INDEX idx_movements_part_code IS 'FK join; parts consumption reporting per spare part (usage frequency, cost analysis).';


-- ─────────────────────────────────────────────────────────────────────────────
-- pm_schedules
-- ─────────────────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_pm_schedules_machine_id
    ON pm_schedules (machine_id);
COMMENT ON INDEX idx_pm_schedules_machine_id IS 'FK lookup; ETL calculates days_since_last_pm by machine for predictive maintenance ML features.';

-- Partial index: active schedules only (avoids scanning deactivated/archived schedules)
CREATE INDEX IF NOT EXISTS idx_pm_schedules_next_due
    ON pm_schedules (next_due_date)
    WHERE is_active = TRUE;
COMMENT ON INDEX idx_pm_schedules_next_due IS 'Partial index: active schedules only. Powers v_pm_compliance_status view — identifies overdue and upcoming PM events.';
