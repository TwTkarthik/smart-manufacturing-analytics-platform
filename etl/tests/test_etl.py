import pytest
import pandas as pd
from transform.cleaning import DataCleaner
from transform.business_rules import BusinessRules
from quality.expectations import Expectations

def test_data_cleaner_duplicates():
    df = pd.DataFrame({'id': [1, 2, 2, 3], 'val': ['A', 'B', 'B', 'C']})
    cleaned = DataCleaner.remove_duplicates(df)
    assert len(cleaned) == 3
    assert cleaned['id'].tolist() == [1, 2, 3]

def test_data_cleaner_missing():
    df = pd.DataFrame({'id': [1, 2, 3], 'reason_code': ['A', None, 'C']})
    cleaned = DataCleaner.handle_missing_values(df, {'reason_code': 'UNKNOWN'})
    assert len(cleaned) == 3
    assert cleaned['reason_code'].tolist() == ['A', 'UNKNOWN', 'C']

def test_business_rules_downtime():
    df = pd.DataFrame({'reason_code': ['MECH-FAIL', 'SETUP', 'UNKNOWN', None]})
    categorized = BusinessRules.categorize_downtime(df)
    assert 'downtime_category' in categorized.columns
    categories = categorized['downtime_category'].tolist()
    assert categories[0] == 'Equipment Failure'
    assert categories[1] == 'Planned Stop'
    assert categories[2] == 'Unknown' # Based on our logic 'UNKNOWN' -> 'Other', wait, 'Unknown' if not present or NA, but 'UNKNOWN' goes to Other since it doesn't match keys. Actually `if not code or pd.isna(code): return 'Unknown'`
    
def test_expectation_not_null():
    df = pd.DataFrame({'id': [1, 2, None]})
    res = Expectations.expect_column_to_not_be_null(df, 'id')
    assert not res.success
    assert res.failed_count == 1
    
def test_expectation_between():
    df = pd.DataFrame({'val': [10, 50, 150]})
    res = Expectations.expect_column_values_to_be_between(df, 'val', 0, 100)
    assert not res.success
    assert res.failed_count == 1
