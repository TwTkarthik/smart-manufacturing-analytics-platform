import pandas as pd
from utils.logger import logger
from load.warehouse_loader import WarehouseLoader
from transform.cleaning import DataCleaner
from transform.validation import DataValidator
from transform.business_rules import BusinessRules
from quality.quality_checks import QualityChecker

class SilverPipeline:
    def __init__(self, db_manager, loader: WarehouseLoader, config: dict, quality_checker: QualityChecker):
        self.db = db_manager
        self.loader = loader
        self.config = config
        self.quality_checker = quality_checker
        self.source_schema = self.config['schemas']['bronze']
        self.target_schema = self.config['schemas']['silver']

    def run(self, table_config: dict) -> None:
        table_name = table_config['name']
        logger.info(f"Starting Silver load for {table_name}")
        
        # Extract full table from Bronze (For simplicity in this pipeline, we process full Bronze to Silver)
        # In a true incremental silver, we'd watermark Bronze.
        query = f"SELECT * FROM {self.source_schema}.{table_name}"
        try:
            df = pd.read_sql_query(query, self.db.engine)
        except Exception as e:
            logger.error(f"Failed to read from bronze.{table_name}: {e}")
            return

        if df.empty:
            logger.info(f"No records in bronze for {table_name}. Skipping.")
            return

        # 1. Clean
        df = DataCleaner.standardize_column_names(df)
        df = DataCleaner.remove_duplicates(df)
        
        # 2. Table-specific rules
        if table_name == 'downtime_events':
            df = DataCleaner.handle_missing_values(df, {'reason_code': 'UNKNOWN'})
            df = BusinessRules.categorize_downtime(df)
            self.quality_checker.run_checks(df, table_name, [
                {"type": "not_null", "column": "machine_id"},
                {"type": "not_null", "column": "downtime_category"}
            ])
            
        elif table_name == 'production_orders':
            df = BusinessRules.calculate_yield(df)
            self.quality_checker.run_checks(df, table_name, [
                {"type": "between", "column": "yield_pct", "min_val": 0, "max_val": 100}
            ])
            
        elif table_name == 'sensor_readings':
            df = DataValidator.enforce_types(df, {'value': 'float64'})
            # Quality check
            self.quality_checker.run_checks(df, table_name, [
                {"type": "not_null", "column": "value"}
            ])

        # Load
        # Silver typically replaces completely or merges, we'll replace for simplicity in this script 
        # unless dealing with massive telemetry.
        mode = "append" if table_config['type'] == 'telemetry' else "replace"
        
        # If telemetry, we should really only load new rows, but for demonstration we'll rely on the loader mode.
        if mode == "append":
            # Just a mock implementation: in reality, we'd need a merge/upsert based on PK.
            # To avoid duplicates in append mode, we'd filter df here against Silver.
            pass
            
        self.loader.load(df, self.target_schema, table_name, mode=mode)
