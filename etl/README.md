# SMAP Enterprise ETL Platform

A modular, configuration-driven ETL framework implementing a Medallion Architecture (Bronze → Silver → Gold) for the Smart Manufacturing Analytics Platform.

## Architecture

- **Extract**: Pulls raw data from PostgreSQL or fallback files.
- **Bronze**: Raw ingestion layer. Adds metadata (`_etl_loaded_at`, `_source`) without altering data types.
- **Silver**: Cleansed and conformed layer. Handles missing values, removes duplicates, validates types, and enforces constraints.
- **Gold**: Business-level aggregations and KPIs (e.g., Daily OEE, Yield, Downtime analysis).
- **Quality**: Expectation-based data quality checks to ensure data reliability before loading.

## Installation

```bash
cd etl
pip install -r requirements.txt
```

## Configuration

Update `config/config.yaml` to specify database connections and pipeline behaviors. Update `config/logging.yaml` for log formatting.

## Execution

Execute the pipelines using the CLI:

```bash
# Run only Bronze extraction
python main.py bronze

# Run Bronze -> Silver
python main.py silver

# Run Bronze -> Silver -> Gold
python main.py gold

# Run full master pipeline
python main.py full
```
