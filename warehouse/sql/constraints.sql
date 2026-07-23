-- constraints.sql
-- Reference Foreign Key Constraints for the Star Schema

ALTER TABLE analytics.fact_production
    ADD CONSTRAINT fk_prod_date FOREIGN KEY (date_key) REFERENCES analytics.dim_date(date_key),
    ADD CONSTRAINT fk_prod_machine FOREIGN KEY (machine_key) REFERENCES analytics.dim_machine(machine_key),
    ADD CONSTRAINT fk_prod_product FOREIGN KEY (product_key) REFERENCES analytics.dim_product(product_key);

ALTER TABLE analytics.fact_quality
    ADD CONSTRAINT fk_qual_date FOREIGN KEY (date_key) REFERENCES analytics.dim_date(date_key),
    ADD CONSTRAINT fk_qual_machine FOREIGN KEY (machine_key) REFERENCES analytics.dim_machine(machine_key),
    ADD CONSTRAINT fk_qual_product FOREIGN KEY (product_key) REFERENCES analytics.dim_product(product_key);

ALTER TABLE analytics.fact_maintenance
    ADD CONSTRAINT fk_maint_date FOREIGN KEY (date_key) REFERENCES analytics.dim_date(date_key),
    ADD CONSTRAINT fk_maint_machine FOREIGN KEY (machine_key) REFERENCES analytics.dim_machine(machine_key);

ALTER TABLE analytics.fact_sensor_readings
    ADD CONSTRAINT fk_sensor_date FOREIGN KEY (date_key) REFERENCES analytics.dim_date(date_key),
    ADD CONSTRAINT fk_sensor_machine FOREIGN KEY (machine_key) REFERENCES analytics.dim_machine(machine_key);
