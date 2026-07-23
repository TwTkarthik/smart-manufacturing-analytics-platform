from utils.logger import logger
from pipelines.bronze_pipeline import BronzePipeline
from pipelines.silver_pipeline import SilverPipeline
from pipelines.gold_pipeline import GoldPipeline

class MasterPipeline:
    def __init__(self, bronze: BronzePipeline, silver: SilverPipeline, gold: GoldPipeline, config: dict):
        self.bronze = bronze
        self.silver = silver
        self.gold = gold
        self.config = config

    def run_bronze(self):
        logger.info("--- Executing Bronze Layer ---")
        for table in self.config['extraction']['tables']:
            self.bronze.run(table)

    def run_silver(self):
        logger.info("--- Executing Silver Layer ---")
        for table in self.config['extraction']['tables']:
            self.silver.run(table)

    def run_gold(self):
        logger.info("--- Executing Gold Layer ---")
        self.gold.run()

    def run_full(self):
        logger.info("=== Starting Full ETL Pipeline ===")
        self.run_bronze()
        self.run_silver()
        self.run_gold()
        logger.info("=== Full ETL Pipeline Completed ===")
