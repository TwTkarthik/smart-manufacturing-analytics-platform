import pandas as pd
from pathlib import Path
from typing import Optional
from utils.logger import logger

class FileExtractor:
    def __init__(self, source_dir: str):
        self.source_dir = Path(source_dir)

    def extract_csv(self, filename: str) -> pd.DataFrame:
        """Extract data from a CSV file."""
        filepath = self.source_dir / f"{filename}.csv"
        if not filepath.exists():
            logger.error(f"File not found: {filepath}")
            raise FileNotFoundError(f"No such file: {filepath}")
            
        try:
            logger.info(f"Extracting from {filepath}")
            df = pd.read_csv(filepath)
            logger.info(f"Extracted {len(df)} rows from {filename}.csv")
            return df
        except Exception as e:
            logger.error(f"Failed to read CSV {filename}: {e}")
            raise

    def extract_json(self, filename: str) -> pd.DataFrame:
        """Extract data from a JSON file."""
        filepath = self.source_dir / f"{filename}.json"
        if not filepath.exists():
            logger.error(f"File not found: {filepath}")
            raise FileNotFoundError(f"No such file: {filepath}")
            
        try:
            logger.info(f"Extracting from {filepath}")
            df = pd.read_json(filepath, orient='records', lines=True)
            logger.info(f"Extracted {len(df)} rows from {filename}.json")
            return df
        except Exception as e:
            logger.error(f"Failed to read JSON {filename}: {e}")
            raise
