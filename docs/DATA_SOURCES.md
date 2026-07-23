# Data Sources — Smart Manufacturing Analytics Platform (SMAP)

**Document Version:** 1.0.0
**Last Updated:** 2026-07-22
**Status:** Approved — Business Domain Baseline
**Owner:** Business Analysis Lead
**Related Documents:** [MANUFACTURING_PROCESS.md](./MANUFACTURING_PROCESS.md) · [KPI_DEFINITIONS.md](./KPI_DEFINITIONS.md) · [../DATABASE_DESIGN.md](../DATABASE_DESIGN.md) · [../SYSTEM_ARCHITECTURE.md](../SYSTEM_ARCHITECTURE.md)

---

## Table of Contents

1. [Data Source Overview](#1-data-source-overview)
2. [ERP System](#2-erp-system)
3. [MES — Manufacturing Execution System](#3-mes--manufacturing-execution-system)
4. [IoT Sensors / SCADA](#4-iot-sensors--scada)
5. [Maintenance Logs](#5-maintenance-logs)
6. [Quality Inspection System](#6-quality-inspection-system)
7. [Inventory System](#7-inventory-system)
8. [Operator Records](#8-operator-records)
9. [Data Source Integration Summary](#9-data-source-integration-summary)
10. [Data Quality Baseline](#10-data-quality-baseline)
11. [SMAP vs. Source System Mapping](#11-smap-vs-source-system-mapping)

---

## 1. Data Source Overview

PrecisionEdge's operational data is distributed across seven distinct source systems. Each system was implemented independently and has its own data model, identifiers, and access method. The SMAP ETL pipeline is responsible for extracting, harmonizing, and loading data from all seven sources into the unified data warehouse.

### 1.1 Source System Landscape

| Source ID  | System Name              | System Type      | Technology            | Data Domain                     | ETL Frequency        |
|------------|--------------------------|------------------|-----------------------|---------------------------------|----------------------|
| **SRC-ERP** | SAP S/4HANA             | ERP              | SAP S/4HANA 2023      | Production orders, inventory, HR | Hourly (incremental) |
| **SRC-MES** | MachineLink MES          | MES              | PostgreSQL (custom app) | Production actuals, downtime events | Every 15 min (incremental) |
| **SRC-IOT** | Siemens WinCC SCADA      | SCADA / IoT      | PostgreSQL (via SCADA gateway) | Sensor telemetry (temp, vibration, RPM, pressure, power) | Every 15 min (high-volume) |
| **SRC-MNT** | MachineLink Maintenance  | Maintenance CMMS | CSV flat file export  | Work orders, PM schedules        | Daily (02:00 UTC)    |
| **SRC-QA**  | MachineLink Quality      | Quality Module   | PostgreSQL (part of MES) | Inspection records, defect logs | Every 4 hours        |
| **SRC-INV** | SAP MM (Materials Mgmt)  | ERP sub-module   | SAP S/4HANA 2023      | Raw material inventory, spare parts stock | Hourly (incremental) |
| **SRC-HR**  | HR Information System    | HRIS             | CSV export from Workday | Operator profiles, shift assignments, skill levels | Daily (03:00 UTC)    |

### 1.2 Source System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    SOURCE SYSTEM LANDSCAPE                           │
├─────────────────┬───────────────────────────────────────────────────┤
│  ERP (SAP)      │  HR (Workday)                                      │
│  ├── Production │  └── Operators, Shifts, Skills                    │
│  ├── Inventory  │                                                     │
│  └── Financials │  SCADA (Siemens WinCC)                             │
│                 │  └── 384 IoT sensors → gateway DB                  │
│  MES (Machine   │                                                     │
│  Link)          │  Maintenance Logs                                   │
│  ├── Prod Orders│  └── Work orders, PM records                       │
│  ├── Quality    │      (CSV export from MachineLink)                  │
│  └── Downtime   │                                                     │
└────────┬────────┴────────────────────────────────────────────────────┘
         │           All sources extracted by SMAP ETL pipeline
         ▼
[SMAP ETL — Python extractors + Airflow DAGs]
         │
         ▼
[MinIO Bronze Zone → Silver Zone → PostgreSQL Data Warehouse]
```

---

## 2. ERP System

### 2.1 System Overview

| Attribute             | Detail                                                    |
|-----------------------|-----------------------------------------------------------|
| **System Name**       | SAP S/4HANA                                               |
| **Version**           | SAP S/4HANA 2023 (on-premise)                             |
| **Deployment**        | On-premise; hosted in PLT-DET data center                 |
| **Primary User Departments** | DEPT-PLN, DEPT-SCM, DEPT-FIN, DEPT-HR             |
| **SMAP Source ID**    | `SRC-ERP`                                                 |
| **Connection Method** | Direct PostgreSQL query via SAP HANA → PostgreSQL replica  |
| **Access Type**       | Read-only service account (`smap_erp_reader`)             |

### 2.2 Data Provided to SMAP

The ERP system is the authoritative source for **planning data** — what was *supposed* to happen. The MES provides the corresponding actuals — what *actually* happened.

| ERP Table / Object         | SMAP Relevance                                       | Key Fields Extracted                               |
|----------------------------|------------------------------------------------------|----------------------------------------------------|
| Production Orders (PP-MRP) | Planned quantity, planned start/end, product code, machine assignment | `order_id`, `machine_id`, `product_code`, `planned_qty`, `planned_start`, `planned_end`, `shift_id` |
| Work Centers               | Machine catalog with rated capacity                  | `work_center_id`, `machine_name`, `rated_capacity_per_hour` |
| Material Master            | Product hierarchy (product → family → category)      | `product_code`, `product_name`, `product_family`, `product_category`, `standard_cost` |
| Routing (Task List)        | Standard cycle time per product per operation        | `product_code`, `operation_code`, `standard_cycle_time_min` |
| Customer Orders (SD)       | Demand signal; links production to customer delivery | `sales_order_id`, `customer_id`, `delivery_date`, `order_qty` |
| GL Accounts (FI/CO)        | Standard cost per unit; scrap cost calculation       | `product_code`, `standard_material_cost`, `standard_labor_cost` |

### 2.3 ERP Data Quality Notes

| Data Quality Issue                | Description                                      | SMAP Handling                                    |
|-----------------------------------|--------------------------------------------------|--------------------------------------------------|
| Planning vs. execution gap        | ERP planned orders are often created before MES actuals are available; they may never update | SMAP joins on `order_id`; missing MES actuals shown as null |
| SAP order ID format               | Format: `PP-YYYYMMDD-XXXXX` (not the same as MES order ID) | ETL mapping table cross-references ERP ↔ MES order IDs |
| Work center ≠ MES machine ID      | SAP work centers use cost center naming; MES uses physical machine codes | `dim_machine` holds both; ETL populates mapping    |
| Planned cycle time accuracy       | Routings not always updated when engineering changes cycle times | Validated during dbt staging; stale routings flagged |

### 2.4 ETL Extraction Details

| Attribute                | Detail                                              |
|--------------------------|-----------------------------------------------------|
| **Extraction Method**    | Watermark-based incremental; `MANDT`/`AENDT` (change date) |
| **Extraction Frequency** | Every 1 hour                                        |
| **Output Format**        | Parquet; Bronze zone partition: `bronze/erp/year=YYYY/month=MM/day=DD/` |
| **Validation Suite**     | Great Expectations: not-null on `order_id`, `product_code`, `planned_qty`; `planned_qty` > 0 |
| **Volume (daily)**       | ~2,000–5,000 order records; ~500 routing records per day (incremental changes) |

---

## 3. MES — Manufacturing Execution System

### 3.1 System Overview

| Attribute             | Detail                                                    |
|-----------------------|-----------------------------------------------------------|
| **System Name**       | MachineLink MES                                           |
| **Version**           | MachineLink v4.2                                          |
| **Deployment**        | On-premise; PLT-DET data center; PostgreSQL backend       |
| **Primary User Departments** | DEPT-OPS, DEPT-QA, DEPT-MNT                      |
| **SMAP Source ID**    | `SRC-MES`                                                 |
| **Connection Method** | Direct PostgreSQL connection                              |
| **Access Type**       | Read-only service account (`smap_mes_reader`)             |

### 3.2 Data Provided to SMAP

The MES is the **most important single data source** for SMAP. It captures everything that happens on the production floor in near-real-time: production actuals, downtime events, quality results, and machine status.

| MES Table                | SMAP Relevance                                       | Key Fields Extracted                               |
|--------------------------|------------------------------------------------------|----------------------------------------------------|
| `production_orders`      | Actual production results — the primary production fact | `order_id`, `machine_id`, `product_code`, `shift_id`, `actual_start`, `actual_end`, `actual_units`, `good_units`, `scrap_units`, `operator_id` |
| `downtime_events`        | Every stop event with reason code                    | `event_id`, `machine_id`, `stop_start`, `stop_end`, `duration_min`, `reason_code`, `event_type` |
| `machine_status_log`     | Real-time machine state (running/idle/down)          | `machine_id`, `status`, `status_timestamp`         |
| `quality_results`        | In-process and final inspection results (Quality module) | See Section 6 (Quality Inspection System)      |
| `maintenance_workorders` | Work order records (Maintenance module)              | See Section 5 (Maintenance Logs)                   |

### 3.3 MES Data Quality Notes

| Data Quality Issue                | Description                                      | SMAP Handling                                    |
|-----------------------------------|--------------------------------------------------|--------------------------------------------------|
| Missing `actual_end` timestamps   | Orders that are "In Progress" at extraction time have null `actual_end` | Filter to `status = 'Complete'` for OEE calculation; in-progress orders tracked separately |
| Operator ID nulls                 | ~4% of records have no `operator_id` (auto-cycle machines) | Treated as `EMP-ROBOT`; flagged in `dim_employee` as automated |
| Duplicate event records           | SCADA gateway occasionally creates duplicate sensor-triggered stop events | Deduplication logic in `stg_downtime_events` using `event_id` uniqueness check |
| MES order ID vs. ERP order ID     | Different key schemes; mapping table in MES `order_crossref` table | ETL joins via `order_crossref`; fallback: match on date + machine + product |

### 3.4 ETL Extraction Details

| Attribute                | Detail                                              |
|--------------------------|-----------------------------------------------------|
| **Extraction Method**    | Watermark-based incremental on `updated_at` column  |
| **Extraction Frequency** | Every 15 minutes                                    |
| **Output Format**        | Parquet; Bronze zone partition: `bronze/mes/year=YYYY/month=MM/day=DD/` |
| **Validation Suite**     | Not-null on `order_id`, `machine_id`, `actual_units`; `actual_units` ≥ 0; `actual_end` > `actual_start` |
| **Volume (daily)**       | ~1,500 production orders; ~3,200 downtime events; ~18,000 machine status records |

---

## 4. IoT Sensors / SCADA

### 4.1 System Overview

| Attribute             | Detail                                                    |
|-----------------------|-----------------------------------------------------------|
| **System Name**       | Siemens WinCC SCADA + Custom IoT gateway database         |
| **Version**           | Siemens WinCC v7.5; custom gateway on PostgreSQL 15       |
| **Deployment**        | On-premise; SCADA server on PLT-DET plant network; gateway on data center PostgreSQL |
| **Primary User Departments** | DEPT-OPS (monitoring), DEPT-ENG (analysis), DEPT-MNT (condition monitoring) |
| **SMAP Source ID**    | `SRC-IOT`                                                 |
| **Connection Method** | Direct PostgreSQL connection to SCADA gateway database    |
| **Access Type**       | Read-only service account (`smap_iot_reader`)             |

### 4.2 Data Provided to SMAP

IoT sensor data is the **highest volume data source** in SMAP and the primary input for predictive maintenance and anomaly detection ML models.

| Sensor Data Stream       | Description                                          | Sensors | Frequency  |
|--------------------------|------------------------------------------------------|---------|------------|
| Temperature readings     | Spindle, coolant, hydraulic oil temperature          | 144     | 30 seconds |
| Vibration readings       | Spindle and gearbox RMS vibration velocity           | 93      | 30 seconds |
| Spindle RPM              | Spindle speed (actual vs. programmed)                | 31      | 30 seconds |
| Hydraulic pressure       | Hydraulic circuit pressure                           | 48      | 30 seconds |
| Power consumption        | Machine power draw (kWh)                             | 48      | 60 seconds |
| Cutting force            | In-cut force measurement (equipped machines)         | 8       | 30 seconds |
| Coolant flow rate        | Coolant pump output volume                           | 12      | 60 seconds |

**All readings are stored in a single `sensor_readings` table with columns:**
`reading_id`, `machine_id` (SCADA tag), `sensor_type`, `sensor_unit`, `value`, `reading_timestamp`, `is_anomaly_flagged`, `data_quality_score`

### 4.3 SCADA-to-SMAP ID Mapping

The SCADA system identifies machines by PLC tag names (e.g., `CELL_A1_LATHE_01`), while the MES uses machine codes (e.g., `MCH-001`). The SMAP ETL pipeline resolves this in `stg_sensor_readings` using a static mapping table (`scada_machine_map`) that cross-references SCADA tag → MES `machine_id`.

### 4.4 IoT Data Quality Notes

| Data Quality Issue                | Description                                      | SMAP Handling                                    |
|-----------------------------------|--------------------------------------------------|--------------------------------------------------|
| Sensor outages / dropouts         | Network interruptions or sensor failures cause gaps in time series | Great Expectations: flag gap > 5 minutes as anomaly; imputation not performed (gaps preserved) |
| Out-of-range readings             | Sensor fault returns extreme values (e.g., -999 or 9999) | Value range validation in GE suite; out-of-range rows quarantined |
| Clock skew                        | SCADA server clock sometimes drifts from database server by up to ±45 seconds | Timestamp normalization in `stg_sensor_readings` to UTC |
| High null rate on `data_quality_score` | Older sensors (pre-2021) don't populate the quality score field | Null treated as 1.0 (assume good quality) for older sensors; documented in metadata |
| SCADA duplicate writes            | SCADA writes can create duplicate readings within the same 30-second window | Deduplicated on (`machine_id`, `sensor_type`, `reading_timestamp`) in staging |

### 4.5 ETL Extraction Details

| Attribute                | Detail                                              |
|--------------------------|-----------------------------------------------------|
| **Extraction Method**    | Watermark-based incremental on `reading_timestamp`  |
| **Extraction Frequency** | Every 15 minutes                                    |
| **Output Format**        | Parquet (partitioned by sensor type for efficient query pushdown); Bronze zone |
| **Validation Suite**     | Not-null on `machine_id`, `reading_timestamp`, `value`; `value` within configured range per sensor type; `reading_timestamp` ≤ now + 5 min |
| **Volume (daily)**       | ~554,000–1,105,000 sensor readings                  |
| **Volume (annual)**      | ~200–400 million records; ~8–15 GB Parquet compressed |

---

## 5. Maintenance Logs

### 5.1 System Overview

| Attribute             | Detail                                                    |
|-----------------------|-----------------------------------------------------------|
| **System Name**       | MachineLink Maintenance (CMMS module)                     |
| **Export Format**     | CSV flat files (nightly export script)                    |
| **Export Location**   | Network file share: `\\FILESERVER01\maintenance_exports\` |
| **Primary User Departments** | DEPT-MNT (Maintenance & Reliability)              |
| **SMAP Source ID**    | `SRC-MNT`                                                 |
| **Connection Method** | SFTP file pickup from network share to ETL server         |
| **Access Type**       | Read-only SFTP credentials                                |

### 5.2 Why CSV (Not Direct DB)?

The MachineLink Maintenance module runs on a separate database instance (legacy Oracle 11g) from the MES (PostgreSQL). To avoid establishing a direct Oracle connection in the ETL pipeline (which would require Oracle client libraries and a dedicated driver), the maintenance team runs a nightly export script that dumps the previous day's work orders to CSV. This is a pragmatic compromise — a direct Oracle connection is planned as a Phase 2 enhancement.

### 5.3 Data Provided to SMAP

| CSV File                    | Content                                              | Approximate Daily Volume |
|-----------------------------|------------------------------------------------------|--------------------------|
| `work_orders_YYYYMMDD.csv`  | All work orders with status change in previous 24 hr | 20–60 rows/day           |
| `pm_schedule_YYYYMMDD.csv`  | Active PM schedule (full dump daily)                 | 250–350 rows (static-ish)|
| `parts_used_YYYYMMDD.csv`   | Spare parts consumed per work order                  | 30–100 rows/day          |

**Key fields in `work_orders` CSV:**
`work_order_id`, `machine_id`, `event_type`, `failure_code`, `description`, `downtime_start`, `downtime_end`, `downtime_minutes`, `technician_id`, `repair_cost`, `parts_replaced`, `root_cause`, `created_at`

### 5.4 Maintenance Data Quality Notes

| Data Quality Issue                | Description                                      | SMAP Handling                                    |
|-----------------------------------|--------------------------------------------------|--------------------------------------------------|
| Free-text `root_cause` field       | Unstructured text; inconsistently filled (~30% completion rate) | Stored as-is; NLP enrichment is a future enhancement |
| `downtime_end` blank for open WOs  | Open work orders have no `downtime_end`           | Only closed WOs (downtime_end not null) used for MTTR |
| Machine ID format mismatch        | Maintenance uses asset tag numbers (e.g., `AT-0042`) not MES machine codes | Static mapping table resolves asset tag → MES `machine_id` |
| Missing `failure_code`            | ~15% of corrective maintenance events lack a failure code | Treated as `FC-OTHER`; flagged for root cause follow-up |
| CSV encoding issues               | Historical CSV exports sometimes contain non-UTF-8 characters in description fields | `chardet` encoding detection + forced UTF-8 decode with error replacement |

### 5.5 ETL Extraction Details

| Attribute                | Detail                                              |
|--------------------------|-----------------------------------------------------|
| **Extraction Method**    | Full file pickup (SFTP); new file detected by filename date suffix |
| **Extraction Frequency** | Daily at 02:00 UTC (after nightly export completes) |
| **Output Format**        | Parquet; Bronze zone partition: `bronze/maintenance/year=YYYY/month=MM/day=DD/` |
| **Validation Suite**     | Not-null on `work_order_id`, `machine_id`, `downtime_start`; `event_type` in accepted values; `downtime_minutes` ≥ 0 |
| **Volume (daily)**       | 20–60 work orders; ~5–15 KB CSV per file            |

---

## 6. Quality Inspection System

### 6.1 System Overview

| Attribute             | Detail                                                    |
|-----------------------|-----------------------------------------------------------|
| **System Name**       | MachineLink Quality (quality module within MES)           |
| **Version**           | Same PostgreSQL instance as MES (`SRC-MES`)               |
| **Primary User Departments** | DEPT-QA (Quality Assurance)                       |
| **SMAP Source ID**    | `SRC-QA`                                                  |
| **Connection Method** | Direct PostgreSQL connection (same DB as MES)             |
| **Access Type**       | Read-only service account (`smap_mes_reader`)             |

### 6.2 Data Provided to SMAP

The Quality module stores all inspection records generated during the production process — first-article, in-process, and final inspections.

| QA Table                    | Content                                              | Key Fields                                       |
|-----------------------------|------------------------------------------------------|--------------------------------------------------|
| `quality_inspections`       | One record per sampling event                        | `inspection_id`, `order_id`, `machine_id`, `inspection_timestamp`, `sample_size`, `defects_found`, `defect_type_code`, `defect_description`, `inspector_id`, `measurement_value`, `measurement_unit`, `pass_fail` |
| `defect_types`              | Defect type code reference table                     | `defect_type_code`, `defect_category`, `severity_level`, `description` |
| `inspection_types`          | Inspection type reference (first-article, in-process, final) | `inspection_type_code`, `inspection_type_name` |
| `quality_holds`             | Active and historical quality holds                  | `hold_id`, `order_id`, `hold_reason`, `hold_start`, `hold_end`, `disposition` |

### 6.3 Quality Data Quality Notes

| Data Quality Issue                | Description                                      | SMAP Handling                                    |
|-----------------------------------|--------------------------------------------------|--------------------------------------------------|
| Defect type code missing          | ~8% of defect records have no `defect_type_code` | Treated as `DFT-OTHER` in `dim_defect_type`      |
| `measurement_value` units         | Inconsistent units for same characteristic across different inspectors | Standardized in `stg_quality_inspections` via `measurement_unit` lookup |
| First-article records vs. production inspections | First-article inspections inflate sample counts if not filtered | `inspection_type_code` filter in dbt intermediate models |
| Defect rate calculation edge case | Orders with `sample_size = 0` (skipped inspection) | Filtered from defect rate calculation; flagged as incomplete |

### 6.4 ETL Extraction Details

| Attribute                | Detail                                              |
|--------------------------|-----------------------------------------------------|
| **Extraction Method**    | Watermark-based incremental on `inspection_timestamp` |
| **Extraction Frequency** | Every 4 hours                                       |
| **Output Format**        | Parquet; Bronze zone partition: `bronze/quality/year=YYYY/month=MM/day=DD/` |
| **Validation Suite**     | Not-null on `inspection_id`, `order_id`, `sample_size`, `pass_fail`; `defects_found` ≤ `sample_size`; `pass_fail` in ('P', 'F') |
| **Volume (daily)**       | ~800–1,500 inspection records/day                   |

---

## 7. Inventory System

### 7.1 System Overview

| Attribute             | Detail                                                    |
|-----------------------|-----------------------------------------------------------|
| **System Name**       | SAP MM (Materials Management) — sub-module of SAP S/4HANA |
| **Version**           | SAP S/4HANA 2023                                          |
| **Primary User Departments** | DEPT-SCM (Supply Chain), DEPT-MNT (spare parts)   |
| **SMAP Source ID**    | `SRC-INV`                                                 |
| **Connection Method** | Same PostgreSQL replica as `SRC-ERP`                      |
| **Access Type**       | Read-only service account (`smap_erp_reader`)             |

### 7.2 Data Provided to SMAP

Inventory data from SAP MM provides two critical data streams: raw material stock levels (for production planning context) and spare parts inventory (for maintenance planning).

| SAP Object / Table           | Content                                              | Key Fields                                       |
|------------------------------|------------------------------------------------------|--------------------------------------------------|
| Material stocks (MARD/MCHB)  | Current stock quantity per material per storage location | `material_code`, `plant`, `storage_location`, `stock_qty`, `stock_uom`, `last_updated` |
| Material movements (MSEG)    | Goods receipts, goods issues, stock transfers        | `movement_type`, `material_code`, `qty`, `movement_date`, `production_order_id` |
| Spare parts catalog          | Spare parts used in maintenance, with reorder points | `spare_part_code`, `part_description`, `stock_qty`, `reorder_point`, `lead_time_days` |
| Material valuation (MBEW)    | Standard cost per unit for scrap cost calculation    | `material_code`, `standard_price`, `currency`    |

### 7.3 Inventory Data Quality Notes

| Data Quality Issue                | Description                                      | SMAP Handling                                    |
|-----------------------------------|--------------------------------------------------|--------------------------------------------------|
| Stock level lag                   | SAP stock levels are updated at goods issue/receipt (transaction time), not continuously — can lag actual physical stock | Noted in data freshness metadata; not a significant issue for daily analytics |
| Spare parts not all in SAP        | ~12% of spare parts in the maintenance storeroom are not in SAP (ordered via petty cash or direct purchase) | These parts are excluded from inventory analytics; flagged as data coverage gap |
| Material code mismatches          | Some spare parts in SAP use different codes than in MachineLink Maintenance `parts_replaced` field | Cross-reference mapping table in ETL; unmapped codes logged |

### 7.4 ETL Extraction Details

| Attribute                | Detail                                              |
|--------------------------|-----------------------------------------------------|
| **Extraction Method**    | Watermark-based incremental on `last_updated`        |
| **Extraction Frequency** | Every 1 hour                                        |
| **Output Format**        | Parquet; Bronze zone: `bronze/inventory/year=YYYY/month=MM/day=DD/` |
| **Volume (daily)**       | ~500–800 material movement records; ~300 stock-level snapshot records |

---

## 8. Operator Records

### 8.1 System Overview

| Attribute             | Detail                                                    |
|-----------------------|-----------------------------------------------------------|
| **System Name**       | Workday HRIS (Human Resources Information System)         |
| **Export Format**     | CSV flat files (daily scheduled export via Workday Integration tool) |
| **Primary User Departments** | DEPT-HR, DEPT-OPS                               |
| **SMAP Source ID**    | `SRC-HR`                                                  |
| **Connection Method** | SFTP file pickup from HR system export location           |
| **Access Type**       | Read-only SFTP; **anonymized data only** (see privacy note below) |

### 8.2 Data Provided to SMAP

Operator records provide the reference dimension for quality traceability, shift attribution, and workforce analytics. SMAP uses operator data at an **aggregated, anonymized level** for analytics — no individual-level performance scoring.

| CSV File                    | Content                                              | Key Fields                                       |
|-----------------------------|------------------------------------------------------|--------------------------------------------------|
| `operators_YYYYMMDD.csv`    | Active operator roster with role and skill data      | `employee_id`, `role_code`, `shift_assignment`, `department_code`, `hire_date`, `skill_level`, `training_certifications` |
| `shift_schedule_YYYYMMDD.csv` | Weekly shift schedule (who is on which shift)     | `employee_id`, `shift_code`, `shift_date`, `line_assignment` |

> **Privacy Note:** SMAP does not store personal identifiable information (PII) beyond what is necessary for manufacturing traceability. Specifically:
> - Employee names are **not** stored in the SMAP warehouse — only anonymized `employee_id` codes
> - The `dim_employee` dimension stores role, department, shift, and skill level — not individual names or contact information
> - Individual operator performance metrics are only accessible in **aggregated** form (by shift, by line, by role) — not as individual scorecards
> - Raw HRIS CSV files are **not** retained after ETL processing — only the anonymized, aggregated warehouse records persist

### 8.3 Operator Data Use Cases in SMAP

| Use Case                                          | Data Used                                     |
|---------------------------------------------------|-----------------------------------------------|
| Quality traceability — link defect to inspector    | `inspector_id` on inspection record → `dim_employee` role |
| Shift-level performance — Day vs. Night comparison | Shift assignment → aggregate OEE by shift      |
| Skill level context for quality analysis           | `skill_level` used as feature in quality prediction ML model |
| Maintenance response time analysis                 | `technician_id` on work order → MTTR by technician team |
| Workforce experience trend                         | `hire_date` → derive tenure; correlate with OEE trend |

### 8.4 ETL Extraction Details

| Attribute                | Detail                                              |
|--------------------------|-----------------------------------------------------|
| **Extraction Method**    | Full file pickup (SFTP); operator roster is small enough for daily full refresh |
| **Extraction Frequency** | Daily at 03:00 UTC                                  |
| **Output Format**        | Parquet; Bronze zone: `bronze/hr/year=YYYY/month=MM/day=DD/` |
| **Validation Suite**     | Not-null on `employee_id`, `role_code`, `shift_assignment`; `role_code` in accepted values list |
| **Volume (daily)**       | ~980 operator records (PLT-DET headcount); ~50 KB CSV |
| **PII Handling**         | `employee_name` column dropped at Bronze → Silver transition; never loaded into warehouse |

---

## 9. Data Source Integration Summary

### 9.1 Source-to-Warehouse Data Flow

```
SRC-ERP ──────────────────────────────────────────────────┐
  (Production orders, routing, material master, cost)       │
                                                           │
SRC-MES ──────────────────────────────────────────────────┤
  (Actual production, downtime events, machine status)      │
                                                           │
SRC-IOT ──────────────────────────────────────────────────┤
  (Sensor telemetry: temp, vibration, RPM, pressure, power) │
                                                           ├──► [SMAP ETL Pipeline]
SRC-MNT ──────────────────────────────────────────────────┤      │
  (Work orders, PM records, parts used, root cause)         │      ▼
                                                           │  [Bronze Lake (MinIO)]
SRC-QA ───────────────────────────────────────────────────┤      │
  (Inspection records, defect logs, disposition)            │      ▼
                                                           │  [Silver Lake (MinIO)]
SRC-INV ──────────────────────────────────────────────────┤      │
  (Material stocks, movements, spare parts)                 │      ▼
                                                           │  [PostgreSQL Staging]
SRC-HR ───────────────────────────────────────────────────┘      │
  (Operator roster, shift schedules, skill levels)                ▼
                                                           [dbt Transformations]
                                                                   │
                                                                   ▼
                                                           [Data Warehouse — Marts]
                                                           fct_production
                                                           fct_quality_inspection
                                                           fct_sensor_reading
                                                           fct_maintenance_event
                                                           dim_machine / dim_product /
                                                           dim_employee / dim_date ...
```

### 9.2 Common Key Cross-Reference

A critical integration challenge is that each source system uses different identifiers for the same real-world entities (machines, products, orders). The SMAP ETL pipeline resolves this via mapping tables loaded into the staging schema:

| Entity    | ERP Key            | MES Key       | SCADA Key              | Maintenance Key | SMAP Warehouse Key |
|-----------|--------------------|---------------|------------------------|-----------------|--------------------|
| Machine   | Work Center code   | `machine_id`  | PLC tag name           | Asset tag number | `machine_sk` (surrogate) |
| Product   | Material code      | `product_code`| N/A                    | N/A             | `product_sk` (surrogate) |
| Order     | PP order number    | `order_id`    | N/A                    | N/A             | `production_sk` (surrogate) |
| Employee  | SAP Personnel No.  | `operator_id` | N/A                    | `technician_id` | `employee_sk` (surrogate) |

---

## 10. Data Quality Baseline

Before SMAP, data quality in PrecisionEdge's source systems had not been systematically measured. As part of SMAP Phase 1, a baseline data quality assessment was conducted. Results inform the Great Expectations validation suite thresholds.

| Source   | Completeness | Consistency | Timeliness     | Accuracy | Overall Grade |
|----------|--------------|-------------|----------------|----------|---------------|
| ERP      | 94%          | High        | 1-hour lag     | High     | **A−**        |
| MES      | 89%          | Medium      | 15-min lag     | High     | **B+**        |
| IoT/SCADA | 96% (with gaps) | High   | Near-real-time | High     | **A−**        |
| Maintenance | 71%       | Low         | 24-hour lag    | Medium   | **C+**        |
| Quality  | 87%          | Medium      | 4-hour lag     | High     | **B+**        |
| Inventory | 92%         | High        | 1-hour lag     | High     | **A−**        |
| HR       | 98%          | High        | 24-hour lag    | High     | **A**         |

> **Completeness:** % of expected records actually present
> **Consistency:** Degree to which values follow expected formats and referential integrity
> **Timeliness:** How current the data is relative to when events occur
> **Accuracy:** Degree to which recorded values reflect actual real-world values

---

## 11. SMAP vs. Source System Mapping

The following table shows how each SMAP warehouse table is built from one or more source systems:

| SMAP Warehouse Object   | Primary Sources             | Secondary Sources        | Key Business Logic Applied      |
|-------------------------|-----------------------------|--------------------------|----------------------------------|
| `dim_machine`           | SRC-MES (machine master)    | SRC-ERP (work center)    | Machine ID normalization; capacity from ERP routing |
| `dim_product`           | SRC-ERP (material master)   | SRC-MES (product codes)  | Product hierarchy from ERP; active flag from MES   |
| `dim_employee`          | SRC-HR (operator roster)    | SRC-MES (operator IDs)   | Anonymization; skill level enrichment              |
| `dim_shift`             | Static seed (dbt)           | SRC-HR (schedule)        | Fixed 3-shift pattern; seeded from process docs    |
| `dim_defect_type`       | SRC-QA (defect_types table) | Static seed              | Defect hierarchy from quality system               |
| `dim_date`              | Static seed (dbt)           | —                        | Calendar + fiscal date attributes                  |
| `fct_production`        | SRC-MES (production orders) | SRC-ERP (planned qty, routing) | OEE calculation; joins planned (ERP) with actual (MES) |
| `fct_quality_inspection`| SRC-QA (inspections)        | SRC-MES (orders)         | Defect rate calculation; order linkage             |
| `fct_sensor_reading`    | SRC-IOT (sensor readings)   | SRC-MES (machine status) | Anomaly flag enrichment; SCADA ID → machine_sk resolution |
| `fct_maintenance_event` | SRC-MNT (work orders)       | SRC-MES (downtime events)| MTTR calculation; planned vs. unplanned classification |

---

*This document is the authoritative reference for all data source integrations within the SMAP platform. Any addition of a new data source, change in extraction frequency, or update to connection method must be reflected here and in the corresponding ETL pipeline documentation. Last reviewed: 2026-07-22.*
