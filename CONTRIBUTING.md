# 🤝 Contributing Guide — Smart Manufacturing Analytics Platform (SMAP)

**Document Version:** 1.0.0
**Last Updated:** 2026-07-20

---

## 📋 Table of Contents

1. [Welcome](#1-welcome)
2. [Code of Conduct](#2-code-of-conduct)
3. [Getting Started](#3-getting-started)
4. [Development Environment Setup](#4-development-environment-setup)
5. [Repository Structure](#5-repository-structure)
6. [Branching Strategy](#6-branching-strategy)
7. [Making Changes](#7-making-changes)
8. [Commit Message Standards](#8-commit-message-standards)
9. [Pull Request Process](#9-pull-request-process)
10. [Coding Standards](#10-coding-standards)
11. [Testing Requirements](#11-testing-requirements)
12. [Documentation Requirements](#12-documentation-requirements)
13. [Issue Reporting](#13-issue-reporting)
14. [Feature Requests](#14-feature-requests)
15. [Review Process](#15-review-process)

---

## 1. Welcome

Thank you for your interest in contributing to the Smart Manufacturing Analytics Platform (SMAP). This guide describes the standards, processes, and expectations for contributing code, documentation, or ideas to this project.

> **Note:** This is primarily a portfolio project. Contributions should align with the project's purpose of demonstrating professional data engineering and analytics practices.

---

## 2. Code of Conduct

All contributors are expected to:

- Communicate respectfully and professionally at all times
- Provide constructive, specific feedback in code reviews
- Assume good intent from other contributors
- Focus criticism on code, not the person

Any disrespectful or harassing behavior will result in removal from the project.

---

## 3. Getting Started

### 3.1 Prerequisites

Before contributing, ensure you have the following installed:

> **Placeholder** — List all required tools and versions:
> - Git 2.40+
> - Python 3.11+
> - Docker Desktop 24+
> - Docker Compose v2
> - Node.js 20+ (for frontend)
> - `make` (optional but recommended)

### 3.2 Fork and Clone

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/<your-username>/smart-manufacturing-analytics.git
cd smart-manufacturing-analytics

# Add the upstream remote
git remote add upstream https://github.com/<original-owner>/smart-manufacturing-analytics.git
```

---

## 4. Development Environment Setup

> **Placeholder** — Step-by-step instructions for getting a local development environment running:

### 4.1 Environment Variables

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env with your local values
# DO NOT commit .env — it is in .gitignore
```

### 4.2 Start Services with Docker

```bash
# Start all services
docker compose up -d

# Verify all containers are healthy
docker compose ps
```

### 4.3 Install Python Dependencies

```bash
# Create and activate a virtual environment
python -m venv .venv
source .venv/bin/activate    # Linux/macOS
.venv\Scripts\activate       # Windows

# Install all dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt
```

### 4.4 Set Up Pre-commit Hooks

```bash
# Install pre-commit hooks (runs linters before every commit)
pre-commit install
```

### 4.5 Run Database Migrations

```bash
# Apply database migrations
alembic upgrade head

# Load seed data
python scripts/setup/seed_database.py
```

### 4.6 Verify Setup

```bash
# Run the test suite to verify the environment is working
pytest testing/unit/ -v

# Start the API server
uvicorn backend.main:app --reload --port 8000

# Start the frontend (separate terminal)
cd frontend && npm install && npm run dev
```

---

## 5. Repository Structure

> **Placeholder** — Brief summary of key directories relevant to contributors. Full structure is documented in [README.md](./README.md).

```
smart-manufacturing-analytics/
├── backend/       ← FastAPI backend — API routes, services, models
├── etl/           ← ETL pipeline — extract, transform, load modules
├── warehouse/dbt/ ← dbt project — SQL transformation models
├── ml/            ← Machine learning — feature engineering, training
├── frontend/      ← React dashboard
├── testing/       ← Pytest test suite
└── docs/          ← Additional documentation
```

---

## 6. Branching Strategy

We use a **trunk-based development** approach with short-lived feature branches.

```
main             ← Protected. Production-ready only. No direct commits.
└── develop      ← Integration branch. Merge PRs here.
    ├── feature/ISSUE-42-add-oee-endpoint
    ├── fix/ISSUE-55-null-handling-in-oee-calc
    ├── docs/ISSUE-60-update-api-spec
    └── refactor/ISSUE-71-extract-db-session-dependency
```

### Branch Naming Rules

| Type | Pattern | Example |
|---|---|---|
| Feature | `feature/ISSUE-{n}-{short-desc}` | `feature/ISSUE-42-add-oee-endpoint` |
| Bug Fix | `fix/ISSUE-{n}-{short-desc}` | `fix/ISSUE-55-null-in-oee-calc` |
| Documentation | `docs/ISSUE-{n}-{short-desc}` | `docs/ISSUE-60-update-api-spec` |
| Refactoring | `refactor/ISSUE-{n}-{short-desc}` | `refactor/ISSUE-71-db-session` |
| Data/ETL | `data/ISSUE-{n}-{short-desc}` | `data/ISSUE-80-sensor-pipeline` |

---

## 7. Making Changes

### 7.1 Sync with Upstream Before Starting

```bash
git fetch upstream
git checkout develop
git merge upstream/develop
```

### 7.2 Create Your Branch

```bash
git checkout -b feature/ISSUE-42-add-oee-endpoint
```

### 7.3 Make Your Changes

> **Placeholder** — Development workflow:
> - Write code following [CODING_STANDARDS.md](./CODING_STANDARDS.md)
> - Write tests alongside code (not after)
> - Update documentation as you go
> - Run linting frequently: `ruff check . --fix && black .`
> - Run tests frequently: `pytest testing/unit/ -v`

### 7.4 Stage and Commit

```bash
# Stage changes
git add -p  # Review each change before staging (recommended)

# Commit with a conventional commit message
git commit -m "feat(api): add OEE calculation endpoint with machine-level breakdown"
```

---

## 8. Commit Message Standards

All commits must follow the **Conventional Commits** specification.

### Format

```
<type>(<scope>): <short summary in present tense, max 72 chars>

[Optional body — explain WHY, not what]

[Optional footer: Closes #42, Refs #38]
```

### Types

| Type | Usage |
|---|---|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code change with no behavior change |
| `test` | New or updated tests |
| `chore` | Build system, CI, dependency updates |
| `perf` | Performance improvement |
| `data` | Dataset or dbt model change |
| `style` | Formatting-only change |

### Examples

```
feat(etl): add incremental extraction with watermark tracking

Replaces full-extract pattern with watermark-based approach.
Reduces average extraction time by ~80% for large sensor tables.

Closes #42

---

fix(api): handle empty result set in OEE calculation

Previously raised UnboundLocalError when no production records
found in the date range. Now returns zero-value OEE object.

Closes #55

---

docs(api-spec): document ML inference endpoints
```

---

## 9. Pull Request Process

### 9.1 Before Opening a PR

- [ ] All CI checks pass locally (`pytest`, `ruff`, `black --check`, `mypy`)
- [ ] New tests written for all new logic
- [ ] Coverage has not decreased
- [ ] Documentation updated (if feature changes user-facing behavior)
- [ ] CHANGELOG.md updated with an `[Unreleased]` entry
- [ ] Branch is up to date with `develop`

### 9.2 PR Title

PR titles must follow Conventional Commits format:

```
feat(api): add machine-level OEE breakdown endpoint
```

### 9.3 PR Description Template

> **Placeholder** — A PR template will be created at `.github/pull_request_template.md`.

Required sections:
- **What does this PR do?** — 2–3 sentence summary
- **Linked Issue:** `Closes #42`
- **Type of change:** Feature / Bug Fix / Docs / Refactor
- **How was this tested?** — Describe manual and automated testing
- **Checklist** — Self-review checklist

### 9.4 PR Rules

- PRs target `develop`, not `main`
- Maximum 400 lines changed per PR (split larger changes)
- All review comments must be resolved before merge
- Squash merge preferred to keep `develop` history clean

---

## 10. Coding Standards

All code must comply with [CODING_STANDARDS.md](./CODING_STANDARDS.md). Key requirements:

- Python: type hints, Google-style docstrings, `black` + `ruff` formatting
- SQL: uppercase keywords, leading commas, named columns only (no `SELECT *`)
- dbt: standard model prefixes (`stg_`, `fct_`, `dim_`), schema.yml required
- JavaScript: ESLint + Prettier, functional components, PropTypes
- Git: Conventional Commits, issue-linked branches

---

## 11. Testing Requirements

> All code changes must maintain or improve test coverage.

| Change Type | Required Tests |
|---|---|
| New ETL function | Unit test with mock data |
| New API endpoint | Pytest test for happy path + error cases |
| New dbt model | dbt schema test (not_null, unique at minimum) |
| New ML feature | Unit test for output shape and dtype |
| Bug fix | Regression test that fails before the fix |

Run the full test suite before submitting:

```bash
pytest testing/ -v --cov=backend --cov=etl --cov-report=term-missing
```

---

## 12. Documentation Requirements

| Change | Documentation Required |
|---|---|
| New API endpoint | Update `API_SPECIFICATION.md` |
| New database table | Update `DATABASE_DESIGN.md` |
| New technology added | Update `TECH_STACK.md` |
| New environment variable | Update `.env.example` |
| Any user-visible change | Update `README.md` relevant section |
| Every PR | Update `CHANGELOG.md` under `[Unreleased]` |

---

## 13. Issue Reporting

### Bug Reports

> **Placeholder** — Reference `.github/ISSUE_TEMPLATE/bug_report.md`

A bug report must include:
- **Expected behavior** — What should happen?
- **Actual behavior** — What actually happens?
- **Steps to reproduce** — Minimal reproducible example
- **Environment** — OS, Docker version, Python version
- **Logs** — Relevant error messages or stack traces

### Good Bug Title Examples

```
✅ [ETL] Sensor extraction fails with KeyError when machine_id is null
✅ [API] OEE endpoint returns 500 when date range exceeds 365 days
❌ "It doesn't work"
❌ "Bug in production"
```

---

## 14. Feature Requests

Before opening a feature request:
1. Check the [ROADMAP.md](./ROADMAP.md) — it may already be planned
2. Search existing GitHub Issues for duplicates
3. Open an issue with the `enhancement` label

Feature request must include:
- **Problem statement** — What problem does this solve?
- **Proposed solution** — High-level description of the feature
- **Alternatives considered** — What other approaches were considered?
- **Impact** — Which layers/modules are affected?

---

## 15. Review Process

### Reviewer Responsibilities

When reviewing PRs:
- Provide specific, actionable feedback (not just "this is wrong")
- Distinguish between blocking issues and suggestions
- Use GitHub suggestions for small code changes
- Approve only when all issues are resolved

### Author Responsibilities

When receiving reviews:
- Respond to every comment (resolve or reply with explanation)
- Do not force-push after review unless requested
- Tag reviewers when all comments are addressed

### Review Timeline

> **Placeholder** — For a solo project, self-review within 24 hours before merge.

---

*Thank you for contributing to SMAP. Well-crafted contributions that meet these standards help demonstrate the professional engineering practices this portfolio project is designed to showcase.*
