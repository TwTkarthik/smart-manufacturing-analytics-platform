-- =============================================================================
-- constraints.sql
-- SMAP Operational Database — Constraints
-- PostgreSQL 16 compatible.
--
-- Execution order: 4 of 9
-- Run AFTER tables.sql; BEFORE indexes.sql.
--
-- Adds:
--   - Foreign Key constraints (FK)  — naming: fk_{child_table}_{parent_table}
--   - CHECK constraints (CK)        — naming: chk_{table}_{column}
--   - UNIQUE constraints (UQ)       — naming: uq_{table}_{column}
--
-- Canonical numbered source: database/sql/05_constraints.sql
-- =============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 1: FOREIGN KEY CONSTRAINTS
-- Applied after all tables exist to avoid dependency ordering issues.
-- All FK constraints are DEFERRABLE NOT DEFERRABLE (enforced on statement).
-- ─────────────────────────────────────────────────────────────────────────────

-- Domain 1: Reference / Master Data relationships
-- machines → production_lines
ALTER TABLE machines
    ADD CONSTRAINT fk_machines_production_lines
    FOREIGN KEY (line_code) REFERENCES production_lines (line_code);

-- employees → shifts
ALTER TABLE employees
    ADD CONSTRAINT fk_employees_shifts
    FOREIGN KEY (shift_assignment) REFERENCES shifts (shift_code);

-- Domain 2: Production Operations relationships
-- production_orders → machines
ALTER TABLE production_orders
    ADD CONSTRAINT fk_production_orders_machines
    FOREIGN KEY (machine_id) REFERENCES machines (machine_id);

-- production_orders → products
ALTER TABLE production_orders
    ADD CONSTRAINT fk_production_orders_products
    FOREIGN KEY (product_code) REFERENCES products (product_code);

-- production_orders → shifts
ALTER TABLE production_orders
    ADD CONSTRAINT fk_production_orders_shifts
    FOREIGN KEY (shift_code) REFERENCES shifts (shift_code);

-- production_orders → employees (nullable: operator_id NULL for automated cycles)
ALTER TABLE production_orders
    ADD CONSTRAINT fk_production_orders_employees
    FOREIGN KEY (operator_id) REFERENCES employees (employee_id);

-- downtime_events → machines
ALTER TABLE downtime_events
    ADD CONSTRAINT fk_downtime_events_machines
    FOREIGN KEY (machine_id) REFERENCES machines (machine_id);

-- downtime_events → production_orders (nullable: stop may occur between orders)
ALTER TABLE downtime_events
    ADD CONSTRAINT fk_downtime_events_production_orders
    FOREIGN KEY (order_id) REFERENCES production_orders (order_id);

-- downtime_events → employees (nullable: reporter may be NULL for auto-detected stops)
ALTER TABLE downtime_events
    ADD CONSTRAINT fk_downtime_events_employees
    FOREIGN KEY (reported_by) REFERENCES employees (employee_id);

-- Domain 3: Sensor Telemetry
-- sensor_readings → machines
-- Note: Applied on the parent partitioned table — applies to ALL partitions automatically.
ALTER TABLE sensor_readings
    ADD CONSTRAINT fk_sensor_readings_machines
    FOREIGN KEY (machine_id) REFERENCES machines (machine_id);

-- Domain 4: Quality Management
-- quality_inspections → production_orders
ALTER TABLE quality_inspections
    ADD CONSTRAINT fk_quality_inspections_production_orders
    FOREIGN KEY (order_id) REFERENCES production_orders (order_id);

-- quality_inspections → machines
ALTER TABLE quality_inspections
    ADD CONSTRAINT fk_quality_inspections_machines
    FOREIGN KEY (machine_id) REFERENCES machines (machine_id);

-- quality_inspections → employees (nullable: automated gauging has no inspector)
ALTER TABLE quality_inspections
    ADD CONSTRAINT fk_quality_inspections_employees
    FOREIGN KEY (inspector_id) REFERENCES employees (employee_id);

-- quality_inspections → defect_types (nullable: NULL if no defect found or code missing)
ALTER TABLE quality_inspections
    ADD CONSTRAINT fk_quality_inspections_defect_types
    FOREIGN KEY (defect_type_code) REFERENCES defect_types (defect_type_code);

-- Domain 5: Maintenance Management
-- pm_schedules → machines
ALTER TABLE pm_schedules
    ADD CONSTRAINT fk_pm_schedules_machines
    FOREIGN KEY (machine_id) REFERENCES machines (machine_id);

-- maintenance_logs → machines
ALTER TABLE maintenance_logs
    ADD CONSTRAINT fk_maintenance_logs_machines
    FOREIGN KEY (machine_id) REFERENCES machines (machine_id);

-- maintenance_logs → employees (nullable: technician may be unassigned at extraction)
ALTER TABLE maintenance_logs
    ADD CONSTRAINT fk_maintenance_logs_employees
    FOREIGN KEY (technician_id) REFERENCES employees (employee_id);

-- maintenance_logs → pm_schedules (nullable: NULL for unplanned and emergency events)
ALTER TABLE maintenance_logs
    ADD CONSTRAINT fk_maintenance_logs_pm_schedules
    FOREIGN KEY (pm_schedule_id) REFERENCES pm_schedules (pm_schedule_id);

-- material_movements → spare_parts
ALTER TABLE material_movements
    ADD CONSTRAINT fk_material_movements_spare_parts
    FOREIGN KEY (part_code) REFERENCES spare_parts (part_code);

-- material_movements → maintenance_logs (nullable: NULL for goods receipts and transfers)
ALTER TABLE material_movements
    ADD CONSTRAINT fk_material_movements_maintenance_logs
    FOREIGN KEY (work_order_id) REFERENCES maintenance_logs (work_order_id);


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 2: CHECK CONSTRAINTS
-- Enforce allowed-values lists and business rules at the database layer.
-- ─────────────────────────────────────────────────────────────────────────────

-- production_lines
ALTER TABLE production_lines
    ADD CONSTRAINT chk_production_lines_plant_code
    CHECK (plant_code IN ('PLT-DET', 'PLT-CLV', 'PLT-CHI', 'PLT-MTY'));

ALTER TABLE production_lines
    ADD CONSTRAINT chk_production_lines_oee_target
    CHECK (oee_target IS NULL OR (oee_target >= 0 AND oee_target <= 1));

-- shifts
ALTER TABLE shifts
    ADD CONSTRAINT chk_shifts_plant_code
    CHECK (plant_code IN ('PLT-DET', 'PLT-CLV', 'PLT-CHI', 'PLT-MTY'));

ALTER TABLE shifts
    ADD CONSTRAINT chk_shifts_duration
    CHECK (shift_duration_hours > 0
           AND planned_production_hours > 0
           AND planned_production_hours <= shift_duration_hours);

-- machines
ALTER TABLE machines
    ADD CONSTRAINT chk_machines_machine_type_code
    CHECK (machine_type_code IN (
        'MCH-LATHE', 'MCH-MILL', 'MCH-GRIND',
        'MCH-PRESS', 'MCH-CMM',  'MCH-CONV', 'MCH-ASSY'
    ));

ALTER TABLE machines
    ADD CONSTRAINT chk_machines_plant_code
    CHECK (plant_code IN ('PLT-DET', 'PLT-CLV', 'PLT-CHI', 'PLT-MTY'));

ALTER TABLE machines
    ADD CONSTRAINT chk_machines_rated_capacity
    CHECK (rated_capacity_per_hour IS NULL OR rated_capacity_per_hour > 0);

-- products
ALTER TABLE products
    ADD CONSTRAINT chk_products_standard_cycle_time
    CHECK (standard_cycle_time_sec > 0);

ALTER TABLE products
    ADD CONSTRAINT chk_products_standard_material_cost
    CHECK (standard_material_cost IS NULL OR standard_material_cost >= 0);

ALTER TABLE products
    ADD CONSTRAINT chk_products_standard_labor_cost
    CHECK (standard_labor_cost IS NULL OR standard_labor_cost >= 0);

-- employees
ALTER TABLE employees
    ADD CONSTRAINT chk_employees_role_code
    CHECK (role_code IN ('OPR-MCH', 'OPR-SET', 'QA-TECH', 'MNT-TECH', 'MNT-PLNR'));

ALTER TABLE employees
    ADD CONSTRAINT chk_employees_department_code
    CHECK (department_code IN ('DEPT-OPS', 'DEPT-QA', 'DEPT-MNT', 'DEPT-ENG'));

ALTER TABLE employees
    ADD CONSTRAINT chk_employees_skill_level
    CHECK (skill_level IS NULL OR skill_level IN ('Junior', 'Senior', 'Expert'));

-- production_orders
ALTER TABLE production_orders
    ADD CONSTRAINT chk_production_orders_status
    CHECK (status IN ('Pending', 'In Progress', 'Complete', 'Cancelled'));

ALTER TABLE production_orders
    ADD CONSTRAINT chk_production_orders_planned_units
    CHECK (planned_units > 0);

ALTER TABLE production_orders
    ADD CONSTRAINT chk_production_orders_actual_units
    CHECK (actual_units IS NULL OR actual_units >= 0);

ALTER TABLE production_orders
    ADD CONSTRAINT chk_production_orders_good_units
    CHECK (good_units IS NULL OR good_units >= 0);

ALTER TABLE production_orders
    ADD CONSTRAINT chk_production_orders_scrap_units
    CHECK (scrap_units IS NULL OR scrap_units >= 0);

ALTER TABLE production_orders
    ADD CONSTRAINT chk_production_orders_rework_units
    CHECK (rework_units IS NULL OR rework_units >= 0);

-- Temporal consistency: actual_end must be >= actual_start when both are populated
ALTER TABLE production_orders
    ADD CONSTRAINT chk_production_orders_timestamps
    CHECK (actual_end IS NULL OR actual_start IS NULL OR actual_end >= actual_start);

-- downtime_events
ALTER TABLE downtime_events
    ADD CONSTRAINT chk_downtime_events_event_type
    CHECK (event_type IN ('Planned', 'Unplanned', 'Emergency'));

ALTER TABLE downtime_events
    ADD CONSTRAINT chk_downtime_events_downtime_minutes
    CHECK (downtime_minutes IS NULL OR downtime_minutes >= 0);

ALTER TABLE downtime_events
    ADD CONSTRAINT chk_downtime_events_timestamps
    CHECK (downtime_end IS NULL OR downtime_end >= downtime_start);

-- sensor_readings (applied on parent — propagates to all partitions)
ALTER TABLE sensor_readings
    ADD CONSTRAINT chk_sensor_readings_sensor_type
    CHECK (sensor_type IN (
        'temperature', 'vibration', 'rpm', 'pressure',
        'power', 'cutting_force', 'coolant_flow'
    ));

ALTER TABLE sensor_readings
    ADD CONSTRAINT chk_sensor_readings_sensor_unit
    CHECK (sensor_unit IN ('C', 'mm/s', 'RPM', 'PSI', 'kWh', 'N', 'L/min'));

ALTER TABLE sensor_readings
    ADD CONSTRAINT chk_sensor_readings_data_quality_score
    CHECK (data_quality_score IS NULL
           OR (data_quality_score >= 0 AND data_quality_score <= 1));

-- quality_inspections
ALTER TABLE quality_inspections
    ADD CONSTRAINT chk_quality_inspections_inspection_type
    CHECK (inspection_type_code IN (
        'FIRST-ARTICLE', 'IN-PROCESS', 'FINAL', 'FUNCTIONAL'
    ));

ALTER TABLE quality_inspections
    ADD CONSTRAINT chk_quality_inspections_sample_size
    CHECK (sample_size >= 0);

-- Business rule: defects_found cannot exceed sample_size
ALTER TABLE quality_inspections
    ADD CONSTRAINT chk_quality_inspections_defects_found
    CHECK (defects_found >= 0 AND defects_found <= sample_size);

ALTER TABLE quality_inspections
    ADD CONSTRAINT chk_quality_inspections_pass_fail
    CHECK (pass_fail IN ('P', 'F'));

-- defect_types
ALTER TABLE defect_types
    ADD CONSTRAINT chk_defect_types_defect_category
    CHECK (defect_category IN (
        'Dimensional', 'Surface', 'Structural', 'Functional', 'Other'
    ));

ALTER TABLE defect_types
    ADD CONSTRAINT chk_defect_types_severity_level
    CHECK (severity_level IN ('Critical', 'Major', 'Minor'));

-- maintenance_logs
ALTER TABLE maintenance_logs
    ADD CONSTRAINT chk_maintenance_logs_event_type
    CHECK (event_type IN ('Planned', 'Unplanned', 'Emergency'));

ALTER TABLE maintenance_logs
    ADD CONSTRAINT chk_maintenance_logs_downtime_minutes
    CHECK (downtime_minutes IS NULL OR downtime_minutes >= 0);

ALTER TABLE maintenance_logs
    ADD CONSTRAINT chk_maintenance_logs_repair_cost
    CHECK (repair_cost IS NULL OR repair_cost >= 0);

ALTER TABLE maintenance_logs
    ADD CONSTRAINT chk_maintenance_logs_timestamps
    CHECK (downtime_end IS NULL OR downtime_end >= downtime_start);

-- pm_schedules
ALTER TABLE pm_schedules
    ADD CONSTRAINT chk_pm_schedules_interval_days
    CHECK (interval_days IS NULL OR interval_days > 0);

ALTER TABLE pm_schedules
    ADD CONSTRAINT chk_pm_schedules_interval_hours
    CHECK (interval_hours IS NULL OR interval_hours > 0);

-- Business rule: at least one interval type must be specified
ALTER TABLE pm_schedules
    ADD CONSTRAINT chk_pm_schedules_interval_set
    CHECK (interval_days IS NOT NULL OR interval_hours IS NOT NULL);

-- spare_parts
ALTER TABLE spare_parts
    ADD CONSTRAINT chk_spare_parts_part_category
    CHECK (part_category IS NULL OR
           part_category IN (
               'Bearings', 'Seals', 'Filters', 'Belts',
               'Electronics', 'Hydraulics', 'Tooling', 'Other'
           ));

ALTER TABLE spare_parts
    ADD CONSTRAINT chk_spare_parts_stock_qty
    CHECK (stock_qty >= 0);

ALTER TABLE spare_parts
    ADD CONSTRAINT chk_spare_parts_reorder_point
    CHECK (reorder_point IS NULL OR reorder_point >= 0);

ALTER TABLE spare_parts
    ADD CONSTRAINT chk_spare_parts_lead_time_days
    CHECK (lead_time_days IS NULL OR lead_time_days >= 0);

ALTER TABLE spare_parts
    ADD CONSTRAINT chk_spare_parts_unit_cost
    CHECK (unit_cost IS NULL OR unit_cost >= 0);

-- material_movements
ALTER TABLE material_movements
    ADD CONSTRAINT chk_material_movements_movement_type
    CHECK (movement_type IN (
        'GOODS_ISSUE', 'GOODS_RECEIPT', 'STOCK_TRANSFER', 'RETURN'
    ));

ALTER TABLE material_movements
    ADD CONSTRAINT chk_material_movements_qty
    CHECK (qty > 0);

ALTER TABLE material_movements
    ADD CONSTRAINT chk_material_movements_unit_cost
    CHECK (unit_cost IS NULL OR unit_cost >= 0);


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 3: UNIQUE CONSTRAINTS
-- Business-level uniqueness beyond primary key enforcement.
-- ─────────────────────────────────────────────────────────────────────────────

-- machines: SCADA tag names must be globally unique (ETL key resolution)
ALTER TABLE machines
    ADD CONSTRAINT uq_machines_scada_tag_name
    UNIQUE (scada_tag_name);

-- machines: CMMS asset tag numbers must be globally unique (ETL key resolution)
ALTER TABLE machines
    ADD CONSTRAINT uq_machines_asset_tag_number
    UNIQUE (asset_tag_number);

-- products: ERP material code must be unique where present
-- Note: UNIQUE constraints implicitly allow multiple NULLs in PostgreSQL.
ALTER TABLE products
    ADD CONSTRAINT uq_products_erp_material_code
    UNIQUE (erp_material_code);

-- production_orders: ERP order cross-reference must be unique where present
ALTER TABLE production_orders
    ADD CONSTRAINT uq_production_orders_erp_order_id
    UNIQUE (erp_order_id);
