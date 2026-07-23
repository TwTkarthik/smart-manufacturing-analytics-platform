# Smart Manufacturing Analytics Platform (SMAP)

> **A production-quality, end-to-end data engineering and analytics platform demonstrating enterprise-grade practices across the modern data stack — built for the manufacturing industry.**

**Document Version:** 1.0.0 | **Status:** In Development | **Phase:** 1 — Foundation

![Project Status](https://img.shields.io/badge/Status-In%20Development-yellow)
![Version](https://img.shields.io/badge/Version-0.1.0-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Python](https://img.shields.io/badge/Python-3.11+-informational)

---

## Table of Contents

- [Project Overview](#project-overview)
- [Business Problem](#business-problem)
- [Key Features](#key-features)
- [Architecture Overview](#architecture-overview)
- [Technology Stack](#technology-stack)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
- [Data Pipeline](#data-pipeline)
- [Analytics & Dashboards](#analytics--dashboards)
- [Machine Learning Models](#machine-learning-models)
- [API Reference](#api-reference)
- [Contributing](#contributing)
- [Roadmap](#roadmap)
- [License](#license)
- [Contact](#contact)

---

## Project Overview

The **Smart Manufacturing Analytics Platform (SMAP)** is a comprehensive data platform designed for the manufacturing industry. It ingests, processes, and analyzes production data from factory floor sensors, ERP systems, and quality control systems to deliver actionable insights through interactive dashboards, automated alerts, and predictive machine learning models.

This project demonstrates real-world proficiency in:

- **Data Engineering** — Scalable ETL pipelines, data lake architecture (medallion pattern), and Airflow orchestration
- **Analytics Engineering** — dbt-based transformations, dimensional modeling (star schema), and governed data marts
- **Business Intelligence** — KPI frameworks, OEE metrics, Pareto analysis, and SPC charting
- **Applied Machine Learning** — Predictive maintenance, anomaly detection, and quality prediction with MLflow tracking
- **Backend Engineering** — FastAPI REST API with OpenAPI documentation, authentication, and structured error handling

---

## Business Problem

Manufacturing operations generate enormous volumes of data from sensors, production systems, quality control logs, and maintenance records — yet most facilities operate with fragmented, siloed data that arrives too late to be actionable.

**The core operational challenges this platform addresses:**

- **Unplanned Downtime:** Equipment failures are reactive. Without predictive signals from sensor telemetry, maintenance teams respond to breakdowns rather than preventing them — driving MTTR up and MTBF down.
- **Hidden Scrap and Yield Loss:** Quality defects are detected after the fact at the end of a production run. Without real-time process monitoring, scrap accumulates before corrective action is taken.
- **Manual, Delayed Reporting:** Production KPIs — OEE, throughput, defect rate — are compiled manually in spreadsheets, often 24–48 hours after the shift closes. Decisions are made on stale data.
- **Siloed Systems:** SCADA, MES, ERP, and quality systems capture data independently with no unified view. Cross-functional analysis (e.g., correlating sensor anomalies with downstream defect rates) requires manual data extraction and reconciliation.
- **No Predictive Capability:** Without a consolidated, clean analytical layer, data science teams cannot build reliable predictive models. Feature engineering from inconsistent source data is the primary bottleneck.

**What SMAP delivers:**

- A unified analytical data layer — a single source of truth for all operational metrics
- Real-time and near-real-time dashboards replacing manual reporting
- Predictive ML models surfacing failure risk and quality signals before they become incidents
- A governed, documented data platform designed for auditability and extensibility

---

## Key Features

| Feature | Description | Status |
|---|---|---|
| Real-Time Sensor Ingestion | Ingest IoT sensor data from factory equipment | 🔲 Planned |
| ETL Pipeline | Extract, Transform, Load from multiple data sources | 🔲 Planned |
| Data Warehouse | Dimensional model with production and quality marts | 🔲 Planned |
| OEE Dashboard | Overall Equipment Effectiveness monitoring | 🔲 Planned |
| Predictive Maintenance | ML model to forecast equipment failures | 🔲 Planned |
| Anomaly Detection | Real-time detection of process anomalies | 🔲 Planned |
| Quality Prediction | Defect rate prediction from process parameters | 🔲 Planned |
| REST API | FastAPI-based backend serving analytics endpoints | 🔲 Planned |
| Interactive Dashboard | React-based frontend visualization layer | 🔲 Planned |
| CI/CD Pipeline | Automated testing and deployment workflows | 🔲 Planned |

**Notation:** 🔲 Planned · 🔵 In Progress · ✅ Complete · ⏸️ Deferred

---

## Architecture Overview

SMAP follows a **layered, medallion-inspired architecture** organized around the classic data engineering progression:

```
Source Systems → Bronze (Raw) → Silver (Cleaned) → Gold (Serving) → Consumption
```

**Five platform layers:**

1. **Ingestion Layer** — Python extractors and Airflow DAGs pull data from simulated source systems (ERP, MES, SCADA) into the MinIO object store (Bronze zone)
2. **Transformation Layer** — dbt models clean, validate, and model raw data through staging, intermediate, and mart layers into a PostgreSQL star schema warehouse
3. **Serving Layer** — FastAPI REST API exposes warehouse data and ML inference endpoints to consuming applications
4. **Consumption Layer** — React dashboard with interactive charts; Jupyter notebooks for ad-hoc analysis
5. **Intelligence Layer** — scikit-learn and XGBoost models for predictive maintenance, anomaly detection, and quality prediction, tracked with MLflow

```
[Data Sources] → [Ingestion Layer] → [Data Lake (Bronze)] → [ETL / dbt] → [Data Warehouse] → [API Layer] → [Dashboard]
                                                                          ↓
                                                                 [ML Model Serving]
```

For full architecture documentation, see [SYSTEM_ARCHITECTURE.md](./SYSTEM_ARCHITECTURE.md).

---

## Technology Stack

| Layer | Technology |
|---|---|
| Orchestration | Apache Airflow 2.7+ |
| Ingestion | Python (pandas, SQLAlchemy, custom connectors) |
| Object Storage | MinIO (S3-compatible) |
| Operational DB | PostgreSQL 15 |
| Transformation | dbt Core 1.7+ |
| Data Warehouse | PostgreSQL 15 (Snowflake-compatible schema design) |
| ML Framework | scikit-learn 1.4+, XGBoost 2.x, Prophet |
| ML Tracking | MLflow 2.x |
| API | FastAPI 0.110+ + Uvicorn (ASGI) |
| Frontend | React 18 + Recharts / Chart.js |
| Containerization | Docker 24+, Docker Compose v2 |
| CI/CD | GitHub Actions |
| Monitoring | Grafana + Prometheus |
| Testing | Pytest 8.x + Great Expectations |

For full technology decisions and rationale, see [TECH_STACK.md](./TECH_STACK.md).

---

## Repository Structure

```
smart-manufacturing-analytics/
├── .github/                   # GitHub workflows and issue templates
│   ├── workflows/             # CI/CD pipeline definitions
│   └── ISSUE_TEMPLATE/        # Bug report and feature request templates
├── analytics/                 # Analytics layer
│   ├── dashboards/            # Dashboard configuration and specs
│   ├── kpis/                  # KPI definitions and business logic
│   └── reports/               # Scheduled report templates
├── assets/                    # Static assets
│   ├── diagrams/              # Architecture and data flow diagrams
│   ├── images/                # Screenshots and images
│   └── mockups/               # UI wireframes and mockups
├── backend/                   # FastAPI backend application
│   ├── api/                   # API route handlers
│   ├── config/                # App configuration
│   ├── models/                # Database ORM models
│   ├── services/              # Business logic services
│   └── utils/                 # Utility functions
├── config/                    # Environment-specific configuration
│   ├── dev/                   # Development configuration
│   ├── staging/               # Staging configuration
│   └── production/            # Production configuration
├── database/                  # Database layer
│   ├── migrations/            # Alembic schema migrations
│   ├── schemas/               # DDL schema definitions
│   └── seeds/                 # Seed data scripts
├── datasets/                  # Data files
│   ├── external/              # Third-party reference datasets
│   ├── processed/             # Cleaned and transformed datasets
│   └── raw/                   # Raw source data
├── deployment/                # Deployment configurations
│   ├── ci_cd/                 # CI/CD pipeline scripts
│   ├── docker/                # Dockerfiles and Compose files
│   └── kubernetes/            # K8s manifests (future)
├── docs/                      # Additional documentation and ADRs
├── etl/                       # ETL pipeline code
│   ├── extract/               # Data extraction modules
│   ├── load/                  # Data loading modules
│   ├── pipelines/             # Airflow DAG definitions
│   └── transform/             # Transformation logic
├── frontend/                  # React.js frontend application
│   ├── components/            # Reusable UI components
│   ├── public/                # Static public assets
│   └── src/                   # Source code
├── ml/                        # Machine learning layer
│   ├── evaluation/            # Model evaluation scripts and reports
│   ├── experiments/           # MLflow experiment tracking
│   ├── feature_engineering/   # Feature pipeline code
│   ├── models/                # Serialized model artifacts
│   └── training/              # Model training scripts
├── notebooks/                 # Jupyter notebooks
│   ├── eda/                   # Exploratory data analysis
│   ├── modeling/              # Model development notebooks
│   └── prototyping/           # Quick prototyping experiments
├── scripts/                   # Utility shell/Python scripts
│   ├── data_generation/       # Synthetic data generation
│   ├── setup/                 # Environment setup scripts
│   └── utilities/             # Miscellaneous utilities
├── testing/                   # Test suite
│   ├── e2e/                   # End-to-end tests
│   ├── fixtures/              # Shared test fixtures
│   ├── integration/           # Integration tests
│   └── unit/                  # Unit tests
├── warehouse/                 # Data warehouse layer
│   ├── dbt/                   # dbt project files
│   ├── marts/                 # Data mart definitions
│   └── staging/               # Staging area models
├── CHANGELOG.md               # Version history and release notes
├── CODING_STANDARDS.md        # Code style and engineering standards
├── CONTRIBUTING.md            # Contribution guidelines
├── DATABASE_DESIGN.md         # Data model documentation
├── LICENSE.md                 # Project license
├── PROJECT_CHARTER.md         # Project scope and objectives
├── README.md                  # This file
├── ROADMAP.md                 # Feature roadmap and milestones
├── SYSTEM_ARCHITECTURE.md     # System design and architecture
├── TECH_STACK.md              # Technology decisions and rationale
└── API_SPECIFICATION.md       # REST API reference documentation
```

---

## Getting Started

### Prerequisites

Ensure the following tools are installed before proceeding:

| Tool | Minimum Version | Purpose |
|---|---|---|
| Git | 2.40+ | Version control |
| Docker Desktop | 24.0+ | Container runtime |
| Docker Compose | v2.0+ | Multi-service orchestration |
| Python | 3.11+ | ETL, API, and ML code |
| Node.js | 20 LTS | Frontend development |
| Make | Any | Project automation commands |

### Installation

**1. Clone the repository**

```bash
git clone https://github.com/<your-username>/smart-manufacturing-analytics.git
cd smart-manufacturing-analytics
```

**2. Configure environment variables**

```bash
# Copy the example environment file
cp .env.example .env

# Open .env and configure your local values
# Do NOT commit the .env file — it is already in .gitignore
```

**3. Start all Docker services**

```bash
docker compose up -d

# Verify all containers are running and healthy
docker compose ps
```

**4. Install Python dependencies**

```bash
python -m venv .venv
source .venv/bin/activate   # Linux / macOS
.venv\Scripts\activate      # Windows

pip install -r requirements.txt
pip install -r requirements-dev.txt
```

**5. Install and activate pre-commit hooks**

```bash
pre-commit install
```

**6. Run database migrations and load seed data**

```bash
alembic upgrade head
python scripts/setup/seed_database.py
```

**7. Verify the installation**

```bash
# Run unit tests
pytest testing/unit/ -v

# Start the API server (http://localhost:8000)
uvicorn backend.main:app --reload --port 8000

# Start the frontend (http://localhost:3000) — separate terminal
cd frontend && npm install && npm run dev
```

### Environment Variables

All configuration is driven by environment variables. Copy `.env.example` to `.env` and populate the following required keys:

| Variable | Description | Example |
|---|---|---|
| `POSTGRES_SOURCE_URL` | Connection string for operational source DB | `postgresql://user:pass@localhost:5432/smap_source` |
| `POSTGRES_WAREHOUSE_URL` | Connection string for data warehouse | `postgresql://user:pass@localhost:5433/smap_warehouse` |
| `MINIO_ENDPOINT` | MinIO S3-compatible endpoint | `localhost:9000` |
| `MINIO_ACCESS_KEY` | MinIO access key | `minioadmin` |
| `MINIO_SECRET_KEY` | MinIO secret key | (set in .env) |
| `API_SECRET_KEY` | Key for API authentication | (generate a secure random value) |
| `AIRFLOW_HOME` | Airflow home directory path | `/opt/airflow` |
| `MLFLOW_TRACKING_URI` | MLflow tracking server URI | `http://localhost:5000` |

---

## Data Pipeline

The SMAP data pipeline follows the **Extract → Transform → Load (ETL)** pattern, orchestrated by Apache Airflow and structured across three logical zones.

### Source Systems

| Source | Type | Data | Update Frequency |
|---|---|---|---|
| Sensor Database | PostgreSQL | Machine telemetry (temperature, vibration, pressure, RPM) | Every 15 minutes |
| Production Log | PostgreSQL | Production orders, shift output, cycle times | Every 1 hour |
| Quality Records | PostgreSQL | Inspection results, defect classifications, measurements | Every 4 hours |
| Maintenance Log | CSV flat files | Work orders, downtime events, part replacements | Daily at 02:00 UTC |

### Pipeline Stages

1. **Extract** — Python extractors pull data incrementally using watermark-based change detection. Raw data is written to MinIO in Parquet format, partitioned by `source/year/month/day/`.
2. **Validate (Bronze → Silver)** — Great Expectations suites enforce schema conformance, null constraints, and value range checks on raw data before it advances.
3. **Transform (Silver → Gold)** — dbt models clean, join, and aggregate data through four layers: `sources → staging → intermediate → marts`.
4. **Load** — Final star schema fact and dimension tables are materialized in the PostgreSQL data warehouse under the `marts` schema.
5. **dbt Testing** — After every `dbt run`, schema tests (not_null, unique, accepted_values) and custom data tests execute automatically.

### dbt Model Lineage

```
sources.yml (raw tables)
    └── staging/       (stg_*)   — 1:1 with sources, light cleaning only
          └── intermediate/ (int_*)  — business logic joins and derivations
                └── marts/      (fct_*, dim_*) — final star schema tables
```

For complete pipeline documentation, see [SYSTEM_ARCHITECTURE.md](./SYSTEM_ARCHITECTURE.md).

---

## Analytics & Dashboards

The React-based dashboard consumes the SMAP REST API to provide real-time operational visibility across four analytical domains:

| Dashboard | Key Metrics | Primary Users |
|---|---|---|
| **OEE Overview** | Overall Equipment Effectiveness, Availability, Performance, Quality waterfall; gap-to-benchmark | Plant Manager, Operations Director |
| **Production Throughput** | Units planned vs. actual, yield rate, scrap rate, line-by-line and shift-by-shift comparison | Production Supervisor |
| **Quality Control** | Defect rate trend, Pareto chart by defect type, Statistical Process Control (SPC) charts | Quality Engineer |
| **Maintenance & Reliability** | Downtime log, MTBF and MTTR trends, planned vs. unplanned maintenance ratio, top failure modes | Maintenance Manager |

---

## Machine Learning Models

Three ML models are deployed as part of the Intelligence Layer, each accessible via the REST API and tracked in MLflow:

| Model | Algorithm | Objective | Target Metric |
|---|---|---|---|
| **Predictive Maintenance** | XGBoost Classifier | Forecast failure probability within a configurable horizon (e.g., 7 days) | ≥ 85% Recall |
| **Anomaly Detection** | Isolation Forest | Flag multivariate sensor readings deviating from learned normal behavior | ≥ 90% Precision |
| **Quality Prediction** | XGBoost Regressor | Predict expected defect rate given current process parameter values | RMSE ≤ 0.5% |

All models are trained on synthetically generated data designed to reflect realistic manufacturing patterns, versioned with MLflow, and served through the FastAPI inference endpoints.

---

## API Reference

The SMAP REST API is available at `http://localhost:8000/api/v1` when running locally. Interactive documentation is auto-generated by FastAPI:

| Interface | URL | Notes |
|---|---|---|
| Swagger UI | `http://localhost:8000/docs` | Interactive endpoint explorer |
| ReDoc | `http://localhost:8000/redoc` | Clean reference documentation |
| OpenAPI JSON | `http://localhost:8000/openapi.json` | Machine-readable schema |

**Key endpoint domains:**

- `GET /health` — API health and component status
- `GET /production/summary` — Production KPIs for a date range
- `GET /quality/summary` — Quality inspection metrics and defect breakdown
- `GET /maintenance/summary` — Downtime, MTBF, MTTR summary
- `GET /kpis/oee` — OEE score with availability, performance, quality breakdown
- `POST /ml/predict/maintenance` — Failure probability prediction for a machine
- `POST /ml/detect/anomaly` — Anomaly detection for recent sensor readings
- `POST /ml/predict/quality` — Defect rate prediction from process parameters

All responses use a standard JSON envelope. See [API_SPECIFICATION.md](./API_SPECIFICATION.md) for complete endpoint contracts, request schemas, and response examples.

---

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](./CONTRIBUTING.md) for the development environment setup, branching strategy, commit message conventions, and pull request process.

All code must comply with [CODING_STANDARDS.md](./CODING_STANDARDS.md) and pass the automated CI checks before merging.

---

## Roadmap

See the full delivery roadmap in [ROADMAP.md](./ROADMAP.md).

**Current Phase:** Phase 1 — Foundation & Infrastructure

| Phase | Name | Status |
|---|---|---|
| Phase 1 | Foundation & Infrastructure | 🔵 In Progress |
| Phase 2 | Data Layer (ETL, Warehouse, dbt) | 🔲 Planned |
| Phase 3 | Application Layer (API, Dashboard) | 🔲 Planned |
| Phase 4 | Intelligence Layer (ML, CI/CD, Testing) | 🔲 Planned |
| Phase 5 | Polish & Portfolio Deployment | 🔲 Planned |

---

## License

This project is licensed under the MIT License. See [LICENSE.md](./LICENSE.md) for details.

---

## Contact

> Add your name, email, LinkedIn, and portfolio link here when publishing.

---

*Built to demonstrate enterprise-grade data engineering and analytics practices across the modern data stack.*
