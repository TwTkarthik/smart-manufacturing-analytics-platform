from sqlalchemy import create_engine
from sqlalchemy.engine import Engine
from contextlib import contextmanager
from typing import Generator
from sqlalchemy.orm import sessionmaker, Session
import pandas as pd
from utils.logger import logger

class DatabaseManager:
    def __init__(self, dsn: str):
        self.dsn = dsn
        self.engine: Engine = create_engine(self.dsn)
        self.SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)

    @contextmanager
    def get_session(self) -> Generator[Session, None, None]:
        """Provide a transactional scope around a series of operations."""
        session = self.SessionLocal()
        try:
            yield session
            session.commit()
        except Exception as e:
            session.rollback()
            logger.error(f"Transaction rolled back due to error: {e}")
            raise
        finally:
            session.close()

    def get_highest_timestamp(self, schema: str, table: str, column: str) -> str:
        """Fetch the maximum timestamp for incremental loads."""
        query = f"SELECT MAX({column}) as max_val FROM {schema}.{table}"
        try:
            df = pd.read_sql_query(query, self.engine)
            val = df.iloc[0]['max_val']
            if pd.isna(val):
                return '1970-01-01 00:00:00'
            return str(val)
        except Exception as e:
            logger.warning(f"Could not fetch high water mark for {schema}.{table}, defaulting to epoch. Error: {e}")
            return '1970-01-01 00:00:00'
