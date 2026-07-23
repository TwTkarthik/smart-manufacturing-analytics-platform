# Business Domain Documentation — Index

**Directory:** `docs/`
**Last Updated:** 2026-07-22

This directory contains the complete **business domain documentation** for the Smart Manufacturing Analytics Platform (SMAP). These documents define the business context, manufacturing processes, operational challenges, KPI framework, data sources, and business vocabulary that underpin all analytics, data models, and ML capabilities built on the platform.

---

## Document Index

| Document | Purpose | Phase |
|---|---|---|
| [COMPANY_PROFILE.md](./COMPANY_PROFILE.md) | Company identity, factory locations, products, departments, and strategic business goals | Phase 1 |
| [MANUFACTURING_PROCESS.md](./MANUFACTURING_PROCESS.md) | End-to-end production workflow, production lines, machines, operators, sensors, maintenance, and quality inspection | Phase 1 |
| [BUSINESS_PROBLEMS.md](./BUSINESS_PROBLEMS.md) | Six operational problems addressed by SMAP, with quantified impact and desired future state | Phase 1 |
| [KPI_DEFINITIONS.md](./KPI_DEFINITIONS.md) | Authoritative definitions, formulas, targets, and metadata for all 11+ KPIs tracked in SMAP | Phase 1 |
| [DATA_SOURCES.md](./DATA_SOURCES.md) | Seven source systems (ERP, MES, IoT/SCADA, Maintenance, Quality, Inventory, HR) with integration details | Phase 1 |
| [BUSINESS_GLOSSARY.md](./BUSINESS_GLOSSARY.md) | Canonical definitions for all business and technical terms used across the SMAP project | Phase 1 |

---

## Reading Order

For first-time readers approaching the SMAP business domain:

1. **[COMPANY_PROFILE.md](./COMPANY_PROFILE.md)** — Start here. Understand who PrecisionEdge is and what they need.
2. **[MANUFACTURING_PROCESS.md](./MANUFACTURING_PROCESS.md)** — Understand how the factory operates end-to-end.
3. **[BUSINESS_PROBLEMS.md](./BUSINESS_PROBLEMS.md)** — Understand what is broken and why it matters (quantified impact).
4. **[KPI_DEFINITIONS.md](./KPI_DEFINITIONS.md)** — Understand how success is measured (exact formulas and targets).
5. **[DATA_SOURCES.md](./DATA_SOURCES.md)** — Understand where the data comes from and how it is integrated.
6. **[BUSINESS_GLOSSARY.md](./BUSINESS_GLOSSARY.md)** — Reference for any unfamiliar term encountered anywhere in the project.

---

## Relationship to Root-Level Documentation

These business domain documents complement the technical documentation at the repository root:

| Root Document | Relationship |
|---|---|
| [README.md](../README.md) | High-level project overview; references these domain docs for business context |
| [PROJECT_CHARTER.md](../PROJECT_CHARTER.md) | Project scope and objectives; the *why* for SMAP |
| [SYSTEM_ARCHITECTURE.md](../SYSTEM_ARCHITECTURE.md) | Technical architecture; *how* the platform is built |
| [DATABASE_DESIGN.md](../DATABASE_DESIGN.md) | Data warehouse schema; the data model that implements these KPIs |
| [API_SPECIFICATION.md](../API_SPECIFICATION.md) | REST API contract; the endpoints that serve these KPIs |

---

*All documents in this directory are living specifications. They are updated when business requirements change, new KPIs are added, or source system integrations are modified. All changes are recorded in [CHANGELOG.md](../CHANGELOG.md).*
