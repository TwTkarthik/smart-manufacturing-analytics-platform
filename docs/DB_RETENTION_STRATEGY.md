# Data Retention Strategy — Smart Manufacturing Analytics Platform (SMAP)

**Document Version:** 1.0.0
**Last Updated:** 2026-07-22
**Status:** Approved — Complete Design Baseline
**Owner:** Lead Database Architect
**Related Documents:**
- [../DATABASE_DESIGN.md](../DATABASE_DESIGN.md)
- [DB_PARTITIONING_STRATEGY.md](./DB_PARTITIONING_STRATEGY.md)
- [../docs/DATA_SOURCES.md](./DATA_SOURCES.md)

---

## Table of Contents

1. [Retention Principles](#1-retention-principles)
2. [Data Lake Retention (MinIO)](#2-data-lake-retention-minio)
3. [Operational Database Retention](#3-operational-database-retention)
4. [Data Warehouse Retention](#4-data-warehouse-retention)
5. [Application and Infrastructure Log Retention](#5-application-and-infrastructure-log-retention)
6. [ML Artifact Retention](#6-ml-artifact-retention)
7. [Retention Enforcement](#7-retention-enforcement)

---

## 1. Retention Principles

SMAP's data retention strategy is governed by four principles:

1. **Purpose Limitation:** Data is retained only as long as it serves an active analytical or
   operational purpose. Retaining data beyond its useful life increases storage costs, query overhead,
   and compliance surface area.

2. **Immutability of Raw Data:** Bronze zone (raw) data is immutable after ingestion. It is
   retained longer than processed data to serve as the authoritative replay source if transformations
   need to be re-run or corrected.

3. **Tiered Retention by Processing Stage:** Retention periods increase as data moves downstream:
   - Raw (Bronze): Shorter retention; high volume; replay source
   - Processed (Silver): Medium retention; cleaned and validated
   - Analytical (Gold/Warehouse): Longer retention; business-critical KPI history
   - Logs: Short retention; operational visibility only

4. **Compliance Baseline:** PrecisionEdge operates under IATF 16949 (automotive quality standard),
   which requires **minimum 3-year retention** of quality inspection records and production traceability
   data. The retention periods below comply with this requirement.

---

## 2. Data Lake Retention (MinIO)

### 2.1 Bronze Zone (Raw Data)

The Bronze zone contains unmodified data exactly as received from source systems — the authoritative
replay source.

| Source | Bronze Path | Retention Period | Rationale |
|---|---|---|---|
| IoT Sensors | `bronze/sensors/year=*/month=*/day=*/` | **90 days** | Highest volume (~8–15 GB/month compressed). Sensor readings are processed to Silver within 15 minutes; 90 days provides ample replay window for any transformation re-run. Storage cost justifies shorter retention. |
| MES Production | `bronze/mes/year=*/month=*/day=*/` | **12 months** | Production records are needed for OEE backcalculation and occasional reconciliation with ERP. Lower volume (< 1 MB/day). |
| ERP Data | `bronze/erp/year=*/month=*/day=*/` | **12 months** | Planning data used in OEE Performance calculation. Low volume. |
| Maintenance Logs | `bronze/maintenance/year=*/month=*/day=*/` | **36 months** | IATF 16949 requires 3-year traceability for maintenance records. Low volume (< 15 KB/day). |
| Quality Inspections | `bronze/quality/year=*/month=*/day=*/` | **36 months** | IATF 16949 requires 3-year traceability for quality inspection records. |
| HR / Operators | `bronze/hr/year=*/month=*/day=*/` | **30 days** | Operator rosters are refreshed daily full-refresh. Raw HR files contain no PII beyond employee_id (name is dropped at ingest). Short retention acceptable. |
| Inventory | `bronze/inventory/year=*/month=*/day=*/` | **12 months** | Inventory movements used for maintenance cost calculation and parts consumption reporting. |

### 2.2 Silver Zone (Cleaned Data)

| Source | Silver Path | Retention Period | Rationale |
|---|---|---|---|
| IoT Sensors | `silver/sensors/` | **90 days** | Same as Bronze — high volume. Silver sensor data is aggregated into warehouse; individual cleaned readings are not needed beyond 90 days. |
| MES Production | `silver/mes/` | **12 months** | Supports ad-hoc notebook analysis on production history. |
| ERP, Maintenance, Quality, Inventory | `silver/*/` | **24 months** | Supports notebook EDA and ad-hoc analysis without querying the warehouse. |
| HR / Operators | `silver/hr/` | **7 days** | Anonymized operator data; minimal retention needed in Silver — warehouse dim_employee is the analytical record of truth. |

### 2.3 Gold Zone (Analytical Exports)

| Path | Retention Period | Rationale |
|---|---|---|
| `gold/oee/` | **36 months** | OEE trend history; executive dashboards. Matches IATF 16949 minimum. |
| `gold/kpis/` | **36 months** | Historical KPI snapshots for period-over-period comparison. |
| `gold/ml_features/` | **12 months** | Feature datasets used to train ML models. Older datasets superseded when models are retrained. |

### 2.4 Quarantine and Dead-Letter Zones

| Zone | Retention Period | Rationale |
|---|---|---|
| `quarantine/` | **30 days** | Records failing Great Expectations validation. Investigated and resolved within the sprint; auto-purged after 30 days. |
| `dead-letter/` | **14 days** | Failed ETL extraction batches for manual retry. Should be resolved within 48 hours; 14-day window for edge cases. |

---

## 3. Operational Database Retention

The operational database simulates live source systems. It is **not** the system of record for
historical analytics — that role belongs to the warehouse. Retention in the operational DB
is therefore shorter and focused on enabling incremental ETL extraction.

| Table | Retention Period | Mechanism | Rationale |
|---|---|---|---|
| `sensor_readings` | **90 days rolling** | Partition DROP (monthly partitions, see DB_PARTITIONING_STRATEGY.md) | High volume (~400M rows/year). Beyond 90 days, sensor data is available in Silver zone and warehouse. Partition DROP is instantaneous and lock-free vs. DELETE-based purging. |
| `production_orders` | **Indefinite** | No automated deletion | Audit trail requirement. Production order history is small volume (< 500K rows/year) and needed for traceability and OEE reconciliation. |
| `quality_inspections` | **Indefinite** | No automated deletion | IATF 16949 requires 3-year traceability minimum. Indefinite retention acceptable given low volume (~500K rows/year). |
| `maintenance_logs` | **Indefinite** | No automated deletion | IATF 16949 and asset history requirement. Equipment maintenance history is needed for failure mode analysis across the machine lifecycle. |
| `downtime_events` | **Indefinite** | No automated deletion | Required for MTBF calculation over rolling windows; needed for OEE Availability backcalculation. Low volume. |
| `employees` | **Indefinite (with soft delete)** | `is_active = FALSE` on departure | Anonymized employee records needed for historical quality traceability (who inspected what). No PII stored. |
| `machines` | **Indefinite (with soft delete)** | `is_active = FALSE` on decommission | Machine history needed for lifetime failure analysis and predictive maintenance model training. |
| `products` | **Indefinite (with soft delete)** | `is_active = FALSE` on discontinuation | Product history needed for long-term defect rate trend analysis. |
| `pm_schedules` | **Indefinite** | No automated deletion | PM schedule history needed for compliance verification. |
| `spare_parts` | **Indefinite (with soft delete)** | `is_active = FALSE` on discontinuation | Parts catalog history needed for historical cost analysis. |
| `material_movements` | **Indefinite** | No automated deletion | Low volume; complete parts consumption history needed for cost and usage analysis. |

---

## 4. Data Warehouse Retention

The warehouse is the long-term system of record for all analytical data. Retention periods
are set to comply with IATF 16949 requirements and support long-term trend analysis.

### 4.1 Dimension Tables

| Table | Retention Period | Rationale |
|---|---|---|
| `dim_date` | Permanent | Static reference data; 3,653 rows — negligible storage |
| `dim_machine` | Permanent | Machine history needed for lifetime OEE and reliability analysis |
| `dim_product` | Permanent | Product catalog history for long-term quality trends |
| `dim_employee` | Permanent | Anonymized employee records for historical quality traceability |
| `dim_shift` | Permanent | Static reference data |
| `dim_defect_type` | Permanent | Defect code history for consistent Pareto analysis over time |
| `dim_failure_code` | Permanent | Failure code history for consistent maintenance analysis |

### 4.2 Fact Tables

| Table | Retention Period | Mechanism | Rationale |
|---|---|---|---|
| `fct_production` | **5 years rolling** | Annual archive to MinIO Gold + partition drop (if partitioned in future) | OEE trend analysis requires multi-year history for seasonality and year-over-year comparison. 5 years exceeds IATF 16949 minimum. |
| `fct_quality_inspection` | **5 years rolling** | Annual archive to MinIO Gold + record deletion | IATF 16949 compliance. Quality inspection traceability required for 3 years minimum. 5 years provides buffer. |
| `fct_sensor_reading` | **24 months rolling** | Monthly partition archival to MinIO Gold + partition DROP | High volume (400M–800M rows at 2 years). 24 months covers the maximum ML model training window (models use 12-month feature windows). Older data archived to MinIO Gold for potential future retrieval. |
| `fct_maintenance_event` | **Indefinite** | No automated deletion | Very low volume (~15K rows/year). IATF 16949 requires maintenance traceability. Indefinite retention is negligible cost. |

### 4.3 Warehouse Schema Tables

| Schema | Retention Period | Notes |
|---|---|---|
| `raw.*` (landing tables) | **30 days** | Landing tables hold data only until the dbt run promotes it to staging. 30 days provides a replay window if a dbt run fails. Auto-truncated by the weekly maintenance DAG. |
| `staging.*` (stg_* views) | N/A — views | Views have no stored data; rebuilt on every dbt run. No retention concern. |
| `intermediate.*` (int_* ephemeral) | N/A — ephemeral | Compiled inline; no materialized data. No retention concern. |

---

## 5. Application and Infrastructure Log Retention

| Log Type | Storage Location | Retention Period | Rationale |
|---|---|---|---|
| Airflow task logs | Airflow log directory (`/opt/airflow/logs/`) | **30 days** | Needed for pipeline debugging and audit. Beyond 30 days, logs are rarely accessed and consume significant storage for the sensor ETL DAG. |
| FastAPI access logs | Docker container log driver → Prometheus | **15 days** | API request logs for performance and error analysis. 15 days covers typical incident investigation window. |
| dbt run logs | MLflow artifact store (`ml/experiments/`) | **90 days** | dbt run artifacts (manifest.json, run_results.json) are retained for lineage debugging. |
| Great Expectations Data Docs | MinIO `data-quality/` bucket | **90 days** | Validation reports for recent runs available for quality audit. Older reports archived. |
| Prometheus metrics | Prometheus data directory | **15 days** | Infrastructure metrics retention matches Prometheus default. Historical metrics available in Grafana annotations. |
| Grafana dashboard snapshots | Grafana database | **90 days** | Dashboard snapshots shared for incident review retained 90 days. |
| Docker container logs | Docker daemon | **7 days** | Raw container stdout/stderr. FastAPI structured logs forwarded to Prometheus; raw logs short-lived. |

---

## 6. ML Artifact Retention

| Artifact Type | Location | Retention Period | Rationale |
|---|---|---|---|
| MLflow experiment runs (metadata) | MLflow SQLite backend (`ml/experiments/`) | **Indefinite** | All experiment metadata retained for reproducibility and comparison. SQLite database is small even for thousands of runs. |
| MLflow model artifacts (serialized .joblib) | MLflow artifact store | **24 months** | Model artifacts for experiments in `Staging` or `Production` stage are retained indefinitely. Archived experiments (superseded models) are pruned after 24 months. |
| Feature engineering datasets | MinIO `gold/ml_features/` | **12 months** | Feature datasets for the most recent 12 months retained. Older datasets are reproducible by re-running the feature pipeline. |
| Model evaluation reports | `ml/evaluation/` | **24 months** | Evaluation notebooks and reports for all registered models retained 24 months. |
| Training data snapshots | MinIO `gold/ml_features/` | **12 months** | Same as feature datasets. |

---

## 7. Retention Enforcement

### 7.1 Automated Enforcement

| Component | Tool | Schedule |
|---|---|---|
| `sensor_readings` partition drop | Airflow DAG `dag_partition_archival` | Monthly on 1st at 04:00 UTC |
| `fct_sensor_reading` partition archive and drop | Airflow DAG `dag_partition_archival` | Monthly on 1st at 04:00 UTC |
| Bronze/Silver MinIO data purge | Airflow DAG `dag_data_lake_retention` | Weekly on Sunday at 05:00 UTC |
| `raw.*` landing table truncation | Airflow DAG `dag_warehouse_maintenance` | Weekly on Sunday at 03:30 UTC |
| Airflow task log cleanup | Airflow built-in log retention setting | Continuous (log_retention_days = 30) |
| Prometheus data retention | Prometheus `--storage.tsdb.retention.time=15d` flag | Continuous (rolling window) |

### 7.2 Retention Audit

A quarterly retention audit is performed by the data engineering team to verify:
1. All automated retention jobs completed successfully in the past quarter (checked via Airflow run history)
2. MinIO bucket sizes are within expected ranges (checked via MinIO console)
3. No data is being retained beyond its defined retention period
4. IATF 16949 compliance: quality inspection and maintenance records are present in the warehouse for the required 3-year window

### 7.3 Retention Policy Change Process

Any change to a retention period requires:
1. A GitHub Issue documenting the proposed change, its business or compliance rationale, and impact
2. Review against IATF 16949 requirements (minimum 3-year quality and maintenance traceability)
3. Update to this document AND the corresponding Airflow DAG configuration
4. Update to the data lake lifecycle policy in MinIO (if applicable)
5. Communication to affected stakeholders (Quality team for quality data; IT for infrastructure logs)

---

*This data retention strategy is reviewed annually and updated whenever regulatory requirements,*
*data volume projections, or business requirements change. Last reviewed: 2026-07-22.*
