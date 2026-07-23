import pandas as pd
from datetime import datetime, timezone
from utils.logger import logger
from extract.postgres_extractor import PostgresExtractor
from load.warehouse_loader import WarehouseLoader
from load.bulk_loader import BulkLoader

class BronzePipeline:
    def __init__(self, extractor: PostgresExtractor, loader: WarehouseLoader, bulk_loader: BulkLoader, config: dict):
        self.extractor = extractor
        self.loader = loader
        self.bulk_loader = bulk_loader
        self.config = config
        self.schema = self.config['schemas']['bronze']

    def run(self, table_config: dict) -> None:
        table_name = table_config['name']
        table_type = table_config['type']
        
        mode = self.config['extraction']['mode']
        
        # Telemetry is always incremental if we have a HWM
        hwm_col = table_config.get('high_water_mark_column', self.config['extraction']['high_water_mark_column'])
        
        if mode == 'incremental':
            hwm = self.loader.db.get_highest_timestamp(self.schema, table_name, hwm_col)
        else:
            hwm = None

        logger.info(f"Starting Bronze load for {table_name}")
        df = self.extractor.extract(table_name, mode=mode, high_water_mark=hwm, hwm_column=hwm_col)
        
        if df.empty:
            logger.info(f"No new records for {table_name}. Skipping.")
            return

        # Add metadata
        df['_etl_loaded_at'] = datetime.now(timezone.utc)
        df['_source'] = 'postgres_smap_dev'
        
        if table_type == 'telemetry':
            self.bulk_loader.load_copy(df, self.schema, table_name)
        else:
            self.loader.load(df, self.schema, table_name, mode=mode)
