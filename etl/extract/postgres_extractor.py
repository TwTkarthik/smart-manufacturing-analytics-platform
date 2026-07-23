import pandas as pd
from typing import Optional
from utils.database import DatabaseManager
from utils.logger import logger

class PostgresExtractor:
    def __init__(self, db_manager: DatabaseManager, schema: str = "public"):
        self.db = db_manager
        self.schema = schema

    def extract(self, table_name: str, mode: str = "full", high_water_mark: Optional[str] = None, hwm_column: str = "updated_at") -> pd.DataFrame:
        """Extract data from a PostgreSQL table."""
        if mode == "incremental":
            if not high_water_mark:
                logger.warning(f"Incremental mode specified for {table_name} but no high water mark provided. Defaulting to full extract.")
                query = f"SELECT * FROM {self.schema}.{table_name}"
            else:
                logger.info(f"Extracting {table_name} incrementally since {high_water_mark} using {hwm_column}")
                # Note: This is a basic string interpolation; in production we'd use SQLAlchemy parameters to avoid injection.
                # Assuming high_water_mark is a safe string from our DB.
                query = f"SELECT * FROM {self.schema}.{table_name} WHERE {hwm_column} > '{high_water_mark}'"
        else:
            logger.info(f"Extracting full table: {table_name}")
            query = f"SELECT * FROM {self.schema}.{table_name}"
            
        try:
            df = pd.read_sql_query(query, self.db.engine)
            logger.info(f"Extracted {len(df)} rows from {table_name}.")
            return df
        except Exception as e:
            logger.error(f"Failed to extract {table_name}: {e}")
            raise
