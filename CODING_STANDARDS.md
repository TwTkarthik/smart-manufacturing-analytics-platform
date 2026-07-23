# Coding Standards — Smart Manufacturing Analytics Platform (SMAP)

**Document Version:** 1.0.0
**Last Updated:** 2026-07-20
**Status:** Approved — Mandatory for All Contributors
**Owner:** Project Lead

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [General Principles](#2-general-principles)
3. [Python Standards](#3-python-standards)
4. [SQL Standards](#4-sql-standards)
5. [dbt Standards](#5-dbt-standards)
6. [JavaScript / React Standards](#6-javascript--react-standards)
7. [Git & Version Control Standards](#7-git--version-control-standards)
8. [Documentation Standards](#8-documentation-standards)
9. [Testing Standards](#9-testing-standards)
10. [Configuration & Secrets Management](#10-configuration--secrets-management)
11. [Tooling Configuration](#11-tooling-configuration)
12. [Code Review Checklist](#12-code-review-checklist)

---

## 1. Introduction

This document defines the coding standards, style guides, and engineering practices for the SMAP project. Adherence to these standards ensures that all code is readable, maintainable, testable, and reflects the professional engineering practices expected in senior data engineering and analytics roles.

> **Rule:** All code submitted to this repository must pass automated linting, formatting, and type-checking as defined in the CI/CD pipeline. A pull request with failing CI checks will not be merged.

These standards apply to all contributors across all layers: Python (ETL, API, ML), SQL (dbt models, raw queries), JavaScript/React (frontend), and Markdown (documentation).

---

## 2. General Principles

### 2.1 Readability Over Cleverness

Write code that a mid-level engineer can understand without explanation. Avoid overly compact or "clever" constructs when a more explicit, readable form is available. The primary audience for the code is the next person who reads it — which is often yourself, three months later.

### 2.2 Explicit Over Implicit

Be explicit about types, configurations, and logic flow. Avoid:
- Magic numbers — use named constants or configuration values
- Implicit defaults — specify defaults explicitly in function signatures
- Global mutable state — use dependency injection or explicit parameter passing

### 2.3 Fail Fast & Loud

Errors must surface immediately with descriptive, actionable messages. Silent failures — swallowed exceptions, empty catch blocks, logging-and-continuing on unrecoverable errors — are architectural defects. Use:
- Type hints and `mypy` to catch type errors at development time
- `pydantic` validation at all external input boundaries (API request bodies, environment config)
- Explicit assertions at layer boundaries (e.g., assert DataFrame has expected columns after extraction)

### 2.4 DRY — Don't Repeat Yourself

Shared logic belongs in utility functions or base classes, not duplicated across modules. Apply the **Rule of Three**: abstract shared logic only after the third repetition. Premature abstraction produces complexity without benefit.

### 2.5 YAGNI — You Aren't Gonna Need It

Do not build features, abstractions, or generalization speculatively. Implement what is required for the current phase. Refactor when the actual need for abstraction is demonstrated by repeated use, not anticipated need.

---

## 3. Python Standards

### 3.1 Language Version

- **Required:** Python 3.11+
- Use modern Python syntax where appropriate: structural pattern matching (`match`), `tomllib` for TOML parsing, `ExceptionGroup` for error aggregation

### 3.2 Code Formatting

| Tool | Rule | Config |
|---|---|---|
| **black** | Auto-format all Python files; line length: 88 characters | `pyproject.toml` |
| **ruff** | Linting — replaces flake8, isort, pyupgrade; zero warnings to merge | `pyproject.toml` |
| **mypy** | Static type checking; strict mode for `backend/` and `etl/`; standard mode for `ml/` | `pyproject.toml` |

```bash
# Format all Python files
black .

# Lint and auto-fix safe issues
ruff check . --fix

# Run type checking
mypy backend/ etl/ ml/
```

### 3.3 Naming Conventions

| Element | Convention | Example |
|---|---|---|
| Variables | `snake_case` | `total_defect_count` |
| Functions | `snake_case` | `calculate_oee_score()` |
| Classes | `PascalCase` | `ProductionDataExtractor` |
| Constants | `UPPER_SNAKE_CASE` | `MAX_RETRY_ATTEMPTS = 3` |
| Modules | `snake_case` | `data_quality_validator.py` |
| Packages | `snake_case` | `feature_engineering/` |
| Private members | Leading underscore | `_validate_watermark()` |

### 3.4 Type Hints

All function signatures — public and private — must include complete type annotations. Use `from __future__ import annotations` at the top of all files to enable modern union syntax (`X | Y` instead of `Union[X, Y]`) without runtime cost.

```python
# ✅ Correct — fully annotated
def calculate_oee(
    availability: float,
    performance: float,
    quality: float,
) -> float:
    """Calculate Overall Equipment Effectiveness (OEE) score."""
    return availability * performance * quality

# ❌ Incorrect — missing type hints
def calculate_oee(a, p, q):
    return a * p * q

# ✅ Correct — complex types
def extract_sensor_data(
    machine_ids: list[str],
    start_date: datetime,
    end_date: datetime,
    *,
    sensor_types: list[str] | None = None,
) -> pd.DataFrame:
    ...
```

Avoid `Any` except when interfacing with untyped third-party libraries. When `Any` is unavoidable, add a `# type: ignore[assignment]` comment with a brief explanation.

### 3.5 Docstrings

All public functions, classes, and modules must have **Google-style docstrings**. Private functions (`_` prefix) should have docstrings when the logic is non-trivial.

```python
def extract_sensor_data(
    machine_id: str,
    start_date: datetime,
    end_date: datetime,
) -> pd.DataFrame:
    """Extract sensor readings for a machine within a date range.

    Uses watermark-based incremental extraction. Only records with
    reading_timestamp > start_date and <= end_date are returned.

    Args:
        machine_id: Unique machine identifier (e.g., 'MCH-001').
        start_date: Start of the extraction window (inclusive).
        end_date: End of the extraction window (inclusive).

    Returns:
        DataFrame with columns:
            reading_id (int), machine_id (str), sensor_type (str),
            value (float), reading_timestamp (datetime), is_anomaly_flagged (bool).
        Returns an empty DataFrame if no records exist in the window.

    Raises:
        DataSourceConnectionError: If the source database is unreachable
            after all retry attempts are exhausted.
        ValueError: If start_date is after end_date.
    """
```

Module-level docstrings must state the module's purpose, its layer (ETL/API/ML), and any important usage notes.

### 3.6 Error Handling

- **Use custom exception classes** per domain. Define them in a `exceptions.py` module in each package:
  - `etl/exceptions.py`: `ETLExtractionError`, `ETLTransformationError`, `DataValidationError`
  - `backend/exceptions.py`: `MachineNotFoundError`, `InvalidDateRangeError`, `ModelUnavailableError`
- **Always log before re-raising.** Log the original exception with full context, then re-raise or wrap in a domain exception.
- **Never use bare `except:` clauses.** Always catch specific exception types. If catching `Exception` is necessary, document why.
- **Use `contextlib.suppress()` only for genuinely ignorable exceptions** — and add a comment explaining why ignoring is safe.

```python
# ✅ Correct
try:
    df = source_db.query(sensor_query)
except sqlalchemy.exc.OperationalError as exc:
    logger.error(
        "Failed to connect to source database",
        extra={"machine_id": machine_id, "error": str(exc)},
    )
    raise DataSourceConnectionError(f"Source DB unreachable: {exc}") from exc

# ❌ Incorrect — bare except, no logging, no re-raise context
try:
    df = source_db.query(sensor_query)
except:
    pass
```

### 3.7 Logging

Use Python's `logging` module exclusively. Do not use `print()` in any code that runs in the pipeline or API — use logging. `print()` is acceptable only in one-off utility scripts.

- **Configuration:** Logging is configured once in the application entry point using `logging.config.dictConfig`. All loggers use structured JSON formatting in production (via `python-json-logger`).
- **Log Levels:**
  - `DEBUG` — Detailed diagnostic information for development troubleshooting
  - `INFO` — Normal pipeline milestones (`"Extraction complete: 15,234 records written to Bronze zone"`)
  - `WARNING` — Data quality issues that are non-blocking (`"3 records skipped: machine_id is null"`)
  - `ERROR` — Failures that require attention (`"ETL pipeline failed: unable to connect to source database"`)
- **Structured Fields:** Always include contextual fields in log records:

```python
logger.info(
    "Extraction complete",
    extra={
        "dag_id": "dag_sensor_etl",
        "source_table": "sensor_readings",
        "record_count": len(df),
        "elapsed_ms": int((time.monotonic() - start_time) * 1000),
        "watermark": watermark_timestamp.isoformat(),
    },
)
```

---

## 4. SQL Standards

### 4.1 Formatting

| Rule | Detail |
|---|---|
| Keyword Case | ALL CAPS for SQL reserved words (`SELECT`, `FROM`, `WHERE`, `JOIN`, `GROUP BY`, `ORDER BY`, `WITH`, `CASE`, `WHEN`, `THEN`, `END`) |
| Identifier Case | `snake_case` for all table names, column names, aliases, and CTEs |
| Indentation | 4 spaces — no tabs |
| Line Length | Maximum 120 characters |
| Commas | Leading commas on new lines for column lists — enables easier commenting and diff review |
| Aliases | Always alias table references; use meaningful short abbreviations (`m` for `dim_machine`, `fp` for `fct_production`) |
| Semicolons | Terminate every standalone statement with a semicolon |

### 4.2 Standard Style Example

```sql
WITH daily_production AS (

    SELECT
        fp.date_key
        , dm.machine_name
        , dm.production_line
        , SUM(fp.actual_units)    AS total_actual_units
        , SUM(fp.good_units)      AS total_good_units
        , SUM(fp.scrap_units)     AS total_scrap_units
        , AVG(fp.oee_overall)     AS avg_oee

    FROM fct_production AS fp
    INNER JOIN dim_machine AS dm
        ON fp.machine_sk = dm.machine_sk
    INNER JOIN dim_date AS dd
        ON fp.date_key = dd.date_key

    WHERE
        dd.full_date >= '2026-01-01'
        AND dd.full_date < '2026-07-01'
        AND dm.is_active = TRUE

    GROUP BY
        fp.date_key
        , dm.machine_name
        , dm.production_line

)

SELECT
    *
    , ROUND(total_good_units::NUMERIC / NULLIF(total_actual_units, 0), 4) AS yield_rate
FROM daily_production
ORDER BY
    date_key ASC
    , avg_oee DESC
;
```

### 4.3 Prohibited SQL Patterns

The following patterns are prohibited and will be rejected in code review:

| Anti-Pattern | Rule | Alternative |
|---|---|---|
| `SELECT *` | Never use in production queries or dbt models | Explicitly name all required columns |
| Implicit JOIN (comma in FROM) | Prohibited — always use explicit `JOIN` syntax | `FROM a INNER JOIN b ON a.id = b.id` |
| Subquery where a CTE improves readability | Avoid nested subqueries beyond two levels | Refactor to a named CTE with `WITH` |
| Magic numbers in `WHERE` clauses | Prohibited — values must be explained | Use a named CTE, a comment, or a configurable variable |
| `FLOAT` or `REAL` for monetary or ratio values | Prohibited — floating-point imprecision is unacceptable for financial or KPI data | Use `NUMERIC(precision, scale)` |
| Non-deterministic functions in incremental models | Prohibited — `NOW()`, `CURRENT_TIMESTAMP` in a WHERE clause breaks idempotency | Use a dbt variable for the run timestamp |

---

## 5. dbt Standards

### 5.1 Model Naming Conventions

| Layer | Prefix | Example |
|---|---|---|
| Sources (in `sources.yml`) | No prefix — raw source table names | `sensor_readings` |
| Staging | `stg_` | `stg_sensor_readings` |
| Intermediate | `int_` | `int_oee_components` |
| Marts — Facts | `fct_` | `fct_production` |
| Marts — Dimensions | `dim_` | `dim_machine` |

### 5.2 Model File Organization

```
warehouse/dbt/
├── models/
│   ├── staging/
│   │   ├── _staging.yml          # All staging source declarations
│   │   ├── stg_sensor_readings.sql
│   │   ├── stg_production_orders.sql
│   │   ├── stg_quality_inspections.sql
│   │   └── stg_maintenance_logs.sql
│   ├── intermediate/
│   │   ├── int_oee_components.sql
│   │   ├── int_maintenance_metrics.sql
│   │   └── int_quality_metrics.sql
│   └── marts/
│       ├── production/
│       │   ├── fct_production.sql
│       │   ├── dim_machine.sql
│       │   ├── dim_product.sql
│       │   ├── dim_shift.sql
│       │   └── _production_marts.yml
│       ├── quality/
│       │   ├── fct_quality_inspection.sql
│       │   ├── dim_defect_type.sql
│       │   └── _quality_marts.yml
│       └── maintenance/
│           ├── fct_maintenance_event.sql
│           ├── dim_employee.sql
│           └── _maintenance_marts.yml
├── tests/             # Custom singular test .sql files
├── seeds/             # dim_date.csv, dim_shift.csv
├── macros/            # generate_schema_name.sql, etc.
└── snapshots/         # SCD Type 2 snapshot definitions
```

### 5.3 Testing Requirements

Every dbt model must have the following tests defined in the corresponding `_*.yml` file:

| Test | Applies To | Required |
|---|---|---|
| `not_null` | All primary key columns | Mandatory |
| `unique` | All primary key columns | Mandatory |
| `accepted_values` | All categorical / enum columns | Mandatory |
| `relationships` | All foreign key columns in fact tables | Mandatory |
| Custom singular test | At least one per fact table | Mandatory |

Example custom test for OEE integrity: `oee_components_must_multiply_to_overall.sql` — asserts that `oee_availability × oee_performance × oee_quality ≈ oee_overall` within a tolerance of 0.001.

A `dbt test` run with any failures blocks the CI pipeline. **Zero failing tests is a hard requirement to merge.**

### 5.4 Documentation Requirements

Every dbt model must be documented in a `schema.yml` file:

- Each model must have a `description` explaining its purpose, grain, and primary use case
- All columns in fact and dimension tables must have a `description`
- All `accepted_values` tests must list the allowed values explicitly
- `dbt docs generate` must produce a valid documentation site — broken references or missing descriptions cause the `dbt parse` CI job to fail

---

## 6. JavaScript / React Standards

### 6.1 Formatting

| Tool | Rule | Config |
|---|---|---|
| **ESLint** | Airbnb configuration; zero errors to merge; warnings are reviewed but not blocking | `frontend/.eslintrc.json` |
| **Prettier** | Auto-format on save; 2-space indentation, single quotes, trailing commas (ES5) | `frontend/.prettierrc` |
| **TypeScript** | `strict: true` in `tsconfig.json`; all components and hooks must be fully typed | `frontend/tsconfig.json` |

### 6.2 Naming Conventions

| Element | Convention | Example |
|---|---|---|
| Components | `PascalCase` | `OEEGaugeChart.tsx` |
| Hooks | `camelCase` with `use` prefix | `useProductionData.ts` |
| Functions | `camelCase` | `formatOEEPercentage()` |
| Constants | `UPPER_SNAKE_CASE` | `DEFAULT_DATE_RANGE_DAYS` |
| CSS classes | `kebab-case` | `.oee-card__value` |
| TypeScript types | `PascalCase` with descriptive suffix | `OEESummaryResponse`, `MachineFilters` |

### 6.3 Component Guidelines

- **Functional components only.** Class components are prohibited.
- **Custom hooks for all data fetching.** No `useEffect` + `fetch` inside component bodies — all data fetching goes through domain-specific hooks that use React Query.
- **TypeScript interfaces for all props.** No untyped component props. Define a `Props` interface in the same file or a co-located `types.ts` for shared types.
- **No inline styles.** All styles use CSS modules (`.module.css`) or CSS custom properties. No `style={{ ... }}` attributes in JSX except for truly dynamic values (e.g., chart width based on container).
- **Single responsibility.** A component either fetches data (container) or renders UI (presentational) — not both. Chart components receive data as props; data fetching is in the parent or hook.
- **Memoization:** Use `React.memo`, `useMemo`, and `useCallback` only when a measurable performance problem is identified — not speculatively.

---

## 7. Git & Version Control Standards

### 7.1 Branch Strategy

```
main                  ← Protected. Production-ready only. No direct commits.
├── develop           ← Integration branch. All PRs target develop.
│   ├── feature/...   ← New feature development
│   ├── fix/...       ← Bug fixes
│   ├── docs/...      ← Documentation updates only
│   └── refactor/...  ← Code restructuring (no behavior change)
└── release/x.y.z     ← Release preparation branches
```

- `main` is protected — direct pushes are blocked
- `develop` is the integration branch — all feature PRs merge here
- `main` is updated only via PR from `release/x.y.z` branches at milestone completion

### 7.2 Commit Message Convention

Follow the **Conventional Commits** specification exactly:

```
<type>(<scope>): <short summary in present tense, max 72 chars>

[Optional body — explain WHY, not what. Wrap at 72 chars.]

[Optional footer: Closes #42, Refs #38]
```

| Type | When to Use |
|---|---|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation change only |
| `refactor` | Code restructuring (no behavior change) |
| `test` | Adding or updating tests |
| `chore` | Build system, CI, dependency updates |
| `perf` | Performance improvement |
| `data` | Dataset additions or dbt model changes |
| `style` | Formatting-only change |

**Examples:**
```
feat(etl): add incremental extraction logic for sensor data

Replaces full-extract pattern with watermark-based approach.
Reduces average extraction time by ~80% for large sensor tables.

Closes #42

---

fix(api): handle null values in OEE calculation endpoint

Previously raised UnboundLocalError when no production records
existed for the requested date range. Now returns a zero-value
OEE response object with an INSUFFICIENT_DATA warning.

Closes #55
```

### 7.3 Pull Request Rules

All pull requests must comply with the following rules before they will be reviewed or merged:

- **PR title** must follow Conventional Commits format exactly (same `<type>(<scope>): <summary>` pattern)
- **Linked Issue** — every PR must reference a GitHub Issue with `Closes #N` or `Refs #N` in the description
- **CI must pass** — all GitHub Actions checks (lint, type-check, test, dbt-parse) must be green
- **Coverage must not decrease** — `pytest-cov` report must show equal or higher line coverage than the target branch
- **Maximum 400 lines changed** — larger changes must be split into multiple PRs
- **Squash merge** into `develop` — preserves a clean, linear history
- **Self-review required** — author must complete the Code Review Checklist (§12) before requesting review

---

## 8. Documentation Standards

### 8.1 Markdown Files

All `.md` files in the repository must comply with the following rules:

- **Heading hierarchy:** Use a single `H1` (`#`) per file; never skip heading levels (`H2` → `H4` is prohibited)
- **Table of Contents:** Required for any document exceeding 500 words
- **Tables:** Use for all structured comparisons, configuration references, and multi-attribute lists — do not use bullet-list tables
- **Code blocks:** Always use fenced code blocks with a language specifier (` ```python `, ` ```sql `, ` ```bash `, ` ```json `) — never use indented code blocks
- **Cross-references:** Link to related documents using relative paths: `[SYSTEM_ARCHITECTURE.md](./SYSTEM_ARCHITECTURE.md)` — not absolute URLs
- **No broken links:** All internal links must point to a file or anchor that exists. Verify before committing.
- **Line endings:** LF (Unix-style) — configured in `.gitattributes`

### 8.2 In-Code Documentation

- **Module docstring:** Every Python module must have a module-level docstring stating its purpose, the layer it belongs to (ETL/API/ML), and any usage notes (e.g., environment variables required).
- **Public function docstring:** Every public function and class method must have a Google-style docstring (§3.5).
- **Inline comments:** Complex business logic must be annotated with comments explaining *why* the logic is structured as it is — not *what* it does (the code itself conveys *what*).
- **TODO comments:** Must include a GitHub Issue number: `# TODO(#42): Implement exponential backoff for retry logic`. TODOs without issue numbers will be rejected in code review.
- **dbt model headers:** Each dbt SQL model must begin with a comment block:

```sql
-- Model: stg_sensor_readings
-- Layer: Staging
-- Description: Cleans and standardizes raw sensor readings from the source database.
--              One row per sensor reading. No business logic applied.
-- Source: public.sensor_readings
-- Grain: One row per reading_id
```

---

## 9. Testing Standards

### 9.1 Coverage Requirements

| Layer | Metric | Minimum Target |
|---|---|---|
| ETL — Extract | Line coverage | ≥ 80% |
| ETL — Transform | Line coverage | ≥ 90% |
| ETL — Load | Line coverage | ≥ 70% |
| API — Routers | Line coverage | ≥ 80% |
| API — Services | Line coverage | ≥ 85% |
| ML — Feature Engineering | Line coverage | ≥ 75% |

Coverage is enforced by the CI pipeline. A PR that reduces coverage below the target threshold will not be merged.

### 9.2 Test Organization

| Test Type | Location | Naming Pattern |
|---|---|---|
| Unit tests | `testing/unit/` | `test_<module_name>.py` |
| Integration tests | `testing/integration/` | `test_<feature>_integration.py` |
| Shared fixtures | `testing/fixtures/conftest.py` | Pytest `conftest.py` at the appropriate scope level |

File structure mirrors the source code structure. A test for `etl/extract/sensor_extractor.py` lives at `testing/unit/etl/extract/test_sensor_extractor.py`.

### 9.3 Test Quality Rules

- **Independence:** Each test must be completely independent. Tests must not share mutable state, and passing or failing must not depend on execution order.
- **Descriptive names:** Test function names must describe the scenario and expected outcome: `test_calculate_oee_returns_zero_when_machine_is_offline`, `test_extract_raises_error_when_database_is_unreachable`.
- **Arrange-Act-Assert:** Structure every test body in three clearly separated blocks. Use blank lines between blocks. Never combine arrange and act, or act and assert in the same expression.
- **Mock all external dependencies:** Unit tests must mock database connections, file system access, and HTTP calls. Use `pytest-mock` (`mocker.patch`) for dependency mocking.
- **Pytest marks:** Categorize tests with `@pytest.mark`:
  - `@pytest.mark.unit` — Fast, isolated unit tests (default)
  - `@pytest.mark.integration` — Tests requiring running services
  - `@pytest.mark.slow` — Tests taking > 5 seconds
- **One logical assertion per test.** A test with 10 assertions typically covers 10 independent behaviors — split it into 10 tests. Use `pytest.approx()` for floating-point comparisons.

---

## 10. Configuration & Secrets Management

### 10.1 Environment Variables

- All sensitive values — database credentials, API keys, service endpoints — must be stored as environment variables. No exceptions.
- A `.env.example` file must be maintained in the repository root with all required variable names and safe placeholder values (empty strings or descriptive placeholders like `your_secret_key_here`).
- The `.env` file must never be committed to git. It is enforced by `.gitignore`. The CI pipeline includes a `trufflehog` scan to detect accidentally committed secrets.
- Use `pydantic-settings` (`BaseSettings`) for all environment configuration in Python. This provides typed, validated config loading with clear error messages for missing required variables.
- Configuration objects must be singletons, loaded once at application startup — not re-read on every function call.

### 10.2 Prohibited Practices

The following are strictly prohibited and grounds for immediate PR rejection:

| Prohibition | Risk |
|---|---|
| Hardcoded database credentials in any source file | Credential exposure in public repository |
| API keys or tokens in source code or documentation | Token theft |
| Passwords in `docker-compose.yml` values (use `env_file` or Docker secrets) | Credential exposure |
| Secrets in commit messages, PR descriptions, or issue comments | Permanent exposure in git history |
| `.env` files committed to the repository | Full credential exposure |
| Logging credential values at any log level | Credential exposure in log aggregation systems |

If a secret is accidentally committed, treat it as compromised immediately: rotate it, then remove it from git history using `git filter-repo`.

---

## 11. Tooling Configuration

All code quality tools are pre-configured in the repository. Contributors must not modify tool configurations without an approved GitHub Issue and corresponding ADR if the change affects linting rules or coverage targets.

| File | Tool | Location | Purpose |
|---|---|---|---|
| `pyproject.toml` | black, ruff, mypy, pytest, pytest-cov | Root | Python formatting, linting, type-checking, test configuration |
| `.pre-commit-config.yaml` | pre-commit | Root | Git hook definitions — runs ruff, black, mypy before every commit |
| `.eslintrc.json` | ESLint | `frontend/` | React/TypeScript linting rules |
| `.prettierrc` | Prettier | `frontend/` | JavaScript/TypeScript formatting rules |
| `tsconfig.json` | TypeScript | `frontend/` | TypeScript compiler options (`strict: true`) |
| `sqlfluff.cfg` | SQLFluff | Root | SQL formatting and linting rules for dbt models and raw SQL |
| `profiles.yml` | dbt | `warehouse/dbt/` | dbt connection profile (reads from environment variables) |
| `Makefile` | GNU Make | Root | Common developer commands: `make setup`, `make test`, `make lint`, `make run`, `make dbt` |

Run `make setup` after cloning to install all dependencies and pre-commit hooks in one command.

---

## 12. Code Review Checklist

Use this checklist when reviewing your own code before submitting a pull request. All items must be checked before requesting review.

### Code Quality

- [ ] All functions and methods have type hints and Google-style docstrings
- [ ] No `print()` statements — all output uses the `logging` module
- [ ] No hardcoded values — all configuration comes from environment variables or named constants
- [ ] No `SELECT *` in any SQL query or dbt model
- [ ] No bare `except:` clauses — all exceptions are caught specifically
- [ ] No `TODO` comments without a GitHub Issue number

### Testing

- [ ] Unit tests written for all new logic
- [ ] Tests are independent — no shared mutable state between tests
- [ ] All tests pass locally: `pytest testing/ -v`
- [ ] Coverage has not decreased: `pytest --cov=backend --cov=etl --cov-report=term-missing`
- [ ] dbt tests pass: `dbt test --select <changed_models>`

### Documentation

- [ ] Module and function docstrings are complete and accurate
- [ ] `CHANGELOG.md` updated with an entry under `[Unreleased]`
- [ ] README or API specification updated if the change affects user-facing behavior
- [ ] New dbt models have complete `schema.yml` entries with descriptions

### Security

- [ ] No credentials, secrets, or API keys in any source file
- [ ] `.env.example` updated if new environment variables were added
- [ ] No sensitive data logged at any level

### Git

- [ ] Commit messages follow Conventional Commits specification
- [ ] Branch name follows the naming convention (`feature/ISSUE-N-short-desc`)
- [ ] PR title follows Conventional Commits format
- [ ] PR description contains `Closes #N` linking to the relevant GitHub Issue
- [ ] Branch is up to date with `develop`

---

*These standards are non-negotiable. A pull request that does not meet these standards will be rejected at code review. The standards exist to produce code that is professional, maintainable, and portfolio-quality — consistent with the engineering practices expected in senior data roles.*
