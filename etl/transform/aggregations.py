import pandas as pd

class Aggregator:
    @staticmethod
    def calculate_daily_machine_oee(orders_df: pd.DataFrame, downtime_df: pd.DataFrame) -> pd.DataFrame:
        """
        Calculates simplistic daily OEE components per machine based on orders and downtime.
        Note: This is a placeholder logic for demonstration of Gold layer aggregations.
        Real OEE requires exact standard cycle times and planned production time configurations.
        """
        if orders_df.empty:
            return pd.DataFrame()
            
        # Extract date from actual_start
        orders_df['production_date'] = pd.to_datetime(orders_df['actual_start']).dt.date
        
        # 1. Quality & Performance from Orders
        daily_prod = orders_df.groupby(['production_date', 'machine_id']).agg(
            total_produced=('actual_units', 'sum'),
            good_produced=('good_units', 'sum'),
            total_scrap=('scrap_units', 'sum')
        ).reset_index()
        
        # Calculate Quality score
        daily_prod['quality_score'] = (daily_prod['good_produced'] / daily_prod['total_produced']).fillna(0)
        
        # 2. Availability from Downtime
        if not downtime_df.empty and 'downtime_start' in downtime_df.columns:
            downtime_df['production_date'] = pd.to_datetime(downtime_df['downtime_start']).dt.date
            daily_dt = downtime_df.groupby(['production_date', 'machine_id']).agg(
                total_downtime_minutes=('downtime_minutes', 'sum')
            ).reset_index()
            
            # Merge
            oee_df = daily_prod.merge(daily_dt, on=['production_date', 'machine_id'], how='left')
            oee_df['total_downtime_minutes'] = oee_df['total_downtime_minutes'].fillna(0)
        else:
            oee_df = daily_prod.copy()
            oee_df['total_downtime_minutes'] = 0.0
            
        # Simplified Availability (Assuming 24h = 1440 mins planned time for this mock)
        oee_df['availability_score'] = ((1440 - oee_df['total_downtime_minutes']) / 1440).clip(lower=0)
        
        # Simplified Performance (Assuming total_produced / theoretical_max. Just mocking here)
        oee_df['performance_score'] = 0.85 # Mocked for this example
        
        oee_df['oee_percentage'] = (oee_df['availability_score'] * oee_df['performance_score'] * oee_df['quality_score']) * 100
        oee_df['oee_percentage'] = oee_df['oee_percentage'].round(2)
        
        return oee_df
