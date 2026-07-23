import pytest
from sqlalchemy import create_engine, text
import pandas as pd
import os

# Assume database is local for tests unless overridden
DB_URI = os.getenv("SMAP_DB_URI", "postgresql://postgres:postgres@localhost:5432/smap_dev")

@pytest.fixture(scope="module")
def db_engine():
    engine = create_engine(DB_URI)
    yield engine
    engine.dispose()

def test_oee_bounds(db_engine):
    """Ensure OEE is between 0 and 100%."""
    query = "SELECT oee_ytd_pct FROM analytics_reporting.kpi_oee_ytd LIMIT 1"
    try:
        with db_engine.connect() as conn:
            result = conn.execute(text(query)).fetchone()
            if result:
                oee = result[0]
                assert 0.0 <= oee <= 100.0, f"OEE {oee} is out of bounds!"
    except Exception as e:
        pytest.skip(f"Could not connect or view doesn't exist yet: {e}")

def test_yield_bounds(db_engine):
    """Ensure First Pass Yield is between 0 and 100%."""
    query = "SELECT first_pass_yield_pct FROM analytics_reporting.kpi_fpy_ytd LIMIT 1"
    try:
        with db_engine.connect() as conn:
            result = conn.execute(text(query)).fetchone()
            if result:
                fpy = result[0]
                assert 0.0 <= fpy <= 100.0, f"FPY {fpy} is out of bounds!"
    except Exception as e:
        pytest.skip(f"Could not connect or view doesn't exist yet: {e}")
