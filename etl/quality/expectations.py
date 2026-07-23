from typing import Any, Callable, List, Dict
import pandas as pd
from dataclasses import dataclass

@dataclass
class ExpectationResult:
    expectation_type: str
    column: str
    success: bool
    failed_count: int
    total_count: int
    message: str

class Expectations:
    """Library of standard data quality expectations."""
    
    @staticmethod
    def expect_column_to_not_be_null(df: pd.DataFrame, column: str) -> ExpectationResult:
        if column not in df.columns:
            return ExpectationResult("not_null", column, False, len(df), len(df), "Column not found")
            
        null_count = df[column].isna().sum()
        total = len(df)
        success = null_count == 0
        return ExpectationResult(
            "not_null", column, success, null_count, total,
            f"{null_count}/{total} rows are null"
        )
        
    @staticmethod
    def expect_column_values_to_be_unique(df: pd.DataFrame, column: str) -> ExpectationResult:
        if column not in df.columns:
            return ExpectationResult("unique", column, False, len(df), len(df), "Column not found")
            
        duplicates = df[column].duplicated(keep=False).sum()
        total = len(df)
        success = duplicates == 0
        return ExpectationResult(
            "unique", column, success, duplicates, total,
            f"{duplicates}/{total} values are duplicated"
        )
        
    @staticmethod
    def expect_column_values_to_be_between(df: pd.DataFrame, column: str, min_val: Any, max_val: Any) -> ExpectationResult:
        if column not in df.columns:
            return ExpectationResult("between", column, False, len(df), len(df), "Column not found")
            
        # Ignore NaNs for range check (handled by not_null if needed)
        mask = df[column].notna()
        out_of_bounds = df.loc[mask, column].apply(lambda x: x < min_val or x > max_val).sum()
        total = mask.sum()
        success = out_of_bounds == 0
        return ExpectationResult(
            "between", column, success, out_of_bounds, total,
            f"{out_of_bounds}/{total} values outside [{min_val}, {max_val}]"
        )

    @staticmethod
    def expect_column_values_to_be_in_set(df: pd.DataFrame, column: str, value_set: List[Any]) -> ExpectationResult:
        if column not in df.columns:
            return ExpectationResult("in_set", column, False, len(df), len(df), "Column not found")
            
        mask = df[column].notna()
        invalid_count = (~df.loc[mask, column].isin(value_set)).sum()
        total = mask.sum()
        success = invalid_count == 0
        return ExpectationResult(
            "in_set", column, success, invalid_count, total,
            f"{invalid_count}/{total} values not in allowed set"
        )
