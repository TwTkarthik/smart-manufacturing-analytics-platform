import pandas as pd
from typing import List, Dict, Callable
from .expectations import ExpectationResult, Expectations
from utils.logger import logger

class QualityChecker:
    def __init__(self, strict_mode: bool = False):
        self.strict_mode = strict_mode
        self.results: List[ExpectationResult] = []

    def run_checks(self, df: pd.DataFrame, table_name: str, checks_config: List[Dict]) -> bool:
        """
        Run a suite of expectations against a DataFrame based on a config list.
        Example checks_config:
        [
            {"type": "not_null", "column": "machine_id"},
            {"type": "between", "column": "temperature", "min_val": 0, "max_val": 200}
        ]
        """
        logger.info(f"Running quality checks for {table_name}...")
        self.results.clear()
        
        for check in checks_config:
            check_type = check.get("type")
            col = check.get("column")
            
            if check_type == "not_null":
                res = Expectations.expect_column_to_not_be_null(df, col)
            elif check_type == "unique":
                res = Expectations.expect_column_values_to_be_unique(df, col)
            elif check_type == "between":
                res = Expectations.expect_column_values_to_be_between(df, col, check.get("min_val"), check.get("max_val"))
            elif check_type == "in_set":
                res = Expectations.expect_column_values_to_be_in_set(df, col, check.get("value_set", []))
            else:
                logger.warning(f"Unknown expectation type: {check_type}")
                continue
                
            self.results.append(res)
            
            if not res.success:
                msg = f"Quality check failed for {table_name}.{col}: {res.message} ({res.expectation_type})"
                if self.strict_mode:
                    logger.error(msg)
                    raise ValueError(msg)
                else:
                    logger.warning(msg)
                    
        failed = sum(1 for r in self.results if not r.success)
        total = len(self.results)
        
        if failed > 0:
            logger.warning(f"Quality checks finished for {table_name}: {failed}/{total} checks failed.")
            return False
            
        logger.info(f"Quality checks passed for {table_name} ({total}/{total}).")
        return True
