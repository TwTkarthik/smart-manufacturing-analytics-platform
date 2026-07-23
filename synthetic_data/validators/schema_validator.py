import pandas as pd
from utils.logger import logger

class SchemaValidator:
    @staticmethod
    def validate_production_orders(df: pd.DataFrame) -> bool:
        """Validate production_orders business rules."""
        is_valid = True
        
        # actual_end >= actual_start
        mask = df['actual_end'].notna() & df['actual_start'].notna()
        if not (df.loc[mask, 'actual_end'] >= df.loc[mask, 'actual_start']).all():
            logger.error("Validation failed: actual_end < actual_start in production_orders.")
            is_valid = False
            
        # status checks
        invalid_statuses = df[~df['status'].isin(['Complete', 'In Progress', 'Pending', 'Cancelled'])]
        if not invalid_statuses.empty:
            logger.error("Validation failed: Invalid status in production_orders.")
            is_valid = False
            
        if is_valid:
            logger.info("production_orders passed validation.")
        return is_valid

    @staticmethod
    def validate_quality_inspections(df: pd.DataFrame) -> bool:
        """Validate quality_inspections business rules."""
        is_valid = True
        
        # defects_found <= sample_size
        if not (df['defects_found'] <= df['sample_size']).all():
            logger.error("Validation failed: defects_found > sample_size in quality_inspections.")
            is_valid = False
            
        if is_valid:
            logger.info("quality_inspections passed validation.")
        return is_valid

    @staticmethod
    def validate_maintenance_logs(df: pd.DataFrame) -> bool:
        """Validate maintenance_logs business rules."""
        is_valid = True
        
        # downtime_end >= downtime_start
        mask = df['downtime_end'].notna() & df['downtime_start'].notna()
        if not (df.loc[mask, 'downtime_end'] >= df.loc[mask, 'downtime_start']).all():
            logger.error("Validation failed: downtime_end < downtime_start in maintenance_logs.")
            is_valid = False
            
        if is_valid:
            logger.info("maintenance_logs passed validation.")
        return is_valid
