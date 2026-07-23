import pandas as pd

class DataEnricher:
    @staticmethod
    def enrich_sensor_with_machine_meta(sensor_df: pd.DataFrame, machine_df: pd.DataFrame) -> pd.DataFrame:
        """Join machine metadata (like line, plant) to sensor readings."""
        if sensor_df.empty or machine_df.empty:
            return sensor_df
            
        # Select only needed cols from machine to avoid bloat
        machine_subset = machine_df[['machine_id', 'machine_type_code', 'line_code', 'plant_code']]
        enriched = sensor_df.merge(machine_subset, on='machine_id', how='left')
        return enriched
