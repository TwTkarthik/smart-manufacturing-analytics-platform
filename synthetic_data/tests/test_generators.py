import pytest
import pandas as pd
from generators.reference_data import ShiftsGenerator, EmployeesGenerator
from generators.core_entities import MachinesGenerator

def test_shifts_generator():
    config = {'row_count': 10}
    gen = ShiftsGenerator(config=config, seed=42)
    df = gen.generate()
    
    assert not df.empty
    assert len(df) == 10
    assert 'shift_code' in df.columns

def test_employees_generator():
    config = {'row_count': 5}
    shifts_df = pd.DataFrame({'shift_code': ['SHIFT-A', 'SHIFT-B']})
    
    gen = EmployeesGenerator(config=config, seed=42, shifts_df=shifts_df)
    df = gen.generate()
    
    # 5 generated + 1 robot
    assert len(df) == 6
    assert 'employee_id' in df.columns
    assert 'EMP-ROBOT' in df['employee_id'].values

def test_deterministic_generation():
    config = {'row_count': 5}
    shifts_df = pd.DataFrame({'shift_code': ['SHIFT-A', 'SHIFT-B']})
    
    gen1 = EmployeesGenerator(config=config, seed=123, shifts_df=shifts_df)
    df1 = gen1.generate()
    
    gen2 = EmployeesGenerator(config=config, seed=123, shifts_df=shifts_df)
    df2 = gen2.generate()
    
    pd.testing.assert_frame_equal(df1, df2)
