import argparse
import yaml
from pathlib import Path
import sys

from utils.logger import logger
from utils.db import DatabaseManager
from loaders.exporter import Exporter
from loaders.pg_loader import PgLoader
from validators.schema_validator import SchemaValidator

from generators.reference_data import (
    ProductionLinesGenerator, ShiftsGenerator, DefectTypesGenerator,
    ProductsGenerator, SparePartsGenerator, EmployeesGenerator
)
from generators.core_entities import MachinesGenerator, PMSchedulesGenerator
from generators.transactions import (
    ProductionOrdersGenerator, DowntimeEventsGenerator, QualityInspectionsGenerator,
    MaintenanceLogsGenerator, MaterialMovementsGenerator
)
from generators.telemetry import SensorReadingsGenerator

def load_config(config_path: str) -> dict:
    with open(config_path, 'r') as f:
        return yaml.safe_load(f)

def main():
    parser = argparse.ArgumentParser(description="SMAP Synthetic Data Generator")
    parser.add_argument("--config", type=str, default="config/config.yaml", help="Path to config file")
    parser.add_argument("--export-csv", action="store_true", help="Export to CSV")
    parser.add_argument("--export-json", action="store_true", help="Export to JSON")
    parser.add_argument("--load-pg", action="store_true", help="Load to PostgreSQL")
    parser.add_argument("--validate", action="store_true", help="Run validation on generated data")
    
    args = parser.parse_args()
    
    config = load_config(args.config)
    seed = config.get('global', {}).get('seed', 42)
    db_dsn = config.get('global', {}).get('db_dsn', '')
    
    logger.info(f"Starting SMAP Synthetic Data Generator (Seed: {seed})")
    
    db_manager = DatabaseManager(db_dsn) if args.load_pg or db_dsn else None
    if db_manager and args.load_pg:
        db_manager.connect()
        
    exporter = Exporter()
    pg_loader = PgLoader(db_manager) if db_manager else None
    
    gen_params = config.get('generation_params', {})
    
    # Storage for dataframes to maintain referential integrity across generations
    dfs = {}
    
    def generate_and_handle(name, GeneratorClass, **kwargs):
        params = gen_params.get(name, {})
        params.update({'start_date': config['global'].get('start_date'), 'end_date': config['global'].get('end_date')})
        
        if params.get('generate', False):
            logger.info(f"Generating {name}...")
            generator = GeneratorClass(config=params, seed=seed, **kwargs)
            df = generator.generate()
            dfs[name] = df
            
            if args.export_csv:
                exporter.export_csv(df, name)
            if args.export_json:
                exporter.export_json(df, name)
            if args.load_pg and pg_loader:
                pg_loader.load(df, name, if_exists="append")
                
        else:
            # If not generating, attempt to fetch from DB if needed as reference data
            logger.info(f"Skipping generation of {name}. Fetching from DB for reference...")
            if db_manager:
                dfs[name] = db_manager.fetch_reference_data(name)
            else:
                dfs[name] = None
                
    # 1. Reference Data
    generate_and_handle('production_lines', ProductionLinesGenerator)
    generate_and_handle('shifts', ShiftsGenerator)
    generate_and_handle('defect_types', DefectTypesGenerator)
    generate_and_handle('products', ProductsGenerator)
    generate_and_handle('spare_parts', SparePartsGenerator)
    
    # 2. Employees (depends on shifts)
    generate_and_handle('employees', EmployeesGenerator, shifts_df=dfs.get('shifts'))
    
    # 3. Core Entities (depends on lines)
    generate_and_handle('machines', MachinesGenerator, production_lines_df=dfs.get('production_lines'))
    generate_and_handle('pm_schedules', PMSchedulesGenerator, machines_df=dfs.get('machines'))
    
    # 4. Transactions
    generate_and_handle(
        'production_orders', ProductionOrdersGenerator, 
        machines_df=dfs.get('machines'), products_df=dfs.get('products'), 
        shifts_df=dfs.get('shifts'), employees_df=dfs.get('employees')
    )
    
    generate_and_handle(
        'downtime_events', DowntimeEventsGenerator,
        machines_df=dfs.get('machines'), orders_df=dfs.get('production_orders'),
        employees_df=dfs.get('employees')
    )
    
    generate_and_handle(
        'quality_inspections', QualityInspectionsGenerator,
        orders_df=dfs.get('production_orders'), machines_df=dfs.get('machines'),
        employees_df=dfs.get('employees'), defects_df=dfs.get('defect_types')
    )
    
    generate_and_handle(
        'maintenance_logs', MaintenanceLogsGenerator,
        machines_df=dfs.get('machines'), employees_df=dfs.get('employees'),
        pm_schedules_df=dfs.get('pm_schedules')
    )
    
    generate_and_handle(
        'material_movements', MaterialMovementsGenerator,
        spare_parts_df=dfs.get('spare_parts'), maintenance_logs_df=dfs.get('maintenance_logs')
    )
    
    # 5. Telemetry
    generate_and_handle(
        'sensor_readings', SensorReadingsGenerator,
        machines_df=dfs.get('machines')
    )

    if args.validate:
        logger.info("Running schema and business rule validations...")
        if 'production_orders' in dfs and dfs['production_orders'] is not None:
            SchemaValidator.validate_production_orders(dfs['production_orders'])
        if 'quality_inspections' in dfs and dfs['quality_inspections'] is not None:
            SchemaValidator.validate_quality_inspections(dfs['quality_inspections'])
        if 'maintenance_logs' in dfs and dfs['maintenance_logs'] is not None:
            SchemaValidator.validate_maintenance_logs(dfs['maintenance_logs'])
            
    logger.info("Generation process completed successfully.")

if __name__ == "__main__":
    main()
