import pandas as pd
import numpy as np
from datetime import datetime, timezone, timedelta
from typing import Dict, Any
from .base import BaseGenerator

class SensorReadingsGenerator(BaseGenerator):
    def __init__(self, config: Dict[str, Any], seed: int, machines_df: pd.DataFrame):
        super().__init__(config, seed)
        self.machines_df = machines_df
        
    def generate(self) -> pd.DataFrame:
        if self.machines_df.empty:
            raise ValueError("machines_df cannot be empty.")
            
        machine_ids = self.machines_df['machine_id'].tolist()
        
        start_date_str = self.config.get('start_date', '2026-01-01T00:00:00Z')
        end_date_str = self.config.get('end_date', '2026-07-23T00:00:00Z')
        start_date = datetime.fromisoformat(start_date_str.replace('Z', '+00:00'))
        end_date = datetime.fromisoformat(end_date_str.replace('Z', '+00:00'))
        
        days_diff = (end_date - start_date).days
        if days_diff < 1:
            days_diff = 1
            
        readings_per_day = self.config.get('readings_per_machine_per_day', 144) # default: every 10 mins
        total_readings_per_machine = readings_per_day * days_diff
        
        sensors = [
            {'type': 'temperature', 'unit': 'C', 'mean': 65.0, 'std': 5.0},
            {'type': 'vibration', 'unit': 'mm/s', 'mean': 2.5, 'std': 0.5},
            {'type': 'rpm', 'unit': 'RPM', 'mean': 1500.0, 'std': 50.0},
            {'type': 'pressure', 'unit': 'PSI', 'mean': 120.0, 'std': 10.0},
            {'type': 'power', 'unit': 'kWh', 'mean': 45.0, 'std': 2.0},
            {'type': 'cutting_force', 'unit': 'N', 'mean': 300.0, 'std': 25.0},
            {'type': 'coolant_flow', 'unit': 'L/min', 'mean': 15.0, 'std': 1.5}
        ]
        
        # We will use vectorized numpy for speed since this is high-volume
        all_data = []
        
        reading_id = 1
        
        # Calculate timestamps once for all machines
        # Create an array of timestamps distributed evenly over the period
        times = [start_date + timedelta(minutes=(1440/readings_per_day)*i) for i in range(total_readings_per_machine)]
        
        for machine_id in machine_ids:
            for sensor in sensors:
                values = np.random.normal(sensor['mean'], sensor['std'], total_readings_per_machine)
                
                # Anomaly injection
                anomaly_rate = self.config.get('anomaly_rate', 0.02)
                anomaly_mask = np.random.rand(total_readings_per_machine) < anomaly_rate
                # Increase or decrease values significantly for anomalies
                anomaly_multiplier = np.random.choice([1.5, 0.5], total_readings_per_machine)
                values[anomaly_mask] = values[anomaly_mask] * anomaly_multiplier[anomaly_mask]
                
                quality_scores = np.random.uniform(0.9, 1.0, total_readings_per_machine)
                quality_scores[anomaly_mask] = np.random.uniform(0.4, 0.8, anomaly_mask.sum())
                
                machine_df = pd.DataFrame({
                    'reading_id': range(reading_id, reading_id + total_readings_per_machine),
                    'machine_id': machine_id,
                    'sensor_type': sensor['type'],
                    'sensor_unit': sensor['unit'],
                    'value': np.round(values, 6),
                    'reading_timestamp': times,
                    'is_anomaly_flagged': anomaly_mask,
                    'data_quality_score': np.round(quality_scores, 3)
                })
                
                all_data.append(machine_df)
                reading_id += total_readings_per_machine
                
        df = pd.concat(all_data, ignore_index=True)
        return df
