-- facts.sql
-- Reference DDL for Fact Tables in the Data Warehouse (Analytics Schema)

CREATE TABLE IF NOT EXISTS analytics.fact_production (
    production_fact_key SERIAL PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    date_key INT NOT NULL,
    machine_key INT NOT NULL,
    product_key INT NOT NULL,
    planned_units INT,
    actual_units INT,
    good_units INT,
    scrap_units INT,
    yield_pct NUMERIC(5, 2)
);

CREATE TABLE IF NOT EXISTS analytics.fact_quality (
    quality_fact_key SERIAL PRIMARY KEY,
    inspection_id VARCHAR(50) NOT NULL,
    date_key INT NOT NULL,
    machine_key INT NOT NULL,
    product_key INT NOT NULL,
    inspector_key INT NOT NULL,
    defect_type_code VARCHAR(20),
    inspection_passed BOOLEAN
);

CREATE TABLE IF NOT EXISTS analytics.fact_maintenance (
    maintenance_fact_key SERIAL PRIMARY KEY,
    log_id VARCHAR(50) NOT NULL,
    date_key INT NOT NULL,
    machine_key INT NOT NULL,
    technician_key INT NOT NULL,
    downtime_minutes INT,
    maintenance_type VARCHAR(50),
    parts_cost NUMERIC(10, 2)
);

CREATE TABLE IF NOT EXISTS analytics.fact_inventory (
    inventory_fact_key SERIAL PRIMARY KEY,
    movement_id VARCHAR(50) NOT NULL,
    date_key INT NOT NULL,
    product_key INT,
    supplier_key INT,
    movement_type VARCHAR(20),
    quantity INT
);

CREATE TABLE IF NOT EXISTS analytics.fact_sensor_readings (
    reading_fact_key BIGSERIAL PRIMARY KEY,
    date_key INT NOT NULL,
    machine_key INT NOT NULL,
    sensor_type VARCHAR(50),
    reading_value NUMERIC(10, 3)
);
