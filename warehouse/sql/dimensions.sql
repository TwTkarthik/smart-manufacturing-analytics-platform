-- dimensions.sql
-- Reference DDL for Dimension Tables in the Data Warehouse (Analytics Schema)

CREATE TABLE IF NOT EXISTS analytics.dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    year INT NOT NULL,
    quarter INT NOT NULL,
    month INT NOT NULL,
    day_of_month INT NOT NULL,
    day_of_week INT NOT NULL,
    is_weekend BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS analytics.dim_machine (
    machine_key SERIAL PRIMARY KEY,
    machine_id VARCHAR(50) NOT NULL,
    machine_name VARCHAR(100),
    machine_type_code VARCHAR(20),
    line_code VARCHAR(20),
    plant_code VARCHAR(20),
    is_active BOOLEAN
);

CREATE TABLE IF NOT EXISTS analytics.dim_product (
    product_key SERIAL PRIMARY KEY,
    product_id VARCHAR(50) NOT NULL,
    product_name VARCHAR(100),
    category VARCHAR(50),
    unit_price NUMERIC(10, 2),
    dbt_valid_from TIMESTAMP,
    dbt_valid_to TIMESTAMP,
    is_current BOOLEAN
);

CREATE TABLE IF NOT EXISTS analytics.dim_employee (
    employee_key SERIAL PRIMARY KEY,
    employee_id VARCHAR(50) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    role VARCHAR(50),
    shift_code VARCHAR(20),
    dbt_valid_from TIMESTAMP,
    dbt_valid_to TIMESTAMP,
    is_current BOOLEAN
);

CREATE TABLE IF NOT EXISTS analytics.dim_shift (
    shift_key SERIAL PRIMARY KEY,
    shift_code VARCHAR(20) NOT NULL,
    start_time TIME,
    end_time TIME
);

-- Stubbed/Derived Dimensions
CREATE TABLE IF NOT EXISTS analytics.dim_customer (
    customer_key SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS analytics.dim_supplier (
    supplier_key SERIAL PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL
);
