import pandas as pd
from utils.logger import logger

class DataValidator:
    @staticmethod
    def enforce_types(df: pd.DataFrame, type_map: dict) -> pd.DataFrame:
        """
        Enforce Pandas data types.
        Example: {'start_time': 'datetime64[ns]', 'qty': 'float64'}
        """
        df_typed = df.copy()
        for col, dtype in type_map.items():
            if col in df_typed.columns:
                try:
                    if dtype.startswith('datetime'):
                        df_typed[col] = pd.to_datetime(df_typed[col], errors='coerce')
                    else:
                        df_typed[col] = df_typed[col].astype(dtype)
                except Exception as e:
                    logger.error(f"Failed to cast {col} to {dtype}: {e}")
        return df_typed
