import time
from utils.logger import logger
from pipelines.master_pipeline import MasterPipeline

class ETLScheduler:
    """Basic loop-based scheduler for demonstration. In prod, use Airflow or Prefect."""
    def __init__(self, master_pipeline: MasterPipeline, interval_seconds: int = 3600):
        self.master_pipeline = master_pipeline
        self.interval_seconds = interval_seconds

    def run_forever(self):
        logger.info(f"Starting ETL Scheduler. Interval: {self.interval_seconds} seconds.")
        try:
            while True:
                logger.info("Scheduler Triggering Master Pipeline...")
                self.master_pipeline.run_full()
                logger.info(f"Sleeping for {self.interval_seconds} seconds...")
                time.sleep(self.interval_seconds)
        except KeyboardInterrupt:
            logger.info("Scheduler stopped by user.")
        except Exception as e:
            logger.error(f"Scheduler crashed: {e}")
            raise
