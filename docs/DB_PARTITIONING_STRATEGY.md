# Partitioning Strategy — Smart Manufacturing Analytics Platform (SMAP)

**Document Version:** 1.0.0
**Last Updated:** 2026-07-22
**Status:** Approved — Complete Design Baseline
**Owner:** Lead Database Architect
**Related Documents:**
- [../DATABASE_DESIGN.md](../DATABASE_DESIGN.md)
- [DB_INDEXING_STRATEGY.md](./DB_INDEXING_STRATEGY.md)
- [DB_RETENTION_STRATEGY.md](./DB_RETENTION_STRATEGY.md)

---

## Table of Contents

1. [Partitioning Decision Framework](#1-partitioning-decision-framework)
2. [Operational Database Partitioning](#2-operational-database-partitioning)
3. [Warehouse Fact Table Partitioning](#3-warehouse-fact-table-partitioning)
4. [Partition Management](#4-partition-management)
5. [Future Partitioning Candidates](#5-future-partitioning-candidates)

---

## 1. Partitioning Decision Framework

Table partitioning is applied when **all three** of the following conditions are met:

1. **Volume:** The table is projected to exceed 50 million rows within 12 months, OR it already
   exceeds 10 million rows and shows significant query degradation without partitioning.
2. **Access Pattern:** The vast majority of queries filter on the partition key column
   (typically a timestamp or date), enabling the query planner to prune irrelevant partitions.
3. **Lifecycle:** Different time ranges have materially different access or retention requirements
   (e.g., recent data is queried frequently; data older than 1 year is rarely accessed or can be archived).

**PostgreSQL Partition Type Used:** `RANGE` partitioning on timestamp or date columns.
All partitions are created in advance for the next 3 months and archived/dropped per the retention policy.

---

## 2. Operational Database Partitioning

### 2.1 `sensor_readings` — PARTITIONED

**Partition Key:** `reading_timestamp` (TIMESTAMPTZ)
**Partition Interval:** Monthly
**Partition Naming:** `sensor_readings_YYYY_MM`

**Justification:**

| Criterion | Assessment |
|---|---|
| Volume | ~554K–1.1M rows/day → ~17–33M rows/month → ~200–400M rows/year. Far exceeds the 50M threshold. |
| Access Pattern | All ETL extraction queries filter on `reading_timestamp` via watermark. All ML feature queries filter by machine + sensor_type + timestamp range. Partition pruning eliminates irrelevant months. |
| Lifecycle | Operational DB retains 90 days rolling. Monthly partitions make DROP TABLE (for expired data) atomic and instantaneous compared to DELETE-based purges on a 400M-row unpartitioned table. |

**Partition Schedule:**
- New partitions created on the 25th of each month for the following month (via Airflow DAG `dag_partition_management`)
- Expired partitions (> 90 days old) detached and dropped after the Bronze → Silver copy is confirmed complete
- Partition map: `sensor_readings` parent table + child tables `sensor_readings_2026_01`, `sensor_readings_2026_02`, etc.

**Active Partitions (v1.0.0 baseline):** 3 partitions (current month + 2 months history) at go-live.

---

### 2.2 `material_movements` — NOT PARTITIONED (v1.0.0)

**Volume:** ~5–15 KB CSV/day → ~1,800–5,400 rows/year → well below the 50M row threshold.
**Decision:** No partitioning required. Revisit if spare parts tracking scope expands significantly.

---

### 2.3 All Other Operational Tables — NOT PARTITIONED

| Table | Max Projected Rows (Annual) | Partitioning Decision |
|---|---|---|
| `machines` | ~100 | No — static reference data |
| `production_lines` | ~15 | No — static reference data |
| `products` | ~200 | No — small catalog |
| `employees` | ~1,500 | No — small roster |
| `shifts` | ~15 | No — static reference data |
| `production_orders` | ~550K | No — well under threshold; B-tree on actual_end sufficient |
| `downtime_events` | ~1.2M | No — under threshold; composite index handles query patterns |
| `quality_inspections` | ~500K | No — under threshold |
| `defect_types` | ~100 | No — static reference |
| `maintenance_logs` | ~20K | No — very small volume |
| `pm_schedules` | ~200 | No — very small |
| `spare_parts` | ~2,000 | No — small catalog |

---

## 3. Warehouse Fact Table Partitioning

### 3.1 `fct_sensor_reading` — PARTITIONED

**Partition Key:** `reading_timestamp` (TIMESTAMPTZ)
**Partition Interval:** Monthly
**Partition Naming:** `fct_sensor_reading_YYYY_MM`

**Justification:**

| Criterion | Assessment |
|---|---|
| Volume | ~200–400M rows/year in the warehouse (2-year retention = 400M–800M total rows). Well exceeds the 50M threshold. |
| Access Pattern | Dashboard sensor trend queries always filter by a date range (last 7 days, last 30 days, custom range). ML feature engineering queries use 7-day, 14-day, and 30-day rolling windows always anchored on reading_timestamp. Partition pruning is highly effective for all these patterns. |
| Lifecycle | 2-year rolling retention. Monthly partitions allow atomic archival and deletion of expired data without table-level locks. |

**Warehouse Partition Benefit — Query Example:**

```
-- Fleet sensor trend (last 7 days): without partitioning → full scan of 400M rows
-- With monthly partitioning → scans only current month's partition (~17M rows)
-- Performance improvement: ~23x reduction in rows scanned for typical dashboard query
```

**dbt Integration:** The `fct_sensor_reading` incremental model uses `partition_by` in the dbt
model configuration to create partitions at materialization time. Each dbt run appends to the
current month's partition without scanning historical partitions.

---

### 3.2 `fct_production` — NOT PARTITIONED

**Volume:** ~500K rows/year → ~1M rows at 2-year retention. Well under the 50M threshold.
**Decision:** No partitioning. The composite B-tree index on `(date_key, machine_sk)` provides
sufficient selectivity for all dashboard queries. Partitioning overhead (partition management,
query planner complexity) is not justified at this volume.

**Review Trigger:** Revisit if production order volume exceeds 5M rows (would require a major
increase in production scope or multi-facility expansion).

---

### 3.3 `fct_quality_inspection` — NOT PARTITIONED

**Volume:** ~250–500K rows/year → ~500K–1M at 2-year retention. Under threshold.
**Decision:** No partitioning. Composite indexes on `(date_key, machine_sk)` are sufficient.

---

### 3.4 `fct_maintenance_event` — NOT PARTITIONED

**Volume:** ~5–15K rows/year → ~30K at 2-year retention. Far under any threshold.
**Decision:** No partitioning warranted.

---

## 4. Partition Management

### 4.1 New Partition Creation

New monthly partitions are created automatically by the Airflow DAG `dag_partition_management`,
which runs on the 25th of each month at 01:00 UTC. It creates partitions for:
- Operational DB: `sensor_readings_YYYY_MM+1`
- Warehouse: `fct_sensor_reading_YYYY_MM+1`

The DAG sends a Slack alert if partition creation fails.

### 4.2 Partition Archival and Deletion

| Layer | Table | Retention | Archival Action |
|---|---|---|---|
| Operational DB | `sensor_readings_YYYY_MM` | 90 days rolling | Detach partition → copy to MinIO Silver zone as Parquet → DROP PARTITION |
| Warehouse | `fct_sensor_reading_YYYY_MM` | 24 months rolling | Detach partition → copy to MinIO Gold archive zone → DROP PARTITION |

**Archival DAG:** `dag_partition_archival` runs monthly on the 1st at 04:00 UTC.
It checks for partitions older than the retention window and executes the archival workflow.

### 4.3 Partition Health Monitoring

The Grafana dashboard `SMAP Infrastructure` includes a partition health panel that displays:
- Number of active partitions per partitioned table
- Row count per partition (most recent 6 partitions)
- Estimated days until next partition creation
- Estimated days until oldest partition expires

---

## 5. Future Partitioning Candidates

As data volumes grow, the following tables should be evaluated for partitioning:

| Table | Current Status | Review Trigger | Proposed Partition Key |
|---|---|---|---|
| `fct_production` | Not partitioned | Row count exceeds 5M | `date_key` (by year or quarter) |
| `fct_quality_inspection` | Not partitioned | Row count exceeds 5M | `date_key` (by year or quarter) |
| `production_orders` | Not partitioned | Row count exceeds 10M | `actual_end` (by month) |
| `downtime_events` | Not partitioned | Row count exceeds 10M | `downtime_start` (by month) |

---

*This partitioning strategy is reviewed quarterly and updated when volume thresholds are approached.*
*Partition creation, archival, and deletion are the responsibility of the data engineering team.*
*Last reviewed: 2026-07-22.*
