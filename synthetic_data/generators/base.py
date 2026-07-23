import pandas as pd
import numpy as np
from faker import Faker
from typing import Dict, Any, List, Optional
from datetime import datetime
from utils.logger import logger

class BaseGenerator:
    """Base class for all synthetic data generators."""
    
    def __init__(self, config: Dict[str, Any], seed: int = 42):
        self.config = config
        self.seed = seed
        self.faker = Faker()
        self.faker.seed_instance(seed)
        np.random.seed(seed)
        
    def _inject_missing_values(self, df: pd.DataFrame, column: str, missing_rate: float) -> pd.DataFrame:
        """Randomly inject missing values (NaN/None) into a specified column."""
        if missing_rate <= 0:
            return df
            
        mask = np.random.rand(len(df)) < missing_rate
        df.loc[mask, column] = None
        return df
        
    def _inject_duplicates(self, df: pd.DataFrame, duplicate_rate: float) -> pd.DataFrame:
        """Randomly duplicate rows to simulate unclean data."""
        if duplicate_rate <= 0:
            return df
            
        num_duplicates = int(len(df) * duplicate_rate)
        if num_duplicates == 0:
            return df
            
        duplicate_indices = np.random.choice(df.index, size=num_duplicates, replace=True)
        duplicates = df.loc[duplicate_indices].copy()
        
        # We need to drop index to avoid collision, though if we need primary keys, 
        # this might cause issues downstream. Usually, we don't inject duplicates on PK columns.
        df = pd.concat([df, duplicates], ignore_index=True)
        return df
    
    def _weighted_choice(self, choices: List[Any], weights: List[float], size: int) -> np.ndarray:
        """Make weighted random choices."""
        # Normalize weights
        weights = np.array(weights) / sum(weights)
        return np.random.choice(choices, size=size, p=weights)
        
    def generate(self) -> pd.DataFrame:
        """Main method to be implemented by child classes."""
        raise NotImplementedError("Subclasses must implement generate()")
