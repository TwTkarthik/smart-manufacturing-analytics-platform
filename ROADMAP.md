# ROADMAP — Smart Manufacturing Analytics Platform (SMAP)

**Document Version:** 1.0.0
**Last Updated:** 2026-07-20
**Status:** Active
**Owner:** Project Lead

---

## Table of Contents

- [How to Read This Roadmap](#how-to-read-this-roadmap)
- [Vision Statement](#vision-statement)
- [Phase Overview](#phase-overview)
- [Phase 1 — Foundation & Infrastructure](#phase-1--foundation--infrastructure)
- [Phase 2 — Data Layer](#phase-2--data-layer)
- [Phase 3 — Application Layer](#phase-3--application-layer)
- [Phase 4 — Intelligence Layer](#phase-4--intelligence-layer)
- [Phase 5 — Polish & Portfolio Deployment](#phase-5--polish--portfolio-deployment)
- [Future Enhancements (Post v1.0.0)](#future-enhancements-post-v100)
- [Progress Summary](#progress-summary)

---

## How to Read This Roadmap

This roadmap tracks all planned work across five sequential development phases. Each phase builds directly on the previous and produces a clearly demonstrable milestone artifact.

**Task Status Notation:**

| Symbol | Meaning |
|---|---|
| 🔲 | Not Started |
| 🔵 | In Progress |
| ✅ | Complete |
| ⏸️ | Deferred — moved to post-v1.0 backlog |

**Version Mapping:** Phase completion maps to the version tags defined in `CHANGELOG.md`:

| Phase | Version Tag |
|---|---|
| Phase 1 | `0.1.x` |
| Phase 2 | `0.2.x` |
| Phase 3 | `0.3.x` |
| Phase 4 | `0.4.x` |
| Phase 5 | `1.0.0` |

All scope changes must be approved via the governance process in [PROJECT_CHARTER.md](./PROJECT_CHARTER.md) before updating this document.

---

## Vision Statement

*A fully automated, end-to-end smart manufacturing data platform that unifies sensor telemetry, production records, and quality data into a single governed analytical layer — delivering real-time operational intelligence, predictive maintenance signals, and quality forecasts through a production-quality REST API and interactive dashboard.*

---

## Phase Overview

```
Phase 1  [Foundation]          → Repository, Documentation, Synthetic Data
Phase 2  [Data Layer]          → ETL, Database, Warehouse, dbt
Phase 3  [Application Layer]   → REST API, Frontend Dashboard
Phase 4  [Intelligence Layer]  → ML Models, Testing, CI/CD
Phase 5  [Polish & Deploy]     → Documentation, Demo Deployment, Portfolio Prep
```

---

## Phase 1 — Foundation & Infrastructure

**Goal:** Establish a professional project skeleton with all documentation, coding standards, and synthetic data generation capabilities in place before implementation begins.

**Target Duration:** 2 Weeks
**Exit Milestone:** Professional repository visible on GitHub with complete documentation and a runnable synthetic data generator.

| # | Task | Description | Status |
|---|---|---|---|
| 1.1 | Repository Initialization | Folder structure, `.gitignore`, LICENSE, branch protection rules | 🔵 |
| 1.2 | Documentation Foundation | README, Charter, Roadmap, Architecture, Tech Stack, Coding Standards, DB Design, API Spec, CONTRIBUTING, CHANGELOG | 🔵 |
| 1.3 | Coding Standards & Tooling | `pyproject.toml` (black, ruff, mypy, pytest), `.pre-commit-config.yaml`, `.eslintrc`, `sqlfluff.cfg` | 🔲 |
| 1.4 | Synthetic Data Design | Define statistical distributions and schemas for sensor, production, quality, and maintenance datasets | 🔲 |
| 1.5 | Data Generation Script | Python script generating realistic synthetic datasets (≥ 500K rows across all tables) | 🔲 |
| 1.6 | Database Schema Design | PostgreSQL DDL for operational source tables (`machines`, `production_orders`, `sensor_readings`, `quality_inspections`, `maintenance_logs`) | 🔲 |
| 1.7 | Docker Compose Skeleton | `docker-compose.yml` with service stubs for Postgres (source + warehouse), MinIO, Airflow, FastAPI, React, MLflow, Grafana, Prometheus | 🔲 |
| 1.8 | CI/CD Foundation | GitHub Actions workflow: lint (`ruff`, `black --check`), type-check (`mypy`), and unit test (`pytest`) on every PR | 🔲 |

---

## Phase 2 — Data Layer

**Goal:** Build the complete data pipeline from raw data ingestion through a validated, queryable star schema data warehouse.

**Target Duration:** 3 Weeks
**Exit Milestone:** Clean, queryable warehouse with validated data, complete dbt lineage, and a documented data quality report.

| # | Task | Description | Status |
|---|---|---|---|
| 2.1 | Database Migrations | Alembic migrations creating all operational source tables in the PostgreSQL source DB | 🔲 |
| 2.2 | Data Seeding | Load synthetic datasets into the operational source database | 🔲 |
| 2.3 | ETL Extract Module | Python extractors for each source table using watermark-based incremental extraction | 🔲 |
| 2.4 | ETL Transform Module | Data cleaning, standardization, null handling, and business rule validation logic | 🔲 |
| 2.5 | ETL Load Module | Load Parquet files to MinIO (Bronze) and cleaned records to PostgreSQL staging tables | 🔲 |
| 2.6 | Airflow DAGs | Orchestrate full ETL pipeline; schedule per source (sensor: 15 min, production: 1 hr, quality: 4 hr, maintenance: daily) | 🔲 |
| 2.7 | Warehouse Schema | DDL for star schema — four fact tables (`fct_production`, `fct_quality_inspection`, `fct_sensor_reading`, `fct_maintenance_event`) and six dimension tables | 🔲 |
| 2.8 | dbt Staging Models | `stg_*` models — 1:1 with source tables, light cleaning and column renaming only | 🔲 |
| 2.9 | dbt Intermediate Models | `int_*` models — business logic joins, OEE component derivation, MTBF/MTTR calculations | 🔲 |
| 2.10 | dbt Mart Models | `fct_*` and `dim_*` models — final star schema tables for production, quality, and maintenance domains | 🔲 |
| 2.11 | dbt Tests | Schema tests (not_null, unique, accepted_values, relationships) for all models; minimum 30 tests total | 🔲 |
| 2.12 | Data Quality Suite | Great Expectations expectation suites for all source tables; data docs generated and committed | 🔲 |

---

## Phase 3 — Application Layer

**Goal:** Build the REST API backend and interactive React frontend dashboard, connected end-to-end to the data warehouse.

**Target Duration:** 3 Weeks
**Exit Milestone:** Working web application serving live warehouse data through a documented REST API, with all four dashboard views functional.

| # | Task | Description | Status |
|---|---|---|---|
| 3.1 | FastAPI Project Setup | Application structure, `pydantic-settings` config, health check endpoint, request logging middleware | 🔲 |
| 3.2 | Database ORM Models | SQLAlchemy 2.x models for all warehouse fact and dimension tables | 🔲 |
| 3.3 | KPI API Endpoints | `/kpis/oee`, `/kpis/oee/by-machine`, `/kpis/oee/trend`, `/kpis/dashboard-summary` | 🔲 |
| 3.4 | Production API Endpoints | `/production/summary`, `/production/by-machine`, `/production/by-shift`, `/production/trend`, `/production/orders` | 🔲 |
| 3.5 | Quality API Endpoints | `/quality/summary`, `/quality/pareto`, `/quality/control-chart`, `/quality/trend` | 🔲 |
| 3.6 | Maintenance API Endpoints | `/maintenance/summary`, `/maintenance/events`, `/maintenance/downtime-by-machine`, `/maintenance/reliability-trend` | 🔲 |
| 3.7 | Sensor API Endpoints | `/sensors/latest`, `/sensors/history`, `/sensors/anomalies` | 🔲 |
| 3.8 | ML Inference Endpoints | `/ml/predict/maintenance`, `/ml/detect/anomaly`, `/ml/predict/quality`, `/ml/models` | 🔲 |
| 3.9 | API Authentication | API key authentication via `X-API-Key` header; middleware enforcement | 🔲 |
| 3.10 | API Documentation | Verify Swagger UI at `/docs` and ReDoc at `/redoc` are accurate and complete | 🔲 |
| 3.11 | Frontend Setup | React 18 + Vite project; routing, design system, API client (React Query), global state | 🔲 |
| 3.12 | OEE Dashboard | OEE gauge/waterfall, Availability/Performance/Quality breakdown, time-trend chart, machine comparison | 🔲 |
| 3.13 | Production Dashboard | Throughput trend, planned vs. actual bar chart, shift comparison, top machines by output | 🔲 |
| 3.14 | Quality Dashboard | Defect rate trend, Pareto chart, SPC control chart with UCL/LCL | 🔲 |
| 3.15 | Maintenance Dashboard | Downtime log table, MTBF/MTTR trend, planned vs. unplanned breakdown, failure mode Pareto | 🔲 |
| 3.16 | Frontend Responsiveness | Tablet and desktop responsive layouts (mobile is out of scope) | 🔲 |

---

## Phase 4 — Intelligence Layer

**Goal:** Build, evaluate, and deploy three ML models; complete the test suite; and finalize the CI/CD pipeline.

**Target Duration:** 3 Weeks
**Exit Milestone:** Three trained, MLflow-tracked ML models with documented evaluation reports; ≥ 80% test coverage across ETL and API; automated CI pipeline fully green.

| # | Task | Description | Status |
|---|---|---|---|
| 4.1 | Feature Engineering Pipeline | Reusable feature pipeline for all three ML use cases: rolling window aggregations, lag features, ratio derivations | 🔲 |
| 4.2 | Predictive Maintenance Model | XGBoost binary classifier on sensor + maintenance history features; target: ≥ 85% recall | 🔲 |
| 4.3 | Anomaly Detection Model | Isolation Forest on multivariate sensor data; target: ≥ 90% precision on flagged anomalies | 🔲 |
| 4.4 | Quality Prediction Model | XGBoost regressor predicting defect rate from process parameters; target: RMSE ≤ 0.5% | 🔲 |
| 4.5 | Model Evaluation Reports | Confusion matrix, ROC/PR curve, feature importance, SHAP values for each model | 🔲 |
| 4.6 | MLflow Experiment Tracking | Log all experiments, parameters, metrics, and artifacts; register final models in MLflow Model Registry | 🔲 |
| 4.7 | Model Serialization | Serialize and version trained models; load on API startup from artifact store | 🔲 |
| 4.8 | Unit Tests — ETL | Pytest coverage for all extract, transform, and load functions; target ≥ 80% | 🔲 |
| 4.9 | Unit Tests — API | Pytest coverage for all API endpoint handlers and service functions; target ≥ 80% | 🔲 |
| 4.10 | Integration Tests | End-to-end pipeline tests from source extraction to warehouse mart query | 🔲 |
| 4.11 | CI/CD — Test Pipeline | GitHub Actions: run ruff, black --check, mypy, pytest with coverage report on every PR | 🔲 |
| 4.12 | CI/CD — Build Pipeline | GitHub Actions: Docker build and image push to registry on merge to `main` | 🔲 |

---

## Phase 5 — Polish & Portfolio Deployment

**Goal:** Finalize all documentation, create architecture diagrams, deploy a live demo, and prepare the full portfolio presentation.

**Target Duration:** 1 Week
**Exit Milestone:** Live, publicly accessible demo with comprehensive documentation, architecture diagrams, a video walkthrough, and a published portfolio write-up.

| # | Task | Description | Status |
|---|---|---|---|
| 5.1 | Architecture Diagrams | Create system architecture, data flow, and ERD diagrams; embed in `SYSTEM_ARCHITECTURE.md` and `DATABASE_DESIGN.md` | 🔲 |
| 5.2 | ADR Documentation | Write one ADR per major technology decision (minimum 6 ADRs) in `docs/adr/` | 🔲 |
| 5.3 | Finalize All Docs | Complete any remaining placeholder sections; ensure all docs are current and accurate | 🔲 |
| 5.4 | Notebook Cleanup | Polish EDA and model development notebooks: clear outputs, add markdown narration, structure as a readable report | 🔲 |
| 5.5 | Demo Data Refresh | Regenerate synthetic datasets with production-quality distributions tuned for compelling dashboard visuals | 🔲 |
| 5.6 | Docker Compose Final | Verify one-command `docker compose up` starts the full stack; document the startup sequence | 🔲 |
| 5.7 | Demo Deployment | Deploy to free-tier cloud platform (Render, Railway, or Fly.io) with public URL | 🔲 |
| 5.8 | Video Walkthrough | Record a 5-minute walkthrough video demonstrating the dashboard, API, and ML inference | 🔲 |
| 5.9 | Portfolio Write-Up | Publish a detailed project write-up on LinkedIn or a personal portfolio site | 🔲 |

---

## Future Enhancements (Post v1.0.0)

> These items are tracked for future development but are explicitly out of scope for the initial release. See [PROJECT_CHARTER.md §4.2](./PROJECT_CHARTER.md) for the full out-of-scope list.

| Enhancement | Description | Priority |
|---|---|---|
| Real-time Streaming | Replace batch ETL with Apache Kafka + Flink for true real-time sensor processing (< 1 second latency) | High |
| Cloud Deployment (IaC) | Full AWS / GCP deployment with Terraform-managed infrastructure; migrate warehouse to Snowflake or BigQuery | High |
| SCADA Protocol Simulation | OPC-UA or MQTT broker integration to simulate industrial sensor network connectivity | Medium |
| Advanced ML Models | LSTM or Transformer-based time-series models for predictive maintenance with longer forecast horizons | Medium |
| Multi-Plant Support | Multi-tenant data isolation; plant-vs-plant comparison dashboards | Low |
| Data Catalog Integration | OpenMetadata or DataHub integration for enterprise-grade data discovery and lineage visualization | Low |
| Cost Analytics Layer | Query cost analysis, warehouse compute optimization, and data freshness monitoring | Low |
| Role-Based Access Control | JWT-based authentication with user roles (Admin, Analyst, Viewer) for the dashboard and API | Low |

---

## Progress Summary

| Phase | Tasks Total | Complete | In Progress | Not Started |
|---|---|---|---|---|
| Phase 1 | 8 | 0 | 2 | 6 |
| Phase 2 | 12 | 0 | 0 | 12 |
| Phase 3 | 16 | 0 | 0 | 16 |
| Phase 4 | 12 | 0 | 0 | 12 |
| Phase 5 | 9 | 0 | 0 | 9 |
| **Total** | **57** | **0** | **2** | **55** |

> **Phase 1 active tasks:** 1.1 Repository Initialization (🔵) · 1.2 Documentation Foundation (🔵)

---

*This roadmap is a living document. It is updated when tasks are completed, priorities shift, or scope changes are approved through the governance process in [PROJECT_CHARTER.md](./PROJECT_CHARTER.md).*
