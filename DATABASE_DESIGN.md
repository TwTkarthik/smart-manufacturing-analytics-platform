# Database Design — Smart Manufacturing Analytics Platform (SMAP)

**Document Version:** 2.0.0
**Last Updated:** 2026-07-22
**Status:** Approved — Complete Design Baseline
**Owner:** Lead Database Architect
**Related Documents:**
- [SYSTEM_ARCHITECTURE.md](./SYSTEM_ARCHITECTURE.md)
- [docs/DATA_SOURCES.md](./docs/DATA_SOURCES.md)
- [docs/KPI_DEFINITIONS.md](./docs/KPI_DEFINITIONS.md)
- [docs/DB_DATA_DICTIONARY.md](./docs/DB_DATA_DICTIONARY.md)
- [docs/DB_ER_DIAGRAM.md](./docs/DB_ER_DIAGRAM.md)
- [docs/DB_INDEXING_STRATEGY.md](./docs/DB_INDEXING_STRATEGY.md)
- [docs/DB_PARTITIONING_STRATEGY.md](./docs/DB_PARTITIONING_STRATEGY.md)
- [docs/DB_RETENTION_STRATEGY.md](./docs/DB_RETENTION_STRATEGY.md)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Database Architecture](#2-database-architecture)
3. [Operational Database — OLTP](#3-operational-database--oltp)
4. [Analytical Data Warehouse](#4-analytical-data-warehouse)
5. [Data Types Reference](#5-data-types-reference)
6. [Naming Conventions](#6-naming-conventions)
7. [Schema Conventions](#7-schema-conventions)
8. [Migration Strategy](#8-migration-strategy)

---

## 1. Overview

The SMAP database layer comprises **two separate PostgreSQL 15 instances** with distinct responsibilities:

| Instance | Port | Purpose | Schemas |
|---|---|---|---|
| **Operational DB** | 5432 | Simulates source/transactional systems (ERP, MES, SCADA) | `public` |
| **Data Warehouse** | 5433 | Analytical star schema populated by ETL + dbt | `raw`, `staging`, `intermediate`, `marts` |

**Design Philosophy:**
- The Operational DB is normalized to 3NF for transactional workloads.
- The Warehouse follows Kimball-style dimensional modeling (star schema) for analytical queries.
- All warehouse conventions are cloud-portable (Snowflake, BigQuery, Redshift compatible).

For detailed sub-documents, see the Related Documents section above.

---

## 2. Database Architecture

```
+-----------------------------------------------------------------------+
|                    SMAP DATABASE ARCHITECTURE                         |
+----------------------------------+------------------------------------+
|  OPERATIONAL DATABASE            |  DATA WAREHOUSE                    |
|  (PostgreSQL 15 - Port 5432)     |  (PostgreSQL 15 - Port 5433)       |
|  Schema: public                  |                                    |
|                                  |  Schema: raw    (landing tables)   |
|  +-- machines                    |  Schema: staging (stg_* views)     |
|  +-- production_lines            |  Schema: intermediate (int_*)      |
|  +-- products                    |  Schema: marts (star schema)       |
|  +-- employees                   |    +-- dim_date                    |
|  +-- shifts                      |    +-- dim_machine                 |
|  +-- production_orders           |    +-- dim_product                 |
|  +-- downtime_events             |    +-- dim_employee                |
|  +-- sensor_readings             |    +-- dim_shift                   |
|  +-- quality_inspections         |    +-- dim_defect_type             |
|  +-- defect_types                |    +-- dim_failure_code            |
|  +-- maintenance_logs            |    +-- fct_production              |
|  +-- pm_schedules                |    +-- fct_quality_inspection      |
|  +-- spare_parts                 |    +-- fct_sensor_reading          |
|  +-- material_movements          |    +-- fct_maintenance_event       |
+----------------------------------+------------------------------------+
```

Connection strings are driven by environment variables:
- `POSTGRES_SOURCE_URL` — operational database
- `POSTGRES_WAREHOUSE_URL` — data warehouse

---

## 3. Operational Database — OLTP

### 3.1 Entity List (14 Entities, 5 Domains)

#### Domain 1 — Reference / Master Data

| Entity | Table | Description |
|---|---|---|
| Machine | `machines` | Master register of all production machines and equipment at all PrecisionEdge facilities. One record per physical asset. |
| Production Line | `production_lines` | Logical groupings of machines into production cells (LINE-A through LINE-K). Plant/line hierarchy above individual machines. |
| Product | `products` | Product/SKU master with three-level hierarchy (product → family → category). Includes standard cycle time for OEE Performance. |
| Employee | `employees` | Anonymized operator and technician roster. Stores role, shift, department, skill level. Employee names excluded per privacy policy. |
| Shift | `shifts` | Reference table for three 8-hour shift windows with scheduled production hours. Static — updated only when shift pattern changes. |

#### Domain 2 — Production Operations

| Entity | Table | Description |
|---|---|---|
| Production Order | `production_orders` | Core production transaction. One record per discrete manufacturing work order linking machine, product, shift, and operator to planned and actual output. |
| Downtime Event | `downtime_events` | Every recorded machine stop event (planned and unplanned) with reason code, duration, and type. Primary source for Availability and MTBF/MTTR KPIs. |

#### Domain 3 — Sensor Telemetry

| Entity | Table | Description |
|---|---|---|
| Sensor Reading | `sensor_readings` | High-volume IoT telemetry. One record per sensor measurement (every 30–60 seconds per sensor across 384 sensors). Primary ML feature source for predictive maintenance and anomaly detection. |

#### Domain 4 — Quality Management

| Entity | Table | Description |
|---|---|---|
| Quality Inspection | `quality_inspections` | One record per quality sampling event. Captures sample size, defects found, measurement value, pass/fail result, and inspector. |
| Defect Type | `defect_types` | Reference table of defect category codes with hierarchy (type → category) and severity. Used for Pareto analysis. |

#### Domain 5 — Maintenance Management

| Entity | Table | Description |
|---|---|---|
| Maintenance Log | `maintenance_logs` | Work order records for all maintenance activities. Source for MTTR, root cause analysis, and maintenance cost tracking. |
| PM Schedule | `pm_schedules` | Preventive maintenance schedules per machine. Used to classify downtime as planned vs. unplanned and as ML input feature. |
| Spare Part | `spare_parts` | Spare parts catalog with stock quantity and reorder points. Supports maintenance parts planning. |
| Material Movement | `material_movements` | Inventory transaction log for goods issues, receipts, and transfers. Enables parts consumption tracking per work order. |

---

### 3.2 Relationships

| Parent Table | Child Table | Cardinality | FK Column |
|---|---|---|---|
| `production_lines` | `machines` | 1:N | `machines.line_code` |
| `machines` | `production_orders` | 1:N | `production_orders.machine_id` |
| `machines` | `sensor_readings` | 1:N | `sensor_readings.machine_id` |
| `machines` | `downtime_events` | 1:N | `downtime_events.machine_id` |
| `machines` | `maintenance_logs` | 1:N | `maintenance_logs.machine_id` |
| `machines` | `pm_schedules` | 1:N | `pm_schedules.machine_id` |
| `products` | `production_orders` | 1:N | `production_orders.product_code` |
| `employees` | `production_orders` | 1:N | `production_orders.operator_id` |
| `employees` | `quality_inspections` | 1:N | `quality_inspections.inspector_id` |
| `employees` | `maintenance_logs` | 1:N | `maintenance_logs.technician_id` |
| `shifts` | `production_orders` | 1:N | `production_orders.shift_code` |
| `production_orders` | `quality_inspections` | 1:N | `quality_inspections.order_id` |
| `production_orders` | `downtime_events` | 1:N | `downtime_events.order_id` |
| `defect_types` | `quality_inspections` | 1:N | `quality_inspections.defect_type_code` |
| `spare_parts` | `material_movements` | 1:N | `material_movements.part_code` |
| `maintenance_logs` | `material_movements` | 1:N | `material_movements.work_order_id` |

---

### 3.3 Normalization Level — Third Normal Form (3NF)

| NF Rule | Compliance | Evidence |
|---|---|---|
| 1NF — Atomic values, no repeating groups | Compliant | Multi-valued attributes use child tables (material_movements for parts lists) — no arrays or delimited strings |
| 2NF — No partial dependencies | Compliant | All tables use single-column primary keys — partial dependencies not possible |
| 3NF — No transitive dependencies | Compliant | product_family and product_category stored only in `products`; line_name stored only in `production_lines` |

> **Intentional Denormalization:** `sensor_readings` includes `sensor_type` and `sensor_unit` on every row (rather than normalizing to a `sensor_types` lookup table). This eliminates join overhead on the highest-volume table (~200–400M rows/year). A CHECK constraint enforces the allowed sensor_type values.

---

### 3.4 Primary and Foreign Keys

#### Primary Keys

| Table | PK Column | Type | Strategy |
|---|---|---|---|
| `machines` | `machine_id` | VARCHAR(20) | Natural key from MES (e.g., MCH-001) |
| `production_lines` | `line_code` | VARCHAR(10) | Natural key (e.g., LINE-A) |
| `products` | `product_code` | VARCHAR(30) | Natural key from ERP (e.g., PRD-001) |
| `employees` | `employee_id` | VARCHAR(20) | Natural key from HRIS (anonymized) |
| `shifts` | `shift_code` | VARCHAR(10) | Natural key (e.g., SHIFT-A) |
| `production_orders` | `order_id` | VARCHAR(30) | Natural key from MES/ERP |
| `downtime_events` | `event_id` | VARCHAR(30) | Natural key from MES |
| `sensor_readings` | `reading_id` | BIGSERIAL | Auto-increment surrogate (no stable natural key) |
| `quality_inspections` | `inspection_id` | VARCHAR(30) | Natural key from QMS |
| `defect_types` | `defect_type_code` | VARCHAR(20) | Natural key from QMS |
| `maintenance_logs` | `work_order_id` | VARCHAR(30) | Natural key from CMMS |
| `pm_schedules` | `pm_schedule_id` | SERIAL | Surrogate (no stable natural key in source) |
| `spare_parts` | `part_code` | VARCHAR(30) | Natural key from ERP MM |
| `material_movements` | `movement_id` | BIGSERIAL | Surrogate (high-volume transaction log) |

#### Foreign Key Constraint Names (pattern: `fk_{child}_{parent}`)

`fk_machines_production_lines` · `fk_production_orders_machines` · `fk_production_orders_products`
`fk_production_orders_employees` · `fk_production_orders_shifts` · `fk_downtime_events_machines`
`fk_downtime_events_orders` · `fk_sensor_readings_machines` · `fk_quality_inspections_orders`
`fk_quality_inspections_machines` · `fk_quality_inspections_defects` · `fk_quality_inspections_employees`
`fk_maintenance_logs_machines` · `fk_maintenance_logs_employees` · `fk_pm_schedules_machines`
`fk_material_movements_parts` · `fk_material_movements_workorders`

---

## 4. Analytical Data Warehouse

### 4.1 Star Schema — 4 Fact Tables, 7 Dimension Tables

**Dimension–Fact Cross-Reference:**

| Dimension | fct_production | fct_quality_inspection | fct_sensor_reading | fct_maintenance_event |
|---|:---:|:---:|:---:|:---:|
| `dim_date` | Yes | Yes | Yes | Yes |
| `dim_machine` | Yes | Yes | Yes | Yes |
| `dim_product` | Yes | Yes | No | No |
| `dim_shift` | Yes | No | No | No |
| `dim_employee` | Yes | Yes | No | Yes |
| `dim_defect_type` | No | Yes | No | No |
| `dim_failure_code` | No | No | No | Yes |

---

### 4.2 Grain Definitions

| Fact Table | Grain |
|---|---|
| `fct_production` | One row per completed production order |
| `fct_quality_inspection` | One row per quality inspection sampling event |
| `fct_sensor_reading` | One row per individual sensor measurement event |
| `fct_maintenance_event` | One row per maintenance work order |

---

### 4.3 Surrogate Key Strategy

| Rule | Implementation |
|---|---|
| Naming convention | `{entity}_sk` (e.g., machine_sk, product_sk) |
| Type | SERIAL (32-bit) for dimensions; BIGSERIAL for high-volume facts |
| Unknown member | Surrogate key -1 pre-seeded in every dimension table for "Unknown" members |
| Natural key preservation | Source natural key retained alongside surrogate key for traceability |
| Degenerate dimensions | Fact tables store degenerate dimensions (order_id, inspection_id, work_order_id) as VARCHAR columns — not separate dimension tables |

---

### 4.4 Slowly Changing Dimensions Strategy

| Dimension | SCD Type | Rationale |
|---|---|---|
| `dim_date` | Type 0 (Fixed) | Calendar dates never change; 2020–2030 pre-populated via dbt seed |
| `dim_shift` | Type 0 (Fixed) | Shift schedules are stable; seeded at platform setup |
| `dim_machine` | Type 1 (Overwrite) | Attribute changes (line reassignment, capacity update) reflected immediately |
| `dim_product` | Type 1 (Overwrite) | Catalog changes (name, category, cycle time) propagated forward |
| `dim_employee` | Type 1 (Overwrite) | Role/shift changes reflected immediately; individual history out of scope per privacy policy |
| `dim_defect_type` | Type 1 (Overwrite) | Defect taxonomy changes propagated forward |
| `dim_failure_code` | Type 1 (Overwrite) | Failure code hierarchy is stable |

> **SCD Type 2 Future Path:** `dim_machine` is the top candidate for Type 2 upgrade in v2.0.0.
> Columns `dbt_valid_from` and `dbt_valid_to` are reserved in the schema (currently NULL).
> The dbt `snapshots/` directory is pre-configured for a `snapshot_dim_machine` snapshot.

**Type 1 refresh mechanism:** All Type 1 dimensions materialize as `table` in dbt.
On each `dbt run` the table is fully rebuilt from staging. `dbt_updated_at` records the last refresh.

---

### 4.5 Dimension Table Definitions

See [docs/DB_DATA_DICTIONARY.md](./docs/DB_DATA_DICTIONARY.md) for complete column specifications.

| Table | Rows (approx.) | Update Strategy | Source |
|---|---|---|---|
| `dim_date` | 3,653 | dbt seed (static) | Seed CSV covering 2020–2030 |
| `dim_machine` | ~48 (PLT-DET) | SCD Type 1, full refresh | MES machine master + ERP work centers |
| `dim_product` | ~50–100 | SCD Type 1, full refresh | ERP material master |
| `dim_employee` | ~980 | SCD Type 1, full refresh | Workday HRIS daily CSV |
| `dim_shift` | 9 (3 shifts × 3 plants) | dbt seed (static) | Process documentation |
| `dim_defect_type` | ~30–50 | SCD Type 1, full refresh | QMS defect_types table |
| `dim_failure_code` | ~25–40 | SCD Type 1, full refresh | CMMS failure code catalog |

---

### 4.6 Fact Table Definitions

| Table | Grain | Volume (annual) | Materialization |
|---|---|---|---|
| `fct_production` | Per completed production order | ~500K rows | Incremental (upsert on order_id) |
| `fct_quality_inspection` | Per inspection sampling event | ~250–500K rows | Incremental (upsert on inspection_id) |
| `fct_sensor_reading` | Per sensor measurement event | 200–400M rows | Incremental, append-only, **partitioned by month** |
| `fct_maintenance_event` | Per maintenance work order | ~5–15K rows | Incremental (upsert on work_order_id) |

**OEE metrics pre-computed in `fct_production`:**
- `oee_availability` = (planned_duration_min - downtime_min) / planned_duration_min
- `oee_performance` = (actual_units × standard_cycle_time_sec / 60) / run_time_min
- `oee_quality` = good_units / actual_units
- `oee_overall` = oee_availability × oee_performance × oee_quality

**MTTR/MTBF metrics pre-computed in `fct_maintenance_event`:**
- `mttr_minutes` = downtime_end - downtime_start (for unplanned events)
- `days_since_last_failure` = days between consecutive unplanned events per machine
- `days_since_last_pm` = days since last PM work order per machine

---

## 5. Data Types Reference

| Concept | PostgreSQL Type | Notes |
|---|---|---|
| Dimension surrogate keys | SERIAL | 32-bit auto-increment |
| Fact table surrogate keys | BIGSERIAL | 64-bit for high-volume tables |
| Date dimension key | INTEGER | YYYYMMDD format (e.g., 20260722) |
| Natural keys | VARCHAR(n) | Sized to source system format |
| OEE components (0–1) | NUMERIC(6,5) | Five decimal precision (e.g., 0.87500) |
| Defect rates / percentages | NUMERIC(8,6) | Six decimal precision |
| Monetary values | NUMERIC(15,4) | Never FLOAT for money |
| Sensor values | NUMERIC(14,6) | Covers small vibration to large RPM values |
| Timestamps | TIMESTAMPTZ | Always UTC with explicit timezone |
| Dates (date only) | DATE | install_date, hire_date, movement_date |
| Times (time only) | TIME | Shift start/end (no date component) |
| Boolean flags | BOOLEAN | Never CHAR(1) or INTEGER for boolean semantics |
| Fixed single-char codes | CHAR(1) | Only for pass_fail and similar fixed-length codes |
| Unbounded text | TEXT | root_cause, description, defect_description |
| Semi-structured data | JSONB | Reserved for future use; not used in v1.0.0 |

---

## 6. Naming Conventions

| Object Type | Convention | Example |
|---|---|---|
| Operational tables | snake_case plural noun | `production_orders`, `sensor_readings` |
| Dimension tables | dim_ prefix + snake_case singular | `dim_machine`, `dim_defect_type` |
| Fact tables | fct_ prefix + snake_case noun phrase | `fct_production`, `fct_sensor_reading` |
| Staging dbt models | stg_ + source table name | `stg_production_orders` |
| Intermediate dbt models | int_ + descriptive phrase | `int_oee_calculation` |
| Surrogate keys | {entity}_sk | `machine_sk`, `product_sk` |
| Natural keys | Original source column name | `machine_id`, `product_code` |
| Date dimension key | date_key | `date_key` (INTEGER, YYYYMMDD) |
| Foreign key columns | Match referenced PK column name | `machine_sk` (in fact = same as in dim) |
| Index names | idx_{table}_{columns} | `idx_sensor_readings_machine_timestamp` |
| FK constraint names | fk_{child}_{parent} | `fk_production_orders_machines` |
| Check constraint names | chk_{table}_{column} | `chk_production_orders_status` |
| Schema names | snake_case lowercase | `marts`, `staging`, `intermediate` |
| dbt seed files | seed_{object_name}.csv | `seed_dim_date.csv` |

---

## 7. Schema Conventions

| Convention | Rule |
|---|---|
| Timestamps | All TIMESTAMPTZ values stored in UTC. Application layer handles timezone conversion for display. |
| NULL semantics | Use NULL for genuinely missing data. Use -1 surrogate for Unknown dimension members. Never use empty string where NULL is correct. |
| Audit columns | Operational tables: `created_at TIMESTAMPTZ NOT NULL DEFAULT now()`. Mutable tables add `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()`. |
| dbt metadata | All warehouse tables include `dbt_updated_at TIMESTAMPTZ NOT NULL`. |
| Boolean defaults | All boolean columns have explicit DEFAULT FALSE or DEFAULT TRUE. Never left without default. |
| Soft deletes | No physical deletes in normal operations. Soft-delete via `is_active = FALSE`. Physical cleanup via data retention policy only. |

---

## 8. Migration Strategy

| Layer | Tool | Approach |
|---|---|---|
| Operational DB | Alembic | Versioned scripts in `database/migrations/`. Each migration has `upgrade()` and `downgrade()`. Destructive migrations require rollback test before merging. |
| Warehouse staging/intermediate | dbt | Views and ephemeral models auto-rebuild on `dbt run`. No migration scripts needed. |
| Warehouse marts | dbt | Incremental fact models upsert on `dbt run`. Full rebuild via `dbt run --full-refresh`. Column additions require `--full-refresh`. |
| dim_date seed | dbt seed | Extend by updating seed CSV and running `dbt seed --select dim_date`. No DDL changes needed. |

**Zero-Downtime Principle:** New nullable columns can be added without a maintenance window.
Non-nullable additions require a two-phase migration: (1) add as nullable, (2) backfill, (3) add NOT NULL constraint.
All migrations are tested locally before applying to any shared environment.

---

*This document is the authoritative source of truth for all SMAP database schema decisions.*
*All implementation changes must be reflected here before the corresponding code change is merged.*
*Last reviewed: 2026-07-22.*
