"""
generators/base_generator.py
SMAP Synthetic Dataset Generator — Abstract Base Generator.

All entity generators inherit from BaseGenerator. This class provides:
  - Seeded random.Random instance (deterministic)
  - Config reference
  - Abstract generate() method
  - Standard logging
  - Output path helper
"""

from __future__ import annotations

import logging
import os
import random
from abc import ABC, abstractmethod
from pathlib import Path
from typing import Any

from config.settings import GeneratorConfig

logger = logging.getLogger(__name__)


class BaseGenerator(ABC):
    """
    Abstract base class for all SMAP entity generators.

    Subclasses must implement generate(), which returns a list of dicts
    where each dict represents one row (column → value mapping).

    All generators share the same seeded random.Random from the config,
    ensuring that the full dataset is reproducible from a single seed.
    """

    #: Entity name — used for logging and registry keys
    entity_name: str = "base"

    def __init__(self, config: GeneratorConfig) -> None:
        self.config = config
        # Each generator gets the global seed offset by a class-specific
        # hash to ensure independence between generators while staying
        # deterministic across runs.
        seed = config.global_.random_seed + hash(self.__class__.__name__) % 10000
        self.rng = random.Random(seed)
        self.logger = logging.getLogger(self.__class__.__name__)

    @abstractmethod
    def generate(self) -> list[dict[str, Any]]:
        """
        Generate all rows for this entity.

        Returns:
            A list of dicts, each representing one database row.
            Column names must exactly match the operational DB table schema.
        """
        ...

    def output_path(self, filename: str | None = None) -> Path:
        """
        Return the output path for this generator's CSV file.

        Args:
            filename: Override filename. Defaults to {entity_name}.csv.

        Returns:
            Absolute Path to the output file.
        """
        gen_dir = Path(__file__).parent.parent
        out_dir = gen_dir / self.config.global_.output_dir
        out_dir.mkdir(parents=True, exist_ok=True)
        name = filename or f"{self.entity_name}.csv"
        return out_dir / name

    def log_generated(self, count: int) -> None:
        """Log standard generation summary."""
        self.logger.info("Generated %d rows for entity '%s'.", count, self.entity_name)
