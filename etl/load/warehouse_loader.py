import pandas as pd
from sqlalchemy.schema import CreateSchema
from sqlalchemy import text
from utils.database import DatabaseManager
from utils.logger import logger

class WarehouseLoader:
    def __init__(self, db_manager: DatabaseManager):
        self.db = db_manager

    def load(self, df: pd.DataFrame, schema: str, table_name: str, mode: str = "append") -> None:
        """Load data into a specific schema and table in the warehouse."""
        if df.empty:
            logger.info(f"DataFrame for {schema}.{table_name} is empty. Skipping load.")
            return

        # Ensure schema exists
        self._ensure_schema(schema)

        if_exists = 'append' if mode == 'incremental' else 'replace'
        
        try:
            logger.info(f"Loading {len(df)} rows into {schema}.{table_name} (mode: {if_exists})")
            
            # Using transaction scope wrapper from DatabaseManager
            with self.db.get_session() as session:
                # Pandas to_sql uses the underlying engine connection, but to participate
                # in the SQLAlchemy session transaction we pass the session's bind (connection)
                connection = session.connection()
                df.to_sql(
                    name=table_name,
                    con=connection,
                    schema=schema,
                    if_exists=if_exists,
                    index=False,
                    chunksize=5000,
                    method='multi'
                )
            logger.info(f"Successfully loaded {schema}.{table_name}")
        except Exception as e:
            logger.error(f"Failed to load {schema}.{table_name}: {e}")
            raise

    def _ensure_schema(self, schema: str) -> None:
        """Create schema if it does not exist."""
        try:
            with self.db.get_session() as session:
                session.execute(text(f"CREATE SCHEMA IF NOT EXISTS {schema}"))
        except Exception as e:
            logger.error(f"Failed to ensure schema {schema}: {e}")
            raise
