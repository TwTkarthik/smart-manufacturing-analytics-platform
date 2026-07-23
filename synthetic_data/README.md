# SMAP Synthetic Data Generator

A modular, configuration-driven Python application to generate deterministic, realistic synthetic data for the Smart Manufacturing Analytics Platform (SMAP).

## Features
- Generates all 14 SMAP operational database entities.
- Configurable row counts, anomaly injection, and missing value rates.
- Maintains strict referential integrity across all entities.
- Deterministic output (same seed = same data).
- Supports export to CSV, JSON, and direct PostgreSQL database loading.

## Requirements
- Python 3.12+
- PostgreSQL (if loading to database)

## Installation

```bash
cd synthetic_data
pip install -r requirements.txt
```

## Usage

Configure the generation parameters in `config/config.yaml`.

### Export to CSV/JSON

```bash
python main.py --config config/config.yaml --export-csv --export-json
```

### Load directly to PostgreSQL

Ensure your database is running and credentials are set in the environment or config.

```bash
python main.py --config config/config.yaml --load-pg
```

### Validation Only

Generate data in memory and run schema/business rule validations.

```bash
python main.py --config config/config.yaml --validate
```
