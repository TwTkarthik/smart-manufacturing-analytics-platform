# AI_CONTEXT.md

## Project Name
Smart Manufacturing Analytics Platform (SMAP)

## Project Vision
The Smart Manufacturing Analytics Platform (SMAP) is an enterprise-grade end-to-end data engineering and analytics project designed to simulate a real-world manufacturing company's modern data platform.

The objective is to demonstrate production-level skills in Data Engineering, Analytics Engineering, Backend Development, Cloud-ready Architecture, and Machine Learning using synthetic manufacturing data.

This project is intended as a professional portfolio project.

---

# Company

PrecisionEdge Manufacturing Ltd.

Industry:
Automotive Tier-2 Manufacturing

Business:
Manufactures precision automotive components using CNC machines, assembly lines, quality inspection stations, warehouses, and logistics.

---

# Architecture

Source Systems
↓

Synthetic Data Platform

↓

PostgreSQL OLTP Database

↓

ETL Pipelines

↓

Data Warehouse (Star Schema)

↓

dbt Models

↓

Analytics SQL

↓

Power BI Dashboards

↓

Machine Learning

↓

FastAPI Backend

↓

React Dashboard

↓

Docker Deployment

---

# Tech Stack

Programming
- Python 3.12
- SQL

Database
- PostgreSQL

Data Engineering
- SQLAlchemy
- Pandas
- NumPy
- Faker
- dbt

Backend
- FastAPI

Frontend
- React
- TypeScript

Visualization
- Power BI

Machine Learning
- Scikit-learn
- XGBoost

Deployment
- Docker

Version Control
- Git
- GitHub

---

# Coding Standards

- Python 3.12
- Type hints everywhere
- Modular architecture
- Configuration-driven
- Production-ready code
- Comprehensive logging
- Error handling
- Unit tests
- No hardcoded values
- PEP8 compliant

---

# Folder Philosophy

Each module should be independent.

Each folder must contain:

README.md (if needed)

tests/

config/

logs/

output/

No monolithic scripts.

---

# Design Principles

Enterprise-first

Scalable

Maintainable

Reusable

Well documented

Configuration driven

Production ready

---

# AI Instructions

Before generating code:

1. Read PROJECT_STATE.md
2. Continue only the current sprint.
3. Never rewrite completed modules.
4. Preserve folder structure.
5. Preserve coding standards.
6. Maintain modular architecture.
7. Prefer readability over cleverness.
8. Every new module must integrate with existing modules.

---

This repository is the single source of truth.