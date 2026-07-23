# Data Dictionary — Smart Manufacturing Analytics Platform (SMAP)

**Document Version:** 1.0.0
**Last Updated:** 2026-07-22
**Status:** Approved — Complete Design Baseline
**Owner:** Lead Database Architect
**Related Documents:**
- [../DATABASE_DESIGN.md](../DATABASE_DESIGN.md)
- [DB_ER_DIAGRAM.md](./DB_ER_DIAGRAM.md)
- [DB_INDEXING_STRATEGY.md](./DB_INDEXING_STRATEGY.md)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Operational Database Tables](#2-operational-database-tables)
   - 2.1 [machines](#21-machines)
   - 2.2 [production_lines](#22-production_lines)
   - 2.3 [products](#23-products)
   - 2.4 [employees](#24-employees)
   - 2.5 [shifts](#25-shifts)
   - 2.6 [production_orders](#26-production_orders)
   - 2.7 [downtime_events](#27-downtime_events)
   - 2.8 [sensor_readings](#28-sensor_readings)
   - 2.9 [quality_inspections](#29-quality_inspections)
   - 2.10 [defect_types](#210-defect_types)
   - 2.11 [maintenance_logs](#211-maintenance_logs)
   - 2.12 [pm_schedules](#212-pm_schedules)
   - 2.13 [spare_parts](#213-spare_parts)
   - 2.14 [material_movements](#214-material_movements)
3. [Warehouse Dimension Tables](#3-warehouse-dimension-tables)
   - 3.1 [dim_date](#31-dim_date)
   - 3.2 [dim_machine](#32-dim_machine)
   - 3.3 [dim_product](#33-dim_product)
   - 3.4 [dim_employee](#34-dim_employee)
   - 3.5 [dim_shift](#35-dim_shift)
   - 3.6 [dim_defect_type](#36-dim_defect_type)
   - 3.7 [dim_failure_code](#37-dim_failure_code)
4. [Warehouse Fact Tables](#4-warehouse-fact-tables)
   - 4.1 [fct_production](#41-fct_production)
   - 4.2 [fct_quality_inspection](#42-fct_quality_inspection)
   - 4.3 [fct_sensor_reading](#43-fct_sensor_reading)
   - 4.4 [fct_maintenance_event](#44-fct_maintenance_event)

---

## 1. Overview

This Data Dictionary is the definitive column-level reference for every table in the SMAP database layer.
For each table it documents: **purpose**, every **column** with data type, nullability, constraints, default
value, and business meaning.

**Legend:**

| Symbol | Meaning |
|---|---|
| PK | Primary Key |
| FK | Foreign Key |
| NN | NOT NULL constraint |
| UQ | UNIQUE constraint |
| CK | CHECK constraint |
| DEF | Column has a DEFAULT value |

---

## 2. Operational Database Tables

### 2.1 `machines`

**Purpose:** Master register of all production machines and equipment across all PrecisionEdge facilities.
One record per physical machine asset. Updated via SCD Type 1 when machine attributes change.

**Source System:** MES machine master (primary) + ERP work center catalog (supplementary)

| Column | Type | Constraints | Default | Business Meaning |
|---|---|---|---|---|
| `machine_id` | VARCHAR(20) | PK, NN, UQ | — | Unique machine identifier from MES (e.g., MCH-001 through MCH-048). Format: MCH-{3-digit sequence}. |
| `machine_name` | VARCHAR(100) | NN | — | Human-readable descriptive name (e.g., "CNC Turning Center #1 — LINE-A"). |
| `machine_type_code` | VARCHAR(20) | NN, CK | — | Equipment category code. Accepted values: MCH-LATHE, MCH-MILL, MCH-GRIND, MCH-PRESS, MCH-CMM, MCH-CONV, MCH-ASSY. |
| `line_code` | VARCHAR(10) | NN, FK(production_lines) | — | Production line assignment. References production_lines.line_code. |
| `plant_code` | VARCHAR(10) | NN, CK | — | Facility code. Accepted values: PLT-DET, PLT-CLV, PLT-CHI, PLT-MTY. |
| `manufacturer` | VARCHAR(100) | NULL | — | Equipment manufacturer name (e.g., Mazak, DMG Mori, Cincinnati). |
| `model_number` | VARCHAR(50) | NULL | — | Manufacturer model designation (e.g., Mazak INTEGREX i-400). |
| `rated_capacity_per_hour` | NUMERIC(10,2) | NULL, CK(>0) | — | Theoretical maximum output units per hour at 100% speed. Source: ERP routing standard. |
| `install_date` | DATE | NULL | — | Date machine was commissioned into production at this facility. |
| `is_active` | BOOLEAN | NN | TRUE | Whether machine is currently in service. FALSE for decommissioned or mothballed assets. |
| `scada_tag_name` | VARCHAR(50) | NULL, UQ | — | SCADA system PLC tag name (e.g., CELL_A1_LATHE_01). Used by ETL to resolve SCADA readings to machine_id. |
| `asset_tag_number` | VARCHAR(20) | NULL, UQ | — | CMMS asset tag number (e.g., AT-0042). Used by ETL to resolve maintenance work orders. |
| `erp_work_center_code` | VARCHAR(20) | NULL | — | SAP work center code for cross-referencing ERP production orders. |
| `created_at` | TIMESTAMPTZ | NN | now() | UTC timestamp when the record was first inserted. |
| `updated_at` | TIMESTAMPTZ | NN | now() | UTC timestamp of the most recent update to any field. Updated by trigger on change. |

---

### 2.2 `production_lines`

**Purpose:** Logical production line hierarchy above individual machines. PLT-DET has four lines
(LINE-A through LINE-D); total across all facilities up to LINE-K. Static reference data seeded at setup.

| Column | Type | Constraints | Default | Business Meaning |
|---|---|---|---|---|
| `line_code` | VARCHAR(10) | PK, NN, UQ | — | Unique line identifier (e.g., LINE-A, LINE-B). |
| `line_name` | VARCHAR(100) | NN | — | Display name (e.g., "Powertrain Turning Cell"). |
| `plant_code` | VARCHAR(10) | NN, CK | — | Facility this line belongs to. Accepted values: PLT-DET, PLT-CLV, PLT-CHI, PLT-MTY. |
| `primary_operation` | VARCHAR(100) | NULL | — | Brief description of the primary manufacturing operation (e.g., "CNC Turning and Grinding"). |
| `shift_pattern` | VARCHAR(50) | NULL | — | Shift schedule description (e.g., "3-shift, 6 days/week"). |
| `oee_target` | NUMERIC(5,4) | NULL, CK(0..1) | — | Plant-configured fleet OEE target for this line (e.g., 0.8100 for 81%). |
| `is_active` | BOOLEAN | NN | TRUE | Whether this line is currently in production. |

---

### 2.3 `products`

**Purpose:** Product/SKU master with three-level hierarchy. Provides the standard cycle time used in
OEE Performance calculation and standard costs used in scrap cost reporting.

**Source System:** ERP material master (primary); MES product codes (secondary)

| Column | Type | Constraints | Default | Business Meaning |
|---|---|---|---|---|
| `product_code` | VARCHAR(30) | PK, NN, UQ | — | Unique product identifier from MES (e.g., PRD-001 through PRD-008). |
| `product_name` | VARCHAR(100) | NN | — | Full product name (e.g., "Crankshaft Bearing Journal — Type A"). |
| `product_family` | VARCHAR(50) | NN | — | Product family grouping (e.g., "Powertrain Components", "Brake Components"). |
| `product_category` | VARCHAR(50) | NN | — | Top-level category (e.g., "Automotive", "Industrial"). |
| `standard_cycle_time_sec` | NUMERIC(10,3) | NN, CK(>0) | — | Target cycle time per unit in seconds. Sourced from ERP routing. Used as OEE Performance denominator. |
| `standard_material_cost` | NUMERIC(15,4) | NULL, CK(>=0) | — | Standard material cost per unit in USD. Used for scrap cost calculation. |
| `standard_labor_cost` | NUMERIC(15,4) | NULL, CK(>=0) | — | Standard labor cost per unit in USD. |
| `is_active` | BOOLEAN | NN | TRUE | Whether product is currently in production at PrecisionEdge. |
| `erp_material_code` | VARCHAR(30) | NULL, UQ | — | SAP material code for cross-system traceability. |
| `created_at` | TIMESTAMPTZ | NN | now() | UTC timestamp of record creation. |
| `updated_at` | TIMESTAMPTZ | NN | now() | UTC timestamp of most recent update. |

---

### 2.4 `employees`

**Purpose:** Anonymized operator and technician roster. Provides role, department, shift assignment,
and skill level for quality traceability and maintenance response analysis. Employee names
are intentionally excluded per PrecisionEdge privacy policy.

**Source System:** Workday HRIS daily CSV export

| Column | Type | Constraints | Default | Business Meaning |
|---|---|---|---|---|
| `employee_id` | VARCHAR(20) | PK, NN, UQ | — | Anonymized employee identifier from HRIS (e.g., EMP-1042). Never maps to a real person without the HR key vault. |
| `role_code` | VARCHAR(20) | NN, CK | — | Role classification. Accepted values: OPR-MCH (machine operator), OPR-SET (setup tech), QA-TECH (quality technician), MNT-TECH (maintenance technician), MNT-PLNR (maintenance planner). |
| `role_name` | VARCHAR(50) | NN | — | Role display name. |
| `department_code` | VARCHAR(20) | NN, CK | — | Department. Accepted values: DEPT-OPS, DEPT-QA, DEPT-MNT, DEPT-ENG. |
| `shift_assignment` | VARCHAR(10) | NN, FK(shifts) | — | Primary assigned shift. References shifts.shift_code. |
| `skill_level` | VARCHAR(20) | NULL, CK | — | Skill classification. Accepted values: Junior, Senior, Expert. |
| `training_certifications` | TEXT | NULL | — | Comma-separated list of certifications relevant to quality and safety (e.g., "IATF-16949, Lock-Out-Tag-Out"). |
| `hire_date` | DATE | NULL | — | Date employee joined PrecisionEdge. Used for tenure calculation. |
| `is_active` | BOOLEAN | NN | TRUE | Whether employee is currently employed and active on the production floor. |
| `is_automated` | BOOLEAN | NN | FALSE | TRUE for the special EMP-ROBOT entry representing auto-cycle machine records with no human operator. |
| `created_at` | TIMESTAMPTZ | NN | now() | UTC timestamp of record creation (first extracted from HRIS). |
| `updated_at` | TIMESTAMPTZ | NN | now() | UTC timestamp of most recent update. |

---

### 2.5 `shifts`

**Purpose:** Reference table defining the three 8-hour shift windows and their scheduled production time.
Static data seeded via dbt seeds at platform initialization. Not modified during normal operations.

| Column | Type | Constraints | Default | Business Meaning |
|---|---|---|---|---|
| `shift_code` | VARCHAR(10) | PK, NN, UQ | — | Unique shift identifier (SHIFT-A, SHIFT-B, SHIFT-C). |
| `shift_name` | VARCHAR(50) | NN | — | Display name (e.g., "Day Shift", "Afternoon Shift", "Night Shift"). |
| `shift_start_time` | TIME | NN | — | Scheduled start time in local plant time (e.g., 06:00:00 for Day Shift at PLT-DET). |
| `shift_end_time` | TIME | NN | — | Scheduled end time in local plant time (e.g., 14:00:00 for Day Shift). |
| `shift_duration_hours` | NUMERIC(4,2) | NN, CK(>0) | — | Total shift duration in hours (typically 8.00). |
| `planned_production_hours` | NUMERIC(4,2) | NN, CK(>0) | — | Planned production time after deducting scheduled breaks (typically 7.50 for a 30-min break). |
| `plant_code` | VARCHAR(10) | NN, CK | — | Facility this shift definition applies to. |

---

### 2.6 `production_orders`

**Purpose:** The core production transaction table. One row per discrete manufacturing work order.
Links a machine, product, shift, and operator to planned and actual output quantities.
All OEE calculations originate from this table.

**Source System:** MES (actual data) + ERP (planned data, joined via order_id)

| Column | Type | Constraints | Default | Business Meaning |
|---|---|---|---|---|
| `order_id` | VARCHAR(30) | PK, NN, UQ | — | Unique production order ID from MES (e.g., MES-20260722-00042). |
| `machine_id` | VARCHAR(20) | NN, FK(machines) | — | Machine on which this order was run. |
| `product_code` | VARCHAR(30) | NN, FK(products) | — | Product being manufactured in this order. |
| `shift_code` | VARCHAR(10) | NN, FK(shifts) | — | Shift during which the order ran. |
| `operator_id` | VARCHAR(20) | NULL, FK(employees) | — | Primary operator ID. NULL for fully automated machine cycles (stored as EMP-ROBOT instead). |
| `planned_start` | TIMESTAMPTZ | NN | — | Scheduled start time from ERP production order. UTC. |
| `actual_start` | TIMESTAMPTZ | NULL | — | Actual start time from MES. NULL if order not yet started. |
| `actual_end` | TIMESTAMPTZ | NULL | — | Actual end time from MES. NULL if order is still in progress or not yet started. |
| `planned_units` | INTEGER | NN, CK(>0) | — | Target output quantity from the production order. |
| `actual_units` | INTEGER | NULL, CK(>=0) | — | Total units produced (good + scrap + rework). NULL if order is in progress. |
| `good_units` | INTEGER | NULL, CK(>=0) | — | Units passing first-pass quality inspection. Numerator of OEE Quality component. |
| `scrap_units` | INTEGER | NULL, CK(>=0) | — | Units scrapped — failed quality with no rework path. |
| `rework_units` | INTEGER | NULL, CK(>=0) | — | Units requiring rework — not counted as good in OEE Quality per standard methodology. |
| `status` | VARCHAR(20) | NN, CK | "Pending" | Order status. Accepted values: Pending, In Progress, Complete, Cancelled. |
| `erp_order_id` | VARCHAR(30) | NULL, UQ | — | Corresponding ERP production order number (format: PP-YYYYMMDD-XXXXX). Used for cross-system tracing. |
| `created_at` | TIMESTAMPTZ | NN | now() | UTC timestamp when the order was created in MES. |
| `updated_at` | TIMESTAMPTZ | NN | now() | UTC timestamp of the most recent status update. |

---

### 2.7 `downtime_events`

**Purpose:** Every recorded machine stop event. Each row represents one contiguous downtime interval
with reason code, duration, and event type classification. The primary source for OEE Availability
calculation and MTBF/MTTR analysis.

**Source System:** MES (operator-entered or machine-triggered stop events)

| Column | Type | Constraints | Default | Business Meaning |
|---|---|---|---|---|
| `event_id` | VARCHAR(30) | PK, NN, UQ | — | Unique event identifier from MES (e.g., DT-20260722-00123). |
| `machine_id` | VARCHAR(20) | NN, FK(machines) | — | Machine that experienced the stop event. |
| `order_id` | VARCHAR(30) | NULL, FK(production_orders) | — | Production order that was active when this stop occurred. NULL if machine stopped between orders. |
| `event_type` | VARCHAR(30) | NN, CK | — | Event classification. Accepted values: Planned, Unplanned, Emergency. |
| `reason_code` | VARCHAR(30) | NULL | — | Specific reason code from MES reason list (e.g., MECH-FAIL, TOOL-BREAK, PM-WINDOW, SETUP). |
| `reason_description` | TEXT | NULL | — | Free-text description of the stop reason as entered by the operator. |
| `downtime_start` | TIMESTAMPTZ | NN | — | UTC timestamp when the machine stopped. |
| `downtime_end` | TIMESTAMPTZ | NULL | — | UTC timestamp when the machine returned to service. NULL for events still open at extraction time. |
| `downtime_minutes` | NUMERIC(10,2) | NULL, CK(>=0) | — | Total stop duration in minutes. NULL if downtime_end is NULL. Populated by ETL from timestamps. |
| `reported_by` | VARCHAR(20) | NULL, FK(employees) | — | Employee ID of the operator who logged the event. |
| `is_planned` | BOOLEAN | NN | FALSE | TRUE for Planned and PM events; FALSE for Unplanned and Emergency. Derived from event_type at insert time. |
| `created_at` | TIMESTAMPTZ | NN | now() | UTC timestamp when the event record was created. |

---

### 2.8 `sensor_readings`

**Purpose:** High-volume IoT telemetry table. One record per sensor measurement event (every
30–60 seconds per sensor across 384 sensors at PLT-DET). The primary data source for
predictive maintenance and anomaly detection ML models.

**Source System:** Siemens WinCC SCADA via PostgreSQL gateway database (SRC-IOT)

**Volume:** ~554K–1.1M rows/day; ~200–400M rows/year

| Column | Type | Constraints | Default | Business Meaning |
|---|---|---|---|---|
| `reading_id` | BIGSERIAL | PK, NN | Auto | System-generated surrogate key. 64-bit to accommodate 400M+ annual rows. |
| `machine_id` | VARCHAR(20) | NN, FK(machines) | — | Machine this reading was captured from. Resolved from SCADA tag via ETL mapping table. |
| `sensor_type` | VARCHAR(30) | NN, CK | — | Sensor type. Accepted values: temperature, vibration, rpm, pressure, power, cutting_force, coolant_flow. |
| `sensor_unit` | VARCHAR(10) | NN, CK | — | Unit of measurement. Values by type: temperature=C, vibration=mm/s, rpm=RPM, pressure=PSI, power=kWh, cutting_force=N, coolant_flow=L/min. |
| `value` | NUMERIC(14,6) | NN | — | Raw sensor measurement value. Range validated per sensor_type in the Great Expectations suite. |
| `reading_timestamp` | TIMESTAMPTZ | NN | — | Exact UTC timestamp of the reading. Normalized to UTC at ETL ingestion (SCADA clock drift handled). |
| `is_anomaly_flagged` | BOOLEAN | NN | FALSE | TRUE if the SCADA source system itself flagged this reading as out-of-range or anomalous. |
| `data_quality_score` | NUMERIC(4,3) | NULL, CK(0..1) | — | Sensor data quality confidence score from SCADA (0.000 = low quality, 1.000 = high quality). NULL for pre-2021 sensors; treated as 1.000 in downstream models. |

> **Index:** BRIN index on `reading_timestamp` (append-only, time-ordered data). B-tree composite index on `(machine_id, sensor_type, reading_timestamp)` for ML feature queries. See [DB_INDEXING_STRATEGY.md](./DB_INDEXING_STRATEGY.md).

---

### 2.9 `quality_inspections`

**Purpose:** One record per quality sampling event. A single production order may generate multiple
inspection records (first article, multiple in-process checks, final inspection). The primary
source for defect rate, First Pass Yield, and SPC chart data.

**Source System:** MachineLink Quality module (QMS — same PostgreSQL instance as MES)

| Column | Type | Constraints | Default | Business Meaning |
|---|---|---|---|---|
| `inspection_id` | VARCHAR(30) | PK, NN, UQ | — | Unique inspection identifier from QMS (e.g., QI-20260722-00089). |
| `order_id` | VARCHAR(30) | NN, FK(production_orders) | — | Production order this inspection is associated with. |
| `machine_id` | VARCHAR(20) | NN, FK(machines) | — | Machine on which the inspected parts were produced. |
| `inspector_id` | VARCHAR(20) | NULL, FK(employees) | — | Employee ID of the inspector. NULL for automated gauging systems. |
| `inspection_type_code` | VARCHAR(20) | NN, CK | — | Inspection type. Accepted values: FIRST-ARTICLE, IN-PROCESS, FINAL, FUNCTIONAL. |
| `inspection_timestamp` | TIMESTAMPTZ | NN | — | UTC timestamp when the inspection event occurred. |
| `sample_size` | INTEGER | NN, CK(>=0) | — | Number of units included in this sampling event. |
| `defects_found` | INTEGER | NN, CK(>=0) | — | Number of defective units found in the sample. Must be <= sample_size. |
| `defect_type_code` | VARCHAR(20) | NULL, FK(defect_types) | — | Primary defect category code. NULL if sample passes or defect code not assigned (~8% of defective records). Treated as DFT-OTHER in dbt models. |
| `defect_description` | TEXT | NULL | — | Free-text description of defect characteristics. Inconsistently populated. |
| `measurement_value` | NUMERIC(12,6) | NULL | — | Key quantitative measurement value (e.g., bore diameter in mm). |
| `measurement_unit` | VARCHAR(20) | NULL | — | Unit of the measurement value (e.g., mm, N/mm2). |
| `pass_fail` | CHAR(1) | NN, CK | — | Lot disposition. P = Pass (lot released), F = Fail (lot rejected or placed on hold). |
| `created_at` | TIMESTAMPTZ | NN | now() | UTC timestamp of record creation. |

---

### 2.10 `defect_types`

**Purpose:** Reference table of defect classification codes with a two-level hierarchy
(defect type → category) and severity level. Supports Pareto analysis and defect trend reporting.

**Source System:** QMS defect_types table (static reference, updated infrequently)

| Column | Type | Constraints | Default | Business Meaning |
|---|---|---|---|---|
| `defect_type_code` | VARCHAR(20) | PK, NN, UQ | — | Unique defect code from QMS (e.g., DFT-DIM, DFT-SURF, DFT-STRUCT). |
| `defect_type_name` | VARCHAR(100) | NN | — | Full defect type name (e.g., "Dimensional Out-of-Specification"). |
| `defect_category` | VARCHAR(50) | NN, CK | — | Pareto grouping. Accepted values: Dimensional, Surface, Structural, Functional, Other. |
| `severity_level` | VARCHAR(20) | NN, CK | — | Impact severity. Accepted values: Critical, Major, Minor. |
| `is_customer_escape_risk` | BOOLEAN | NN | FALSE | TRUE for defect types that may escape to the customer undetected if not 100% inspected. |
| `description` | TEXT | NULL | — | Detailed description of the defect type, common root causes, and typical detection method. |
| `is_active` | BOOLEAN | NN | TRUE | Whether this code is currently active in the QMS. |

---

### 2.11 `maintenance_logs`

**Purpose:** Work order records for all maintenance activities — planned (PM), unplanned (breakdown),
and emergency. The primary source for MTTR calculation, failure root cause analysis, repair cost
tracking, and predictive maintenance ML model labeling.

**Source System:** MachineLink Maintenance CMMS module — nightly CSV export

| Column | Type | Constraints | Default | Business Meaning |
|---|---|---|---|---|
| `work_order_id` | VARCHAR(30) | PK, NN, UQ | — | Unique work order identifier from CMMS (e.g., WO-20260722-0023). |
| `machine_id` | VARCHAR(20) | NN, FK(machines) | — | Machine that required maintenance. |
| `technician_id` | VARCHAR(20) | NULL, FK(employees) | — | Assigned maintenance technician ID. NULL if unassigned at extraction time. |
| `event_type` | VARCHAR(30) | NN, CK | — | Work order type. Accepted values: Planned, Unplanned, Emergency. |
| `failure_code` | VARCHAR(20) | NULL | — | Failure category code from CMMS (e.g., FC-MECH, FC-ELEC, FC-HYD). NULL for ~15% of corrective events. |
| `description` | TEXT | NULL | — | Technician description of the issue or planned work. |
| `downtime_start` | TIMESTAMPTZ | NN | — | UTC timestamp when machine went offline. |
| `downtime_end` | TIMESTAMPTZ | NULL | — | UTC timestamp when machine returned to service. NULL for open work orders. |
| `downtime_minutes` | NUMERIC(10,2) | NULL, CK(>=0) | — | Total downtime duration in minutes. NULL for open WOs. |
| `repair_cost` | NUMERIC(15,4) | NULL, CK(>=0) | — | Total repair cost (labor + parts) in USD. |
| `root_cause` | TEXT | NULL | — | Root cause analysis notes written by the technician or maintenance planner. ~30% completion rate. |
| `pm_schedule_id` | INTEGER | NULL, FK(pm_schedules) | — | Links planned maintenance events back to the PM schedule that generated them. NULL for unplanned events. |
| `created_at` | TIMESTAMPTZ | NN | now() | UTC timestamp when the work order record was created (from CMMS export). |

---

### 2.12 `pm_schedules`

**Purpose:** Preventive maintenance schedules defining the planned maintenance intervals per machine.
Used to classify downtime events as planned vs. unplanned and as an input feature
(days_since_last_pm) for the predictive maintenance ML model.

| Column | Type | Constraints | Default | Business Meaning |
|---|---|---|---|---|
| `pm_schedule_id` | SERIAL | PK, NN | Auto | System-generated surrogate key. |
| `machine_id` | VARCHAR(20) | NN, FK(machines) | — | Machine this PM schedule applies to. One machine may have multiple PM schedules for different PM types. |
| `pm_type` | VARCHAR(50) | NN | — | Type of PM activity (e.g., "Lubrication", "Filter Service", "Spindle Inspection"). |
| `interval_days` | INTEGER | NULL, CK(>0) | — | Calendar-day interval between PM events. NULL if interval_hours is used instead. |
| `interval_hours` | NUMERIC(10,2) | NULL, CK(>0) | — | Operating-hours interval between PM events. NULL if interval_days is used instead. |
| `last_performed_date` | DATE | NULL | — | Date the most recent PM of this type was completed. Used to calculate days_since_last_pm. |
| `next_due_date` | DATE | NULL | — | Calculated next due date. Updated by ETL after each completed PM event. |
| `is_active` | BOOLEAN | NN | TRUE | Whether this PM schedule is currently active. |
| `created_at` | TIMESTAMPTZ | NN | now() | UTC timestamp of record creation. |
| `updated_at` | TIMESTAMPTZ | NN | now() | UTC timestamp of most recent update (e.g., when next_due_date is recalculated). |

---

### 2.13 `spare_parts`

**Purpose:** Spare parts catalog for maintenance planning. Tracks current stock quantity, reorder point,
and procurement lead time. SMAP uses this to detect low-stock risk before predicted failures occur,
enabling proactive parts pre-positioning.

**Source System:** SAP MM Materials Management (SRC-INV)

| Column | Type | Constraints | Default | Business Meaning |
|---|---|---|---|---|
| `part_code` | VARCHAR(30) | PK, NN, UQ | — | Unique part identifier from SAP MM (e.g., SP-BEARING-6205). |
| `part_description` | VARCHAR(200) | NN | — | Full part description (e.g., "Deep groove ball bearing 6205-2RS, 25x52x15mm"). |
| `part_category` | VARCHAR(50) | NULL, CK | — | Part classification. Accepted values: Bearings, Seals, Filters, Belts, Electronics, Hydraulics, Tooling, Other. |
| `stock_qty` | NUMERIC(10,2) | NN, CK(>=0) | 0 | Current quantity on hand in the maintenance storeroom. |
| `reorder_point` | NUMERIC(10,2) | NULL, CK(>=0) | — | Stock level that triggers a purchase order. |
| `lead_time_days` | INTEGER | NULL, CK(>=0) | — | Typical procurement lead time in calendar days. |
| `unit_cost` | NUMERIC(15,4) | NULL, CK(>=0) | — | Standard unit cost in USD (from SAP MBEW). |
| `supplier_code` | VARCHAR(30) | NULL | — | Primary supplier identifier. |
| `updated_at` | TIMESTAMPTZ | NN | now() | UTC timestamp of most recent stock level update. |

---

### 2.14 `material_movements`

**Purpose:** Inventory transaction log — one row per goods issue, goods receipt, or stock transfer event.
Links spare parts consumption to specific maintenance work orders, enabling cost-per-repair
and parts consumption analysis for maintenance planning.

**Source System:** SAP MM material movements (MSEG table equivalent)

| Column | Type | Constraints | Default | Business Meaning |
|---|---|---|---|---|
| `movement_id` | BIGSERIAL | PK, NN | Auto | System-generated surrogate key. 64-bit for high-volume transaction log. |
| `part_code` | VARCHAR(30) | NN, FK(spare_parts) | — | Spare part involved in this transaction. |
| `work_order_id` | VARCHAR(30) | NULL, FK(maintenance_logs) | — | Work order this parts issue is associated with. NULL for non-maintenance movements (receipt, transfer). |
| `movement_type` | VARCHAR(30) | NN, CK | — | Transaction type. Accepted values: GOODS_ISSUE (to work order), GOODS_RECEIPT (from supplier), STOCK_TRANSFER, RETURN. |
| `qty` | NUMERIC(10,4) | NN | — | Quantity moved. Positive for receipts and transfers; negative for issues and returns is NOT used — movement_type determines direction. |
| `unit_cost` | NUMERIC(15,4) | NULL, CK(>=0) | — | Unit cost at time of movement (may differ from current spare_parts.unit_cost for historical records). |
| `total_cost` | NUMERIC(15,4) | NULL | — | qty × unit_cost. Computed at insert time. |
| `movement_date` | DATE | NN | — | Date of the inventory transaction. |
| `created_by` | VARCHAR(20) | NULL | — | Employee ID or system identifier that created the transaction. |
| `created_at` | TIMESTAMPTZ | NN | now() | UTC timestamp when the record was inserted. |

---

## 3. Warehouse Dimension Tables

### 3.1 `dim_date`

**Purpose:** Fully populated calendar and fiscal date dimension covering 2020-01-01 to 2030-12-31.
Used by all four fact tables for time-based analysis. Seeded via dbt seed CSV — no ETL required.

**Schema:** marts | **Rows:** 3,653 | **Update Strategy:** Type 0 (Fixed) | **Materialization:** table

| Column | Type | Nullable | Description |
|---|---|---|---|
| `date_key` | INTEGER | NO | PK. YYYYMMDD format (e.g., 20260722). Enables direct integer comparison without date parsing. |
| `full_date` | DATE | NO | Calendar date value. |
| `day_of_week` | SMALLINT | NO | 1=Monday through 7=Sunday (ISO 8601). |
| `day_name` | VARCHAR(10) | NO | Full day name (Monday through Sunday). |
| `day_of_month` | SMALLINT | NO | 1 through 31. |
| `day_of_year` | SMALLINT | NO | 1 through 366. |
| `week_of_year` | SMALLINT | NO | ISO week number 1 through 53. |
| `month_number` | SMALLINT | NO | 1 through 12. |
| `month_name` | VARCHAR(10) | NO | Full month name (January through December). |
| `month_name_short` | CHAR(3) | NO | Three-letter abbreviation (Jan through Dec). |
| `quarter` | SMALLINT | NO | 1 through 4. |
| `year` | SMALLINT | NO | Four-digit calendar year. |
| `fiscal_week` | SMALLINT | NO | Fiscal week number. PrecisionEdge fiscal calendar begins January 1. |
| `fiscal_quarter` | SMALLINT | NO | Fiscal quarter 1 through 4. |
| `fiscal_year` | SMALLINT | NO | Fiscal year (same as calendar year for PrecisionEdge). |
| `is_weekend` | BOOLEAN | NO | TRUE for Saturday and Sunday. |
| `is_holiday` | BOOLEAN | NO | TRUE for US federal public holidays relevant to plant staffing. |
| `is_working_day` | BOOLEAN | NO | TRUE for days the plant is scheduled to operate. FALSE for weekends, holidays, and plant-wide shutdown periods. |
| `shift_count_per_day` | SMALLINT | YES | Number of shifts scheduled on this day (0, 2, or 3). Varies by line and facility shift pattern. |

---

### 3.2 `dim_machine`

**Purpose:** Machine master dimension with organizational hierarchy, cross-system ID mappings,
capacity attributes, and SCD Type 2 reserve columns. The central dimension referenced by all four fact tables.

**Schema:** marts | **Update Strategy:** SCD Type 1 | **Materialization:** table

| Column | Type | Nullable | Description |
|---|---|---|---|
| `machine_sk` | SERIAL | NO | PK. Surrogate key auto-incremented at dbt run time. |
| `machine_id` | VARCHAR(20) | NO | Natural key from MES (e.g., MCH-001). Used for ETL lookup. |
| `machine_name` | VARCHAR(100) | NO | Human-readable machine name. |
| `machine_type_code` | VARCHAR(20) | NO | Equipment category code (MCH-LATHE, MCH-MILL, MCH-GRIND, MCH-PRESS, MCH-CMM, MCH-CONV, MCH-ASSY). |
| `machine_type_name` | VARCHAR(50) | NO | Equipment category display name. |
| `line_code` | VARCHAR(10) | NO | Production line code (LINE-A through LINE-K). |
| `line_name` | VARCHAR(50) | NO | Production line display name. Denormalized from production_lines for query efficiency. |
| `plant_code` | VARCHAR(10) | NO | Facility code (PLT-DET, PLT-CLV, PLT-CHI, PLT-MTY). |
| `manufacturer` | VARCHAR(100) | YES | Equipment manufacturer. |
| `model_number` | VARCHAR(50) | YES | Manufacturer model designation. |
| `rated_capacity_per_hour` | NUMERIC(10,2) | YES | Maximum output units per hour at full speed. |
| `install_date` | DATE | YES | Date machine was commissioned. |
| `is_active` | BOOLEAN | NO | Currently in service. |
| `oee_target` | NUMERIC(5,4) | YES | Plant-configured OEE target for this machine (e.g., 0.8100). |
| `scada_tag_name` | VARCHAR(50) | YES | SCADA PLC tag name for sensor reading resolution. |
| `asset_tag_number` | VARCHAR(20) | YES | CMMS asset tag for maintenance log resolution. |
| `erp_work_center_code` | VARCHAR(20) | YES | SAP work center code for ERP cross-reference. |
| `dbt_updated_at` | TIMESTAMPTZ | NO | Timestamp of the most recent dbt run that refreshed this row. |
| `dbt_valid_from` | TIMESTAMPTZ | YES | Reserved for SCD Type 2 upgrade. Currently NULL. |
| `dbt_valid_to` | TIMESTAMPTZ | YES | Reserved for SCD Type 2 upgrade. Currently NULL. NULL implies current record. |

---

### 3.3 `dim_product`

**Purpose:** Product/SKU dimension with three-level hierarchy and standard cost data.
The standard_cycle_time_sec column is critical — it is the denominator in the OEE Performance formula.

**Schema:** marts | **Update Strategy:** SCD Type 1 | **Materialization:** table

| Column | Type | Nullable | Description |
|---|---|---|---|
| `product_sk` | SERIAL | NO | PK. Surrogate key. |
| `product_code` | VARCHAR(30) | NO | Natural key from ERP/MES (e.g., PRD-001). |
| `product_name` | VARCHAR(100) | NO | Full product name. |
| `product_family` | VARCHAR(50) | NO | Product family (e.g., Powertrain Components). |
| `product_category` | VARCHAR(50) | NO | Top-level category (e.g., Automotive). |
| `standard_cycle_time_sec` | NUMERIC(10,3) | NO | Target cycle time per unit in seconds. OEE Performance denominator. |
| `standard_material_cost` | NUMERIC(15,4) | YES | Standard material cost per unit USD. Used in scrap cost calculation. |
| `standard_labor_cost` | NUMERIC(15,4) | YES | Standard labor cost per unit USD. |
| `is_active` | BOOLEAN | NO | Currently in production. |
| `erp_material_code` | VARCHAR(30) | YES | SAP material code for cross-system tracing. |
| `dbt_updated_at` | TIMESTAMPTZ | NO | Timestamp of most recent dbt refresh. |
| `dbt_valid_from` | TIMESTAMPTZ | YES | Reserved for SCD Type 2. Currently NULL. |
| `dbt_valid_to` | TIMESTAMPTZ | YES | Reserved for SCD Type 2. Currently NULL. |

---

### 3.4 `dim_employee`

**Purpose:** Anonymized employee dimension for quality traceability and maintenance response analysis.
No PII stored — employee names are dropped at ETL ingestion per PrecisionEdge privacy policy.

**Schema:** marts | **Update Strategy:** SCD Type 1 | **Materialization:** table

| Column | Type | Nullable | Description |
|---|---|---|---|
| `employee_sk` | SERIAL | NO | PK. Surrogate key. |
| `employee_id` | VARCHAR(20) | NO | Natural key from HRIS (anonymized code — no real names). |
| `role_code` | VARCHAR(20) | NO | Role classification code. |
| `role_name` | VARCHAR(50) | NO | Role display name. |
| `department_code` | VARCHAR(20) | NO | Department (DEPT-OPS, DEPT-QA, DEPT-MNT, DEPT-ENG). |
| `shift_assignment` | VARCHAR(10) | NO | Primary shift (SHIFT-A, SHIFT-B, SHIFT-C). |
| `skill_level` | VARCHAR(20) | YES | Junior, Senior, or Expert. |
| `tenure_years` | NUMERIC(5,2) | YES | Years employed calculated from hire_date at dbt run time. |
| `is_active` | BOOLEAN | NO | Currently employed and active. |
| `is_automated` | BOOLEAN | NO | TRUE for the EMP-ROBOT pseudo-employee record. |
| `dbt_updated_at` | TIMESTAMPTZ | NO | Timestamp of most recent dbt refresh. |

---

### 3.5 `dim_shift`

**Purpose:** Shift schedule reference dimension for time-of-day attribution in production and quality reporting.
Pre-seeded via dbt seed. Supports shift-level comparison (Day vs. Night vs. Afternoon).

**Schema:** marts | **Update Strategy:** Type 0 (Fixed) | **Materialization:** table

| Column | Type | Nullable | Description |
|---|---|---|---|
| `shift_sk` | SERIAL | NO | PK. Surrogate key. |
| `shift_code` | VARCHAR(10) | NO | Natural key (SHIFT-A, SHIFT-B, SHIFT-C). |
| `shift_name` | VARCHAR(50) | NO | Display name (Day Shift, Afternoon Shift, Night Shift). |
| `shift_start_time` | TIME | NO | Scheduled start time in local plant time. |
| `shift_end_time` | TIME | NO | Scheduled end time in local plant time. |
| `shift_duration_hours` | NUMERIC(4,2) | NO | Total shift duration in hours. |
| `planned_production_hours` | NUMERIC(4,2) | NO | Planned production time after deducting scheduled breaks. |
| `plant_code` | VARCHAR(10) | NO | Facility this shift definition applies to. |

---

### 3.6 `dim_defect_type`

**Purpose:** Defect classification hierarchy for Pareto analysis on the Quality Control dashboard.
Enables grouping of defects by category and severity for root cause prioritization.

**Schema:** marts | **Update Strategy:** SCD Type 1 | **Materialization:** table

| Column | Type | Nullable | Description |
|---|---|---|---|
| `defect_type_sk` | SERIAL | NO | PK. Surrogate key. |
| `defect_type_code` | VARCHAR(20) | NO | Natural key from QMS. |
| `defect_type_name` | VARCHAR(100) | NO | Defect type display name. |
| `defect_category` | VARCHAR(50) | NO | Pareto grouping (Dimensional, Surface, Structural, Functional, Other). |
| `severity_level` | VARCHAR(20) | NO | Critical, Major, or Minor. |
| `is_customer_escape_risk` | BOOLEAN | NO | TRUE for defect types that could reach the customer if not 100% inspected. |
| `description` | TEXT | YES | Full description of defect type and detection method. |
| `is_active` | BOOLEAN | NO | Whether this code is currently in use. |
| `dbt_updated_at` | TIMESTAMPTZ | NO | Timestamp of most recent dbt refresh. |

---

### 3.7 `dim_failure_code`

**Purpose:** Failure code dimension for maintenance event analysis and failure mode attribution.
Supports Pareto analysis of downtime by root cause category on the Maintenance and Reliability dashboard.

**Schema:** marts | **Update Strategy:** SCD Type 1 | **Materialization:** table

| Column | Type | Nullable | Description |
|---|---|---|---|
| `failure_code_sk` | SERIAL | NO | PK. Surrogate key. |
| `failure_code` | VARCHAR(20) | NO | Natural key from CMMS (e.g., FC-MECH, FC-ELEC, FC-HYD). |
| `failure_code_name` | VARCHAR(100) | NO | Display name (e.g., Mechanical Failure — Bearing Wear). |
| `failure_category` | VARCHAR(50) | NO | Top-level grouping (Mechanical, Electrical, Hydraulic, Process, Unknown). |
| `typical_mttr_hours` | NUMERIC(6,2) | YES | Historical average MTTR for this failure code. Informational only — not used in MTTR calculation. |
| `description` | TEXT | YES | Failure mode description and common causes. |
| `is_active` | BOOLEAN | NO | Whether this code is currently used in the CMMS. |
| `dbt_updated_at` | TIMESTAMPTZ | NO | Timestamp of most recent dbt refresh. |

---

## 4. Warehouse Fact Tables

### 4.1 `fct_production`

**Purpose:** Central fact table for production and OEE reporting. One row per completed production order.
All three OEE components (Availability, Performance, Quality) and the composite OEE score are
pre-computed by the `int_oee_calculation` dbt intermediate model and stored here for query performance.

**Schema:** marts | **Grain:** Completed production order | **Materialization:** incremental (upsert on order_id)

| Column | Type | Nullable | Description |
|---|---|---|---|
| `production_sk` | BIGSERIAL | NO | PK. Surrogate key (64-bit). |
| `date_key` | INTEGER | NO | FK to dim_date. Uses actual_end date (UTC). |
| `machine_sk` | INTEGER | NO | FK to dim_machine. |
| `product_sk` | INTEGER | NO | FK to dim_product. |
| `shift_sk` | INTEGER | NO | FK to dim_shift. |
| `employee_sk` | INTEGER | YES | FK to dim_employee. -1 for Unknown operator. |
| `order_id` | VARCHAR(30) | NO | Source order ID. Degenerate dimension. |
| `planned_units` | INTEGER | NO | Target output from production plan. |
| `actual_units` | INTEGER | NO | Total units produced (good + scrap + rework). |
| `good_units` | INTEGER | NO | First-pass good units (OEE Quality numerator). |
| `scrap_units` | INTEGER | NO | Units scrapped. |
| `rework_units` | INTEGER | NO | Units sent for rework (not counted as good per OEE standard). |
| `planned_duration_min` | NUMERIC(10,2) | YES | Scheduled run time in minutes. |
| `actual_duration_min` | NUMERIC(10,2) | YES | Elapsed time from actual_start to actual_end in minutes. |
| `downtime_min` | NUMERIC(10,2) | YES | Total downtime minutes during this order from downtime_events. |
| `run_time_min` | NUMERIC(10,2) | YES | actual_duration_min minus downtime_min. OEE Performance denominator. |
| `setup_time_min` | NUMERIC(10,2) | YES | Setup/changeover time at start of order. |
| `oee_availability` | NUMERIC(6,5) | YES | (planned_duration_min - downtime_min) / planned_duration_min. NULL if planned_duration_min = 0. |
| `oee_performance` | NUMERIC(6,5) | YES | (actual_units * standard_cycle_time_sec / 60) / run_time_min. NULL if run_time_min = 0 or cycle time missing. |
| `oee_quality` | NUMERIC(6,5) | YES | good_units / actual_units. NULL if actual_units = 0. |
| `oee_overall` | NUMERIC(6,5) | YES | oee_availability * oee_performance * oee_quality. NULL if any component is NULL. |
| `throughput_rate_per_hr` | NUMERIC(10,4) | YES | good_units / (run_time_min / 60). |
| `scrap_cost` | NUMERIC(15,4) | YES | scrap_units * dim_product.standard_material_cost. |
| `dbt_updated_at` | TIMESTAMPTZ | NO | Timestamp of most recent dbt run. |

---

### 4.2 `fct_quality_inspection`

**Purpose:** Fact table for quality analysis at the inspection event level. Supports defect rate trending,
Pareto analysis by defect type, SPC charts, and First Pass Yield reporting.

**Schema:** marts | **Grain:** Quality inspection sampling event | **Materialization:** incremental (upsert on inspection_id)

| Column | Type | Nullable | Description |
|---|---|---|---|
| `inspection_sk` | BIGSERIAL | NO | PK. Surrogate key (64-bit). |
| `date_key` | INTEGER | NO | FK to dim_date (inspection_timestamp date). |
| `machine_sk` | INTEGER | NO | FK to dim_machine. |
| `product_sk` | INTEGER | NO | FK to dim_product. |
| `employee_sk` | INTEGER | YES | FK to dim_employee (inspector). -1 if automated gauging or unknown. |
| `defect_type_sk` | INTEGER | YES | FK to dim_defect_type. -1 if no defect found or defect_type_code missing. |
| `inspection_id` | VARCHAR(30) | NO | Source inspection ID. Degenerate dimension. |
| `order_id` | VARCHAR(30) | NO | Source order ID. Degenerate dimension. |
| `inspection_type_code` | VARCHAR(20) | NO | FIRST-ARTICLE, IN-PROCESS, FINAL, or FUNCTIONAL. |
| `sample_size` | INTEGER | NO | Number of units sampled in this event. |
| `defects_found` | INTEGER | NO | Number of defective units found. |
| `defect_rate_pct` | NUMERIC(8,6) | YES | defects_found / sample_size. NULL if sample_size = 0. |
| `defect_rate_ppm` | NUMERIC(12,2) | YES | defect_rate_pct * 1,000,000. |
| `pass_fail` | CHAR(1) | NO | P=Pass or F=Fail. |
| `measurement_value` | NUMERIC(12,6) | YES | Quantitative measurement value. |
| `measurement_unit` | VARCHAR(20) | YES | Unit of measurement. |
| `measurement_nominal` | NUMERIC(12,6) | YES | Target nominal value from product specification. |
| `measurement_deviation` | NUMERIC(12,6) | YES | measurement_value minus measurement_nominal. Positive = above nominal, negative = below. |
| `dbt_updated_at` | TIMESTAMPTZ | NO | Timestamp of most recent dbt run. |

---

### 4.3 `fct_sensor_reading`

**Purpose:** Highest-volume fact table. Stores all sensor telemetry from IoT sensors at
machine-level granularity. Primary input for predictive maintenance and anomaly detection ML models.
A derived `fct_sensor_hourly_summary` table provides hourly aggregates for API and dashboard use.

**Schema:** marts | **Grain:** Individual sensor measurement event | **Materialization:** incremental append-only, **partitioned by month**

| Column | Type | Nullable | Description |
|---|---|---|---|
| `sensor_sk` | BIGSERIAL | NO | PK. Surrogate key (64-bit). |
| `date_key` | INTEGER | NO | FK to dim_date (date of reading_timestamp). |
| `machine_sk` | INTEGER | NO | FK to dim_machine. |
| `reading_id` | BIGINT | NO | Source reading ID from operational DB. Degenerate dimension. |
| `sensor_type` | VARCHAR(30) | NO | Sensor type code: temperature, vibration, rpm, pressure, power, cutting_force, coolant_flow. |
| `sensor_unit` | VARCHAR(10) | NO | Unit of measurement. |
| `value` | NUMERIC(14,6) | NO | Raw sensor reading value. |
| `reading_timestamp` | TIMESTAMPTZ | NO | Exact UTC timestamp of the reading. |
| `is_anomaly_flagged` | BOOLEAN | NO | TRUE if SCADA source system flagged this reading. |
| `data_quality_score` | NUMERIC(4,3) | YES | Data quality confidence score 0-1. NULL for pre-2021 sensors; treated as 1.000 downstream. |
| `is_within_spec` | BOOLEAN | YES | TRUE if value is within the configured operating range for this sensor type per machine. |
| `dbt_updated_at` | TIMESTAMPTZ | NO | Timestamp of most recent dbt run. |

---

### 4.4 `fct_maintenance_event`

**Purpose:** Maintenance event fact table capturing the complete lifecycle of each work order.
Supports MTTR analysis, MTBF calculation, planned vs. unplanned downtime reporting,
repair cost tracking, and PM compliance monitoring.

**Schema:** marts | **Grain:** Maintenance work order | **Materialization:** incremental (upsert on work_order_id)

| Column | Type | Nullable | Description |
|---|---|---|---|
| `maintenance_sk` | BIGSERIAL | NO | PK. Surrogate key (64-bit). |
| `date_key` | INTEGER | NO | FK to dim_date (downtime_start date). |
| `machine_sk` | INTEGER | NO | FK to dim_machine. |
| `employee_sk` | INTEGER | YES | FK to dim_employee (assigned technician). -1 if unknown. |
| `failure_code_sk` | INTEGER | YES | FK to dim_failure_code. -1 if no failure code assigned. |
| `work_order_id` | VARCHAR(30) | NO | Source work order ID. Degenerate dimension. |
| `event_type` | VARCHAR(30) | NO | Planned, Unplanned, or Emergency. |
| `is_planned` | BOOLEAN | NO | TRUE for Planned or PM events. FALSE for Unplanned or Emergency. |
| `downtime_start` | TIMESTAMPTZ | NO | UTC timestamp when machine stopped. |
| `downtime_end` | TIMESTAMPTZ | YES | UTC timestamp when machine returned to service. NULL for open work orders. |
| `downtime_minutes` | NUMERIC(10,2) | YES | Total downtime duration in minutes. NULL for open WOs. |
| `response_time_minutes` | NUMERIC(10,2) | YES | Time from downtime_start to technician arrival. NULL if not recorded. |
| `mttr_minutes` | NUMERIC(10,2) | YES | Mean Time to Repair in minutes for this event. NULL for open WOs. |
| `repair_cost` | NUMERIC(15,4) | YES | Total repair cost (labor + parts) in USD. |
| `parts_cost` | NUMERIC(15,4) | YES | Parts consumed cost from material_movements for this work order. |
| `days_since_last_failure` | NUMERIC(10,2) | YES | Days between this failure and the previous unplanned failure on the same machine. MTBF component. |
| `days_since_last_pm` | NUMERIC(10,2) | YES | Days since the most recently completed PM event for this machine. Key ML feature. |
| `pm_compliance` | BOOLEAN | YES | TRUE if this planned event occurred within the scheduled PM window (next_due_date +/- 3 days). |
| `dbt_updated_at` | TIMESTAMPTZ | NO | Timestamp of most recent dbt run. |

---

*This data dictionary is the definitive column-level reference for all SMAP database tables.*
*Any schema change must be reflected here before implementation. Last reviewed: 2026-07-22.*
