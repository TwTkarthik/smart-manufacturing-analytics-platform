import argparse
import sys
from utils.logger import logger
from utils.helpers import load_config
from utils.database import DatabaseManager

from extract.postgres_extractor import PostgresExtractor
from load.warehouse_loader import WarehouseLoader
from load.bulk_loader import BulkLoader
from quality.quality_checks import QualityChecker

from pipelines.bronze_pipeline import BronzePipeline
from pipelines.silver_pipeline import SilverPipeline
from pipelines.gold_pipeline import GoldPipeline
from pipelines.master_pipeline import MasterPipeline

def main():
    parser = argparse.ArgumentParser(description="SMAP Enterprise ETL Platform")
    parser.add_argument("pipeline", choices=["bronze", "silver", "gold", "full"], help="Pipeline layer to execute")
    parser.add_argument("--config", default="config/config.yaml", help="Path to config yaml")
    
    args = parser.parse_args()
    
    try:
        config = load_config(args.config)
        
        # Init resources
        source_db = DatabaseManager(config['database']['source']['dsn'])
        target_db = DatabaseManager(config['database']['destination']['dsn'])
        
        # We need a fallback if the target DW doesn't exist yet, we can test using source db
        try:
            target_db.engine.connect()
        except Exception:
            logger.warning("Target DW is unavailable. Falling back to source DB for schema creation.")
            target_db = DatabaseManager(config['database']['destination']['fallback_dsn'])
        
        # Init Extractors and Loaders
        pg_extractor = PostgresExtractor(source_db, schema=config['database']['source']['schema'])
        wh_loader = WarehouseLoader(target_db)
        bulk_loader = BulkLoader(target_db)
        quality_checker = QualityChecker(strict_mode=config['quality'].get('strict_mode', False))
        
        # Init Pipelines
        bronze = BronzePipeline(pg_extractor, wh_loader, bulk_loader, config)
        silver = SilverPipeline(target_db, wh_loader, config, quality_checker)
        gold = GoldPipeline(target_db, wh_loader, config)
        master = MasterPipeline(bronze, silver, gold, config)
        
        if args.pipeline == "bronze":
            master.run_bronze()
        elif args.pipeline == "silver":
            master.run_silver()
        elif args.pipeline == "gold":
            master.run_gold()
        elif args.pipeline == "full":
            master.run_full()
            
    except Exception as e:
        logger.error(f"ETL Execution failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
