# System Architecture — Smart Manufacturing Analytics Platform (SMAP)

**Document Version:** 1.0.0
**Last Updated:** 2026-07-20
**Status:** Draft — Architecture Under Design
**Owner:** Project Lead

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Design Principles](#2-design-principles)
3. [System Context Diagram](#3-system-context-diagram)
4. [High-Level Architecture Diagram](#4-high-level-architecture-diagram)
5. [Layer-by-Layer Breakdown](#5-layer-by-layer-breakdown)
6. [Data Flow Architecture](#6-data-flow-architecture)
7. [Data Lake Architecture](#7-data-lake-architecture)
8. [Data Warehouse Architecture](#8-data-warehouse-architecture)
9. [Application Architecture](#9-application-architecture)
10. [Machine Learning Architecture](#10-machine-learning-architecture)
11. [Infrastructure Architecture](#11-infrastructure-architecture)
12. [Security Architecture](#12-security-architecture)
13. [Scalability Considerations](#13-scalability-considerations)
14. [Architecture Decision Log](#14-architecture-decision-log)

---

## 1. Architecture Overview

The SMAP system follows a **layered, medallion-inspired architecture** organized around the classic data engineering progression:

```
Source Systems → Bronze (Raw) → Silver (Cleaned) → Gold (Serving) → Consumption
```

The platform is composed of five major layers:

1. **Ingestion Layer** — Brings data from source systems into the raw data lake via Airflow-orchestrated Python extractors
2. **Transformation Layer** — Cleans, validates, and models data through dbt into the analytical warehouse
3. **Serving Layer** — FastAPI REST API exposes warehouse data and ML inference to consuming applications
4. **Consumption Layer** — React dashboard, Jupyter notebooks, and scheduled reports
5. **Intelligence Layer** — scikit-learn and XGBoost ML models for prediction and anomaly detection, tracked with MLflow

Every layer communicates through a well-defined interface: file formats (Parquet), SQL schemas, or REST contracts. No layer reaches across interface boundaries.

---

## 2. Design Principles

### 2.1 Separation of Concerns

Each system layer has a clearly defined single responsibility and a formal interface. The ETL layer extracts and stores raw data — it contains no business logic. The transformation layer applies business rules — it does not interact with source systems directly. The API layer serves data — it does not contain transformation logic. Violations of layer boundaries are treated as architectural defects.

### 2.2 Loose Coupling

Components communicate through well-defined contracts: REST APIs with versioned schemas, SQL warehouse schemas with stable column names, and Parquet files with documented schemas. Replacing one component (e.g., PostgreSQL → Snowflake, MinIO → AWS S3) requires changing configuration only, not application code.

### 2.3 Idempotency

All ETL operations are idempotent — running a pipeline twice with the same parameters produces the same result as running it once. This is enforced by:
- Watermark-based incremental extraction (no double-ingestion)
- `dbt run --select` with `unique_key` on incremental models (upsert, not append)
- Parquet files written with deterministic partition paths (overwrite if re-run)

### 2.4 Data Immutability

Raw (Bronze) data is never modified after ingestion. All transformations create new datasets in downstream zones. The Bronze zone serves as an audit log of exactly what was received from each source system. Corrections are applied in the Silver or Gold transformation layers, not by modifying raw files.

### 2.5 Observability by Default

Every pipeline run, API request, and ML inference emits structured logs and Prometheus metrics. No silent failures. Key observability contracts:
- Airflow task logs are structured JSON with `dag_id`, `task_id`, `execution_date`, `record_count`, and `elapsed_ms`
- FastAPI logs every request with `method`, `path`, `status_code`, `duration_ms`, and `request_id`
- ML inference logs `model_name`, `model_version`, `input_hash`, `prediction`, and `latency_ms`

### 2.6 Schema-First Design

Database schemas, API contracts, and dbt model interfaces are defined and documented before implementation begins. Changes to schemas are versioned:
- Operational DB: Alembic migration scripts
- Warehouse: dbt model changes with documented `schema.yml` updates
- API: Pydantic response models with versioned endpoint paths

---

## 3. System Context Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                        External Actors                           │
├──────────────────────────────────────────────────────────────────┤
│  [Factory Floor Sensors]   [ERP System (Simulated)]              │
│  [Quality Control System]  [Maintenance Log (Simulated)]         │
└──────────────┬───────────────────────────────────────────────────┘
               │ Batch / Near-Real-Time Data
               ▼
┌──────────────────────────────────────────────────────────────────┐
│              Smart Manufacturing Analytics Platform               │
│                          (SMAP)                                  │
└──────────────┬────────────────────────────────┬──────────────────┘
               │                                │
               ▼                                ▼
    [Analytics Dashboard]            [REST API Consumers]
    [Jupyter Notebooks]              [External Applications]
    [Scheduled Reports]              [ML Inference Clients]
```

---

## 4. High-Level Architecture Diagram

> Architecture diagram asset will be embedded here once created in Phase 5.
> Target path: `assets/diagrams/system_architecture.png`

```
╔══════════════════════════════════════════════════════════════════╗
║                   HIGH-LEVEL ARCHITECTURE                        ║
╠════════════════╦═════════════════╦═══════════════╦══════════════╣
║  SOURCE LAYER  ║ INGESTION LAYER ║ STORAGE LAYER ║ SERVING LAYER║
║                ║                 ║               ║              ║
║  PostgreSQL    ║  Python ETL     ║ MinIO (Raw)   ║  FastAPI     ║
║  (Simulated    ║  Extractors     ║ PostgreSQL    ║  REST API    ║
║  Source DB)    ║                 ║ (Warehouse)   ║              ║
║                ║  Apache Airflow ║               ║  React       ║
║  CSV/JSON      ║  (Orchestration)║ dbt Models    ║  Dashboard   ║
║  Flat Files    ║                 ║ (Transform)   ║              ║
╠════════════════╩═════════════════╩═══════════════╩══════════════╣
║                      INTELLIGENCE LAYER                          ║
║  scikit-learn Models │ XGBoost │ MLflow Tracking │ Model Serving ║
╠══════════════════════════════════════════════════════════════════╣
║                    INFRASTRUCTURE LAYER                          ║
║  Docker Compose │ GitHub Actions CI/CD │ Grafana │ Prometheus    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 5. Layer-by-Layer Breakdown

### 5.1 Source Layer

The source layer simulates the transactional systems present in a real manufacturing environment. In v1.0.0, all source data is synthetically generated with realistic statistical distributions; no live physical integration is performed.

| Source | Type | Data Domain | Update Frequency |
|---|---|---|---|
| Sensor Database | PostgreSQL table (`sensor_readings`) | Machine telemetry — temperature, vibration, pressure, RPM | Simulated continuous; extracted every 15 minutes |
| Production Log | PostgreSQL table (`production_orders`) | Production orders, shift assignments, unit counts, cycle times | Hourly batch |
| Quality Records | PostgreSQL table (`quality_inspections`) | Inspection results, defect classifications, measurement values | Every 4 hours |
| Maintenance Log | CSV flat files | Work orders, downtime events, part replacements, technician notes | Daily batch at 02:00 UTC |

### 5.2 Ingestion Layer

The ingestion layer is responsible for extracting data from source systems and landing it in the data lake. It contains no transformation or business logic.

- **Extraction Pattern:** Watermark-based incremental extraction using the maximum `updated_at` or `reading_timestamp` from the previous successful run. Stored in Airflow Variables. Full refresh is supported via a `full_refresh` parameter.
- **Output Format:** Parquet (Snappy-compressed), partitioned by `source/year=YYYY/month=MM/day=DD/`, written to the MinIO Bronze zone.
- **Error Handling:** Extraction failures retry 3 times with exponential backoff. Failed batches are written to a dead-letter path (`bronze/dead-letter/<source>/<timestamp>/`) for manual inspection. The watermark is not advanced on failure — the next run re-attempts the same window.
- **Schema Validation:** Raw Parquet files are validated against a Great Expectations expectation suite immediately after ingestion. Records failing validation are quarantined in `bronze/quarantine/` and do not advance to Silver.

### 5.3 Storage Layer

The storage layer is organized into three zones following the medallion architecture pattern:

| Zone | Location | Contents | Access Pattern |
|---|---|---|---|
| **Bronze (Raw)** | MinIO: `smap-data-lake/bronze/` | Unmodified raw data exactly as received; immutable | ETL pipelines only; no direct queries |
| **Silver (Cleaned)** | MinIO: `smap-data-lake/silver/` | Schema-normalized, null-handled, validated data | ETL pipelines and ad-hoc notebook analysis |
| **Gold (Serving)** | PostgreSQL Warehouse (`marts` schema) | Fully modeled star schema; dbt-managed | REST API, Jupyter notebooks, dashboards |

The MinIO (Bronze and Silver) layer uses Parquet for all data. The PostgreSQL warehouse (Gold) uses relational tables with indexed access patterns optimized for the API's query patterns.

### 5.4 Transformation Layer

The transformation layer converts raw source data into governed, business-aligned analytical models using dbt Core. It is the only layer that contains business logic — OEE calculation, MTBF/MTTR derivation, defect rate computation.

dbt model layering:

| Layer | Prefix | Materialization | Responsibility |
|---|---|---|---|
| Sources | `src_` (in `sources.yml`) | External reference | Declare raw source tables; define freshness expectations |
| Staging | `stg_` | View | 1:1 with source tables; light cleaning, column renaming, type casting only |
| Intermediate | `int_` | Ephemeral | Business logic joins, multi-source aggregations, derived metric calculations |
| Marts — Facts | `fct_` | Incremental table | Final denormalized fact tables; append-only with upsert on surrogate key |
| Marts — Dimensions | `dim_` | Full refresh table | Slowly changing reference data; full replace on each dbt run |

dbt runs are triggered by the Airflow DAG `dag_dbt_refresh` after each domain's ETL pipeline completes, and once as a full-refresh on the weekly Sunday maintenance window.

### 5.5 Serving Layer

The serving layer exposes the data warehouse through a typed, versioned REST API. It is the exclusive interface between the data layer and all consuming applications — no consumer queries the warehouse directly in production.

Key design decisions for the serving layer:
- **Single responsibility:** The API reads from the warehouse and serves responses; it does not write to the warehouse, trigger ETL, or contain transformation logic.
- **Caching:** Frequently requested aggregations (e.g., `/kpis/dashboard-summary`) are cached in-process with a configurable TTL (default: 60 seconds) using FastAPI's dependency injection pattern. Redis caching is the planned upgrade path.
- **Response Time Targets:** All non-ML endpoints: p95 < 200 ms. ML inference endpoints: p95 < 1,000 ms.
- **Pagination:** All list endpoints support offset-based pagination with a default page size of 50 and a maximum of 500 records per request.

### 5.6 Consumption Layer

Three consumption patterns are supported in v1.0.0:

| Consumer | Interface | Use Case |
|---|---|---|
| **React Dashboard** | REST API (`/api/v1/`) | Operational monitoring — OEE, Production, Quality, Maintenance views |
| **Jupyter Notebooks** | Direct PostgreSQL connection to warehouse (`marts` schema) | Exploratory analysis, model development, ad-hoc reporting |
| **Scheduled Reports** | Airflow DAG (`dag_reporting`) triggering Python scripts | PDF/HTML report generation for historical KPI summaries |

All direct notebook connections to the warehouse are read-only, enforced by a dedicated read-only PostgreSQL user (`smap_analyst`).

---

## 6. Data Flow Architecture

### 6.1 Batch ETL Flow

```
[Source DB (PostgreSQL :5432)]
    │
    │  watermark-based incremental extract (Python extractor)
    ▼
[MinIO Bronze Zone]  ─── raw Parquet files, partitioned by date
    │
    │  Great Expectations validation
    ├── (fail) → MinIO Quarantine Zone + alert
    │
    │  (pass) → load to staging tables (Python loader)
    ▼
[PostgreSQL Staging (warehouse :5433, schema: staging)]
    │
    │  dbt run (staging → intermediate → marts)
    ▼
[PostgreSQL Warehouse (warehouse :5433, schema: marts)]
    │
    │  FastAPI REST API
    ▼
[React Dashboard]  │  [Jupyter Notebooks]  │  [External Consumers]
```

### 6.2 Pipeline Scheduling

| DAG | Schedule | Source | Target |
|---|---|---|---|
| `dag_sensor_etl` | Every 15 minutes | `sensor_readings` (source DB) | MinIO Bronze → staging |
| `dag_production_etl` | Every 1 hour | `production_orders` (source DB) | MinIO Bronze → staging |
| `dag_quality_etl` | Every 4 hours | `quality_inspections` (source DB) | MinIO Bronze → staging |
| `dag_maintenance_etl` | Daily at 02:00 UTC | CSV flat files → `maintenance_logs` (source DB) | MinIO Bronze → staging |
| `dag_dbt_refresh` | Triggered after each ETL DAG | Staging schema | Marts schema (incremental) |
| `dag_dbt_full_refresh` | Weekly — Sunday 03:00 UTC | Staging schema | Marts schema (full rebuild) |

---

## 7. Data Lake Architecture

### 7.1 Bucket Structure (MinIO / S3-compatible)

```
smap-data-lake/
├── bronze/                     # Raw, unmodified data (immutable after write)
│   ├── sensors/
│   │   └── year=2026/month=07/day=20/sensors_20260720_143000.parquet
│   ├── production/
│   │   └── year=2026/month=07/day=20/
│   ├── quality/
│   │   └── year=2026/month=07/day=20/
│   └── maintenance/
│       └── year=2026/month=07/day=20/
├── silver/                     # Cleaned, schema-validated data
│   ├── sensors/
│   ├── production/
│   ├── quality/
│   └── maintenance/
├── gold/                       # Aggregated and analytics-ready exports
│   ├── oee/
│   ├── kpis/
│   └── ml_features/
├── quarantine/                 # Records failing Great Expectations validation
│   └── sensors/year=2026/...
└── dead-letter/                # Extraction failures for manual retry
    └── sensors/year=2026/...
```

### 7.2 File Format Strategy

| Zone | Format | Compression | Rationale |
|---|---|---|---|
| Bronze | Parquet | Snappy | Columnar, preserves schema, efficient for downstream reads; Snappy is fast with good compression |
| Silver | Parquet | Snappy | Same benefits; enables efficient predicate pushdown in notebook analysis |
| Gold | Parquet / JSON | Snappy / None | Parquet for analytical exports; JSON for small API-bound payloads |
| Quarantine / Dead-letter | Parquet | Snappy | Preserves original schema for diagnosis and replay |

---

## 8. Data Warehouse Architecture

### 8.1 Dimensional Model Overview

The warehouse follows a **star schema** with four fact tables and six dimension tables. See [DATABASE_DESIGN.md](./DATABASE_DESIGN.md) for full column definitions, data types, and indexing strategy.

#### Fact Tables

| Table | Grain | Key Measures |
|---|---|---|
| `fct_production` | One row per completed production order | `planned_units`, `actual_units`, `good_units`, `scrap_units`, `oee_availability`, `oee_performance`, `oee_quality`, `oee_overall` |
| `fct_quality_inspection` | One row per quality inspection event | `sample_size`, `defects_found`, `defect_rate_pct`, `pass_fail`, `measurement_value` |
| `fct_sensor_reading` | One row per sensor reading event (high-volume) | `sensor_type`, `value`, `is_anomaly_flagged`, `data_quality_score` |
| `fct_maintenance_event` | One row per maintenance work order | `event_type`, `failure_code`, `downtime_minutes`, `repair_cost`, `mttr_minutes` |

#### Dimension Tables

| Table | Description | Update Strategy |
|---|---|---|
| `dim_machine` | Machine attributes, production line, plant | SCD Type 1 (full refresh) |
| `dim_product` | Product/SKU hierarchy (product → family → category) | SCD Type 1 (full refresh) |
| `dim_shift` | Shift schedule and time boundaries | Static — seeded via dbt seed |
| `dim_defect_type` | Defect classification hierarchy for Pareto analysis | SCD Type 1 (full refresh) |
| `dim_employee` | Operator and technician reference data | SCD Type 1 (full refresh) |
| `dim_date` | Full calendar and fiscal date attributes | Static — seeded via dbt seed; covers 2020–2030 |

---

## 9. Application Architecture

### 9.1 Backend API Structure

```
backend/
├── main.py                  # FastAPI application factory, middleware registration
├── api/
│   └── v1/
│       ├── routers/
│       │   ├── health.py        # GET /health
│       │   ├── production.py    # GET /production/*
│       │   ├── quality.py       # GET /quality/*
│       │   ├── maintenance.py   # GET /maintenance/*
│       │   ├── kpis.py          # GET /kpis/*
│       │   ├── sensors.py       # GET /sensors/*
│       │   └── ml.py            # POST /ml/*
│       └── dependencies.py      # Shared: DB session, API key verification
├── models/                  # SQLAlchemy ORM table definitions
├── schemas/                 # Pydantic request/response models
├── services/                # Business logic — one service class per domain
├── repositories/            # Data access layer — SQL queries via SQLAlchemy
└── config/                  # pydantic-settings configuration
```

**Request Lifecycle:**

```
HTTP Request
    → FastAPI Router (route matching, path param extraction)
    → Dependencies (DB session injection, API key validation)
    → Service Layer (business logic, orchestration)
    → Repository Layer (SQLAlchemy query construction and execution)
    → Pydantic Response Model (serialization and validation)
    → HTTP Response (JSON)
```

The service layer contains all business logic. Repositories contain only SQL query construction — no business logic. This separation ensures the service layer is fully unit-testable without database access.

### 9.2 Frontend Architecture

```
frontend/src/
├── features/
│   ├── oee/                 # OEE dashboard components, hooks, types
│   ├── production/          # Production dashboard
│   ├── quality/             # Quality dashboard
│   └── maintenance/         # Maintenance dashboard
├── components/
│   ├── charts/              # Reusable chart wrappers (LineChart, BarChart, Gauge)
│   ├── layout/              # AppShell, Sidebar, Header, PageContainer
│   └── common/              # Buttons, Cards, Badges, LoadingSpinner
├── hooks/
│   ├── useApiQuery.ts       # Base hook wrapping React Query with API key header
│   └── useFilters.ts        # Shared date range and filter state hook
├── api/
│   └── client.ts            # Axios instance with base URL and default headers
├── types/
│   └── api.ts               # TypeScript types mirroring API response schemas
└── config/
    └── constants.ts         # API base URL, default date ranges, color palette
```

**Data Fetching Pattern:** Each feature uses a domain-specific hook (e.g., `useOEEData(dateRange, machineId)`) that calls `useApiQuery` internally. React Query manages caching with a 30-second stale time for dashboard data, preventing redundant API calls when users navigate between views.

---

## 10. Machine Learning Architecture

### 10.1 Model Inventory

| Model | Algorithm | Input Features | Output | Serving Method |
|---|---|---|---|---|
| Predictive Maintenance | XGBoost Classifier | Rolling window sensor aggregates (7d, 14d, 30d), days since last maintenance, historical failure rate, vibration trend slope | Failure probability (0.0–1.0) + risk level (LOW/MEDIUM/HIGH) | REST endpoint: `POST /ml/predict/maintenance` |
| Anomaly Detection | Isolation Forest | Multivariate sensor readings (temperature, vibration, pressure, RPM) for the preceding 24 hours | Anomaly score (−1.0 to 1.0) + binary flag | REST endpoint: `POST /ml/detect/anomaly` |
| Quality Prediction | XGBoost Regressor | Process parameter values (machine speed, temperature, pressure, shift) + historical defect rate (7d) | Predicted defect rate (%) + confidence interval | REST endpoint: `POST /ml/predict/quality` |

### 10.2 ML Pipeline Flow

```
[Raw Sensor & Operational Data]
    │
    │  feature_engineering/ pipeline
    ▼
[Feature DataFrame (pandas)]
    │
    ├── Training Path:
    │       │  ml/training/<model>.py
    │       ▼
    │   [MLflow Experiment Run]
    │       │  log params, metrics, artifacts
    │       ▼
    │   [MLflow Model Registry]
    │       │  Staging → (evaluation) → Production
    │       ▼
    │   [Serialized Model Artifact]  (.joblib / .pkl)
    │
    └── Inference Path:
            │  FastAPI startup: load Production model from MLflow artifact store
            ▼
        [FastAPI Inference Endpoint]
            │  Pydantic input validation → feature construction → model.predict()
            ▼
        [Structured Prediction Response]
```

---

## 11. Infrastructure Architecture

### 11.1 Docker Services Map

| Service | Image | Port(s) | Role | Health Check |
|---|---|---|---|---|
| `postgres_source` | `postgres:15-alpine` | 5432 | Operational source database | `pg_isready` |
| `postgres_warehouse` | `postgres:15-alpine` | 5433 | Data warehouse | `pg_isready` |
| `minio` | `minio/minio` | 9000, 9001 | Object storage (S3-compatible) | HTTP GET /minio/health/live |
| `airflow-webserver` | `apache/airflow:2.7` | 8080 | DAG management UI | HTTP GET /health |
| `airflow-scheduler` | `apache/airflow:2.7` | — | DAG scheduling engine | `airflow jobs check` |
| `backend` | Custom Dockerfile | 8000 | FastAPI REST API | HTTP GET /health |
| `frontend` | Custom Dockerfile | 3000 | React dashboard | HTTP GET / |
| `mlflow` | Custom Dockerfile | 5000 | MLflow tracking and model registry | HTTP GET /health |
| `prometheus` | `prom/prometheus:latest` | 9090 | Metrics collection | HTTP GET /-/healthy |
| `grafana` | `grafana/grafana:latest` | 3001 | Infrastructure monitoring dashboards | HTTP GET /api/health |

All services communicate via a dedicated Docker bridge network (`smap-network`). Services reference each other by Docker Compose service name (e.g., `backend` connects to PostgreSQL at `postgres_warehouse:5432`).

**Startup Order (depends_on):**
1. `postgres_source`, `postgres_warehouse`, `minio` (infrastructure)
2. `airflow-webserver`, `airflow-scheduler`, `mlflow` (platform services — depend on databases)
3. `backend` (depends on `postgres_warehouse`, `mlflow`)
4. `frontend` (depends on `backend`)
5. `prometheus`, `grafana` (monitoring — depend on all services being reachable)

---

## 12. Security Architecture

### 12.1 Authentication & Authorization

SMAP v1.0.0 implements a simple, transparent security model appropriate for a portfolio demo:

| Control | Implementation |
|---|---|
| API Authentication | `X-API-Key` header validated by FastAPI middleware on all routes except `/health` |
| API Key Storage | Stored in `.env` file; loaded via `pydantic-settings`; never committed to git |
| Database Credentials | All connection strings stored as environment variables; injected via Docker Compose `env_file` |
| Cross-Origin | CORS configured in FastAPI to allow only the React frontend origin (`http://localhost:3000`) |
| Secret Management | `.env.example` provided with all required keys and placeholder values; `.env` is in `.gitignore` |

**Security rules enforced in CI:**
- `ruff` rule `S105` (hardcoded passwords) runs on every PR
- `git-secrets` or `trufflehog` scan runs in the CI pipeline to detect accidentally committed secrets

### 12.2 Data Security

| Control | Implementation |
|---|---|
| No PII in datasets | All synthetic data uses fictional machine IDs, operator codes, and product codes — no real personal information |
| Read-only analyst access | Jupyter notebooks connect to the warehouse via a read-only PostgreSQL user (`smap_analyst`) |
| Container network isolation | Services are on an isolated Docker network; only explicitly mapped ports are accessible from the host |
| No secrets in Docker images | Docker images contain no credentials; all secrets are injected at runtime via environment variables |

---

## 13. Scalability Considerations

The v1.0.0 architecture is designed for a single-node local deployment, but every component is selected and configured with a documented cloud migration path.

| Layer | v1.0.0 (Local) | Scale Path | Migration Effort |
|---|---|---|---|
| Orchestration | Airflow LocalExecutor (single process) | CeleryExecutor (Redis broker) → AWS MWAA or GCP Composer | Low — configuration change only |
| Ingestion | Python extractors in Airflow tasks | Add Kafka producers for real-time ingestion; use Flink for stream processing | Medium — new streaming layer |
| Object Storage | MinIO (local Docker) | AWS S3 (change endpoint URL and credentials only) | Very Low — S3-compatible API |
| Warehouse | PostgreSQL 15 (single node) | Snowflake or BigQuery (schema already compatible) | Low — dbt adapter change + data migration |
| API | Single Uvicorn process | Multiple Uvicorn workers behind nginx; add Redis for response caching | Low — stateless API scales horizontally |
| ML Inference | Models loaded in-process on API startup | Dedicated model serving (Triton, MLflow serving, or separate FastAPI worker) | Medium — requires decoupling |
| Frontend | React dev server (Vite) | Static build deployed to CDN (CloudFront, Netlify, Vercel) | Very Low — standard React build |
| Monitoring | Prometheus + Grafana (local) | Same stack in cloud or managed alternatives (Datadog, CloudWatch) | Low — exporters already in place |

---

## 14. Architecture Decision Log

| ADR # | Title | Decision | Date | Status |
|---|---|---|---|---|
| ADR-001 | Warehouse Technology | Use PostgreSQL locally with a Snowflake-compatible star schema; defer cloud migration | 2026-07-20 | Accepted |
| ADR-002 | Orchestration | Apache Airflow over Prefect/Dagster for broader enterprise recognition | 2026-07-20 | Accepted |
| ADR-003 | API Framework | FastAPI over Flask/Django for async support, Pydantic validation, and auto-docs | 2026-07-20 | Accepted |
| ADR-004 | Object Storage | MinIO for local S3-compatible storage; zero-cost migration path to AWS S3 | 2026-07-20 | Accepted |
| ADR-005 | ML Tracking | MLflow for experiment tracking and model registry | 2026-07-20 | Accepted |
| ADR-006 | Transformation | dbt Core for all warehouse transformations; SQL-native, version-controlled | 2026-07-20 | Accepted |

Full ADR documents (with context, options considered, and decision rationale) will be created in `docs/adr/` during Phase 5. See [TECH_STACK.md §13](./TECH_STACK.md) for rationale summaries.

---

*This document is a living specification. It is updated whenever architectural decisions change, new components are added, or interface contracts are modified. All changes are recorded in `CHANGELOG.md`.*
