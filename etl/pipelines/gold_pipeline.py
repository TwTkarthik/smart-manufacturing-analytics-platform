import pandas as pd
from utils.logger import logger
from load.warehouse_loader import WarehouseLoader
from transform.aggregations import Aggregator

class GoldPipeline:
    def __init__(self, db_manager, loader: WarehouseLoader, config: dict):
        self.db = db_manager
        self.loader = loader
        self.config = config
        self.source_schema = self.config['schemas']['silver']
        self.target_schema = self.config['schemas']['gold']

    def run(self) -> None:
        logger.info("Starting Gold layer aggregations")
        
        # Example Aggregation: Daily Machine OEE
        try:
            orders_df = pd.read_sql_query(f"SELECT * FROM {self.source_schema}.production_orders", self.db.engine)
            downtime_df = pd.read_sql_query(f"SELECT * FROM {self.source_schema}.downtime_events", self.db.engine)
            
            oee_df = Aggregator.calculate_daily_machine_oee(orders_df, downtime_df)
            
            if not oee_df.empty:
                self.loader.load(oee_df, self.target_schema, 'fct_daily_machine_oee', mode='replace')
            else:
                logger.warning("Could not calculate OEE, DataFrames empty.")
                
        except Exception as e:
            logger.error(f"Failed during Gold pipeline execution: {e}")
