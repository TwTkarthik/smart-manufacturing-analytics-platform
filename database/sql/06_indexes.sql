-- =============================================================================
-- 06_indexes.sql
-- SMAP Operational Database — Indexes
-- Implements all indexes per DB_INDEXING_STRATEGY.md.
-- Run AFTER 05_constraints.sql.
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- machines
-- ─────────────────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_machines_line_code
    ON machines (line_code);
COMMENT ON INDEX idx_machines_line_code IS 'ETL and API queries filter by production line.';

CREATE INDEX IF NOT EXISTS idx_machines_plant_code
    ON machines (plant_code);
COMMENT ON INDEX idx_machines_plant_code IS 'Multi-facility queries filter by plant.';

-- Note: scada_tag_name and asset_tag_number already indexed via UNIQUE constraints.

-- ─────────────────────────────────────────────────────────────────────────────
-- production_orders
-- ─────────────────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_prod_orders_machine_id
    ON production_orders (machine_id);
COMMENT ON INDEX idx_prod_orders_machine_id IS 'FK lookup; join target from downtime_events and quality_inspections.';

CREATE INDEX IF NOT EXISTS idx_prod_orders_product_code
    ON production_orders (product_code);
COMMENT ON INDEX idx_prod_orders_product_code IS 'FK lookup; product-level OEE reporting queries.';

CREATE INDEX IF NOT EXISTS idx_prod_orders_actual_end
    ON production_orders (actual_end);
COMMENT ON INDEX idx_prod_orders_actual_end IS 'Watermark-based incremental ETL extraction.';

CREATE INDEX IF NOT EXISTS idx_prod_orders_status_partial
    ON production_orders (machine_id, planned_start)
    WHERE status = 'In Progress';
COMMENT ON INDEX idx_prod_orders_status_partial IS 'Partial index: active orders only. Efficiently locate in-progress orders without full scan.';

CREATE INDEX IF NOT EXISTS idx_prod_orders_machine_shift
    ON production_orders (machine_id, shift_code);
COMMENT ON INDEX idx_prod_orders_machine_shift IS 'Shift-level OEE queries by machine.';

-- ─────────────────────────────────────────────────────────────────────────────
-- downtime_events
-- ─────────────────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_downtime_machine_start
    ON downtime_events (machine_id, downtime_start);
COMMENT ON INDEX idx_downtime_machine_start IS 'MTBF calculation: chronological unplanned events per machine.';

CREATE INDEX IF NOT EXISTS idx_downtime_order_id
    ON downtime_events (order_id);
COMMENT ON INDEX idx_downtime_order_id IS 'FK join from production_orders for OEE Availability calculation.';

CREATE INDEX IF NOT EXISTS idx_downtime_start
    ON downtime_events (downtime_start);
COMMENT ON INDEX idx_downtime_start IS 'Watermark-based ETL extraction.';

CREATE INDEX IF NOT EXISTS idx_downtime_unplanned_partial
    ON downtime_events (machine_id, downtime_start)
    WHERE is_planned = FALSE;
COMMENT ON INDEX idx_downtime_unplanned_partial IS 'Partial index: unplanned events only (~40% of rows). Used for MTBF/MTTR calculation.';

-- ─────────────────────────────────────────────────────────────────────────────
-- sensor_readings  (indexes on parent table — apply to all partitions)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_sensor_machine_type_ts
    ON sensor_readings (machine_id, sensor_type, reading_timestamp);
COMMENT ON INDEX idx_sensor_machine_type_ts IS 'Primary ML feature query: all readings of one type for one machine in a time window.';

CREATE INDEX IF NOT EXISTS idx_sensor_timestamp_brin
    ON sensor_readings USING BRIN (reading_timestamp);
COMMENT ON INDEX idx_sensor_timestamp_brin IS 'BRIN index for time-range scans on append-only, time-ordered data. ~1% maintenance overhead vs B-tree.';

CREATE INDEX IF NOT EXISTS idx_sensor_anomaly_partial
    ON sensor_readings (machine_id, reading_timestamp)
    WHERE is_anomaly_flagged = TRUE;
COMMENT ON INDEX idx_sensor_anomaly_partial IS 'Partial index: anomalous readings only (small subset). Used by anomaly investigation queries.';

-- ─────────────────────────────────────────────────────────────────────────────
-- quality_inspections
-- ─────────────────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_quality_order_id
    ON quality_inspections (order_id);
COMMENT ON INDEX idx_quality_order_id IS 'FK join from production_orders.';

CREATE INDEX IF NOT EXISTS idx_quality_machine_id
    ON quality_inspections (machine_id);
COMMENT ON INDEX idx_quality_machine_id IS 'Machine-level defect rate reporting.';

CREATE INDEX IF NOT EXISTS idx_quality_timestamp
    ON quality_inspections (inspection_timestamp);
COMMENT ON INDEX idx_quality_timestamp IS 'Watermark-based ETL extraction.';

CREATE INDEX IF NOT EXISTS idx_quality_failed_partial
    ON quality_inspections (machine_id, inspection_timestamp)
    WHERE pass_fail = 'F';
COMMENT ON INDEX idx_quality_failed_partial IS 'Partial index: failed inspections only (~20% of rows). Defect rate dashboard query path.';

-- ─────────────────────────────────────────────────────────────────────────────
-- maintenance_logs
-- ─────────────────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_maintenance_machine_id
    ON maintenance_logs (machine_id);
COMMENT ON INDEX idx_maintenance_machine_id IS 'Machine-level MTTR/MTBF reporting.';

CREATE INDEX IF NOT EXISTS idx_maintenance_downtime_start
    ON maintenance_logs (downtime_start);
COMMENT ON INDEX idx_maintenance_downtime_start IS 'Watermark-based ETL extraction; chronological MTBF analysis.';

CREATE INDEX IF NOT EXISTS idx_maintenance_unplanned_partial
    ON maintenance_logs (machine_id, downtime_start)
    WHERE event_type IN ('Unplanned', 'Emergency');
COMMENT ON INDEX idx_maintenance_unplanned_partial IS 'Partial index: failure events only. Used for MTBF calculation per machine.';

-- ─────────────────────────────────────────────────────────────────────────────
-- material_movements
-- ─────────────────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_movements_date_brin
    ON material_movements USING BRIN (movement_date);
COMMENT ON INDEX idx_movements_date_brin IS 'BRIN index on append-only transaction log. Date-range queries for parts cost reporting.';

CREATE INDEX IF NOT EXISTS idx_movements_work_order
    ON material_movements (work_order_id);
COMMENT ON INDEX idx_movements_work_order IS 'Join to maintenance_logs for per-work-order parts cost calculation.';

CREATE INDEX IF NOT EXISTS idx_movements_part_code
    ON material_movements (part_code);
COMMENT ON INDEX idx_movements_part_code IS 'FK join; parts consumption reporting per spare part.';

-- ─────────────────────────────────────────────────────────────────────────────
-- pm_schedules
-- ─────────────────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_pm_schedules_machine_id
    ON pm_schedules (machine_id);
COMMENT ON INDEX idx_pm_schedules_machine_id IS 'FK lookup; ETL calculates days_since_last_pm by machine.';

CREATE INDEX IF NOT EXISTS idx_pm_schedules_next_due
    ON pm_schedules (next_due_date)
    WHERE is_active = TRUE;
COMMENT ON INDEX idx_pm_schedules_next_due IS 'Partial index: active schedules only. Used to identify overdue PM events.';
