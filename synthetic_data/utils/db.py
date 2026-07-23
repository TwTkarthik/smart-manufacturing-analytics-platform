from sqlalchemy import create_engine
import pandas as pd
from typing import Optional
from sqlalchemy.engine import Engine
from .logger import logger

class DatabaseManager:
    def __init__(self, dsn: str):
        self.dsn = dsn
        self.engine: Optional[Engine] = None

    def connect(self) -> None:
        """Initialize the SQLAlchemy engine."""
        try:
            self.engine = create_engine(self.dsn)
            logger.info("Database connection established.")
        except Exception as e:
            logger.error(f"Failed to connect to database: {e}")
            raise

    def fetch_reference_data(self, table_name: str) -> pd.DataFrame:
        """Fetch reference data from the database into a DataFrame."""
        if not self.engine:
            self.connect()
        try:
            df = pd.read_sql_table(table_name, self.engine)
            logger.info(f"Fetched {len(df)} rows from {table_name}")
            return df
        except Exception as e:
            logger.error(f"Failed to fetch {table_name}: {e}")
            # Return empty dataframe to not crash completely if table doesn't exist
            return pd.DataFrame()

    def bulk_load(self, table_name: str, df: pd.DataFrame, if_exists: str = "append") -> None:
        """Bulk load a DataFrame into PostgreSQL."""
        if not self.engine:
            self.connect()
        try:
            # For extremely large datasets, consider using raw psycopg3 copy for performance,
            # but to_sql is sufficient for standard generation runs if chunked correctly.
            logger.info(f"Loading {len(df)} rows to {table_name}...")
            df.to_sql(table_name, self.engine, if_exists=if_exists, index=False, chunksize=10000)
            logger.info(f"Successfully loaded {table_name}.")
        except Exception as e:
            logger.error(f"Failed to load {table_name}: {e}")
            raise
