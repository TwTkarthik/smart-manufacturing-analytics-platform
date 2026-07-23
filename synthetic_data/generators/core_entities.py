import pandas as pd
import numpy as np
from datetime import datetime, timezone, timedelta
from typing import Dict, Any
from .base import BaseGenerator

class MachinesGenerator(BaseGenerator):
    def __init__(self, config: Dict[str, Any], seed: int, production_lines_df: pd.DataFrame):
        super().__init__(config, seed)
        self.lines_df = production_lines_df
        
    def generate(self) -> pd.DataFrame:
        count = self.config.get('row_count', 48)
        machine_types = ['MCH-LATHE', 'MCH-MILL', 'MCH-GRIND', 'MCH-PRESS', 'MCH-CMM', 'MCH-CONV', 'MCH-ASSY']
        
        # We need a line_code and plant_code. They come together from lines_df
        if self.lines_df.empty:
            raise ValueError("production_lines_df is empty. Cannot generate machines without lines.")
            
        lines_sample = self.lines_df.sample(n=count, replace=True, random_state=self.seed).reset_index(drop=True)
        
        data = {
            'machine_id': [f'MCH-{i:03d}' for i in range(1, count + 1)],
            'machine_name': [f"{self.faker.word().capitalize()} Machine {i}" for i in range(1, count + 1)],
            'machine_type_code': np.random.choice(machine_types, count),
            'line_code': lines_sample['line_code'],
            'plant_code': lines_sample['plant_code'],
            'manufacturer': [self.faker.company() for _ in range(count)],
            'model_number': [f"{self.faker.bothify(text='??-####')}" for _ in range(count)],
            'rated_capacity_per_hour': np.random.uniform(50.0, 500.0, count).round(2),
            'install_date': [self.faker.date_between(start_date='-10y', end_date='today') for _ in range(count)],
            'is_active': np.random.choice([True, False], count, p=[0.9, 0.1]),
            'scada_tag_name': [f"TAG_{self.faker.bothify(text='??###')}_{i}" for i in range(count)],
            'asset_tag_number': [f"AT-{i:04d}" for i in range(count)],
            'erp_work_center_code': [f"WC-{self.faker.bothify(text='####')}" for _ in range(count)],
            'created_at': [datetime.now(timezone.utc)] * count,
            'updated_at': [datetime.now(timezone.utc)] * count
        }
        
        return pd.DataFrame(data)

class PMSchedulesGenerator(BaseGenerator):
    def __init__(self, config: Dict[str, Any], seed: int, machines_df: pd.DataFrame):
        super().__init__(config, seed)
        self.machines_df = machines_df
        
    def generate(self) -> pd.DataFrame:
        count_per_machine = self.config.get('count_per_machine', 3)
        
        if self.machines_df.empty:
            raise ValueError("machines_df is empty. Cannot generate pm_schedules.")
            
        active_machines = self.machines_df[self.machines_df['is_active'] == True]['machine_id'].tolist()
        
        pm_types = ['Lubrication', 'Filter Service', 'Spindle Inspection', 'Full Annual Overhaul', 'Calibration']
        
        data = []
        schedule_id = 1
        
        for machine_id in active_machines:
            num_schedules = np.random.randint(1, count_per_machine + 1)
            selected_types = np.random.choice(pm_types, num_schedules, replace=False)
            
            for pm_type in selected_types:
                # Decide if it's based on days, hours, or both
                mode = np.random.choice(['days', 'hours', 'both'])
                interval_days = np.random.choice([7, 14, 30, 90, 180, 365]) if mode in ['days', 'both'] else None
                interval_hours = np.random.choice([100.0, 500.0, 1000.0, 5000.0]) if mode in ['hours', 'both'] else None
                
                last_performed = self.faker.date_between(start_date='-1y', end_date='today')
                # Simplistic next due date calculation for mock data
                if interval_days:
                    next_due = last_performed + timedelta(days=int(interval_days))
                else:
                    next_due = last_performed + timedelta(days=30) # default if only hours
                    
                data.append({
                    'pm_schedule_id': schedule_id,
                    'machine_id': machine_id,
                    'pm_type': pm_type,
                    'interval_days': interval_days,
                    'interval_hours': interval_hours,
                    'last_performed_date': last_performed,
                    'next_due_date': next_due,
                    'is_active': np.random.choice([True, False], p=[0.95, 0.05]),
                    'created_at': datetime.now(timezone.utc),
                    'updated_at': datetime.now(timezone.utc)
                })
                schedule_id += 1
                
        return pd.DataFrame(data)
