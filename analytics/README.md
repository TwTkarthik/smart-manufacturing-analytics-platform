# SMAP Enterprise Analytics SQL Layer

This module contains the enterprise-grade SQL layer exposing business-ready KPIs, materialized views, and analytical datasets optimized for consumption by BI tools like Power BI.

## Architecture

The Analytics SQL layer queries the dimensional Data Warehouse (`analytics` schema) and exposes its outputs through a new schema (`analytics_reporting`).

- **KPIs (`sql/kpis.sql`)**: Centralized definitions for critical metrics like OEE, Inventory Turnover, and First Pass Yield.
- **Dashboards (`sql/*_dashboard.sql`)**: Purpose-built views tailored for specific BI dashboard pages (Executive, Production, Maintenance, Quality, Inventory, Financial, Workforce).
- **Materialized Views (`sql/materialized_views.sql`)**: Heavy aggregations pre-calculated for dashboard performance using advanced window functions and time intelligence.
- **Analytical Views (`sql/analytical_views.sql`)**: Real-time or ad-hoc query interfaces.
- **Queries (`queries/`)**: Reusable standalone `.sql` files for ad-hoc business analysis.

## Setup & Deployment

1. Install dependencies:
```bash
cd analytics
pip install -r requirements.txt
```

2. Deploy the Analytics SQL objects to the database:
```bash
python main.py deploy
```

3. Run SQL Validation tests:
```bash
python main.py test
```
