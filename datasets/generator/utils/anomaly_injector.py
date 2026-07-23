"""
utils/anomaly_injector.py
SMAP Synthetic Dataset Generator — Anomaly and Missing Value Injection.

Provides stateless injection utilities used by all generator modules
to simulate realistic data quality issues:
  - Missing values (NULL injection)
  - Anomalous sensor readings (out-of-range values)
  - Near-duplicate rows
"""

from __future__ import annotations

import random
from typing import Any, TypeVar

from config.settings import SensorRange

T = TypeVar("T")


class AnomalyInjector:
    """
    Stateless collection of injection utilities.
    All methods accept a seeded random.Random instance for determinism.
    """

    @staticmethod
    def maybe_null(value: T, rate: float, rng: random.Random) -> T | None:
        """
        Return None with probability `rate`; otherwise return value as-is.

        Args:
            value:  The original value.
            rate:   Probability of returning None (0.0 = never, 1.0 = always).
            rng:    Seeded random.Random instance.

        Returns:
            None or the original value.
        """
        if rate <= 0.0:
            return value
        return None if rng.random() < rate else value

    @staticmethod
    def sensor_value(
        sensor_type: str,
        sensor_range: SensorRange,
        anomaly_rate: float,
        rng: random.Random,
    ) -> tuple[float, bool]:
        """
        Generate a sensor reading value, optionally anomalous.

        Args:
            sensor_type:   The sensor type string (used for logging).
            sensor_range:  The SensorRange config for this sensor type.
            anomaly_rate:  Probability of generating an out-of-range value.
            rng:           Seeded random.Random instance.

        Returns:
            A tuple of (value, is_anomaly_flagged).
        """
        is_anomaly = rng.random() < anomaly_rate

        if is_anomaly:
            # Generate a value outside the normal range
            # 50/50 split: below normal_min or above normal_max
            if rng.random() < 0.5:
                value = rng.uniform(sensor_range.anomaly_low, sensor_range.normal_min)
            else:
                value = rng.uniform(sensor_range.normal_max, sensor_range.anomaly_high)
        else:
            # Generate a value within the normal operating range
            # Use a truncated normal-like distribution: midpoint with slight spread
            midpoint = (sensor_range.normal_min + sensor_range.normal_max) / 2.0
            spread = (sensor_range.normal_max - sensor_range.normal_min) * 0.35
            raw = rng.gauss(midpoint, spread)
            value = max(sensor_range.normal_min, min(sensor_range.normal_max, raw))

        return round(value, 6), is_anomaly

    @staticmethod
    def data_quality_score(
        null_rate: float,
        rng: random.Random,
    ) -> float | None:
        """
        Generate a data quality score (0.000–1.000) or None.

        Simulates pre-2021 sensor records that have no quality score.
        Most readings have a high quality score (0.85–1.00).

        Args:
            null_rate:  Probability of returning None (no score).
            rng:        Seeded random.Random instance.

        Returns:
            None or a quality score float rounded to 3 decimal places.
        """
        if rng.random() < null_rate:
            return None
        # Skew toward high quality (beta distribution a=5, b=1)
        score = rng.betavariate(5, 1)
        return round(max(0.0, min(1.0, score)), 3)

    @staticmethod
    def inject_duplicates(
        rows: list[dict[str, Any]],
        rate: float,
        rng: random.Random,
        pk_field: str,
        pk_suffix: str = "-DUP",
    ) -> list[dict[str, Any]]:
        """
        Inject near-duplicate rows into a list of generated rows.

        Near-duplicates have a modified PK (to avoid constraint violations
        before deduplication) and identical data values — simulating
        SCADA retry or QMS double-submission bugs.

        Args:
            rows:       Original generated rows.
            rate:       Fraction of rows to duplicate.
            rng:        Seeded random.Random instance.
            pk_field:   The primary key column name.
            pk_suffix:  Suffix to append to duplicate PKs.

        Returns:
            Original rows + injected duplicate rows (unsorted).
        """
        if rate <= 0.0:
            return rows
        duplicates: list[dict[str, Any]] = []
        for row in rows:
            if rng.random() < rate:
                dup = dict(row)
                dup[pk_field] = str(row[pk_field]) + pk_suffix
                duplicates.append(dup)
        return rows + duplicates
