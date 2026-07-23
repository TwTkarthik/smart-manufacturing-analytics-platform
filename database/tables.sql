-- =============================================================================
-- tables.sql
-- SMAP Operational Database — Complete Table Definitions
-- PostgreSQL 16 compatible.
--
-- Execution order: 3 of 9
-- Run AFTER schema.sql; BEFORE constraints.sql.
--
-- Creates all 14 operational (OLTP) tables across 5 business domains, in
-- dependency order (parent tables before child tables).
-- Foreign key constraints are applied separately in constraints.sql.
--
-- Canonical numbered source: database/sql/04_tables.sql
--
-- Table creation order:
--   Domain 1 — Reference / Master Data
--     1.  production_lines
--     2.  shifts
--     3.  machines              (FK → production_lines)
--     4.  products
--     5.  employees             (FK → shifts — constraint applied in constraints.sql)
--
--   Domain 4 — Quality Management (reference table first)
--     6.  defect_types
--
--   Domain 5 — Maintenance Management (spare_parts before transactions)
--     7.  spare_parts
--
--   Domain 2 — Production Operations
--     8.  production_orders     (FK → machines, products, shifts, employees)
--     9.  downtime_events       (FK → machines, production_orders, employees)
--
--   Domain 3 — Sensor Telemetry
--     10. sensor_readings       (partitioned by month: 2026-01 through 2026-12)
--
--   Domain 4 — Quality Management (transaction table)
--     11. quality_inspections   (FK → production_orders, machines, employees, defect_types)
--
--   Domain 5 — Maintenance Management (transaction tables)
--     12. pm_schedules          (FK → machines)
--     13. maintenance_logs      (FK → machines, employees, pm_schedules)
--     14. material_movements    (FK → spare_parts, maintenance_logs)
-- =============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- DOMAIN 1: Reference / Master Data
-- ─────────────────────────────────────────────────────────────────────────────

-- ---------------------------------------------------------------------------
-- 1. production_lines
-- Logical groupings of machines into production cells.
-- PLT-DET: LINE-A through LINE-D; all facilities: LINE-A through LINE-K.
-- Static reference data — seeded at platform initialization.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS production_lines (
    line_code           VARCHAR(10)     NOT NULL,
    line_name           VARCHAR(100)    NOT NULL,
    plant_code          VARCHAR(10)     NOT NULL,
    primary_operation   VARCHAR(100),
    shift_pattern       VARCHAR(50),
    oee_target          NUMERIC(5,4),
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_production_lines PRIMARY KEY (line_code)
);

COMMENT ON TABLE  production_lines              IS 'Logical production line groupings above individual machines. PLT-DET: LINE-A through LINE-D; all plants: LINE-A through LINE-K.';
COMMENT ON COLUMN production_lines.line_code    IS 'Unique line identifier (e.g., LINE-A). PK. Natural key.';
COMMENT ON COLUMN production_lines.line_name    IS 'Human-readable line name (e.g., Powertrain Turning Cell).';
COMMENT ON COLUMN production_lines.plant_code   IS 'Facility code. One of: PLT-DET, PLT-CLV, PLT-CHI, PLT-MTY. Enforced by CHECK in constraints.sql.';
COMMENT ON COLUMN production_lines.oee_target   IS 'Plant-configured fleet OEE target for this line as decimal (e.g., 0.8100 = 81%).';
COMMENT ON COLUMN production_lines.is_active    IS 'FALSE for lines that are shut down or decommissioned.';


-- ---------------------------------------------------------------------------
-- 2. shifts
-- Three 8-hour shift windows (with 10-hour variants for CHI).
-- Static reference — seeded at setup; updated only when shift pattern changes.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS shifts (
    shift_code              VARCHAR(10)     NOT NULL,
    shift_name              VARCHAR(50)     NOT NULL,
    shift_start_time        TIME            NOT NULL,
    shift_end_time          TIME            NOT NULL,
    shift_duration_hours    NUMERIC(4,2)    NOT NULL,
    planned_production_hours NUMERIC(4,2)   NOT NULL,
    plant_code              VARCHAR(10)     NOT NULL,

    CONSTRAINT pk_shifts PRIMARY KEY (shift_code)
);

COMMENT ON TABLE  shifts                          IS 'Shift schedule reference. SHIFT-A through SHIFT-J across all plants. Seeded at setup; static during normal operations.';
COMMENT ON COLUMN shifts.shift_code               IS 'Unique shift identifier: SHIFT-A through SHIFT-J (per-plant variants).';
COMMENT ON COLUMN shifts.shift_start_time         IS 'Scheduled start time in local plant time.';
COMMENT ON COLUMN shifts.shift_end_time           IS 'Scheduled end time in local plant time. Night shifts cross midnight (22:00 → 06:00).';
COMMENT ON COLUMN shifts.shift_duration_hours     IS 'Total shift duration in hours (8.00 or 10.00 depending on plant).';
COMMENT ON COLUMN shifts.planned_production_hours IS 'Net production hours after deducting scheduled breaks (e.g., 7.50 for 30-min break in an 8-hr shift).';
COMMENT ON COLUMN shifts.plant_code               IS 'Facility this shift definition applies to.';


-- ---------------------------------------------------------------------------
-- 3. machines
-- Master register of all production equipment across all PrecisionEdge plants.
-- One record per physical machine asset. Updated via SCD Type 1 on attribute change.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS machines (
    machine_id              VARCHAR(20)     NOT NULL,
    machine_name            VARCHAR(100)    NOT NULL,
    machine_type_code       VARCHAR(20)     NOT NULL,
    line_code               VARCHAR(10)     NOT NULL,
    plant_code              VARCHAR(10)     NOT NULL,
    manufacturer            VARCHAR(100),
    model_number            VARCHAR(50),
    rated_capacity_per_hour NUMERIC(10,2),
    install_date            DATE,
    is_active               BOOLEAN         NOT NULL DEFAULT TRUE,
    scada_tag_name          VARCHAR(50),
    asset_tag_number        VARCHAR(20),
    erp_work_center_code    VARCHAR(20),
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ     NOT NULL DEFAULT now(),

    CONSTRAINT pk_machines PRIMARY KEY (machine_id)
);

COMMENT ON TABLE  machines                        IS 'Master register of all production machines across all PrecisionEdge facilities. MCH-001 through MCH-048 at PLT-DET.';
COMMENT ON COLUMN machines.machine_id             IS 'Unique machine identifier from MES. Format: MCH-NNN (e.g., MCH-001 through MCH-048). PK.';
COMMENT ON COLUMN machines.machine_type_code      IS 'Equipment category: MCH-LATHE, MCH-MILL, MCH-GRIND, MCH-PRESS, MCH-CMM, MCH-CONV, MCH-ASSY. Enforced by CHECK in constraints.sql.';
COMMENT ON COLUMN machines.line_code              IS 'Production line assignment. FK → production_lines.line_code (applied in constraints.sql).';
COMMENT ON COLUMN machines.plant_code             IS 'Facility code. One of: PLT-DET, PLT-CLV, PLT-CHI, PLT-MTY. Enforced by CHECK in constraints.sql.';
COMMENT ON COLUMN machines.scada_tag_name         IS 'SCADA PLC tag name (e.g., CELL_A1_LATHE_01). Used by ETL to resolve SCADA readings to machine_id. UNIQUE.';
COMMENT ON COLUMN machines.asset_tag_number       IS 'CMMS asset tag number (e.g., AT-0042). Used by ETL to resolve CMMS work orders to machine_id. UNIQUE.';
COMMENT ON COLUMN machines.rated_capacity_per_hour IS 'Theoretical maximum output units/hour at 100% speed. Source: ERP routing standard.';
COMMENT ON COLUMN machines.created_at             IS 'UTC timestamp when the machine record was first inserted.';
COMMENT ON COLUMN machines.updated_at             IS 'UTC timestamp of the most recent attribute update. Maintained by trg_machines_updated_at trigger.';

-- updated_at trigger for machines
CREATE TRIGGER trg_machines_updated_at
    BEFORE UPDATE ON machines
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();


-- ---------------------------------------------------------------------------
-- 4. products
-- Product/SKU master. Three-level hierarchy: product → family → category.
-- Provides standard_cycle_time_sec — the OEE Performance denominator.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS products (
    product_code            VARCHAR(30)     NOT NULL,
    product_name            VARCHAR(100)    NOT NULL,
    product_family          VARCHAR(50)     NOT NULL,
    product_category        VARCHAR(50)     NOT NULL,
    standard_cycle_time_sec NUMERIC(10,3)   NOT NULL,
    standard_material_cost  NUMERIC(15,4),
    standard_labor_cost     NUMERIC(15,4),
    is_active               BOOLEAN         NOT NULL DEFAULT TRUE,
    erp_material_code       VARCHAR(30),
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ     NOT NULL DEFAULT now(),

    CONSTRAINT pk_products PRIMARY KEY (product_code)
);

COMMENT ON TABLE  products                          IS 'Product/SKU master with three-level hierarchy. Provides standard_cycle_time_sec for OEE Performance and standard costs for scrap cost calculation.';
COMMENT ON COLUMN products.product_code             IS 'Unique product identifier from MES. Format: PRD-NNN (e.g., PRD-001). PK.';
COMMENT ON COLUMN products.product_name             IS 'Full product name (e.g., Crankshaft Bearing Journal — Type A).';
COMMENT ON COLUMN products.product_family           IS 'Product family grouping (e.g., Powertrain Components, Brake Components).';
COMMENT ON COLUMN products.product_category         IS 'Top-level category (e.g., Automotive, Industrial).';
COMMENT ON COLUMN products.standard_cycle_time_sec  IS 'Target cycle time per unit in SECONDS. CRITICAL: OEE Performance denominator. Source: ERP routing.';
COMMENT ON COLUMN products.standard_material_cost   IS 'Standard material cost per unit in USD. Used for scrap cost calculation.';
COMMENT ON COLUMN products.erp_material_code        IS 'SAP MM material code for cross-system traceability. UNIQUE where present.';
COMMENT ON COLUMN products.updated_at               IS 'UTC timestamp of most recent update. Maintained by trg_products_updated_at trigger.';

-- updated_at trigger for products
CREATE TRIGGER trg_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();


-- ---------------------------------------------------------------------------
-- 5. employees
-- Anonymized operator and technician roster.
-- Employee names EXCLUDED per PrecisionEdge privacy policy.
-- EMP-ROBOT is a special pseudo-employee for automated machine cycles.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS employees (
    employee_id             VARCHAR(20)     NOT NULL,
    role_code               VARCHAR(20)     NOT NULL,
    role_name               VARCHAR(50)     NOT NULL,
    department_code         VARCHAR(20)     NOT NULL,
    shift_assignment        VARCHAR(10)     NOT NULL,
    skill_level             VARCHAR(20),
    training_certifications TEXT,
    hire_date               DATE,
    is_active               BOOLEAN         NOT NULL DEFAULT TRUE,
    is_automated            BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ     NOT NULL DEFAULT now(),

    CONSTRAINT pk_employees PRIMARY KEY (employee_id)
);

COMMENT ON TABLE  employees                       IS 'Anonymized operator and technician roster. No PII stored (names excluded per privacy policy). EMP-ROBOT = automated cycle pseudo-employee.';
COMMENT ON COLUMN employees.employee_id           IS 'Anonymized HRIS employee code. Format: EMP-NNNN. PK.';
COMMENT ON COLUMN employees.role_code             IS 'Role: OPR-MCH (machine operator), OPR-SET (setup tech), QA-TECH, MNT-TECH, MNT-PLNR. Enforced by CHECK in constraints.sql.';
COMMENT ON COLUMN employees.department_code       IS 'Department: DEPT-OPS, DEPT-QA, DEPT-MNT, DEPT-ENG. Enforced by CHECK in constraints.sql.';
COMMENT ON COLUMN employees.shift_assignment      IS 'Primary assigned shift. FK → shifts.shift_code (applied in constraints.sql).';
COMMENT ON COLUMN employees.skill_level           IS 'Skill classification: Junior, Senior, Expert. NULL for EMP-ROBOT.';
COMMENT ON COLUMN employees.training_certifications IS 'Comma-separated list of relevant certifications (e.g., IATF-16949, Lock-Out-Tag-Out).';
COMMENT ON COLUMN employees.is_active             IS 'FALSE for former employees who have left PrecisionEdge.';
COMMENT ON COLUMN employees.is_automated          IS 'TRUE only for the EMP-ROBOT pseudo-employee record representing automated machine cycles.';
COMMENT ON COLUMN employees.updated_at            IS 'UTC timestamp of most recent update. Maintained by trg_employees_updated_at trigger.';

-- updated_at trigger for employees
CREATE TRIGGER trg_employees_updated_at
    BEFORE UPDATE ON employees
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();


-- ─────────────────────────────────────────────────────────────────────────────
-- DOMAIN 4: Quality Management — Reference Table
-- defect_types must exist before quality_inspections (FK dependency)
-- ─────────────────────────────────────────────────────────────────────────────

-- ---------------------------------------------------------------------------
-- 6. defect_types
-- Reference table for defect classification codes.
-- Two-level hierarchy: defect type → category. Supports Pareto analysis.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS defect_types (
    defect_type_code        VARCHAR(20)     NOT NULL,
    defect_type_name        VARCHAR(100)    NOT NULL,
    defect_category         VARCHAR(50)     NOT NULL,
    severity_level          VARCHAR(20)     NOT NULL,
    is_customer_escape_risk BOOLEAN         NOT NULL DEFAULT FALSE,
    description             TEXT,
    is_active               BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_defect_types PRIMARY KEY (defect_type_code)
);

COMMENT ON TABLE  defect_types                        IS 'Defect classification reference table. Supports Pareto analysis on the Quality Control dashboard. Seeded with 15 canonical defect types.';
COMMENT ON COLUMN defect_types.defect_type_code       IS 'Unique defect code from QMS (e.g., DFT-DIM-OOS, DFT-SURF-BRN). PK.';
COMMENT ON COLUMN defect_types.defect_category        IS 'Pareto grouping: Dimensional, Surface, Structural, Functional, Other. Enforced by CHECK in constraints.sql.';
COMMENT ON COLUMN defect_types.severity_level         IS 'Impact severity: Critical, Major, Minor. Enforced by CHECK in constraints.sql.';
COMMENT ON COLUMN defect_types.is_customer_escape_risk IS 'TRUE for defect types that may reach the customer if 100% inspection is not performed.';
COMMENT ON COLUMN defect_types.description            IS 'Detailed description of the defect type, common root causes, and typical detection method.';


-- ─────────────────────────────────────────────────────────────────────────────
-- DOMAIN 5: Maintenance Management — Catalog Table
-- spare_parts must exist before material_movements (FK dependency)
-- ─────────────────────────────────────────────────────────────────────────────

-- ---------------------------------------------------------------------------
-- 7. spare_parts
-- Spare parts catalog for maintenance planning and low-stock risk detection.
-- Source: SAP MM Materials Management.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS spare_parts (
    part_code           VARCHAR(30)     NOT NULL,
    part_description    VARCHAR(200)    NOT NULL,
    part_category       VARCHAR(50),
    stock_qty           NUMERIC(10,2)   NOT NULL DEFAULT 0,
    reorder_point       NUMERIC(10,2),
    lead_time_days      INTEGER,
    unit_cost           NUMERIC(15,4),
    supplier_code       VARCHAR(30),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),

    CONSTRAINT pk_spare_parts PRIMARY KEY (part_code)
);

COMMENT ON TABLE  spare_parts                IS 'Spare parts catalog from SAP MM. Used for maintenance parts planning and predictive low-stock risk detection.';
COMMENT ON COLUMN spare_parts.part_code      IS 'Unique part identifier from SAP MM (e.g., SP-BEAR-6205). PK.';
COMMENT ON COLUMN spare_parts.part_category  IS 'Classification: Bearings, Seals, Filters, Belts, Electronics, Hydraulics, Tooling, Other. Enforced by CHECK in constraints.sql.';
COMMENT ON COLUMN spare_parts.stock_qty      IS 'Current on-hand quantity in the maintenance storeroom. Updated by inventory transaction ETL.';
COMMENT ON COLUMN spare_parts.reorder_point  IS 'Stock level that triggers a purchase requisition. NULL means no auto-reorder configured.';
COMMENT ON COLUMN spare_parts.lead_time_days IS 'Typical procurement lead time in calendar days. Used to estimate parts availability date.';
COMMENT ON COLUMN spare_parts.unit_cost      IS 'Standard unit cost in USD from SAP MBEW (material valuation). NULL for consignment items.';
COMMENT ON COLUMN spare_parts.updated_at     IS 'UTC timestamp of the most recent stock level update by the ETL pipeline.';


-- ─────────────────────────────────────────────────────────────────────────────
-- DOMAIN 2: Production Operations
-- Dependency: machines, products, shifts, employees must exist first.
-- ─────────────────────────────────────────────────────────────────────────────

-- ---------------------------------------------------------------------------
-- 8. production_orders
-- Core production transaction. One row per discrete manufacturing work order.
-- All three OEE components originate from this table.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS production_orders (
    order_id            VARCHAR(30)     NOT NULL,
    machine_id          VARCHAR(20)     NOT NULL,
    product_code        VARCHAR(30)     NOT NULL,
    shift_code          VARCHAR(10)     NOT NULL,
    operator_id         VARCHAR(20),
    planned_start       TIMESTAMPTZ     NOT NULL,
    actual_start        TIMESTAMPTZ,
    actual_end          TIMESTAMPTZ,
    planned_units       INTEGER         NOT NULL,
    actual_units        INTEGER,
    good_units          INTEGER,
    scrap_units         INTEGER,
    rework_units        INTEGER,
    status              VARCHAR(20)     NOT NULL DEFAULT 'Pending',
    erp_order_id        VARCHAR(30),
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),

    CONSTRAINT pk_production_orders PRIMARY KEY (order_id)
);

COMMENT ON TABLE  production_orders               IS 'Core production transaction — one row per work order. Links machine, product, shift, and operator to planned and actual output. All OEE calculations originate here.';
COMMENT ON COLUMN production_orders.order_id      IS 'Unique MES order ID. Format: MES-YYYYMMDD-NNNNN. PK.';
COMMENT ON COLUMN production_orders.machine_id    IS 'Machine on which this order was run. FK → machines.machine_id.';
COMMENT ON COLUMN production_orders.product_code  IS 'Product being manufactured. FK → products.product_code.';
COMMENT ON COLUMN production_orders.shift_code    IS 'Shift during which the order ran. FK → shifts.shift_code.';
COMMENT ON COLUMN production_orders.operator_id   IS 'Primary operator ID. NULL for fully automated machine cycles (use EMP-ROBOT for tracked auto-cycles). FK → employees.employee_id.';
COMMENT ON COLUMN production_orders.planned_start IS 'Scheduled start time from ERP production plan. UTC.';
COMMENT ON COLUMN production_orders.actual_start  IS 'Actual start time from MES. NULL if order not yet started.';
COMMENT ON COLUMN production_orders.actual_end    IS 'Actual end time from MES. NULL if order is in progress or not yet started.';
COMMENT ON COLUMN production_orders.good_units    IS 'Units passing first-pass quality inspection. Numerator of OEE Quality component.';
COMMENT ON COLUMN production_orders.scrap_units   IS 'Units scrapped — failed QC with no rework path.';
COMMENT ON COLUMN production_orders.rework_units  IS 'Units requiring rework — NOT counted as good in OEE Quality per ISO 22400 methodology.';
COMMENT ON COLUMN production_orders.status        IS 'Order lifecycle: Pending | In Progress | Complete | Cancelled. Enforced by CHECK in constraints.sql.';
COMMENT ON COLUMN production_orders.erp_order_id  IS 'Cross-reference to ERP production order. Format: PP-YYYYMMDD-XXXXX. UNIQUE where present.';
COMMENT ON COLUMN production_orders.updated_at    IS 'UTC timestamp of the most recent status update. Maintained by trg_production_orders_updated_at trigger.';

-- updated_at trigger for production_orders
CREATE TRIGGER trg_production_orders_updated_at
    BEFORE UPDATE ON production_orders
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();


-- ---------------------------------------------------------------------------
-- 9. downtime_events
-- Every machine stop event (planned and unplanned).
-- Primary source for OEE Availability and MTBF/MTTR KPIs.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS downtime_events (
    event_id            VARCHAR(30)     NOT NULL,
    machine_id          VARCHAR(20)     NOT NULL,
    order_id            VARCHAR(30),
    event_type          VARCHAR(30)     NOT NULL,
    reason_code         VARCHAR(30),
    reason_description  TEXT,
    downtime_start      TIMESTAMPTZ     NOT NULL,
    downtime_end        TIMESTAMPTZ,
    downtime_minutes    NUMERIC(10,2),
    reported_by         VARCHAR(20),
    is_planned          BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),

    CONSTRAINT pk_downtime_events PRIMARY KEY (event_id)
);

COMMENT ON TABLE  downtime_events                    IS 'Every recorded machine stop event. Primary source for OEE Availability and MTBF/MTTR KPIs.';
COMMENT ON COLUMN downtime_events.event_id           IS 'Unique MES event ID. Format: DT-YYYYMMDD-NNNNN. PK.';
COMMENT ON COLUMN downtime_events.machine_id         IS 'Machine that experienced the stop. FK → machines.machine_id.';
COMMENT ON COLUMN downtime_events.order_id           IS 'Active production order at time of stop. NULL if machine stopped between orders. FK → production_orders.order_id.';
COMMENT ON COLUMN downtime_events.event_type         IS 'Stop classification: Planned | Unplanned | Emergency. Enforced by CHECK in constraints.sql.';
COMMENT ON COLUMN downtime_events.reason_code        IS 'MES reason list code (e.g., MECH-FAIL, TOOL-BREAK, PM-WINDOW, SETUP). NULL for ~5% of events.';
COMMENT ON COLUMN downtime_events.downtime_minutes   IS 'Stop duration in minutes. NULL while event is still open (downtime_end IS NULL). Populated at event close.';
COMMENT ON COLUMN downtime_events.reported_by        IS 'Employee who logged the stop event. FK → employees.employee_id.';
COMMENT ON COLUMN downtime_events.is_planned         IS 'TRUE for Planned and PM events; FALSE for Unplanned and Emergency. Derived from event_type at insert time.';


-- ─────────────────────────────────────────────────────────────────────────────
-- DOMAIN 3: Sensor Telemetry
-- High-volume IoT table — partitioned by month for performance and retention.
-- ─────────────────────────────────────────────────────────────────────────────

-- ---------------------------------------------------------------------------
-- 10. sensor_readings  (parent partitioned table)
-- ~554K–1.1M rows/day; ~200–400M rows/year.
-- BRIN index on reading_timestamp; B-tree composite on (machine_id, sensor_type, reading_timestamp).
-- Partition management: additional partitions created by dag_partition_management Airflow DAG.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sensor_readings (
    reading_id          BIGSERIAL       NOT NULL,
    machine_id          VARCHAR(20)     NOT NULL,
    sensor_type         VARCHAR(30)     NOT NULL,
    sensor_unit         VARCHAR(10)     NOT NULL,
    value               NUMERIC(14,6)   NOT NULL,
    reading_timestamp   TIMESTAMPTZ     NOT NULL,
    is_anomaly_flagged  BOOLEAN         NOT NULL DEFAULT FALSE,
    data_quality_score  NUMERIC(4,3),

    -- Composite PK required for range-partitioned tables in PostgreSQL
    CONSTRAINT pk_sensor_readings PRIMARY KEY (reading_id, reading_timestamp)
) PARTITION BY RANGE (reading_timestamp);

COMMENT ON TABLE  sensor_readings                    IS 'IoT sensor telemetry — ~200–400M rows/year. Monthly range-partitioned. Primary ML feature source for predictive maintenance and anomaly detection.';
COMMENT ON COLUMN sensor_readings.reading_id         IS '64-bit auto-increment surrogate key. Composite PK with reading_timestamp required for partitioned table.';
COMMENT ON COLUMN sensor_readings.machine_id         IS 'Machine this reading was captured from. Resolved from SCADA tag by ETL. FK → machines.machine_id.';
COMMENT ON COLUMN sensor_readings.sensor_type        IS 'Type code: temperature | vibration | rpm | pressure | power | cutting_force | coolant_flow. Enforced by CHECK in constraints.sql.';
COMMENT ON COLUMN sensor_readings.sensor_unit        IS 'Unit of measurement by type: temperature=C, vibration=mm/s, rpm=RPM, pressure=PSI, power=kWh, cutting_force=N, coolant_flow=L/min. Enforced by CHECK in constraints.sql.';
COMMENT ON COLUMN sensor_readings.is_anomaly_flagged IS 'TRUE if the SCADA source system flagged this reading as out-of-range at acquisition time.';
COMMENT ON COLUMN sensor_readings.data_quality_score IS 'SCADA data quality confidence 0.000–1.000. NULL for pre-2021 sensors; treated as 1.000 in downstream dbt models.';

-- ---------------------------------------------------------------------------
-- Monthly partitions: 2026-01 through 2026-12
-- Additional partitions for future months are created by the Airflow
-- dag_partition_management DAG (runs on the 20th of each month).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sensor_readings_2026_01
    PARTITION OF sensor_readings
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE IF NOT EXISTS sensor_readings_2026_02
    PARTITION OF sensor_readings
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');

CREATE TABLE IF NOT EXISTS sensor_readings_2026_03
    PARTITION OF sensor_readings
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');

CREATE TABLE IF NOT EXISTS sensor_readings_2026_04
    PARTITION OF sensor_readings
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');

CREATE TABLE IF NOT EXISTS sensor_readings_2026_05
    PARTITION OF sensor_readings
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

CREATE TABLE IF NOT EXISTS sensor_readings_2026_06
    PARTITION OF sensor_readings
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');

CREATE TABLE IF NOT EXISTS sensor_readings_2026_07
    PARTITION OF sensor_readings
    FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');

CREATE TABLE IF NOT EXISTS sensor_readings_2026_08
    PARTITION OF sensor_readings
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');

CREATE TABLE IF NOT EXISTS sensor_readings_2026_09
    PARTITION OF sensor_readings
    FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');

CREATE TABLE IF NOT EXISTS sensor_readings_2026_10
    PARTITION OF sensor_readings
    FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');

CREATE TABLE IF NOT EXISTS sensor_readings_2026_11
    PARTITION OF sensor_readings
    FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');

CREATE TABLE IF NOT EXISTS sensor_readings_2026_12
    PARTITION OF sensor_readings
    FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');


-- ─────────────────────────────────────────────────────────────────────────────
-- DOMAIN 4: Quality Management — Transaction Table
-- ─────────────────────────────────────────────────────────────────────────────

-- ---------------------------------------------------------------------------
-- 11. quality_inspections
-- One record per quality sampling event per production order.
-- Multiple inspections per order: first-article, in-process, final, functional.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS quality_inspections (
    inspection_id           VARCHAR(30)     NOT NULL,
    order_id                VARCHAR(30)     NOT NULL,
    machine_id              VARCHAR(20)     NOT NULL,
    inspector_id            VARCHAR(20),
    inspection_type_code    VARCHAR(20)     NOT NULL,
    inspection_timestamp    TIMESTAMPTZ     NOT NULL,
    sample_size             INTEGER         NOT NULL,
    defects_found           INTEGER         NOT NULL,
    defect_type_code        VARCHAR(20),
    defect_description      TEXT,
    measurement_value       NUMERIC(12,6),
    measurement_unit        VARCHAR(20),
    pass_fail               CHAR(1)         NOT NULL,
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT now(),

    CONSTRAINT pk_quality_inspections PRIMARY KEY (inspection_id)
);

COMMENT ON TABLE  quality_inspections                     IS 'Quality sampling events — one order may generate multiple inspections (first-article, in-process, final). Primary source for defect rate, FPY, and SPC chart data.';
COMMENT ON COLUMN quality_inspections.inspection_id       IS 'Unique QMS inspection ID. Format: QI-YYYYMMDD-NNNNN. PK.';
COMMENT ON COLUMN quality_inspections.order_id            IS 'Production order this inspection is associated with. FK → production_orders.order_id.';
COMMENT ON COLUMN quality_inspections.machine_id          IS 'Machine on which the inspected parts were produced. FK → machines.machine_id.';
COMMENT ON COLUMN quality_inspections.inspector_id        IS 'Inspector employee ID. NULL for automated gauging systems. FK → employees.employee_id.';
COMMENT ON COLUMN quality_inspections.inspection_type_code IS 'Inspection type: FIRST-ARTICLE | IN-PROCESS | FINAL | FUNCTIONAL. Enforced by CHECK in constraints.sql.';
COMMENT ON COLUMN quality_inspections.sample_size         IS 'Number of units included in this sampling event.';
COMMENT ON COLUMN quality_inspections.defects_found       IS 'Count of defective units in the sample. Must be <= sample_size (enforced by CHECK in constraints.sql).';
COMMENT ON COLUMN quality_inspections.defect_type_code    IS 'Primary defect category code. NULL if sample passes or defect code not yet assigned (~8% of defective records). FK → defect_types.defect_type_code.';
COMMENT ON COLUMN quality_inspections.measurement_value   IS 'Key quantitative measurement value (e.g., bore diameter in mm). NULL for attribute-only inspections.';
COMMENT ON COLUMN quality_inspections.pass_fail           IS 'Lot disposition: P = Pass (released), F = Fail (hold/reject). Enforced by CHECK in constraints.sql.';


-- ─────────────────────────────────────────────────────────────────────────────
-- DOMAIN 5: Maintenance Management — Transaction Tables
-- ─────────────────────────────────────────────────────────────────────────────

-- ---------------------------------------------------------------------------
-- 12. pm_schedules
-- Preventive maintenance schedule per machine and PM type.
-- Used to classify downtime as planned vs. unplanned and as ML model input feature.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS pm_schedules (
    pm_schedule_id      SERIAL          NOT NULL,
    machine_id          VARCHAR(20)     NOT NULL,
    pm_type             VARCHAR(50)     NOT NULL,
    interval_days       INTEGER,
    interval_hours      NUMERIC(10,2),
    last_performed_date DATE,
    next_due_date       DATE,
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),

    CONSTRAINT pk_pm_schedules PRIMARY KEY (pm_schedule_id)
);

COMMENT ON TABLE  pm_schedules                   IS 'Preventive maintenance schedules per machine. Classifies downtime as planned vs. unplanned and feeds days_since_last_pm ML feature.';
COMMENT ON COLUMN pm_schedules.pm_schedule_id    IS 'System-generated surrogate key. SERIAL. PK.';
COMMENT ON COLUMN pm_schedules.machine_id        IS 'Machine this PM schedule applies to. One machine may have multiple schedules for different PM types. FK → machines.machine_id.';
COMMENT ON COLUMN pm_schedules.pm_type           IS 'PM activity type (e.g., Lubrication, Filter Service, Spindle Inspection, Full Annual Overhaul).';
COMMENT ON COLUMN pm_schedules.interval_days     IS 'Calendar-day interval between PM events. NULL if interval_hours is used instead.';
COMMENT ON COLUMN pm_schedules.interval_hours    IS 'Operating-hours interval between PM events. NULL if interval_days is used instead. At least one must be set.';
COMMENT ON COLUMN pm_schedules.last_performed_date IS 'Date the most recent PM of this type was completed. Used to calculate days_since_last_pm ML feature.';
COMMENT ON COLUMN pm_schedules.next_due_date     IS 'Calculated next due date. Updated by ETL after each completed PM event is logged in maintenance_logs.';
COMMENT ON COLUMN pm_schedules.updated_at        IS 'UTC timestamp of most recent update. Maintained by trg_pm_schedules_updated_at trigger.';

-- updated_at trigger for pm_schedules
CREATE TRIGGER trg_pm_schedules_updated_at
    BEFORE UPDATE ON pm_schedules
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();


-- ---------------------------------------------------------------------------
-- 13. maintenance_logs
-- CMMS work order records for all maintenance activities.
-- Source for MTTR, root cause analysis, and maintenance cost tracking.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS maintenance_logs (
    work_order_id       VARCHAR(30)     NOT NULL,
    machine_id          VARCHAR(20)     NOT NULL,
    technician_id       VARCHAR(20),
    event_type          VARCHAR(30)     NOT NULL,
    failure_code        VARCHAR(20),
    description         TEXT,
    downtime_start      TIMESTAMPTZ     NOT NULL,
    downtime_end        TIMESTAMPTZ,
    downtime_minutes    NUMERIC(10,2),
    repair_cost         NUMERIC(15,4),
    root_cause          TEXT,
    pm_schedule_id      INTEGER,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),

    CONSTRAINT pk_maintenance_logs PRIMARY KEY (work_order_id)
);

COMMENT ON TABLE  maintenance_logs                   IS 'CMMS work order records for all maintenance activities. Primary source for MTTR, root cause analysis, repair cost tracking, and predictive maintenance ML model labeling.';
COMMENT ON COLUMN maintenance_logs.work_order_id     IS 'Unique CMMS work order ID. Format: WO-YYYYMMDD-NNNN. PK.';
COMMENT ON COLUMN maintenance_logs.machine_id        IS 'Machine that required maintenance. FK → machines.machine_id.';
COMMENT ON COLUMN maintenance_logs.technician_id     IS 'Assigned maintenance technician. NULL if unassigned at extraction time. FK → employees.employee_id.';
COMMENT ON COLUMN maintenance_logs.event_type        IS 'Work order type: Planned | Unplanned | Emergency. Enforced by CHECK in constraints.sql.';
COMMENT ON COLUMN maintenance_logs.failure_code      IS 'CMMS failure category (e.g., FC-MECH, FC-ELEC, FC-HYD). NULL for ~15% of corrective events.';
COMMENT ON COLUMN maintenance_logs.downtime_minutes  IS 'Total downtime in minutes. NULL for open (in-progress) work orders.';
COMMENT ON COLUMN maintenance_logs.repair_cost       IS 'Total repair cost (labor + parts) in USD. NULL for open work orders.';
COMMENT ON COLUMN maintenance_logs.root_cause        IS 'Root cause analysis notes. ~30% completion rate in CMMS.';
COMMENT ON COLUMN maintenance_logs.pm_schedule_id    IS 'FK → pm_schedules for planned events. NULL for unplanned and emergency events.';


-- ---------------------------------------------------------------------------
-- 14. material_movements
-- Inventory transaction log for spare parts consumption.
-- Links parts to maintenance work orders for cost-per-repair analysis.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS material_movements (
    movement_id         BIGSERIAL       NOT NULL,
    part_code           VARCHAR(30)     NOT NULL,
    work_order_id       VARCHAR(30),
    movement_type       VARCHAR(30)     NOT NULL,
    qty                 NUMERIC(10,4)   NOT NULL,
    unit_cost           NUMERIC(15,4),
    total_cost          NUMERIC(15,4),
    movement_date       DATE            NOT NULL,
    created_by          VARCHAR(20),
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),

    CONSTRAINT pk_material_movements PRIMARY KEY (movement_id)
);

COMMENT ON TABLE  material_movements                 IS 'Inventory transaction log — one row per goods issue, receipt, or stock transfer. Links spare parts consumption to maintenance work orders.';
COMMENT ON COLUMN material_movements.movement_id     IS '64-bit auto-increment surrogate key. BIGSERIAL. PK.';
COMMENT ON COLUMN material_movements.part_code       IS 'Spare part involved in this transaction. FK → spare_parts.part_code.';
COMMENT ON COLUMN material_movements.work_order_id   IS 'Associated CMMS work order. NULL for non-maintenance movements (goods receipts, stock transfers). FK → maintenance_logs.work_order_id.';
COMMENT ON COLUMN material_movements.movement_type   IS 'Transaction type: GOODS_ISSUE | GOODS_RECEIPT | STOCK_TRANSFER | RETURN. Enforced by CHECK in constraints.sql.';
COMMENT ON COLUMN material_movements.qty             IS 'Quantity moved. Always positive — direction determined by movement_type.';
COMMENT ON COLUMN material_movements.total_cost      IS 'qty × unit_cost. Computed at insert time by the ETL pipeline.';
COMMENT ON COLUMN material_movements.created_by      IS 'Employee ID or system identifier (e.g., ETL-SAP-EXTRACT) that created this transaction record.';
