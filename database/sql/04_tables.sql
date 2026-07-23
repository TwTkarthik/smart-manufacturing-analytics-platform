-- =============================================================================
-- 04_tables.sql
-- SMAP Operational Database — Complete Table Definitions
-- Creates all 14 operational (OLTP) tables in dependency order.
-- Foreign key constraints are in 05_constraints.sql.
-- Run AFTER 03_schema.sql.
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- DOMAIN 1: Reference / Master Data
-- Dependency order: production_lines → machines (FK)
--                   shifts → employees (FK)
-- ─────────────────────────────────────────────────────────────────────────────

-- ---------------------------------------------------------------------------
-- production_lines
-- Logical groupings of machines into production cells.
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

COMMENT ON TABLE  production_lines              IS 'Logical production line groupings above individual machines. PLT-DET: LINE-A through LINE-D.';
COMMENT ON COLUMN production_lines.line_code    IS 'Unique line identifier (e.g., LINE-A). PK.';
COMMENT ON COLUMN production_lines.line_name    IS 'Human-readable line name (e.g., Powertrain Turning Cell).';
COMMENT ON COLUMN production_lines.plant_code   IS 'Facility code. One of: PLT-DET, PLT-CLV, PLT-CHI, PLT-MTY.';
COMMENT ON COLUMN production_lines.oee_target   IS 'Fleet OEE target for this line as decimal (e.g., 0.8100 = 81%).';
COMMENT ON COLUMN production_lines.is_active    IS 'FALSE for lines that are shut down or decommissioned.';

-- ---------------------------------------------------------------------------
-- shifts
-- Three 8-hour shift windows. Static reference — seeded at setup.
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

COMMENT ON TABLE  shifts                        IS 'Three 8-hour shift definitions. Seeded at setup; static during normal operations.';
COMMENT ON COLUMN shifts.shift_code             IS 'Unique shift identifier: SHIFT-A, SHIFT-B, SHIFT-C.';
COMMENT ON COLUMN shifts.shift_start_time       IS 'Scheduled start time in local plant time.';
COMMENT ON COLUMN shifts.planned_production_hours IS 'Net production hours after deducting scheduled breaks.';

-- ---------------------------------------------------------------------------
-- machines
-- Master register of all production equipment.
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

COMMENT ON TABLE  machines                      IS 'Master register of all production machines across all PrecisionEdge facilities.';
COMMENT ON COLUMN machines.machine_id           IS 'Unique machine ID from MES. Format: MCH-NNN (e.g., MCH-001 through MCH-048).';
COMMENT ON COLUMN machines.machine_type_code    IS 'Equipment category: MCH-LATHE, MCH-MILL, MCH-GRIND, MCH-PRESS, MCH-CMM, MCH-CONV, MCH-ASSY.';
COMMENT ON COLUMN machines.line_code            IS 'Production line assignment. FK → production_lines.line_code.';
COMMENT ON COLUMN machines.scada_tag_name       IS 'SCADA PLC tag name — used by ETL to resolve sensor readings to machine_id.';
COMMENT ON COLUMN machines.asset_tag_number     IS 'CMMS asset tag number — used by ETL to resolve CMMS work orders to machine_id.';
COMMENT ON COLUMN machines.rated_capacity_per_hour IS 'Theoretical max output units/hour at 100% speed. Source: ERP routing.';

-- updated_at trigger for machines
CREATE TRIGGER trg_machines_updated_at
    BEFORE UPDATE ON machines
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ---------------------------------------------------------------------------
-- products
-- Product/SKU master. Three-level hierarchy: product → family → category.
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

COMMENT ON TABLE  products                          IS 'Product/SKU master. Three-level hierarchy used in OEE Performance and scrap cost calculations.';
COMMENT ON COLUMN products.product_code             IS 'Unique product ID from MES. Format: PRD-NNN (e.g., PRD-001).';
COMMENT ON COLUMN products.standard_cycle_time_sec  IS 'Target cycle time per unit in SECONDS. Critical: OEE Performance denominator.';
COMMENT ON COLUMN products.erp_material_code        IS 'SAP MM material code for cross-system traceability.';

-- updated_at trigger for products
CREATE TRIGGER trg_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ---------------------------------------------------------------------------
-- employees
-- Anonymized operator and technician roster. No PII stored.
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

COMMENT ON TABLE  employees                     IS 'Anonymized operator and technician roster. No PII (names excluded per privacy policy).';
COMMENT ON COLUMN employees.employee_id         IS 'Anonymized HRIS employee code. Format: EMP-NNNN. EMP-ROBOT = automated cycle pseudo-employee.';
COMMENT ON COLUMN employees.role_code           IS 'Role: OPR-MCH, OPR-SET, QA-TECH, MNT-TECH, MNT-PLNR.';
COMMENT ON COLUMN employees.department_code     IS 'Department: DEPT-OPS, DEPT-QA, DEPT-MNT, DEPT-ENG.';
COMMENT ON COLUMN employees.shift_assignment    IS 'Primary shift assignment. FK → shifts.shift_code.';
COMMENT ON COLUMN employees.is_automated        IS 'TRUE for EMP-ROBOT — used when a machine cycle has no human operator.';

-- updated_at trigger for employees
CREATE TRIGGER trg_employees_updated_at
    BEFORE UPDATE ON employees
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- DOMAIN 4: Quality Management (defect_types before quality_inspections)
-- ─────────────────────────────────────────────────────────────────────────────

-- ---------------------------------------------------------------------------
-- defect_types
-- Reference table for defect classification codes.
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

COMMENT ON TABLE  defect_types                      IS 'Defect classification reference. Supports Pareto analysis on Quality Control dashboard.';
COMMENT ON COLUMN defect_types.defect_type_code     IS 'Unique defect code from QMS (e.g., DFT-DIM, DFT-SURF, DFT-STRUCT).';
COMMENT ON COLUMN defect_types.defect_category      IS 'Pareto grouping: Dimensional, Surface, Structural, Functional, Other.';
COMMENT ON COLUMN defect_types.severity_level       IS 'Impact severity: Critical, Major, Minor.';
COMMENT ON COLUMN defect_types.is_customer_escape_risk IS 'TRUE for defects that may reach the customer if 100% inspection is not performed.';

-- ─────────────────────────────────────────────────────────────────────────────
-- DOMAIN 5: Maintenance Management (spare_parts and pm_schedules)
-- ─────────────────────────────────────────────────────────────────────────────

-- ---------------------------------------------------------------------------
-- spare_parts
-- Spare parts catalog for maintenance planning.
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

COMMENT ON TABLE  spare_parts               IS 'Spare parts catalog. Used for maintenance parts planning and low-stock risk detection.';
COMMENT ON COLUMN spare_parts.part_code     IS 'Unique part identifier from SAP MM (e.g., SP-BEARING-6205).';
COMMENT ON COLUMN spare_parts.part_category IS 'Classification: Bearings, Seals, Filters, Belts, Electronics, Hydraulics, Tooling, Other.';
COMMENT ON COLUMN spare_parts.stock_qty     IS 'Current on-hand quantity in maintenance storeroom.';
COMMENT ON COLUMN spare_parts.reorder_point IS 'Stock level that triggers a purchase order.';

-- ─────────────────────────────────────────────────────────────────────────────
-- DOMAIN 2: Production Operations
-- Dependency order: machines + products + shifts + employees → production_orders
-- ─────────────────────────────────────────────────────────────────────────────

-- ---------------------------------------------------------------------------
-- production_orders
-- Core production transaction. One row per discrete work order.
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

COMMENT ON TABLE  production_orders             IS 'Core production transaction. One row per work order. All OEE calculations originate here.';
COMMENT ON COLUMN production_orders.order_id    IS 'Unique MES order ID. Format: MES-YYYYMMDD-NNNNN.';
COMMENT ON COLUMN production_orders.operator_id IS 'NULL for automated cycles; use EMP-ROBOT for tracked auto-cycles.';
COMMENT ON COLUMN production_orders.good_units  IS 'Units passing first-pass QC. Numerator of OEE Quality component.';
COMMENT ON COLUMN production_orders.scrap_units IS 'Scrapped units — failed QC with no rework path.';
COMMENT ON COLUMN production_orders.rework_units IS 'Rework units — not counted as good in OEE Quality per standard methodology.';
COMMENT ON COLUMN production_orders.status      IS 'Order lifecycle status: Pending, In Progress, Complete, Cancelled.';
COMMENT ON COLUMN production_orders.erp_order_id IS 'Cross-reference to ERP order. Format: PP-YYYYMMDD-XXXXX.';

-- updated_at trigger for production_orders
CREATE TRIGGER trg_production_orders_updated_at
    BEFORE UPDATE ON production_orders
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ---------------------------------------------------------------------------
-- downtime_events
-- Every machine stop event (planned and unplanned).
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

COMMENT ON TABLE  downtime_events               IS 'Every recorded machine stop event. Primary source for OEE Availability and MTBF/MTTR KPIs.';
COMMENT ON COLUMN downtime_events.event_id      IS 'Unique MES event ID. Format: DT-YYYYMMDD-NNNNN.';
COMMENT ON COLUMN downtime_events.order_id      IS 'Active production order at time of stop. NULL if machine stopped between orders.';
COMMENT ON COLUMN downtime_events.event_type    IS 'Stop classification: Planned, Unplanned, Emergency.';
COMMENT ON COLUMN downtime_events.reason_code   IS 'MES reason list code (e.g., MECH-FAIL, TOOL-BREAK, PM-WINDOW, SETUP).';
COMMENT ON COLUMN downtime_events.downtime_minutes IS 'Stop duration in minutes. NULL while event is still open (no downtime_end).';
COMMENT ON COLUMN downtime_events.is_planned    IS 'TRUE for Planned and PM events; FALSE for Unplanned and Emergency.';

-- ─────────────────────────────────────────────────────────────────────────────
-- DOMAIN 3: Sensor Telemetry
-- ─────────────────────────────────────────────────────────────────────────────

-- ---------------------------------------------------------------------------
-- sensor_readings
-- High-volume IoT telemetry. ~200-400M rows/year. Partitioned by month.
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

    CONSTRAINT pk_sensor_readings PRIMARY KEY (reading_id, reading_timestamp)
) PARTITION BY RANGE (reading_timestamp);

COMMENT ON TABLE  sensor_readings                   IS 'IoT sensor telemetry. ~200-400M rows/year. Monthly range partitioned. Source for predictive maintenance ML models.';
COMMENT ON COLUMN sensor_readings.reading_id        IS '64-bit auto-increment surrogate key (composite PK with reading_timestamp for partitioning).';
COMMENT ON COLUMN sensor_readings.sensor_type       IS 'Type code: temperature, vibration, rpm, pressure, power, cutting_force, coolant_flow.';
COMMENT ON COLUMN sensor_readings.sensor_unit       IS 'Measurement unit by type: C, mm/s, RPM, PSI, kWh, N, L/min.';
COMMENT ON COLUMN sensor_readings.is_anomaly_flagged IS 'TRUE if SCADA source system flagged this reading as out-of-range.';
COMMENT ON COLUMN sensor_readings.data_quality_score IS 'SCADA data quality score 0.000-1.000. NULL for pre-2021 sensors; treated as 1.000 downstream.';

-- Create initial monthly partition for current baseline period (2026-01 through 2026-12)
-- Additional partitions created by dag_partition_management Airflow DAG.
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
-- DOMAIN 4 continued: quality_inspections
-- ─────────────────────────────────────────────────────────────────────────────

-- ---------------------------------------------------------------------------
-- quality_inspections
-- One record per quality sampling event per production order.
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

COMMENT ON TABLE  quality_inspections                   IS 'Quality sampling events. One order may have multiple inspections (first-article, in-process, final).';
COMMENT ON COLUMN quality_inspections.inspection_id     IS 'Unique QMS inspection ID. Format: QI-YYYYMMDD-NNNNN.';
COMMENT ON COLUMN quality_inspections.inspection_type_code IS 'Type: FIRST-ARTICLE, IN-PROCESS, FINAL, FUNCTIONAL.';
COMMENT ON COLUMN quality_inspections.defects_found     IS 'Count of defective units in the sample. Must be <= sample_size (enforced by CHECK).';
COMMENT ON COLUMN quality_inspections.pass_fail         IS 'Lot disposition: P = Pass (released), F = Fail (hold/reject).';
COMMENT ON COLUMN quality_inspections.measurement_value IS 'Key quantitative measurement (e.g., bore diameter in mm).';

-- ─────────────────────────────────────────────────────────────────────────────
-- DOMAIN 5 continued: pm_schedules, maintenance_logs, material_movements
-- ─────────────────────────────────────────────────────────────────────────────

-- ---------------------------------------------------------------------------
-- pm_schedules
-- Preventive maintenance schedule per machine.
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

COMMENT ON TABLE  pm_schedules                  IS 'Preventive maintenance schedules per machine. Used to classify downtime as planned vs. unplanned and as ML model input feature.';
COMMENT ON COLUMN pm_schedules.pm_type          IS 'PM activity type (e.g., Lubrication, Filter Service, Spindle Inspection).';
COMMENT ON COLUMN pm_schedules.interval_days    IS 'Calendar-day interval between PM events. NULL if interval_hours is used.';
COMMENT ON COLUMN pm_schedules.interval_hours   IS 'Operating-hours interval between PM events. NULL if interval_days is used.';
COMMENT ON COLUMN pm_schedules.next_due_date    IS 'Calculated next due date. Updated by ETL after each completed PM.';

-- updated_at trigger for pm_schedules
CREATE TRIGGER trg_pm_schedules_updated_at
    BEFORE UPDATE ON pm_schedules
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ---------------------------------------------------------------------------
-- maintenance_logs
-- Work order records for all maintenance activities.
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

COMMENT ON TABLE  maintenance_logs                  IS 'CMMS work order records. Source for MTTR calculation, root cause analysis, and maintenance cost tracking.';
COMMENT ON COLUMN maintenance_logs.work_order_id    IS 'Unique CMMS work order ID. Format: WO-YYYYMMDD-NNNN.';
COMMENT ON COLUMN maintenance_logs.event_type       IS 'Work order type: Planned, Unplanned, Emergency.';
COMMENT ON COLUMN maintenance_logs.failure_code     IS 'CMMS failure category (e.g., FC-MECH, FC-ELEC, FC-HYD). NULL for ~15% of corrective events.';
COMMENT ON COLUMN maintenance_logs.downtime_minutes IS 'Total downtime in minutes. NULL for open (in-progress) work orders.';
COMMENT ON COLUMN maintenance_logs.pm_schedule_id   IS 'FK → pm_schedules for planned events. NULL for unplanned and emergency events.';

-- ---------------------------------------------------------------------------
-- material_movements
-- Inventory transaction log for spare parts consumption.
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

COMMENT ON TABLE  material_movements                IS 'Inventory transaction log — one row per goods issue, receipt, or transfer. Links parts to maintenance work orders.';
COMMENT ON COLUMN material_movements.movement_type  IS 'Transaction type: GOODS_ISSUE, GOODS_RECEIPT, STOCK_TRANSFER, RETURN.';
COMMENT ON COLUMN material_movements.qty            IS 'Quantity moved. Always positive — direction determined by movement_type.';
COMMENT ON COLUMN material_movements.total_cost     IS 'qty * unit_cost. Computed at insert time.';
COMMENT ON COLUMN material_movements.work_order_id  IS 'Associated CMMS work order. NULL for non-maintenance movements.';
