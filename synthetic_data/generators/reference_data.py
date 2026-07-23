import pandas as pd
from datetime import datetime, timezone
import numpy as np
from typing import Dict, Any, List
from .base import BaseGenerator

class ProductionLinesGenerator(BaseGenerator):
    def generate(self) -> pd.DataFrame:
        count = self.config.get('row_count', 11)
        plants = ['PLT-DET', 'PLT-CLV', 'PLT-CHI', 'PLT-MTY']
        
        data = {
            'line_code': [f'LINE-{chr(65+i)}' for i in range(count)],
            'line_name': [f"{self.faker.word().capitalize()} Cell {i}" for i in range(count)],
            'plant_code': self._weighted_choice(plants, [0.4, 0.3, 0.2, 0.1], count),
            'primary_operation': [self.faker.job() for _ in range(count)],
            'shift_pattern': np.random.choice(['3-shift, 6 days/week', '2-shift, 5 days/week'], count),
            'oee_target': np.random.uniform(0.70, 0.90, count).round(4),
            'is_active': np.random.choice([True, False], count, p=[0.95, 0.05])
        }
        return pd.DataFrame(data)


class ShiftsGenerator(BaseGenerator):
    def generate(self) -> pd.DataFrame:
        data = {
            'shift_code': ['SHIFT-A', 'SHIFT-B', 'SHIFT-C', 'SHIFT-D', 'SHIFT-E', 'SHIFT-F', 'SHIFT-G', 'SHIFT-H', 'SHIFT-I', 'SHIFT-J'],
            'shift_name': ['Day Shift', 'Afternoon Shift', 'Night Shift'] * 3 + ['Day Shift'],
            'shift_start_time': ['06:00:00', '14:00:00', '22:00:00'] * 3 + ['07:00:00'],
            'shift_end_time': ['14:00:00', '22:00:00', '06:00:00'] * 3 + ['15:00:00'],
            'shift_duration_hours': [8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 10.0, 10.0, 8.0, 8.0],
            'planned_production_hours': [7.5, 7.5, 7.5, 7.75, 7.75, 7.75, 9.5, 9.5, 7.5, 7.5],
            'plant_code': ['PLT-DET']*3 + ['PLT-CLV']*3 + ['PLT-CHI']*2 + ['PLT-MTY']*2
        }
        return pd.DataFrame(data)


class DefectTypesGenerator(BaseGenerator):
    def generate(self) -> pd.DataFrame:
        count = self.config.get('row_count', 15)
        categories = ['Dimensional', 'Surface', 'Structural', 'Functional', 'Other']
        severities = ['Critical', 'Major', 'Minor']
        
        data = {
            'defect_type_code': [f'DFT-{i:03d}' for i in range(count)],
            'defect_type_name': [f"{self.faker.word().capitalize()} Defect" for _ in range(count)],
            'defect_category': np.random.choice(categories, count),
            'severity_level': self._weighted_choice(severities, [0.2, 0.5, 0.3], count),
            'is_customer_escape_risk': np.random.choice([True, False], count, p=[0.3, 0.7]),
            'description': [self.faker.sentence() for _ in range(count)],
            'is_active': [True] * count
        }
        return pd.DataFrame(data)


class ProductsGenerator(BaseGenerator):
    def generate(self) -> pd.DataFrame:
        count = self.config.get('row_count', 8)
        categories = ['Automotive', 'Industrial']
        families = ['Powertrain', 'Brake', 'Steering', 'Suspension', 'Flange']
        
        data = {
            'product_code': [f'PRD-{i:03d}' for i in range(count)],
            'product_name': [f"{self.faker.word().capitalize()} Component" for _ in range(count)],
            'product_family': np.random.choice(families, count),
            'product_category': np.random.choice(categories, count),
            'standard_cycle_time_sec': np.random.uniform(100.0, 600.0, count).round(3),
            'standard_material_cost': np.random.uniform(10.0, 100.0, count).round(4),
            'standard_labor_cost': np.random.uniform(5.0, 30.0, count).round(4),
            'is_active': [True] * count,
            'erp_material_code': [f'MAT-{i:03d}' for i in range(count)],
            'created_at': [datetime.now(timezone.utc)] * count,
            'updated_at': [datetime.now(timezone.utc)] * count
        }
        return pd.DataFrame(data)


class SparePartsGenerator(BaseGenerator):
    def generate(self) -> pd.DataFrame:
        count = self.config.get('row_count', 20)
        categories = ['Bearings', 'Seals', 'Filters', 'Belts', 'Electronics', 'Hydraulics', 'Tooling', 'Other']
        
        data = {
            'part_code': [f'SP-{i:04d}' for i in range(count)],
            'part_description': [self.faker.sentence(nb_words=4) for _ in range(count)],
            'part_category': np.random.choice(categories, count),
            'stock_qty': np.random.randint(0, 200, count),
            'reorder_point': np.random.randint(5, 50, count),
            'lead_time_days': np.random.randint(1, 30, count),
            'unit_cost': np.random.uniform(1.0, 500.0, count).round(4),
            'supplier_code': [f'SUP-{self.faker.word().upper()[:4]}-{i}' for i in range(count)],
            'updated_at': [datetime.now(timezone.utc)] * count
        }
        return pd.DataFrame(data)


class EmployeesGenerator(BaseGenerator):
    def __init__(self, config: Dict[str, Any], seed: int = 42, shifts_df: pd.DataFrame = None):
        super().__init__(config, seed)
        self.shifts_df = shifts_df if shifts_df is not None else pd.DataFrame({'shift_code': ['SHIFT-A']})

    def generate(self) -> pd.DataFrame:
        count = self.config.get('row_count', 50)
        roles = ['OPR-MCH', 'OPR-SET', 'QA-TECH', 'MNT-TECH', 'MNT-PLNR']
        depts = ['DEPT-OPS', 'DEPT-QA', 'DEPT-MNT', 'DEPT-ENG']
        skills = ['Junior', 'Senior', 'Expert']
        shifts = self.shifts_df['shift_code'].tolist()
        
        # Determine department based on role
        def get_dept(role):
            if role in ['OPR-MCH', 'OPR-SET']: return 'DEPT-OPS'
            if role == 'QA-TECH': return 'DEPT-QA'
            if role in ['MNT-TECH', 'MNT-PLNR']: return 'DEPT-MNT'
            return 'DEPT-ENG'

        role_assignments = self._weighted_choice(roles, [0.6, 0.15, 0.1, 0.1, 0.05], count)
        dept_assignments = [get_dept(r) for r in role_assignments]
        
        data = {
            'employee_id': [f'EMP-{i:04d}' for i in range(1, count + 1)],
            'role_code': role_assignments,
            'role_name': [f"{r} Name" for r in role_assignments],
            'department_code': dept_assignments,
            'shift_assignment': np.random.choice(shifts, count),
            'skill_level': self._weighted_choice(skills, [0.4, 0.4, 0.2], count),
            'training_certifications': ['IATF-16949' if np.random.rand() > 0.5 else '' for _ in range(count)],
            'hire_date': [self.faker.date_between(start_date='-5y', end_date='today') for _ in range(count)],
            'is_active': np.random.choice([True, False], count, p=[0.9, 0.1]),
            'is_automated': [False] * count,
            'created_at': [datetime.now(timezone.utc)] * count,
            'updated_at': [datetime.now(timezone.utc)] * count
        }
        
        df = pd.DataFrame(data)
        
        # Add EMP-ROBOT as a special record
        robot = pd.DataFrame([{
            'employee_id': 'EMP-ROBOT',
            'role_code': 'OPR-MCH',
            'role_name': 'Automated Machine Cycle',
            'department_code': 'DEPT-OPS',
            'shift_assignment': shifts[0],
            'skill_level': None,
            'training_certifications': None,
            'hire_date': None,
            'is_active': True,
            'is_automated': True,
            'created_at': datetime.now(timezone.utc),
            'updated_at': datetime.now(timezone.utc)
        }])
        
        df = pd.concat([df, robot], ignore_index=True)
        return df
