# SMAP Enterprise Data Warehouse (dbt)

This project contains the dbt models and SQL schema definitions for the Smart Manufacturing Analytics Platform dimensional data warehouse.

## Architecture

The data warehouse consumes data from the Silver/Gold schemas populated by the ETL pipeline and transforms it into a dimensional star schema using dbt.

- **Staging (`models/staging`)**: Views that cast, rename, and standardize the source data.
- **Marts (`models/marts`)**: The dimensional star schema, grouped by business domains (Manufacturing, Quality, Inventory, Maintenance).
- **Snapshots (`snapshots`)**: Implements Slowly Changing Dimensions (SCD Type 2) for historical tracking of critical dimensions.

## Requirements

- Python 3.12
- PostgreSQL 16
- dbt-postgres

## Setup

```bash
cd warehouse
pip install -r requirements.txt
```

Initialize your `profiles.yml` (usually in `~/.dbt/profiles.yml`) to point to the operational DB / DW:

```yaml
smap_dw:
  target: dev
  outputs:
    dev:
      type: postgres
      threads: 4
      host: localhost
      port: 5432
      user: postgres
      pass: postgres
      dbname: smap_dev
      schema: analytics
```

## Execution Commands

```bash
# Test the connection
dbt debug

# Run staging models
dbt run --select staging

# Snapshot SCD Type 2 dimensions
dbt snapshot

# Run all models
dbt run

# Run tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve
```
