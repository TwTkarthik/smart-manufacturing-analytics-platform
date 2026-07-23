import pandas as pd
from utils.db import DatabaseManager
from utils.logger import logger

class PgLoader:
    def __init__(self, db_manager: DatabaseManager):
        self.db = db_manager
        
    def load(self, df: pd.DataFrame, table_name: str, if_exists: str = "append") -> None:
        """Load DataFrame into PostgreSQL using the DatabaseManager."""
        if df.empty:
            logger.warning(f"DataFrame for {table_name} is empty. Skipping load.")
            return
            
        try:
            logger.info(f"Starting load for {table_name}...")
            self.db.bulk_load(table_name, df, if_exists)
            logger.info(f"Successfully loaded {table_name}.")
        except Exception as e:
            logger.error(f"Failed to load data for {table_name}: {e}")
            raise
