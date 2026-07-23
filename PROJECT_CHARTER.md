# Project Charter — Smart Manufacturing Analytics Platform (SMAP)

**Document Version:** 1.0.0
**Date:** 2026-07-20
**Status:** Draft — Pending Formal Approval
**Owner:** *[Project Owner Name]*
**Approved By:** *[Approver Name]*
**Last Reviewed:** 2026-07-20

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Problem Statement](#2-problem-statement)
3. [Project Objectives](#3-project-objectives)
4. [Scope](#4-scope)
5. [Stakeholders](#5-stakeholders)
6. [Success Criteria](#6-success-criteria)
7. [Deliverables](#7-deliverables)
8. [Assumptions & Constraints](#8-assumptions--constraints)
9. [Risks & Mitigations](#9-risks--mitigations)
10. [Timeline & Milestones](#10-timeline--milestones)
11. [Budget & Resources](#11-budget--resources)
12. [Governance](#12-governance)
13. [Sign-Off](#13-sign-off)

---

## 1. Executive Summary

The **Smart Manufacturing Analytics Platform (SMAP)** is a full-stack data and analytics platform engineered to transform raw manufacturing operations data into actionable operational intelligence. The platform consolidates sensor telemetry, production records, quality inspection logs, and maintenance events into a unified, governed analytical system that supports real-time monitoring, KPI reporting, and predictive machine learning capabilities.

Manufacturing operations routinely generate terabytes of sensor and operational data that remain largely unutilized because they are locked in disconnected source systems with no common analytical layer. SMAP addresses this by building a modern data platform — using industry-standard open-source tooling — that ingests, cleans, models, and serves this data through interactive dashboards and a REST API.

The platform is designed to demonstrate the full breadth of a production-quality data engineering engagement: from raw data ingestion through Apache Airflow-orchestrated ETL pipelines and dbt-managed transformations, to ML model serving via FastAPI and visualization through a React-based analytics dashboard. All architecture decisions are made with cloud portability in mind — the local PostgreSQL warehouse is designed to be schema-compatible with Snowflake and BigQuery for future migration.

This project serves dual purposes: it is a functioning analytical system for the manufacturing domain, and a portfolio-quality showcase of enterprise data engineering, analytics engineering, and applied machine learning practices.

---

## 2. Problem Statement

### 2.1 Current State

Manufacturing facilities operating without a unified analytical platform face a consistent set of operational challenges:

- **Siloed source systems:** Data from SCADA, MES, ERP, and quality management systems is captured independently. No single system provides a unified operational view, and cross-system analysis requires manual extraction and reconciliation.
- **Delayed, manual reporting:** Production KPIs — OEE, throughput, scrap rate, MTBF — are compiled manually in spreadsheets, often 24–48 hours after the relevant shift or production run closes. By the time reports reach decision-makers, conditions on the floor have changed.
- **Reactive maintenance posture:** Equipment failures are addressed after they occur. Without predictive signals derived from sensor telemetry and maintenance history, maintenance teams cannot prioritize resources toward machines with the highest failure risk.
- **No governed data layer:** Inconsistent data quality across source systems makes it impractical to build reliable ML models or trust aggregate KPI calculations. There is no single source of truth.
- **Inaccessible to analysts:** Data is locked in operational databases, accessible only to IT personnel with database access. Business analysts and operational managers cannot perform self-service analysis.

### 2.2 Desired Future State

After SMAP is deployed:

- A unified data warehouse provides a single, trusted source of truth for all operational metrics, populated automatically by scheduled ETL pipelines.
- Real-time and near-real-time dashboards deliver OEE, throughput, quality, and maintenance KPIs to floor managers and executives without manual compilation.
- Predictive ML models surface equipment failure risk and quality deviation signals before they become incidents, enabling proactive maintenance scheduling.
- Automated data quality validation prevents untrusted data from advancing into the analytical layer.
- Analysts can query the warehouse directly or consume data through the REST API without requiring IT intervention.

### 2.3 Gap Analysis

| Dimension | Current State | Future State (SMAP) |
|---|---|---|
| Data Access | Siloed across SCADA, MES, ERP, QMS | Unified warehouse with governed schemas |
| Reporting Speed | Days (manual, Excel-based) | Real-time to hourly (automated pipelines) |
| Predictive Capability | None — fully reactive | ML-driven failure and quality forecasts |
| Data Quality | Inconsistent, unvalidated | Great Expectations validation at ingestion |
| Accessibility | IT-dependent database access | Self-service via dashboard and REST API |
| Auditability | Ad-hoc, undocumented | Versioned dbt lineage and changelog |

---

## 3. Project Objectives

### 3.1 Primary Objectives

The following objectives are **Specific, Measurable, Achievable, Relevant, and Time-Bound**:

1. **Build a scalable ETL pipeline** that ingests data from at least four source system tables (sensors, production orders, quality inspections, maintenance logs) using incremental, watermark-based extraction — completing each pipeline run within 10 minutes.
2. **Implement a star schema data warehouse** containing at least four fact tables and six dimension tables, populated and tested by a dbt project with a minimum of 30 schema tests.
3. **Deliver an OEE dashboard** with sub-5-second initial load time, displaying overall OEE, its three components (Availability, Performance, Quality), and a time-trend chart.
4. **Train and deploy three ML models** — predictive maintenance (≥ 85% recall), anomaly detection (≥ 90% precision), and quality prediction (RMSE ≤ 0.5%) — tracked in MLflow and served through FastAPI endpoints.
5. **Achieve ≥ 80% unit test coverage** across the ETL and API layers as measured by `pytest-cov`.

### 3.2 Secondary Objectives

1. Document all major technology and architecture decisions as Architecture Decision Records (ADRs) stored in `docs/adr/`.
2. Containerize all platform services using Docker Compose, enabling a reproducible one-command local startup: `docker compose up`.
3. Implement a CI/CD pipeline via GitHub Actions that runs linting, type checking, and the full test suite on every pull request.
4. Produce polished Jupyter notebooks for exploratory data analysis and model development, suitable for portfolio review.
5. Maintain all documentation in a current, accurate state throughout development — updating docs as part of each feature's definition of done.

---

## 4. Scope

### 4.1 In Scope

The following capabilities are explicitly included in the SMAP v1.0.0 release:

- [x] Data ingestion from synthetically generated sensor, production, quality, and maintenance datasets
- [x] Incremental ETL pipeline with watermark-based change detection, orchestrated by Apache Airflow
- [x] MinIO object storage (Bronze/Raw zone) for Parquet-format raw data
- [x] PostgreSQL operational database (simulated source system) and PostgreSQL data warehouse (star schema)
- [x] dbt transformation layer: sources → staging → intermediate → marts
- [x] Great Expectations data quality validation suite
- [x] FastAPI REST API with authentication, OpenAPI documentation, and versioning
- [x] React-based frontend dashboard with four analytical views (OEE, Production, Quality, Maintenance)
- [x] Three ML models with MLflow experiment tracking and FastAPI inference endpoints
- [x] Docker Compose configuration for complete local deployment
- [x] GitHub Actions CI/CD pipeline (lint, type-check, test, build)
- [x] Comprehensive documentation suite (this charter, architecture, tech stack, coding standards, API spec, database design)

### 4.2 Out of Scope

The following are explicitly excluded from the SMAP v1.0.0 release:

- Physical sensor integration via MQTT, OPC-UA, or other industrial protocols (synthetic data only)
- Live ERP system integration (simulated datasets only)
- Mobile application (web dashboard only)
- Multi-tenant authentication and role-based access control (single fixed API key for portfolio demo)
- Production cloud deployment with infrastructure-as-code (Terraform, CDK) — local Docker only
- Real-time streaming pipeline (Kafka/Flink) — batch ETL only in v1.0.0

---

## 5. Stakeholders

| Role | Name | Responsibility | Engagement Level |
|---|---|---|---|
| Project Owner | *[Name]* | Defines vision, priorities, and scope decisions | High |
| Data Engineer | *[Name]* | Builds ETL pipelines, data lake, and warehouse schema | High |
| Analytics Engineer | *[Name]* | Owns dbt transformations, data modeling, and documentation | High |
| ML Engineer | *[Name]* | Develops and evaluates ML models; manages MLflow experiments | Medium |
| Frontend Developer | *[Name]* | Builds React dashboard and chart components | Medium |
| Portfolio Reviewer | Recruiter / Hiring Manager | Evaluates project quality, code standards, and documentation | External |

---

## 6. Success Criteria

### 6.1 Technical Success Criteria

| Criterion | Target | Measurement Method |
|---|---|---|
| ETL pipeline execution time | < 10 minutes per full pipeline run | Airflow DAG execution log |
| Data warehouse row count | ≥ 500,000 rows across all fact tables | Direct warehouse query |
| dbt test pass rate | 100% — all schema tests green | `dbt test` output |
| API response time (p95) | < 200 ms for all non-ML endpoints | Prometheus / API metrics |
| API response time (p95, ML) | < 1,000 ms for inference endpoints | Prometheus / API metrics |
| Unit test coverage | ≥ 80% across ETL and API layers | `pytest-cov` report |
| Predictive maintenance recall | ≥ 85% | MLflow evaluation metrics |
| Anomaly detection precision | ≥ 90% | MLflow evaluation metrics |
| Quality prediction RMSE | ≤ 0.5% defect rate error | MLflow evaluation metrics |
| OEE dashboard load time | < 5 seconds (initial render) | Browser developer tools |

### 6.2 Documentation and Portfolio Success Criteria

| Criterion | Target |
|---|---|
| All Markdown documents | Complete — zero unfilled placeholder sections |
| README | Comprehensive, professional, and self-contained for a first-time visitor |
| API documentation | All endpoints documented with request/response examples |
| dbt documentation | All models and columns described in `schema.yml` |
| Code comments | Complex business logic documented with inline comments explaining *why* |
| Live demo | Accessible environment with realistic synthetic data |

---

## 7. Deliverables

| # | Deliverable | Description | Target Phase |
|---|---|---|---|
| D1 | Repository Foundation | Folder structure, all Markdown documentation, `.gitignore`, LICENSE | Phase 1 |
| D2 | Synthetic Datasets | Realistic synthetic data for sensors, production, quality, and maintenance | Phase 1 |
| D3 | ETL Pipeline | Working Airflow DAGs with extract, validate, transform, and load stages | Phase 2 |
| D4 | Data Warehouse | PostgreSQL star schema + complete dbt project with tests and documentation | Phase 2 |
| D5 | REST API | FastAPI application with all documented endpoints, auth, and OpenAPI spec | Phase 3 |
| D6 | Frontend Dashboard | React application with OEE, Production, Quality, and Maintenance views | Phase 3 |
| D7 | ML Models | Three trained, evaluated, and MLflow-tracked models with inference endpoints | Phase 4 |
| D8 | CI/CD Pipeline | GitHub Actions workflows for lint, test, and build on every PR | Phase 4 |
| D9 | Final Documentation | All docs finalized, architecture diagrams embedded, ADRs written | Phase 5 |
| D10 | Live Demo | Deployed, publicly accessible demo with video walkthrough | Phase 5 |

---

## 8. Assumptions & Constraints

### 8.1 Assumptions

| # | Assumption | Impact if False |
|---|---|---|
| A1 | All manufacturing data will be synthetically generated using realistic statistical distributions modeled on published manufacturing benchmarks | Scope increase if real data sourcing is required |
| A2 | Development will use a local Docker-based environment — no paid cloud infrastructure required | Budget impact if cloud services become necessary |
| A3 | Primary audience for portfolio review comprises technical evaluators in data engineering, analytics engineering, or ML engineering roles | Documentation style and technical depth may need adjustment |
| A4 | All open-source tools selected (Airflow, dbt, PostgreSQL, FastAPI, React, MLflow) remain actively maintained and freely available under their current licenses | Technology selection may need to be revisited |
| A5 | Python 3.11 and Node.js 20 LTS remain the stable, widely supported versions throughout the project lifecycle | Minor version updates may be required |

### 8.2 Constraints

| # | Constraint | Type | Impact |
|---|---|---|---|
| C1 | No budget — all tools must be open-source or free tier | Budget | Technology selection limited to open-source stack |
| C2 | Development occurs on a local machine without access to enterprise hardware | Infrastructure | Dataset size and performance targets calibrated accordingly |
| C3 | Solo developer — all disciplines (DE, AE, ML, BE, FE) covered by one person | Resource | Phase timeline assumes sequential, not parallel, development |
| C4 | Project must remain publicly accessible on GitHub — no proprietary or sensitive data | Compliance | Synthetic data only; no real operational datasets |
| C5 | All deliverables must be completable within the 12-week timeline | Schedule | Scope ruthlessly enforced; out-of-scope items deferred |

---

## 9. Risks & Mitigations

| # | Risk | Probability | Impact | Mitigation Strategy |
|---|---|---|---|---|
| R1 | Scope creep — features grow beyond Phase 1–5 plan | High | Medium | Strictly enforce in-scope/out-of-scope list; defer all additions to a post-v1.0 backlog |
| R2 | Technical complexity — Airflow or dbt configuration issues consume excessive time | Medium | High | Time-box troubleshooting at 4 hours; fall back to simpler alternatives (e.g., cron + plain SQL) for non-portfolio-critical components |
| R3 | Documentation debt — docs fall behind implementation | High | Medium | Documentation is part of each feature's definition of done — no feature is complete until its corresponding doc section is updated |
| R4 | Synthetic data quality — generated data does not reflect realistic manufacturing patterns | Low | High | Research published manufacturing benchmarks (OEE industry averages, failure rate distributions, defect category distributions) before generating data |
| R5 | Outdated or breaking dependency changes | Medium | Low | Pin all dependency versions in `requirements.txt` and `package.json`; use Dependabot for automated update PRs |
| R6 | ML model performance targets not achievable on synthetic data | Low | Medium | Adjust data generation parameters to produce learnable patterns; lower targets are acceptable if documented with analysis |

---

## 10. Timeline & Milestones

| Phase | Name | Key Activities | Target Duration | Exit Milestone |
|---|---|---|---|---|
| Phase 1 | Foundation & Infrastructure | Repository setup, all documentation, synthetic data generation scripts, Docker skeleton, CI foundation | 2 weeks | Professional repository live on GitHub with complete documentation |
| Phase 2 | Data Layer | ETL pipelines (Airflow DAGs), database migrations, dbt models and tests, Great Expectations validation suite | 3 weeks | Clean, queryable warehouse with validated data and documented dbt lineage |
| Phase 3 | Application Layer | FastAPI REST API, all endpoints, React dashboard with four views, frontend-API integration | 3 weeks | Working web application with live warehouse data, served via REST API |
| Phase 4 | Intelligence Layer | Three ML models (train, evaluate, serialize), MLflow tracking, full test suite, CI/CD pipeline | 3 weeks | Three deployed models; ≥ 80% test coverage; CI pipeline green |
| Phase 5 | Polish & Portfolio Deployment | Architecture diagrams, doc finalization, demo deployment, video walkthrough, portfolio write-up | 1 week | Live, publicly accessible demo with portfolio-quality documentation |

**Full delivery roadmap:** See [ROADMAP.md](./ROADMAP.md)

---

## 11. Budget & Resources

### 11.1 Technology Budget

All tools selected for SMAP are open-source or free-tier, resulting in zero licensing cost:

| Tool | License | Cost |
|---|---|---|
| Python, PostgreSQL, MinIO | Open Source | $0 |
| Apache Airflow, dbt Core | Apache 2.0 | $0 |
| FastAPI, Uvicorn, SQLAlchemy | MIT / BSD | $0 |
| React, Recharts, Chart.js | MIT | $0 |
| scikit-learn, XGBoost, MLflow | BSD / Apache 2.0 | $0 |
| Docker Desktop (personal use) | Free (non-commercial) | $0 |
| GitHub (public repository) | Free tier | $0 |
| **Total** | | **$0** |

Optional cloud deployment (Phase 5) will target free-tier platforms (Render, Railway, or Fly.io) to maintain zero cost.

### 11.2 Time Budget

| Phase | Estimated Hours | Notes |
|---|---|---|
| Phase 1 | 20–25 hours | Documentation is the primary deliverable |
| Phase 2 | 40–50 hours | ETL and dbt are the most complex components |
| Phase 3 | 35–45 hours | API and frontend development in parallel |
| Phase 4 | 35–45 hours | ML work, testing, CI/CD |
| Phase 5 | 10–15 hours | Polish, deployment, portfolio prep |
| **Total** | **140–180 hours** | Approximately 12 weeks at 12–15 hours/week |

---

## 12. Governance

### 12.1 Decision Authority

All technical, scope, and prioritization decisions are made by the project owner (sole developer). Significant architectural changes require:

1. A GitHub Issue opened to document the proposed change and its rationale
2. An Architecture Decision Record (ADR) written and committed to `docs/adr/` before implementation begins
3. Updates to the affected documentation files (`TECH_STACK.md`, `SYSTEM_ARCHITECTURE.md`, etc.) in the same commit or PR as the change

### 12.2 Change Management

The process for proposing and approving scope changes:

1. Open a GitHub Issue with the label `scope-change`; document the proposed change, its motivation, and its impact on timeline and deliverables
2. Assess whether the change is truly in scope for v1.0.0 or should be deferred to the post-v1.0 backlog
3. If approved: update this charter, `ROADMAP.md`, and `CHANGELOG.md`; update or create ADR if an architecture decision is involved
4. If deferred: add to the **Future Enhancements** section of `ROADMAP.md`

### 12.3 Progress Tracking

- **GitHub Projects board** — task-level tracking across all phases
- **ROADMAP.md** — phase and milestone status updated on task completion
- **CHANGELOG.md** — updated with every completed feature or deliverable, following Keep a Changelog conventions
- **Weekly self-review** — assess progress against the current phase milestone; adjust scope or timeline as needed

---

## 13. Sign-Off

> In a formal project context, this section contains explicit approval signatures from all accountable parties, indicating they have reviewed this charter and accept its scope, objectives, and constraints.

| Role | Name | Date | Status |
|---|---|---|---|
| Project Owner | *[Name]* | *[Date]* | Pending |
| Technical Lead | *[Name]* | *[Date]* | Pending |

---

*This charter is a living document. It is reviewed and updated at the start of each phase to reflect scope refinements, resolved risks, and timeline adjustments. All material changes are recorded in `CHANGELOG.md`.*
