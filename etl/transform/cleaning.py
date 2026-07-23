import pandas as pd
from utils.logger import logger

class DataCleaner:
    @staticmethod
    def remove_duplicates(df: pd.DataFrame, subset_cols: list = None) -> pd.DataFrame:
        """Remove exact duplicate rows based on subset."""
        initial_len = len(df)
        df_clean = df.drop_duplicates(subset=subset_cols)
        dropped = initial_len - len(df_clean)
        if dropped > 0:
            logger.info(f"Removed {dropped} duplicate rows.")
        return df_clean

    @staticmethod
    def handle_missing_values(df: pd.DataFrame, fill_rules: dict) -> pd.DataFrame:
        """
        Fill missing values based on dictionary rules.
        Example: {'reason_code': 'UNKNOWN', 'downtime_minutes': 0}
        """
        df_clean = df.copy()
        for col, fill_val in fill_rules.items():
            if col in df_clean.columns:
                missing_count = df_clean[col].isna().sum()
                if missing_count > 0:
                    df_clean[col] = df_clean[col].fillna(fill_val)
                    logger.info(f"Filled {missing_count} missing values in {col} with '{fill_val}'.")
        return df_clean

    @staticmethod
    def standardize_column_names(df: pd.DataFrame) -> pd.DataFrame:
        """Ensure column names are lowercase snake_case (basic implementation)."""
        df.columns = [c.strip().lower().replace(' ', '_') for c in df.columns]
        return df
