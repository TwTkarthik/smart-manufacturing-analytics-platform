import pandas as pd
import numpy as np
from datetime import datetime, timezone, timedelta
from typing import Dict, Any
from .base import BaseGenerator

class ProductionOrdersGenerator(BaseGenerator):
    def __init__(self, config: Dict[str, Any], seed: int, machines_df: pd.DataFrame, products_df: pd.DataFrame, shifts_df: pd.DataFrame, employees_df: pd.DataFrame):
        super().__init__(config, seed)
        self.machines_df = machines_df
        self.products_df = products_df
        self.shifts_df = shifts_df
        self.employees_df = employees_df
        
    def generate(self) -> pd.DataFrame:
        count = self.config.get('row_count', 5000)
        start_date_str = self.config.get('start_date', '2026-01-01T00:00:00Z')
        end_date_str = self.config.get('end_date', '2026-07-23T00:00:00Z')
        
        start_date = datetime.fromisoformat(start_date_str.replace('Z', '+00:00'))
        end_date = datetime.fromisoformat(end_date_str.replace('Z', '+00:00'))
        
        if any(df.empty for df in [self.machines_df, self.products_df, self.shifts_df, self.employees_df]):
            raise ValueError("Reference DataFrames cannot be empty.")
            
        machine_ids = self.machines_df['machine_id'].tolist()
        product_codes = self.products_df['product_code'].tolist()
        shift_codes = self.shifts_df['shift_code'].tolist()
        
        # Operators for assignment
        operators = self.employees_df[self.employees_df['role_code'] == 'OPR-MCH']['employee_id'].tolist()
        if not operators:
            operators = self.employees_df['employee_id'].tolist()
            
        planned_starts = [self.faker.date_time_between(start_date=start_date, end_date=end_date, tzinfo=timezone.utc) for _ in range(count)]
        planned_starts.sort() # Sort to simulate chronological orders
        
        data = []
        for i, planned_start in enumerate(planned_starts):
            status = np.random.choice(['Complete', 'In Progress', 'Pending', 'Cancelled'], p=[0.9, 0.05, 0.03, 0.02])
            planned_units = np.random.randint(100, 5000)
            
            actual_start = None
            actual_end = None
            actual_units = None
            good_units = None
            scrap_units = None
            rework_units = None
            
            if status in ['Complete', 'In Progress']:
                actual_start = planned_start + timedelta(minutes=np.random.randint(-15, 30))
                
                if status == 'Complete':
                    # Simulate cycle time (let's say 2-10 mins per unit average for batch)
                    run_time_minutes = (planned_units * np.random.uniform(0.1, 1.0))
                    actual_end = actual_start + timedelta(minutes=run_time_minutes)
                    
                    # Yield logic
                    actual_units = int(planned_units * np.random.uniform(0.9, 1.1))
                    scrap_units = int(actual_units * np.random.uniform(0.0, 0.05))
                    rework_units = int(actual_units * np.random.uniform(0.0, 0.03))
                    good_units = actual_units - scrap_units - rework_units
                elif status == 'In Progress':
                    actual_units = int(planned_units * np.random.uniform(0.1, 0.9)) # Partial completion
                    good_units = int(actual_units * 0.95)
                    scrap_units = int(actual_units * 0.03)
                    rework_units = actual_units - good_units - scrap_units
            
            order = {
                'order_id': f"MES-{planned_start.strftime('%Y%m%d')}-{i:05d}",
                'machine_id': np.random.choice(machine_ids),
                'product_code': np.random.choice(product_codes),
                'shift_code': np.random.choice(shift_codes),
                'operator_id': np.random.choice(operators),
                'planned_start': planned_start,
                'actual_start': actual_start,
                'actual_end': actual_end,
                'planned_units': planned_units,
                'actual_units': actual_units,
                'good_units': good_units,
                'scrap_units': scrap_units,
                'rework_units': rework_units,
                'status': status,
                'erp_order_id': f"PP-{planned_start.strftime('%Y%m%d')}-{i:05d}" if np.random.rand() > 0.1 else None,
                'created_at': planned_start - timedelta(days=np.random.randint(1, 5)),
                'updated_at': actual_end if actual_end else (actual_start if actual_start else planned_start)
            }
            data.append(order)
            
        df = pd.DataFrame(data)
        
        # Inject missing values if configured
        missing_rate = self.config.get('missing_value_rate', 0.0)
        df = self._inject_missing_values(df, 'erp_order_id', missing_rate)
        
        return df


class DowntimeEventsGenerator(BaseGenerator):
    def __init__(self, config: Dict[str, Any], seed: int, machines_df: pd.DataFrame, orders_df: pd.DataFrame, employees_df: pd.DataFrame):
        super().__init__(config, seed)
        self.machines_df = machines_df
        self.orders_df = orders_df
        self.employees_df = employees_df
        
    def generate(self) -> pd.DataFrame:
        count = self.config.get('row_count', 2000)
        
        if self.machines_df.empty:
            raise ValueError("machines_df cannot be empty.")
            
        machine_ids = self.machines_df['machine_id'].tolist()
        order_ids = self.orders_df['order_id'].tolist() if not self.orders_df.empty else [None]
        employees = self.employees_df['employee_id'].tolist()
        
        reasons = ['MECH-FAIL', 'TOOL-BREAK', 'PM-WINDOW', 'SETUP', 'NO-MAT', 'ELEC-FAIL', 'PROG-ERR']
        
        start_date_str = self.config.get('start_date', '2026-01-01T00:00:00Z')
        end_date_str = self.config.get('end_date', '2026-07-23T00:00:00Z')
        start_date = datetime.fromisoformat(start_date_str.replace('Z', '+00:00'))
        end_date = datetime.fromisoformat(end_date_str.replace('Z', '+00:00'))
        
        data = []
        for i in range(count):
            downtime_start = self.faker.date_time_between(start_date=start_date, end_date=end_date, tzinfo=timezone.utc)
            event_type = self._weighted_choice(['Planned', 'Unplanned', 'Emergency'], [0.6, 0.3, 0.1], 1)[0]
            
            is_planned = event_type == 'Planned'
            downtime_minutes = np.random.uniform(5.0, 240.0)
            downtime_end = downtime_start + timedelta(minutes=downtime_minutes)
            
            data.append({
                'event_id': f"DT-{downtime_start.strftime('%Y%m%d')}-{i:05d}",
                'machine_id': np.random.choice(machine_ids),
                'order_id': np.random.choice(order_ids) if np.random.rand() > 0.2 else None,
                'event_type': event_type,
                'reason_code': np.random.choice(reasons),
                'reason_description': self.faker.sentence(),
                'downtime_start': downtime_start,
                'downtime_end': downtime_end,
                'downtime_minutes': round(downtime_minutes, 2),
                'reported_by': np.random.choice(employees) if np.random.rand() > 0.1 else None,
                'is_planned': is_planned,
                'created_at': downtime_start
            })
            
        df = pd.DataFrame(data)
        missing_rate = self.config.get('missing_value_rate', 0.05)
        df = self._inject_missing_values(df, 'reason_code', missing_rate)
        
        return df


class QualityInspectionsGenerator(BaseGenerator):
    def __init__(self, config: Dict[str, Any], seed: int, orders_df: pd.DataFrame, machines_df: pd.DataFrame, employees_df: pd.DataFrame, defects_df: pd.DataFrame):
        super().__init__(config, seed)
        self.orders_df = orders_df
        self.machines_df = machines_df
        self.employees_df = employees_df
        self.defects_df = defects_df
        
    def generate(self) -> pd.DataFrame:
        count = self.config.get('row_count', 6000)
        
        if self.orders_df.empty or self.machines_df.empty:
            raise ValueError("Reference DataFrames cannot be empty.")
            
        # Filter to completed/in-progress orders
        valid_orders = self.orders_df[self.orders_df['status'].isin(['Complete', 'In Progress'])]
        if valid_orders.empty:
            valid_orders = self.orders_df
            
        qa_techs = self.employees_df[self.employees_df['role_code'] == 'QA-TECH']['employee_id'].tolist()
        if not qa_techs:
            qa_techs = self.employees_df['employee_id'].tolist()
            
        defect_codes = self.defects_df['defect_type_code'].tolist() if not self.defects_df.empty else [None]
        
        data = []
        overall_defect_rate = self.config.get('defect_rate', 0.15)
        
        for i in range(count):
            order = valid_orders.sample(1, random_state=self.seed + i).iloc[0]
            base_time = order['actual_start'] if pd.notna(order['actual_start']) else order['planned_start']
            
            inspection_ts = base_time + timedelta(minutes=np.random.randint(10, 120))
            
            pass_fail = 'F' if np.random.rand() < overall_defect_rate else 'P'
            sample_size = np.random.randint(5, 50)
            
            if pass_fail == 'F':
                defects_found = np.random.randint(1, sample_size + 1)
                defect_code = np.random.choice(defect_codes)
            else:
                defects_found = 0
                defect_code = None
                
            data.append({
                'inspection_id': f"QI-{inspection_ts.strftime('%Y%m%d')}-{i:05d}",
                'order_id': order['order_id'],
                'machine_id': order['machine_id'],
                'inspector_id': np.random.choice(qa_techs) if np.random.rand() > 0.1 else None,
                'inspection_type_code': np.random.choice(['FIRST-ARTICLE', 'IN-PROCESS', 'FINAL', 'FUNCTIONAL']),
                'inspection_timestamp': inspection_ts,
                'sample_size': sample_size,
                'defects_found': defects_found,
                'defect_type_code': defect_code,
                'defect_description': self.faker.sentence() if pass_fail == 'F' else None,
                'measurement_value': round(np.random.normal(50.0, 0.5), 6),
                'measurement_unit': 'mm',
                'pass_fail': pass_fail,
                'created_at': inspection_ts
            })
            
        return pd.DataFrame(data)


class MaintenanceLogsGenerator(BaseGenerator):
    def __init__(self, config: Dict[str, Any], seed: int, machines_df: pd.DataFrame, employees_df: pd.DataFrame, pm_schedules_df: pd.DataFrame):
        super().__init__(config, seed)
        self.machines_df = machines_df
        self.employees_df = employees_df
        self.pm_schedules_df = pm_schedules_df
        
    def generate(self) -> pd.DataFrame:
        count = self.config.get('row_count', 1000)
        
        if self.machines_df.empty:
            raise ValueError("machines_df cannot be empty.")
            
        machine_ids = self.machines_df['machine_id'].tolist()
        mnt_techs = self.employees_df[self.employees_df['department_code'] == 'DEPT-MNT']['employee_id'].tolist()
        if not mnt_techs:
            mnt_techs = self.employees_df['employee_id'].tolist()
            
        pm_ids = self.pm_schedules_df['pm_schedule_id'].tolist() if not self.pm_schedules_df.empty else [None]
        
        start_date_str = self.config.get('start_date', '2026-01-01T00:00:00Z')
        end_date_str = self.config.get('end_date', '2026-07-23T00:00:00Z')
        start_date = datetime.fromisoformat(start_date_str.replace('Z', '+00:00'))
        end_date = datetime.fromisoformat(end_date_str.replace('Z', '+00:00'))
        
        data = []
        for i in range(count):
            downtime_start = self.faker.date_time_between(start_date=start_date, end_date=end_date, tzinfo=timezone.utc)
            event_type = self._weighted_choice(['Planned', 'Unplanned', 'Emergency'], [0.5, 0.4, 0.1], 1)[0]
            
            downtime_minutes = np.random.uniform(15.0, 480.0)
            downtime_end = downtime_start + timedelta(minutes=downtime_minutes)
            
            data.append({
                'work_order_id': f"WO-{downtime_start.strftime('%Y%m%d')}-{i:04d}",
                'machine_id': np.random.choice(machine_ids),
                'technician_id': np.random.choice(mnt_techs),
                'event_type': event_type,
                'failure_code': f"FC-{self.faker.word()[:4].upper()}" if event_type != 'Planned' else None,
                'description': self.faker.sentence(),
                'downtime_start': downtime_start,
                'downtime_end': downtime_end,
                'downtime_minutes': round(downtime_minutes, 2),
                'repair_cost': round(np.random.uniform(50.0, 5000.0), 4),
                'root_cause': self.faker.paragraph() if np.random.rand() > 0.7 else None,
                'pm_schedule_id': np.random.choice(pm_ids) if event_type == 'Planned' and pm_ids[0] else None,
                'created_at': downtime_start - timedelta(days=np.random.randint(0, 7))
            })
            
        return pd.DataFrame(data)


class MaterialMovementsGenerator(BaseGenerator):
    def __init__(self, config: Dict[str, Any], seed: int, spare_parts_df: pd.DataFrame, maintenance_logs_df: pd.DataFrame):
        super().__init__(config, seed)
        self.spare_parts_df = spare_parts_df
        self.maintenance_logs_df = maintenance_logs_df
        
    def generate(self) -> pd.DataFrame:
        count = self.config.get('row_count', 3000)
        
        if self.spare_parts_df.empty:
            raise ValueError("spare_parts_df cannot be empty.")
            
        part_codes = self.spare_parts_df['part_code'].tolist()
        work_orders = self.maintenance_logs_df['work_order_id'].tolist() if not self.maintenance_logs_df.empty else [None]
        
        start_date_str = self.config.get('start_date', '2026-01-01T00:00:00Z')
        end_date_str = self.config.get('end_date', '2026-07-23T00:00:00Z')
        start_date = datetime.fromisoformat(start_date_str.replace('Z', '+00:00')).date()
        end_date = datetime.fromisoformat(end_date_str.replace('Z', '+00:00')).date()
        
        data = []
        for i in range(1, count + 1):
            mov_type = self._weighted_choice(['GOODS_ISSUE', 'GOODS_RECEIPT', 'STOCK_TRANSFER', 'RETURN'], [0.6, 0.2, 0.1, 0.1], 1)[0]
            
            part = np.random.choice(part_codes)
            qty = round(np.random.uniform(1.0, 50.0), 4)
            # Find unit cost from spare parts
            part_row = self.spare_parts_df[self.spare_parts_df['part_code'] == part]
            unit_cost = part_row['unit_cost'].values[0] if not part_row.empty else 10.0
            total_cost = round(qty * unit_cost, 4)
            
            data.append({
                'movement_id': i,
                'part_code': part,
                'work_order_id': np.random.choice(work_orders) if mov_type in ['GOODS_ISSUE', 'RETURN'] and work_orders[0] else None,
                'movement_type': mov_type,
                'qty': qty,
                'unit_cost': unit_cost,
                'total_cost': total_cost,
                'movement_date': self.faker.date_between(start_date=start_date, end_date=end_date),
                'created_by': 'EMP-SYSTEM',
                'created_at': datetime.now(timezone.utc)
            })
            
        return pd.DataFrame(data)
