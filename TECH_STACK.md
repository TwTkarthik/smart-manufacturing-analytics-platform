# Technology Stack — Smart Manufacturing Analytics Platform (SMAP)

**Document Version:** 1.0.0
**Last Updated:** 2026-07-20
**Status:** Approved
**Owner:** Project Lead

---

## Table of Contents

1. [Overview](#1-overview)
2. [Technology Selection Principles](#2-technology-selection-principles)
3. [Data Ingestion & Orchestration](#3-data-ingestion--orchestration)
4. [Storage & Data Lake](#4-storage--data-lake)
5. [Data Transformation & Warehouse](#5-data-transformation--warehouse)
6. [Backend API](#6-backend-api)
7. [Frontend & Visualization](#7-frontend--visualization)
8. [Machine Learning](#8-machine-learning)
9. [Testing](#9-testing)
10. [Infrastructure & Deployment](#10-infrastructure--deployment)
11. [Monitoring & Observability](#11-monitoring--observability)
12. [Developer Tooling](#12-developer-tooling)
13. [Architecture Decision Records (ADRs)](#13-architecture-decision-records-adrs)
14. [Technology Comparison Tables](#14-technology-comparison-tables)

---

## 1. Overview

The SMAP technology stack is selected for production-quality relevance, open-source availability, industry adoption in manufacturing and data engineering roles, and suitability for portfolio demonstration.

### Stack Summary

```
┌─────────────────────────────────────────────────────────────────────┐
│                     SMAP Technology Stack                           │
├──────────────────────┬──────────────────────────────────────────────┤
│ Layer                │ Technology                                   │
├──────────────────────┼──────────────────────────────────────────────┤
│ Orchestration        │ Apache Airflow 2.7+                          │
│ Ingestion            │ Python (pandas, SQLAlchemy, custom)          │
│ Streaming (Future)   │ Apache Kafka                                 │
│ Operational DB       │ PostgreSQL 15                                │
│ Object Storage       │ MinIO (S3-compatible)                        │
│ Transformation       │ dbt Core 1.7+                                │
│ Warehouse            │ PostgreSQL 15 (Snowflake-compatible schema)  │
│ API                  │ FastAPI + Uvicorn                            │
│ Frontend             │ React 18 + Chart.js / Recharts               │
│ ML Framework         │ scikit-learn, XGBoost, Prophet               │
│ ML Tracking          │ MLflow 2.x                                   │
│ Containerization     │ Docker 24+ + Docker Compose v2               │
│ CI/CD                │ GitHub Actions                               │
│ Monitoring           │ Grafana + Prometheus                         │
│ Testing              │ Pytest 8.x + Great Expectations              │
└──────────────────────┴──────────────────────────────────────────────┘
```

---

## 2. Technology Selection Principles

All technology choices for SMAP are governed by five explicit principles applied consistently across every layer:

### 2.1 Principle 1 — Industry Relevance

Select technologies that appear prominently in job descriptions for Data Engineer, Analytics Engineer, ML Engineer, and Data Analyst roles at manufacturing, technology, and data-intensive companies. Portfolio recognition value is a primary selection criterion.

### 2.2 Principle 2 — Open Source First

All tools must be open-source or have a viable free tier. The entire stack must be reproducible at zero cost by any reviewer who clones the repository, without requiring cloud accounts, paid licenses, or proprietary software.

### 2.3 Principle 3 — Production-Grade Patterns

Prefer tools and configurations that mirror how mature data teams operate in production — not educational shortcuts or toy implementations. The local stack must be architecturally equivalent to a production cloud deployment; only the infrastructure substrate differs.

### 2.4 Principle 4 — Composability

Each layer of the stack must be independently replaceable without cascading changes. The dbt transformation layer is PostgreSQL-compatible today and Snowflake-compatible tomorrow. The ETL extractors write to an interface (MinIO/S3), not to a specific storage vendor. This composability is demonstrated through deliberate abstraction at every integration boundary.

### 2.5 Principle 5 — Developer Experience

Tools must have strong documentation, active communities, stable APIs, and minimal setup friction. A reviewer who clones this repository should be able to run `docker compose up` and have a functioning stack within 10 minutes.

---

## 3. Data Ingestion & Orchestration

### 3.1 Apache Airflow 2.7+

| Attribute | Detail |
|---|---|
| **Role** | Pipeline orchestration and scheduling |
| **Version** | 2.7+ |
| **Rationale** | Industry-standard orchestration tool; widely used across enterprise data teams; appears in the majority of data engineering job descriptions |
| **Alternatives Considered** | Prefect, Dagster, Luigi |
| **Why Not Alternatives** | Airflow has broader enterprise adoption and name recognition; Prefect and Dagster are strong but less represented in manufacturing and traditional enterprise contexts |

**Configuration Decisions:**

- **Executor:** `LocalExecutor` in development (single-node Docker); designed to migrate to `CeleryExecutor` or `KubernetesExecutor` for production scale
- **DAG Organization:** One DAG per data domain (`dag_sensor_etl`, `dag_production_etl`, `dag_quality_etl`, `dag_maintenance_etl`, `dag_dbt_refresh`); domains do not share DAG files
- **Connections:** All database and storage credentials managed via Airflow Connections (UI or environment variables); never hardcoded in DAG files
- **Retry Policy:** 3 retries with exponential backoff (1 min, 4 min, 9 min) for all source extraction tasks; 1 retry for dbt tasks
- **Alerting:** Email or Slack notification on DAG failure via Airflow callbacks

### 3.2 Python Data Extractors

| Attribute | Detail |
|---|---|
| **Role** | Custom extraction modules for each data source |
| **Libraries** | `pandas`, `sqlalchemy`, `requests`, `boto3`-compatible `minio` client |
| **Rationale** | Full control over extraction logic; clean integration with Airflow Python operators; no black-box connectors |

**Extraction Pattern:** Watermark-based incremental extraction. Each extractor reads the maximum `updated_at` or `reading_timestamp` from the last successful run (stored in Airflow Variables), queries only new or changed records, and advances the watermark on success. Full refresh is supported via a `full_refresh=True` flag.

---

## 4. Storage & Data Lake

### 4.1 PostgreSQL 15 (Operational / Source Database)

| Attribute | Detail |
|---|---|
| **Role** | Simulates the operational source database (ERP / MES / SCADA) |
| **Version** | 15.x |
| **Rationale** | Widely adopted, free, production-quality RDBMS; simulates transactional systems found in real manufacturing environments |
| **Docker Image** | `postgres:15-alpine` |
| **Port** | 5432 (source) |

**Configuration:**

- **Schema:** `public` — all operational tables in a single schema for simplicity
- **Connection Pooling:** `max_connections = 100`; application uses `SQLAlchemy` with a pool size of 5 and overflow of 10
- **Schema Conventions:** `snake_case` table and column names; `TIMESTAMPTZ` for all timestamps (always UTC); `BIGSERIAL` for high-volume table primary keys

### 4.2 MinIO (Object Storage)

| Attribute | Detail |
|---|---|
| **Role** | S3-compatible object storage for the raw data lake (Bronze zone) |
| **Rationale** | Enables S3-like data lake architecture locally without cloud costs; 100% API-compatible with AWS S3 — migration requires only changing the endpoint URL |
| **API Compatibility** | AWS S3 API v4 (full compatibility) |
| **Ports** | 9000 (API) · 9001 (Console UI) |

**Bucket Structure and Naming Conventions:**

```
smap-data-lake/
├── bronze/                         # Raw, unmodified data as received from source
│   ├── sensors/year=YYYY/month=MM/day=DD/
│   ├── production/year=YYYY/month=MM/day=DD/
│   ├── quality/year=YYYY/month=MM/day=DD/
│   └── maintenance/year=YYYY/month=MM/day=DD/
├── silver/                         # Cleaned and validated data
│   ├── sensors/
│   ├── production/
│   ├── quality/
│   └── maintenance/
└── gold/                           # Aggregated, analytics-ready exports
    ├── oee/
    ├── kpis/
    └── ml_features/
```

**File Format:** Parquet (columnar, compressed with Snappy) for all zones. JSON only for small API-bound payloads in the Gold zone.

---

## 5. Data Transformation & Warehouse

### 5.1 dbt Core 1.7+

| Attribute | Detail |
|---|---|
| **Role** | SQL-based transformation layer from raw staging to marts |
| **Version** | 1.7+ |
| **Adapter** | `dbt-postgres` |
| **Rationale** | Gold standard for analytics engineering; massive and growing industry adoption; generates documentation and lineage graphs automatically |
| **Alternatives Considered** | SQLMesh, custom SQL scripts |
| **Why Not Alternatives** | SQLMesh is excellent but less recognized; custom SQL scripts lack testing, documentation, and lineage features |

**dbt Project Structure:**

```
warehouse/dbt/
├── models/
│   ├── staging/           # stg_* — 1:1 with source tables, light cleaning only
│   ├── intermediate/      # int_* — business logic, multi-source joins, derivations
│   └── marts/
│       ├── production/    # fct_production, dim_machine, dim_product, dim_shift
│       ├── quality/       # fct_quality_inspection, dim_defect_type
│       └── maintenance/   # fct_maintenance_event, dim_employee
├── tests/                 # Custom singular test SQL files
├── seeds/                 # dim_date seed CSV (pre-populated calendar dimension)
├── macros/                # Reusable Jinja macros (e.g., generate_schema_name)
├── snapshots/             # SCD Type 2 snapshots for slowly changing dimensions
├── analyses/              # Ad-hoc analysis SQL (not materialized)
└── dbt_project.yml        # Project configuration and materialization defaults
```

**Materialization Strategy:**

| Layer | Materialization | Rationale |
|---|---|---|
| Staging | `view` | No storage overhead; refreshed on each `dbt run` |
| Intermediate | `ephemeral` | Compiled inline; no intermediate tables stored |
| Marts (dimensions) | `table` | Full refresh on each run; dimensions are small |
| Marts (facts) | `incremental` | Append-only; use `updated_at` watermark to process only new records |

**Testing Strategy:** Every model requires `not_null` and `unique` on primary keys. Categorical columns require `accepted_values`. Fact tables require at least one custom singular test (e.g., OEE components must sum correctly).

### 5.2 PostgreSQL 15 (Data Warehouse)

| Attribute | Detail |
|---|---|
| **Role** | Hosts the dimensional data warehouse (star schema) |
| **Port** | 5433 (separate instance from source DB) |
| **Schema Design** | Star schema with four schemas: `raw`, `staging`, `intermediate`, `marts` |
| **Cloud Compatibility** | Schema designed to be directly migrated to Snowflake or BigQuery — no PostgreSQL-specific syntax in dbt models |

---

## 6. Backend API

### 6.1 FastAPI

| Attribute | Detail |
|---|---|
| **Role** | REST API serving analytics data to the frontend and external consumers |
| **Version** | 0.110+ |
| **Python Version** | 3.11+ |
| **Rationale** | Modern, async-native, auto-generates OpenAPI docs; growing adoption in data teams; type safety via Pydantic; the highest-performance Python web framework for I/O-bound workloads |
| **Alternatives Considered** | Flask, Django REST Framework |
| **Why FastAPI** | Flask lacks built-in async and schema validation; Django REST Framework adds unnecessary complexity for a data-serving API |
| **Web Server** | Uvicorn (ASGI) |
| **ORM** | SQLAlchemy 2.x (async engine) |

**API Design Decisions:**

- **Versioning:** URL path-based — all endpoints under `/api/v1/`; v2 prefix reserved for breaking changes
- **Authentication:** API key via `X-API-Key` header; validated by FastAPI middleware; missing or invalid key returns `401`/`403` respectively
- **Response Envelope:** All responses — success and error — use a consistent JSON envelope (`status`, `data`, `meta`). See [API_SPECIFICATION.md §3](./API_SPECIFICATION.md) for the full schema.
- **Error Handling:** Application-level error codes (e.g., `MACHINE_NOT_FOUND`, `INVALID_DATE_RANGE`) returned in a structured `error` object. All unhandled exceptions are caught by a global exception handler and returned as `500` with a safe error message.
- **Request Lifecycle:** `Router → Dependency Injection (DB session, API key) → Service Layer → Repository (SQLAlchemy query) → Response Model (Pydantic)`

---

## 7. Frontend & Visualization

### 7.1 React 18

| Attribute | Detail |
|---|---|
| **Role** | Interactive analytics dashboard UI |
| **Version** | 18.x |
| **Build Tool** | Vite 5.x |
| **Rationale** | Most widely adopted frontend framework; strong ecosystem for data visualization; concurrent rendering improves dashboard responsiveness |

**Frontend Architecture Decisions:**

- **Component Organization:** Feature-based structure — each dashboard domain (OEE, Production, Quality, Maintenance) is a self-contained feature folder with its own components, hooks, and types
- **State Management:** React Query (TanStack Query) for server state — all API fetching, caching, and background refresh; no global client-side state store needed for v1.0.0
- **API Integration Pattern:** Custom `useApiQuery` hook wraps React Query and injects the API key header; all components consume data through domain-specific hooks (e.g., `useOEEData`, `useProductionSummary`)
- **Theming:** CSS custom properties (variables) for design tokens; no CSS-in-JS; component styles via CSS modules

### 7.2 Charting Libraries

| Library | Use Case | Rationale |
|---|---|---|
| **Recharts** | Time-series trends, line charts, bar charts, area charts | React-native, composable API, good performance at dashboard scale |
| **Chart.js** | Gauge charts, radar charts, doughnut charts | Best-in-class gauge rendering; used only where Recharts falls short |
| **D3.js** (optional) | Custom Pareto charts, SPC control charts with UCL/LCL lines | Used only for custom visualizations not available in Recharts or Chart.js |

---

## 8. Machine Learning

### 8.1 Core Libraries

| Library | Version | Use Case |
|---|---|---|
| `scikit-learn` | 1.4+ | Preprocessing pipelines, Isolation Forest (anomaly detection), evaluation metrics |
| `XGBoost` | 2.x | Gradient boosting for predictive maintenance (classifier) and quality prediction (regressor) |
| `Prophet` | 1.1+ | Time-series decomposition and forecasting for trend analysis in notebooks |
| `pandas` | 2.x | Data manipulation for feature engineering pipelines |
| `numpy` | 1.26+ | Numerical array operations |
| `matplotlib` / `seaborn` | Latest | Visualization in EDA and model evaluation notebooks |
| `shap` | Latest | SHAP feature importance values for model explainability |

### 8.2 MLflow 2.x (Experiment Tracking)

| Attribute | Detail |
|---|---|
| **Role** | Track experiments, log parameters, metrics, and model artifacts; serve as the Model Registry |
| **Version** | 2.x |
| **Rationale** | Industry-standard MLOps tool; enables fully reproducible experiments; Model Registry enables clean promotion workflow |
| **Backend Store** | SQLite (local) for metadata |
| **Artifact Store** | Local filesystem under `ml/experiments/` |

**ML Lifecycle Decisions:**

- **Experiment Naming Convention:** `smap-<model-type>-<date>` (e.g., `smap-predictive-maintenance-2026-07`)
- **Run Naming Convention:** `<algorithm>-<key-hyperparameter>-<timestamp>` (e.g., `xgb-n100-d5-20260720`)
- **Model Registration:** Best-performing run from each experiment is registered in the MLflow Model Registry under a canonical name (`smap-maintenance-predictor`, `smap-anomaly-detector`, `smap-quality-predictor`)
- **Promotion Process:** Models move through three stages — `Staging` (registered, under evaluation) → `Production` (deployed to API) → `Archived` (superseded). Promotion requires documented evaluation metrics meeting or exceeding the targets defined in [PROJECT_CHARTER.md §6.1](./PROJECT_CHARTER.md).
- **API Loading:** FastAPI loads the `Production`-stage model for each use case on startup; model version is logged in every inference response under `model_version`

---

## 9. Testing

### 9.1 Pytest 8.x

| Attribute | Detail |
|---|---|
| **Role** | Unit and integration testing for all Python code (ETL, API, ML feature pipeline) |
| **Version** | 8.x |
| **Coverage Tool** | `pytest-cov` |
| **Target Coverage** | ≥ 80% across ETL (extract, transform, load) and API layers |
| **Key Plugins** | `pytest-asyncio` (async API tests), `pytest-mock` (mocking), `pytest-cov` (coverage) |

### 9.2 Great Expectations 0.18+

| Attribute | Detail |
|---|---|
| **Role** | Data quality validation — schema conformance, null constraints, value range enforcement |
| **Version** | 0.18+ |
| **Rationale** | Industry-standard data quality framework; generates human-readable "Data Docs" as a validation report |

**Testing Strategy by Layer:**

| Layer | Tool | Type | Target |
|---|---|---|---|
| Source data (Bronze) | Great Expectations | Schema and null validation | 100% expectation pass rate before advancing to Silver |
| ETL functions | Pytest | Unit tests with mock data | ≥ 80% coverage |
| dbt models | dbt test | Schema tests (not_null, unique, accepted_values) | 100% — zero failing tests allowed to merge |
| API endpoints | Pytest + httpx | Unit + integration tests | ≥ 80% coverage, all happy paths and error cases |
| ML features | Pytest | Output shape, dtype, and range assertions | ≥ 75% coverage |
| End-to-end | Pytest integration | Full pipeline from extraction to warehouse query | One integration test per data domain |

---

## 10. Infrastructure & Deployment

### 10.1 Docker & Docker Compose

| Attribute | Detail |
|---|---|
| **Role** | Containerization and local multi-service orchestration |
| **Version** | Docker 24+, Compose v2 |
| **Rationale** | Fully reproducible environments; one-command local startup; mirrors container-based production deployment patterns |

**Docker Compose Service Map:**

| Service | Image | Port(s) | Role |
|---|---|---|---|
| `postgres_source` | `postgres:15-alpine` | 5432 | Operational source database |
| `postgres_warehouse` | `postgres:15-alpine` | 5433 | Data warehouse |
| `minio` | `minio/minio` | 9000, 9001 | Object storage (S3-compatible) |
| `airflow-webserver` | `apache/airflow:2.7` | 8080 | Airflow DAG management UI |
| `airflow-scheduler` | `apache/airflow:2.7` | — | DAG scheduling engine |
| `backend` | `./deployment/docker/Dockerfile.api` | 8000 | FastAPI REST API |
| `frontend` | `./deployment/docker/Dockerfile.frontend` | 3000 | React dashboard |
| `mlflow` | `./deployment/docker/Dockerfile.mlflow` | 5000 | MLflow tracking server |
| `prometheus` | `prom/prometheus` | 9090 | Metrics collection and storage |
| `grafana` | `grafana/grafana` | 3001 | Infrastructure monitoring dashboards |

All services are connected via a Docker bridge network (`smap-network`). Services that must communicate (e.g., backend → postgres_warehouse) use Docker service names as hostnames.

### 10.2 GitHub Actions (CI/CD)

| Attribute | Detail |
|---|---|
| **Role** | Automated CI/CD pipeline |
| **Triggers** | Pull request to `develop`; push to `main` |
| **CI Jobs** | `lint` (ruff + black --check), `type-check` (mypy), `test` (pytest with coverage), `dbt-parse` (validate dbt project) |
| **CD Jobs** | `docker-build` (build and tag all images) on merge to `main` |
| **Required to Merge** | All CI jobs must pass green; coverage must not decrease |

---

## 11. Monitoring & Observability

### 11.1 Grafana + Prometheus

| Tool | Role |
|---|---|
| **Prometheus** | Scrapes and stores time-series metrics from all services; retention: 15 days |
| **Grafana** | Dashboard visualization for infrastructure and application metrics |

**Key Metrics Tracked:**

| Metric | Source | Purpose |
|---|---|---|
| ETL pipeline duration | Airflow (StatsD exporter) | Track pipeline performance regression |
| ETL success/failure rate | Airflow (StatsD exporter) | Alert on pipeline failures |
| API request rate and latency (p50, p95, p99) | FastAPI (Prometheus middleware) | Monitor API performance against SLA |
| API error rate (4xx, 5xx) | FastAPI (Prometheus middleware) | Detect regressions and errors |
| Database connection pool utilization | SQLAlchemy metrics | Detect connection exhaustion |
| ML model inference latency | FastAPI (Prometheus middleware) | Monitor model serving performance |
| Container CPU and memory | Docker (cAdvisor) | Infrastructure capacity monitoring |

**Alerting:** Grafana alerting rules defined for: ETL failure (immediate), API p95 latency > 500 ms (5-minute window), API error rate > 1% (5-minute window).

---

## 12. Developer Tooling

| Tool | Version | Purpose | Config File |
|---|---|---|---|
| `pre-commit` | 3.x | Enforce code quality checks before every commit | `.pre-commit-config.yaml` |
| `black` | 24.x | Python code auto-formatter (line length: 88) | `pyproject.toml` |
| `ruff` | 0.4+ | Python linter — replaces flake8, isort, pyupgrade | `pyproject.toml` |
| `mypy` | 1.x | Static type checking; strict mode for `backend/` and `etl/` | `pyproject.toml` |
| `ESLint` | 8.x | JavaScript/React linting (Airbnb config) | `frontend/.eslintrc.json` |
| `Prettier` | 3.x | JavaScript/React formatting (2 spaces, single quotes) | `frontend/.prettierrc` |
| `sqlfluff` | 2.x | SQL linter for raw SQL files and dbt model SQL | `sqlfluff.cfg` |
| `Makefile` | — | Common project commands (`make setup`, `make test`, `make lint`, `make run`) | `Makefile` |

---

## 13. Architecture Decision Records (ADRs)

Full ADR documents are stored in `docs/adr/` and will be created during Phase 5. This table provides the index and current status:

| ADR # | Decision | Rationale Summary | Status |
|---|---|---|---|
| ADR-001 | Use PostgreSQL as both operational DB and warehouse | Free, production-grade, Snowflake-compatible schema patterns | Accepted |
| ADR-002 | Use dbt Core (not dbt Cloud) for transformations | Zero cost; same functionality for a portfolio project; version-controllable profiles | Accepted |
| ADR-003 | Use FastAPI over Flask or Django REST | Async-native, built-in Pydantic validation, auto-generates OpenAPI docs | Accepted |
| ADR-004 | Use MinIO for local object storage instead of AWS S3 | Zero cost; 100% S3 API compatible; migration to S3 requires only endpoint change | Accepted |
| ADR-005 | Use scikit-learn + XGBoost over deep learning | Interpretable, fast to train, production-proven on tabular manufacturing data; deep learning adds complexity without clear benefit | Accepted |
| ADR-006 | Use incremental extraction over full refresh for ETL | Scales to large tables; watermark approach is industry standard; reduces database load | Accepted |

---

## 14. Technology Comparison Tables

### 14.1 Orchestration

| Tool | Pros | Cons | Decision |
|---|---|---|---|
| Apache Airflow | Industry standard, DAG-based, rich UI, massive ecosystem, strong JD recognition | Complex setup, heavy resource usage | ✅ **Selected** |
| Prefect | Modern Python-native API, easier local setup, strong UI | Less represented in enterprise JDs | ❌ Not selected |
| Dagster | Type-safe assets, excellent software-defined assets model | Less enterprise adoption; smaller community | ❌ Not selected |

### 14.2 Data Warehouse

| Tool | Pros | Cons | Decision |
|---|---|---|---|
| PostgreSQL | Free, local, production-grade, well-understood | Not a true MPP warehouse; limited concurrent analytical query performance | ✅ **Selected (local)** |
| Snowflake | Cloud DWH gold standard; elastic compute; strong JD recognition | Requires paid account; cost at scale | 🔮 Future migration target |
| BigQuery | Serverless, scalable, strong GCP ecosystem | GCP account dependency; cost for heavy querying | ❌ Not selected |
| DuckDB | In-process, extremely fast for analytical queries, zero setup | Less production equivalent; no concurrent multi-user support | ❌ Not selected for v1.0.0 |

### 14.3 ML Framework

| Tool | Pros | Cons | Decision |
|---|---|---|---|
| scikit-learn + XGBoost | Production-proven on tabular data; fast training; interpretable; strong industry adoption | Not suited for deep learning or large-scale unstructured data | ✅ **Selected** |
| PyTorch / TensorFlow | Best for deep learning; large community; LSTM and Transformer support | Overkill for tabular manufacturing data; longer training time; more complex deployment | ❌ Not selected (Post-v1.0 enhancement) |
| LightGBM | Faster than XGBoost in many cases; excellent performance | Slightly lower recognition than XGBoost in JDs | ❌ Not selected |

---

*This document is maintained by the project lead and updated whenever a technology is added, replaced, or a new ADR is accepted.*
