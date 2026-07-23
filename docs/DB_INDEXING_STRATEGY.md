# Indexing Strategy — Smart Manufacturing Analytics Platform (SMAP)

**Document Version:** 1.0.0
**Last Updated:** 2026-07-22
**Status:** Approved — Complete Design Baseline
**Owner:** Lead Database Architect
**Related Documents:**
- [../DATABASE_DESIGN.md](../DATABASE_DESIGN.md)
- [DB_PARTITIONING_STRATEGY.md](./DB_PARTITIONING_STRATEGY.md)

---

## Table of Contents

1. [Overview and Principles](#1-overview-and-principles)
2. [Operational Database Indexes](#2-operational-database-indexes)
3. [Warehouse Dimension Indexes](#3-warehouse-dimension-indexes)
4. [Warehouse Fact Table Indexes](#4-warehouse-fact-table-indexes)
5. [Index Maintenance](#5-index-maintenance)
6. [Performance Considerations](#6-performance-considerations)

---

## 1. Overview and Principles

### 1.1 Indexing Philosophy

SMAP follows a **selective indexing** philosophy: indexes are added only where they provide a
measurable query improvement, and avoided where they would create unnecessary write overhead.
The system has two distinct write patterns that inform index design:

| Layer | Write Pattern | Index Priority |
|---|---|---|
| Operational DB | Frequent transactional writes (sensor readings: 18K/min) | Minimize write-overhead indexes; index selectively |
| Warehouse Dimension tables | Infrequent full-refresh writes | Full indexing acceptable |
| Warehouse Fact tables | Batch incremental writes (ETL pipeline runs) | Index query-critical columns; avoid over-indexing high-volume tables |

### 1.2 Index Type Selection

| Index Type | When Used |
|---|---|
| B-tree | Equality lookups, range queries, ORDER BY on most data types — the default for FK columns and date range filters |
| BRIN (Block Range Index) | Append-only, physically ordered time-series data (sensor_readings, material_movements) — tiny size, fast range scans |
| Hash | Pure equality lookups on high-cardinality columns where range queries are not needed (not yet used in v1.0.0) |
| Partial | Indexes filtered to a subset of rows (e.g., only active records, only failed inspections) — reduces index size |

### 1.3 Naming Convention

All indexes follow the pattern: `idx_{table_name}_{column(s)}`

For composite indexes: `idx_{table}_{col1}_{col2}` (columns listed in selectivity order, most selective first)

For partial indexes: `idx_{table}_{column}_partial` with a comment describing the WHERE clause

---

## 2. Operational Database Indexes

### 2.1 `machines`

| Index Name | Type | Column(s) | Rationale |
|---|---|---|---|
| Primary key | B-tree | `machine_id` | Auto-created by PK constraint |
| `idx_machines_line_code` | B-tree | `line_code` | ETL and API queries filter by production line |
| `idx_machines_plant_code` | B-tree | `plant_code` | Multi-facility queries filter by plant |
| `idx_machines_scada_tag` | B-tree | `scada_tag_name` | ETL SCADA-to-machine-ID resolution lookups |
| `idx_machines_asset_tag` | B-tree | `asset_tag_number` | ETL CMMS-to-machine-ID resolution lookups |

### 2.2 `production_orders`

| Index Name | Type | Column(s) | Rationale |
|---|---|---|---|
| Primary key | B-tree | `order_id` | Auto-created by PK constraint |
| `idx_prod_orders_machine_id` | B-tree | `machine_id` | FK lookup; frequent join from downtime_events and quality_inspections |
| `idx_prod_orders_product_code` | B-tree | `product_code` | FK lookup; product-level reporting queries |
| `idx_prod_orders_actual_end` | B-tree | `actual_end` | Watermark-based incremental ETL extraction |
| `idx_prod_orders_status` | B-tree (partial) | `status` WHERE status = 'In Progress' | Efficiently find active orders; small subset of all rows |
| `idx_prod_orders_machine_shift` | B-tree | `(machine_id, shift_code)` | Shift-level OEE queries by machine |

### 2.3 `downtime_events`

| Index Name | Type | Column(s) | Rationale |
|---|---|---|---|
| Primary key | B-tree | `event_id` | Auto-created by PK constraint |
| `idx_downtime_machine_start` | B-tree | `(machine_id, downtime_start)` | MTBF calculation: find all unplanned events per machine in time order |
| `idx_downtime_order_id` | B-tree | `order_id` | FK join from production orders for OEE Availability calculation |
| `idx_downtime_start` | B-tree | `downtime_start` | Watermark-based ETL extraction |
| `idx_downtime_unplanned` | B-tree (partial) | `machine_id` WHERE is_planned = FALSE | MTBF/MTTR queries on unplanned events only — reduces index size by ~60% |

### 2.4 `sensor_readings`

The highest-volume table. Indexes are carefully chosen to balance ETL write throughput and read performance.

| Index Name | Type | Column(s) | Rationale |
|---|---|---|---|
| Primary key | B-tree | `reading_id` | Auto-created by PK constraint (BIGSERIAL) |
| `idx_sensor_timestamp_brin` | **BRIN** | `reading_timestamp` | Append-only, time-ordered data; BRIN is orders of magnitude smaller than B-tree with near-equivalent range-scan performance for this access pattern. Supports ETL watermark extraction. |
| `idx_sensor_machine_type_ts` | B-tree | `(machine_id, sensor_type, reading_timestamp)` | Primary ML feature engineering query: fetch all readings of a specific type for a specific machine in a time window. Composite order chosen for high-cardinality machine_id first. |

> **Note:** No index on `value` column alone. ML queries always filter by `(machine_id, sensor_type)` first, making a standalone value index unnecessary. If value-range queries become common, a partial index on anomaly-flagged rows will be considered.

### 2.5 `quality_inspections`

| Index Name | Type | Column(s) | Rationale |
|---|---|---|---|
| Primary key | B-tree | `inspection_id` | Auto-created by PK constraint |
| `idx_quality_order_id` | B-tree | `order_id` | FK join from production orders |
| `idx_quality_machine_id` | B-tree | `machine_id` | Machine-level defect rate reporting |
| `idx_quality_timestamp` | B-tree | `inspection_timestamp` | Watermark-based ETL extraction |
| `idx_quality_failed` | B-tree (partial) | `(machine_id, inspection_timestamp)` WHERE pass_fail = 'F' | Defect rate dashboard queries — only failed inspections subset |

### 2.6 `maintenance_logs`

| Index Name | Type | Column(s) | Rationale |
|---|---|---|---|
| Primary key | B-tree | `work_order_id` | Auto-created by PK constraint |
| `idx_maintenance_machine_id` | B-tree | `machine_id` | FK join; machine-level MTTR/MTBF reporting |
| `idx_maintenance_start` | B-tree | `downtime_start` | Watermark-based ETL extraction; chronological MTBF analysis |
| `idx_maintenance_unplanned` | B-tree (partial) | `(machine_id, downtime_start)` WHERE event_type IN ('Unplanned', 'Emergency') | MTBF calculation: only failure events per machine in time order |

### 2.7 `material_movements`

| Index Name | Type | Column(s) | Rationale |
|---|---|---|---|
| Primary key | B-tree | `movement_id` | Auto-created by PK (BIGSERIAL) |
| `idx_movements_ts_brin` | **BRIN** | `movement_date` | Append-only transaction log; date-range queries for cost reporting |
| `idx_movements_work_order` | B-tree | `work_order_id` | Join to maintenance_logs for per-work-order parts cost calculation |
| `idx_movements_part_code` | B-tree | `part_code` | FK join; parts consumption reporting per spare part |

---

## 3. Warehouse Dimension Indexes

Dimension tables are small (< 10K rows each) and refreshed infrequently. B-tree indexes on
natural keys are the primary requirement for ETL surrogate key lookup queries.

| Table | Index Name | Type | Column(s) | Rationale |
|---|---|---|---|---|
| `dim_date` | PK | B-tree | `date_key` | Auto-created by PK |
| `dim_date` | `idx_dim_date_full_date` | B-tree | `full_date` | Convert calendar date to date_key for ETL fact loading |
| `dim_machine` | PK | B-tree | `machine_sk` | Auto-created by PK |
| `dim_machine` | `idx_dim_machine_id` | B-tree | `machine_id` | Natural key lookup for ETL surrogate key resolution |
| `dim_machine` | `idx_dim_machine_plant` | B-tree | `plant_code` | Filter by plant for multi-facility dashboards |
| `dim_product` | PK | B-tree | `product_sk` | Auto-created by PK |
| `dim_product` | `idx_dim_product_code` | B-tree | `product_code` | Natural key lookup |
| `dim_employee` | PK | B-tree | `employee_sk` | Auto-created by PK |
| `dim_employee` | `idx_dim_employee_id` | B-tree | `employee_id` | Natural key lookup |
| `dim_shift` | PK | B-tree | `shift_sk` | Auto-created by PK |
| `dim_shift` | `idx_dim_shift_code` | B-tree | `shift_code` | Natural key lookup |
| `dim_defect_type` | PK | B-tree | `defect_type_sk` | Auto-created by PK |
| `dim_defect_type` | `idx_dim_defect_code` | B-tree | `defect_type_code` | Natural key lookup |
| `dim_failure_code` | PK | B-tree | `failure_code_sk` | Auto-created by PK |
| `dim_failure_code` | `idx_dim_failure_code` | B-tree | `failure_code` | Natural key lookup |

---

## 4. Warehouse Fact Table Indexes

Fact tables are large and receive batch writes during ETL. Indexes focus on the primary
query patterns from the API endpoints and dashboard queries.

### 4.1 `fct_production`

**Primary API queries:** OEE by machine and date range, production summary by shift and date, throughput trend

| Index Name | Type | Column(s) | Rationale |
|---|---|---|---|
| PK | B-tree | `production_sk` | Auto-created |
| `idx_fct_prod_date_machine` | B-tree | `(date_key, machine_sk)` | OEE trend queries: filter by date range, group by machine. Date first because date ranges are the most common dashboard filter. |
| `idx_fct_prod_machine_date` | B-tree | `(machine_sk, date_key)` | Machine-specific OEE history: filter by machine, order by date |
| `idx_fct_prod_product` | B-tree | `product_sk` | Product-level throughput and yield analysis |
| `idx_fct_prod_shift` | B-tree | `shift_sk` | Shift comparison queries (Day vs. Night OEE) |
| `idx_fct_prod_order_id` | B-tree | `order_id` | Degenerate dimension lookup for drill-through queries |

### 4.2 `fct_quality_inspection`

**Primary API queries:** Defect rate trend by machine and date, Pareto analysis by defect type

| Index Name | Type | Column(s) | Rationale |
|---|---|---|---|
| PK | B-tree | `inspection_sk` | Auto-created |
| `idx_fct_quality_date_machine` | B-tree | `(date_key, machine_sk)` | Defect rate trend queries filtered by date and machine |
| `idx_fct_quality_defect_type` | B-tree | `defect_type_sk` | Pareto analysis grouping by defect type |
| `idx_fct_quality_product` | B-tree | `product_sk` | Product-level quality analysis |
| `idx_fct_quality_fail` | B-tree (partial) | `(date_key, machine_sk)` WHERE pass_fail = 'F' | Failed inspection queries — the most common dashboard filter. Partial index reduces size by ~80%. |

### 4.3 `fct_sensor_reading`

**Highest-volume table — partitioned by month.** Indexes operate per-partition.

| Index Name | Type | Column(s) | Rationale |
|---|---|---|---|
| PK | B-tree | `sensor_sk` | Auto-created; per-partition |
| `idx_fct_sensor_machine_type_ts` | B-tree | `(machine_sk, sensor_type, reading_timestamp)` | Primary ML feature query: "give me all temperature readings for machine X in the last 7 days" |
| `idx_fct_sensor_timestamp_brin` | **BRIN** | `reading_timestamp` | Per-partition BRIN for cross-machine time range scans by the anomaly detection pipeline |
| `idx_fct_sensor_anomaly` | B-tree (partial) | `(machine_sk, reading_timestamp)` WHERE is_anomaly_flagged = TRUE | Anomaly investigation queries — tiny subset of all rows |

### 4.4 `fct_maintenance_event`

**Primary API queries:** MTTR trend by machine and date, planned vs. unplanned ratio, downtime Pareto

| Index Name | Type | Column(s) | Rationale |
|---|---|---|---|
| PK | B-tree | `maintenance_sk` | Auto-created |
| `idx_fct_maint_machine_date` | B-tree | `(machine_sk, date_key)` | Machine-level MTTR/MTBF time series |
| `idx_fct_maint_date` | B-tree | `date_key` | Fleet-level maintenance summary by date period |
| `idx_fct_maint_failure_code` | B-tree | `failure_code_sk` | Pareto analysis by failure category |
| `idx_fct_maint_unplanned` | B-tree (partial) | `(machine_sk, date_key)` WHERE is_planned = FALSE | MTBF/MTTR queries — unplanned events only (~40% of all events) |

---

## 5. Index Maintenance

### 5.1 Bloat Monitoring

Append-heavy tables (sensor_readings, material_movements, fct_sensor_reading) accumulate
index bloat over time. PostgreSQL's autovacuum handles most cases, but the following
monitoring query should run weekly via the `dag_reporting` Airflow DAG:

```sql
-- Check index bloat (informational — no SQL executed in v1.0.0)
-- Target: index bloat < 30% before manual REINDEX is triggered
SELECT schemaname, tablename, indexname, pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
ORDER BY pg_relation_size(indexrelid) DESC;
```

### 5.2 REINDEX Schedule

| Trigger | Action |
|---|---|
| Index bloat > 30% on a critical query index | REINDEX CONCURRENTLY on the affected index (zero downtime) |
| Monthly maintenance window (Sunday 03:00 UTC) | ANALYZE on all fact tables to refresh planner statistics |
| After a `dbt run --full-refresh` on any dimension | ANALYZE on the dimension table |

### 5.3 New Index Policy

Any new index added to a production table must:
1. Be tested on the local development database using `EXPLAIN ANALYZE` to confirm query plan improvement.
2. Be added as a `CONCURRENTLY` index to avoid table-level locks.
3. Be documented in this file with rationale before deployment.
4. Pass `pg_stat_user_indexes` monitoring after 7 days to confirm it is being used (scans > 0).

---

## 6. Performance Considerations

### 6.1 `sensor_readings` Write Performance

The `sensor_readings` table receives ~18K inserts/minute at peak production. Write performance
is maintained by:
- Using BRIN instead of B-tree for the timestamp index (BRIN has ~1% of the maintenance overhead)
- Batching ETL inserts in chunks of 10,000 rows using `COPY` rather than row-by-row `INSERT`
- The `(machine_id, sensor_type, reading_timestamp)` composite index is B-tree because ML queries
  require precise equality + range lookups — BRIN is too coarse for the specific machine/type combination

### 6.2 `fct_sensor_reading` Partition Pruning

With monthly partitioning, the query planner prunes irrelevant partitions automatically when
`reading_timestamp` is used in a WHERE clause. All dashboard and ML queries that include a
date filter will benefit from partition pruning, scanning only the relevant month's partition(s)
instead of the full 400M-row table.

### 6.3 Date Key vs. Timestamp Filtering

The warehouse fact tables use `date_key INTEGER` (YYYYMMDD) for joining to `dim_date`.
For date-range filtering in the API, the query pattern is:

```sql
-- Efficient: integer range on date_key (direct B-tree scan)
WHERE date_key BETWEEN 20260701 AND 20260731

-- Less efficient: timestamp extraction (requires function evaluation)
WHERE DATE(reading_timestamp) BETWEEN '2026-07-01' AND '2026-07-31'
```

All dbt intermediate models and API repository queries use the `date_key` integer range pattern.

### 6.4 Covering Indexes

Where the API's most frequent queries fetch only a small number of columns, covering indexes
(with INCLUDE) will be evaluated in v1.1.0 to avoid heap fetches. The highest-priority
candidate is `fct_production` for the OEE dashboard summary endpoint.

---

*This indexing strategy is reviewed after every major data volume milestone (100M sensor rows, 500K production rows)*
*and updated whenever new query patterns are identified from slow query logs. Last reviewed: 2026-07-22.*
