# ER Diagram — Smart Manufacturing Analytics Platform (SMAP)

**Document Version:** 1.0.0
**Last Updated:** 2026-07-22
**Status:** Approved — Complete Design Baseline
**Owner:** Lead Database Architect
**Related Documents:**
- [../DATABASE_DESIGN.md](../DATABASE_DESIGN.md)
- [DB_DATA_DICTIONARY.md](./DB_DATA_DICTIONARY.md)

---

## Table of Contents

1. [Operational Database ERD](#1-operational-database-erd)
2. [Data Warehouse Star Schema ERD](#2-data-warehouse-star-schema-erd)
3. [Diagram Notes](#3-diagram-notes)

---

## 1. Operational Database ERD

The following Mermaid ER diagram depicts all 14 entities in the SMAP operational (OLTP)
database and their relationships. The operational database is in Third Normal Form (3NF).

```mermaid
erDiagram
    production_lines {
        varchar line_code PK
        varchar line_name
        varchar plant_code
        varchar primary_operation
        varchar shift_pattern
        numeric oee_target
        boolean is_active
    }

    machines {
        varchar machine_id PK
        varchar machine_name
        varchar machine_type_code
        varchar line_code FK
        varchar plant_code
        varchar manufacturer
        varchar model_number
        numeric rated_capacity_per_hour
        date install_date
        boolean is_active
        varchar scada_tag_name
        varchar asset_tag_number
        varchar erp_work_center_code
        timestamptz created_at
        timestamptz updated_at
    }

    shifts {
        varchar shift_code PK
        varchar shift_name
        time shift_start_time
        time shift_end_time
        numeric shift_duration_hours
        numeric planned_production_hours
        varchar plant_code
    }

    employees {
        varchar employee_id PK
        varchar role_code
        varchar role_name
        varchar department_code
        varchar shift_assignment FK
        varchar skill_level
        text training_certifications
        date hire_date
        boolean is_active
        boolean is_automated
        timestamptz created_at
        timestamptz updated_at
    }

    products {
        varchar product_code PK
        varchar product_name
        varchar product_family
        varchar product_category
        numeric standard_cycle_time_sec
        numeric standard_material_cost
        numeric standard_labor_cost
        boolean is_active
        varchar erp_material_code
        timestamptz created_at
        timestamptz updated_at
    }

    production_orders {
        varchar order_id PK
        varchar machine_id FK
        varchar product_code FK
        varchar shift_code FK
        varchar operator_id FK
        timestamptz planned_start
        timestamptz actual_start
        timestamptz actual_end
        integer planned_units
        integer actual_units
        integer good_units
        integer scrap_units
        integer rework_units
        varchar status
        varchar erp_order_id
        timestamptz created_at
        timestamptz updated_at
    }

    downtime_events {
        varchar event_id PK
        varchar machine_id FK
        varchar order_id FK
        varchar event_type
        varchar reason_code
        text reason_description
        timestamptz downtime_start
        timestamptz downtime_end
        numeric downtime_minutes
        varchar reported_by FK
        boolean is_planned
        timestamptz created_at
    }

    sensor_readings {
        bigserial reading_id PK
        varchar machine_id FK
        varchar sensor_type
        varchar sensor_unit
        numeric value
        timestamptz reading_timestamp
        boolean is_anomaly_flagged
        numeric data_quality_score
    }

    defect_types {
        varchar defect_type_code PK
        varchar defect_type_name
        varchar defect_category
        varchar severity_level
        boolean is_customer_escape_risk
        text description
        boolean is_active
    }

    quality_inspections {
        varchar inspection_id PK
        varchar order_id FK
        varchar machine_id FK
        varchar inspector_id FK
        varchar inspection_type_code
        timestamptz inspection_timestamp
        integer sample_size
        integer defects_found
        varchar defect_type_code FK
        text defect_description
        numeric measurement_value
        varchar measurement_unit
        char pass_fail
        timestamptz created_at
    }

    pm_schedules {
        serial pm_schedule_id PK
        varchar machine_id FK
        varchar pm_type
        integer interval_days
        numeric interval_hours
        date last_performed_date
        date next_due_date
        boolean is_active
        timestamptz created_at
        timestamptz updated_at
    }

    maintenance_logs {
        varchar work_order_id PK
        varchar machine_id FK
        varchar technician_id FK
        varchar event_type
        varchar failure_code
        text description
        timestamptz downtime_start
        timestamptz downtime_end
        numeric downtime_minutes
        numeric repair_cost
        text root_cause
        integer pm_schedule_id FK
        timestamptz created_at
    }

    spare_parts {
        varchar part_code PK
        varchar part_description
        varchar part_category
        numeric stock_qty
        numeric reorder_point
        integer lead_time_days
        numeric unit_cost
        varchar supplier_code
        timestamptz updated_at
    }

    material_movements {
        bigserial movement_id PK
        varchar part_code FK
        varchar work_order_id FK
        varchar movement_type
        numeric qty
        numeric unit_cost
        numeric total_cost
        date movement_date
        varchar created_by
        timestamptz created_at
    }

    production_lines ||--o{ machines : "contains"
    shifts ||--o{ employees : "assigned-to"
    machines ||--o{ production_orders : "runs"
    products ||--o{ production_orders : "produced-in"
    employees ||--o{ production_orders : "operates"
    shifts ||--o{ production_orders : "scheduled-in"
    machines ||--o{ downtime_events : "stops-on"
    production_orders ||--o{ downtime_events : "interrupted-by"
    employees ||--o{ downtime_events : "reported-by"
    machines ||--o{ sensor_readings : "emits"
    production_orders ||--o{ quality_inspections : "inspected-under"
    machines ||--o{ quality_inspections : "produced-on"
    employees ||--o{ quality_inspections : "performed-by"
    defect_types ||--o{ quality_inspections : "classifies"
    machines ||--o{ maintenance_logs : "maintained-via"
    employees ||--o{ maintenance_logs : "assigned-to"
    pm_schedules ||--o{ maintenance_logs : "scheduled-by"
    machines ||--o{ pm_schedules : "has-schedule"
    spare_parts ||--o{ material_movements : "consumed-in"
    maintenance_logs ||--o{ material_movements : "uses"
```

---

## 2. Data Warehouse Star Schema ERD

The following Mermaid ER diagram depicts the analytical warehouse star schema in the `marts` schema.
Four fact tables share seven common dimension tables.

```mermaid
erDiagram
    dim_date {
        integer date_key PK
        date full_date
        smallint day_of_week
        varchar day_name
        smallint week_of_year
        smallint month_number
        varchar month_name
        smallint quarter
        smallint year
        smallint fiscal_quarter
        smallint fiscal_year
        boolean is_weekend
        boolean is_holiday
        boolean is_working_day
    }

    dim_machine {
        serial machine_sk PK
        varchar machine_id
        varchar machine_name
        varchar machine_type_code
        varchar machine_type_name
        varchar line_code
        varchar line_name
        varchar plant_code
        numeric rated_capacity_per_hour
        boolean is_active
        numeric oee_target
        timestamptz dbt_updated_at
    }

    dim_product {
        serial product_sk PK
        varchar product_code
        varchar product_name
        varchar product_family
        varchar product_category
        numeric standard_cycle_time_sec
        numeric standard_material_cost
        boolean is_active
        timestamptz dbt_updated_at
    }

    dim_employee {
        serial employee_sk PK
        varchar employee_id
        varchar role_code
        varchar role_name
        varchar department_code
        varchar shift_assignment
        varchar skill_level
        numeric tenure_years
        boolean is_active
        boolean is_automated
        timestamptz dbt_updated_at
    }

    dim_shift {
        serial shift_sk PK
        varchar shift_code
        varchar shift_name
        time shift_start_time
        time shift_end_time
        numeric shift_duration_hours
        numeric planned_production_hours
        varchar plant_code
    }

    dim_defect_type {
        serial defect_type_sk PK
        varchar defect_type_code
        varchar defect_type_name
        varchar defect_category
        varchar severity_level
        boolean is_customer_escape_risk
        boolean is_active
        timestamptz dbt_updated_at
    }

    dim_failure_code {
        serial failure_code_sk PK
        varchar failure_code
        varchar failure_code_name
        varchar failure_category
        numeric typical_mttr_hours
        boolean is_active
        timestamptz dbt_updated_at
    }

    fct_production {
        bigserial production_sk PK
        integer date_key FK
        integer machine_sk FK
        integer product_sk FK
        integer shift_sk FK
        integer employee_sk FK
        varchar order_id
        integer planned_units
        integer actual_units
        integer good_units
        integer scrap_units
        integer rework_units
        numeric planned_duration_min
        numeric actual_duration_min
        numeric downtime_min
        numeric run_time_min
        numeric oee_availability
        numeric oee_performance
        numeric oee_quality
        numeric oee_overall
        numeric throughput_rate_per_hr
        numeric scrap_cost
        timestamptz dbt_updated_at
    }

    fct_quality_inspection {
        bigserial inspection_sk PK
        integer date_key FK
        integer machine_sk FK
        integer product_sk FK
        integer employee_sk FK
        integer defect_type_sk FK
        varchar inspection_id
        varchar order_id
        varchar inspection_type_code
        integer sample_size
        integer defects_found
        numeric defect_rate_pct
        numeric defect_rate_ppm
        char pass_fail
        numeric measurement_value
        numeric measurement_deviation
        timestamptz dbt_updated_at
    }

    fct_sensor_reading {
        bigserial sensor_sk PK
        integer date_key FK
        integer machine_sk FK
        bigint reading_id
        varchar sensor_type
        varchar sensor_unit
        numeric value
        timestamptz reading_timestamp
        boolean is_anomaly_flagged
        numeric data_quality_score
        boolean is_within_spec
        timestamptz dbt_updated_at
    }

    fct_maintenance_event {
        bigserial maintenance_sk PK
        integer date_key FK
        integer machine_sk FK
        integer employee_sk FK
        integer failure_code_sk FK
        varchar work_order_id
        varchar event_type
        boolean is_planned
        timestamptz downtime_start
        timestamptz downtime_end
        numeric downtime_minutes
        numeric mttr_minutes
        numeric repair_cost
        numeric days_since_last_failure
        numeric days_since_last_pm
        boolean pm_compliance
        timestamptz dbt_updated_at
    }

    dim_date ||--o{ fct_production : "date_key"
    dim_date ||--o{ fct_quality_inspection : "date_key"
    dim_date ||--o{ fct_sensor_reading : "date_key"
    dim_date ||--o{ fct_maintenance_event : "date_key"

    dim_machine ||--o{ fct_production : "machine_sk"
    dim_machine ||--o{ fct_quality_inspection : "machine_sk"
    dim_machine ||--o{ fct_sensor_reading : "machine_sk"
    dim_machine ||--o{ fct_maintenance_event : "machine_sk"

    dim_product ||--o{ fct_production : "product_sk"
    dim_product ||--o{ fct_quality_inspection : "product_sk"

    dim_shift ||--o{ fct_production : "shift_sk"

    dim_employee ||--o{ fct_production : "employee_sk"
    dim_employee ||--o{ fct_quality_inspection : "employee_sk"
    dim_employee ||--o{ fct_maintenance_event : "employee_sk"

    dim_defect_type ||--o{ fct_quality_inspection : "defect_type_sk"

    dim_failure_code ||--o{ fct_maintenance_event : "failure_code_sk"
```

---

## 3. Diagram Notes

### Operational DB ERD Notes

- All foreign key relationships shown are enforced at the database level as `FOREIGN KEY` constraints.
- The `sensor_readings` table connects only to `machines` — it is deliberately kept flat to minimize
  join overhead on the highest-volume table.
- The `downtime_events.order_id` FK is nullable — a machine can stop between production orders.
- The `material_movements.work_order_id` FK is nullable — supports non-maintenance inventory transactions
  (goods receipts, stock transfers).
- The `employees.shift_assignment` references `shifts.shift_code` — representing the primary shift,
  not the actual shift on any given day (actual shift coverage is in the HR shift_schedule CSV).

### Warehouse ERD Notes

- All dimension surrogate keys (-1) represent the pre-seeded "Unknown" member.
- `fct_sensor_reading` connects only to `dim_date` and `dim_machine` — sensor readings have no product,
  shift, or employee dimension. Sensor-to-production-order correlation is done in the intermediate layer
  via timestamp overlap joins, not stored in the fact table.
- `fct_production` and `fct_quality_inspection` share the same date, machine, product, and employee
  dimensions — enabling cross-fact-table analysis (e.g., OEE vs. defect rate by machine and date).
- The `fct_sensor_hourly_summary` derived table (not shown) provides hourly aggregates per machine
  per sensor type for dashboard and ML feature use. It references `dim_date` and `dim_machine` only.

---

*This ER diagram is the authoritative visual representation of the SMAP database schema.*
*Any schema change must be reflected here before implementation. Last reviewed: 2026-07-22.*
