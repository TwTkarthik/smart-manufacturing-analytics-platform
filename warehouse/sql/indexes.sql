-- indexes.sql
-- Indexes for performance optimization on the Star Schema

-- Production Fact Indexes
CREATE INDEX IF NOT EXISTS idx_fact_prod_date ON analytics.fact_production(date_key);
CREATE INDEX IF NOT EXISTS idx_fact_prod_machine ON analytics.fact_production(machine_key);
CREATE INDEX IF NOT EXISTS idx_fact_prod_product ON analytics.fact_production(product_key);

-- Quality Fact Indexes
CREATE INDEX IF NOT EXISTS idx_fact_qual_date ON analytics.fact_quality(date_key);
CREATE INDEX IF NOT EXISTS idx_fact_qual_machine ON analytics.fact_quality(machine_key);

-- Maintenance Fact Indexes
CREATE INDEX IF NOT EXISTS idx_fact_maint_date ON analytics.fact_maintenance(date_key);
CREATE INDEX IF NOT EXISTS idx_fact_maint_machine ON analytics.fact_maintenance(machine_key);

-- Sensor Fact Indexes (High Volume)
CREATE INDEX IF NOT EXISTS idx_fact_sensor_date ON analytics.fact_sensor_readings(date_key);
CREATE INDEX IF NOT EXISTS idx_fact_sensor_machine ON analytics.fact_sensor_readings(machine_key);
