import pandas as pd
from pathlib import Path
from utils.logger import logger

class Exporter:
    def __init__(self, output_dir: str = "output"):
        self.output_dir = Path(__file__).parent.parent / output_dir
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
    def export_csv(self, df: pd.DataFrame, filename: str) -> None:
        """Export DataFrame to CSV."""
        filepath = self.output_dir / f"{filename}.csv"
        try:
            df.to_csv(filepath, index=False)
            logger.info(f"Successfully exported {filename}.csv ({len(df)} rows)")
        except Exception as e:
            logger.error(f"Failed to export {filename}.csv: {e}")
            
    def export_json(self, df: pd.DataFrame, filename: str) -> None:
        """Export DataFrame to JSON records."""
        filepath = self.output_dir / f"{filename}.json"
        try:
            # Handle datetime serialization by converting to ISO format strings first
            # if default pandas serialization is insufficient
            df.to_json(filepath, orient='records', date_format='iso', lines=True)
            logger.info(f"Successfully exported {filename}.json ({len(df)} rows)")
        except Exception as e:
            logger.error(f"Failed to export {filename}.json: {e}")
