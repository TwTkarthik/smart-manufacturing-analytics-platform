import pandas as pd

class BusinessRules:
    @staticmethod
    def categorize_downtime(df: pd.DataFrame) -> pd.DataFrame:
        """Derive a top-level category from reason codes for downtime."""
        if 'reason_code' not in df.columns:
            return df
            
        def categorize(code):
            if not code or pd.isna(code): return 'Unknown'
            code = str(code).upper()
            if 'MECH' in code or 'TOOL' in code or 'ELEC' in code: return 'Equipment Failure'
            if 'PM' in code or 'SETUP' in code: return 'Planned Stop'
            if 'MAT' in code: return 'Material Shortage'
            return 'Other'
            
        df['downtime_category'] = df['reason_code'].apply(categorize)
        return df

    @staticmethod
    def calculate_yield(df: pd.DataFrame) -> pd.DataFrame:
        """Calculate yield percentage for production orders."""
        if all(col in df.columns for col in ['actual_units', 'good_units']):
            # Avoid division by zero
            mask = df['actual_units'] > 0
            df['yield_pct'] = 0.0
            df.loc[mask, 'yield_pct'] = (df.loc[mask, 'good_units'] / df.loc[mask, 'actual_units']) * 100.0
            df['yield_pct'] = df['yield_pct'].round(2)
        return df
