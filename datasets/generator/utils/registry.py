"""
utils/registry.py
SMAP Synthetic Dataset Generator — Entity Registry.

In-memory store of all generated entity keys, used to maintain referential
integrity across all generators without requiring a live database.

Pattern:
    Registry.register("machines", ["MCH-001", "MCH-002", ...])
    machine_id = Registry.sample("machines")  # returns a random valid FK value
"""

from __future__ import annotations

import logging
import random
from typing import Any

logger = logging.getLogger(__name__)


class Registry:
    """
    Thread-local entity key registry. Stores generated primary key values
    for each entity so that child generators can sample valid foreign keys.

    Usage:
        # After generating production_lines:
        Registry.register("production_lines", [pl["line_code"] for pl in rows])

        # In the machines generator:
        line_code = Registry.sample("production_lines")
    """

    _store: dict[str, list[Any]] = {}

    @classmethod
    def register(cls, entity: str, keys: list[Any]) -> None:
        """Register a list of primary key values for an entity."""
        cls._store[entity] = list(keys)
        logger.debug("Registry: registered %d keys for '%s'", len(keys), entity)

    @classmethod
    def sample(cls, entity: str, rng: random.Random | None = None) -> Any:
        """
        Sample one random key from the entity registry.

        Args:
            entity: The entity name (e.g., 'machines', 'products').
            rng:    Optional seeded random.Random instance for determinism.

        Returns:
            A single primary key value sampled uniformly at random.

        Raises:
            KeyError: If the entity has not been registered.
            ValueError: If the entity registry is empty.
        """
        if entity not in cls._store:
            raise KeyError(
                f"Registry: entity '{entity}' not found. "
                f"Registered entities: {sorted(cls._store.keys())}"
            )
        keys = cls._store[entity]
        if not keys:
            raise ValueError(f"Registry: entity '{entity}' has no registered keys.")
        picker = rng or random
        return picker.choice(keys)

    @classmethod
    def sample_n(cls, entity: str, n: int, rng: random.Random | None = None) -> list[Any]:
        """Sample n keys (with replacement) from the entity registry."""
        picker = rng or random
        keys = cls._store[entity]
        return [picker.choice(keys) for _ in range(n)]

    @classmethod
    def get_all(cls, entity: str) -> list[Any]:
        """Return all registered keys for an entity."""
        return list(cls._store.get(entity, []))

    @classmethod
    def is_registered(cls, entity: str) -> bool:
        """Return True if the entity has been registered."""
        return entity in cls._store and bool(cls._store[entity])

    @classmethod
    def clear(cls) -> None:
        """Clear all registry entries. Used between test runs."""
        cls._store.clear()
        logger.debug("Registry: cleared all entries.")

    @classmethod
    def summary(cls) -> dict[str, int]:
        """Return a dict of {entity: key_count} for logging."""
        return {k: len(v) for k, v in cls._store.items()}
