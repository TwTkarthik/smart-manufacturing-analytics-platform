"""
config/settings.py
SMAP Synthetic Dataset Generator — Configuration dataclasses.

Loads generator_config.yaml and exposes typed, validated settings
to all generator modules. Override any field via environment variable
or CLI argument (see main.py).
"""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import yaml


# ─────────────────────────────────────────────────────────────────────────────
# Nested configuration dataclasses
# ─────────────────────────────────────────────────────────────────────────────

@dataclass
class GlobalSettings:
    random_seed: int = 42
    output_dir: str = "output"
    output_format: str = "csv"
    log_level: str = "INFO"


@dataclass
class TemporalSettings:
    start_date: str = "2026-01-01"
    end_date: str = "2026-07-22"
    timezone: str = "UTC"


@dataclass
class EntityCounts:
    production_lines: int = 11
    shifts: int = 10
    machines: int = 48
    employees: int = 200
    products: int = 8
    defect_types: int = 15
    spare_parts: int = 20
    production_orders: int = 5000
    downtime_events: int = 2500
    sensor_readings: int = 100000
    quality_inspections: int = 8000
    pm_schedules: int = 144
    maintenance_logs: int = 400
    material_movements: int = 1200


@dataclass
class MissingRates:
    """Fraction (0.0–1.0) of rows where a field should be NULL."""
    employees_skill_level: float = 0.05
    employees_hire_date: float = 0.08
    downtime_events_reason_code: float = 0.12
    downtime_events_downtime_minutes: float = 0.03
    maintenance_logs_failure_code: float = 0.15
    maintenance_logs_root_cause: float = 0.70
    maintenance_logs_repair_cost: float = 0.25
    quality_inspections_defect_type_code: float = 0.08
    quality_inspections_measurement_value: float = 0.30
    sensor_readings_data_quality_score: float = 0.15


@dataclass
class DuplicateRates:
    """Fraction of rows injected as near-duplicates."""
    sensor_readings: float = 0.001
    quality_inspections: float = 0.002


@dataclass
class AnomalyRates:
    """Fraction of sensor readings that are flagged as anomalous per sensor type."""
    temperature: float = 0.025
    vibration: float = 0.030
    rpm: float = 0.015
    pressure: float = 0.020
    power: float = 0.010
    cutting_force: float = 0.035
    coolant_flow: float = 0.018


@dataclass
class DataQualitySettings:
    missing_rates: MissingRates = field(default_factory=MissingRates)
    duplicate_rates: DuplicateRates = field(default_factory=DuplicateRates)
    anomaly_rates: AnomalyRates = field(default_factory=AnomalyRates)


@dataclass
class SensorRange:
    normal_min: float
    normal_max: float
    anomaly_low: float
    anomaly_high: float
    unit: str


@dataclass
class SensorRanges:
    temperature: SensorRange = field(default_factory=lambda: SensorRange(20.0, 65.0, 5.0, 95.0, "C"))
    vibration: SensorRange = field(default_factory=lambda: SensorRange(0.5, 4.5, 0.0, 12.0, "mm/s"))
    rpm: SensorRange = field(default_factory=lambda: SensorRange(200.0, 8000.0, 0.0, 9500.0, "RPM"))
    pressure: SensorRange = field(default_factory=lambda: SensorRange(1500.0, 3000.0, 500.0, 3800.0, "PSI"))
    power: SensorRange = field(default_factory=lambda: SensorRange(2.0, 85.0, 0.0, 120.0, "kWh"))
    cutting_force: SensorRange = field(default_factory=lambda: SensorRange(200.0, 2500.0, 0.0, 3500.0, "N"))
    coolant_flow: SensorRange = field(default_factory=lambda: SensorRange(8.0, 40.0, 0.0, 60.0, "L/min"))


@dataclass
class GeneratorConfig:
    """
    Root configuration object. Load from YAML via GeneratorConfig.from_yaml().
    """
    global_: GlobalSettings = field(default_factory=GlobalSettings)
    temporal: TemporalSettings = field(default_factory=TemporalSettings)
    entities: EntityCounts = field(default_factory=EntityCounts)
    data_quality: DataQualitySettings = field(default_factory=DataQualitySettings)
    sensor_ranges: SensorRanges = field(default_factory=SensorRanges)

    # ─────────────────────────────────────────────────────────────────────────
    # Factory methods
    # ─────────────────────────────────────────────────────────────────────────

    @classmethod
    def from_yaml(cls, config_path: str | Path) -> "GeneratorConfig":
        """Load and parse generator_config.yaml into a typed GeneratorConfig."""
        with open(config_path, "r", encoding="utf-8") as fh:
            raw: dict[str, Any] = yaml.safe_load(fh)

        cfg = cls()

        # Global
        g = raw.get("global", {})
        cfg.global_ = GlobalSettings(
            random_seed=g.get("random_seed", 42),
            output_dir=g.get("output_dir", "output"),
            output_format=g.get("output_format", "csv"),
            log_level=g.get("log_level", "INFO"),
        )

        # Temporal
        t = raw.get("temporal", {})
        cfg.temporal = TemporalSettings(
            start_date=t.get("start_date", "2026-01-01"),
            end_date=t.get("end_date", "2026-07-22"),
            timezone=t.get("timezone", "UTC"),
        )

        # Entity counts (nested under "entities" → each entity → "count")
        e = raw.get("entities", {})
        counts = EntityCounts()
        for entity_name, entity_cfg in e.items():
            if hasattr(counts, entity_name) and isinstance(entity_cfg, dict):
                setattr(counts, entity_name, entity_cfg.get("count", getattr(counts, entity_name)))
        cfg.entities = counts

        # Data quality
        dq = raw.get("data_quality", {})
        mr_raw = dq.get("missing_rates", {})
        mr = MissingRates(
            employees_skill_level=mr_raw.get("employees.skill_level", 0.05),
            employees_hire_date=mr_raw.get("employees.hire_date", 0.08),
            downtime_events_reason_code=mr_raw.get("downtime_events.reason_code", 0.12),
            downtime_events_downtime_minutes=mr_raw.get("downtime_events.downtime_minutes", 0.03),
            maintenance_logs_failure_code=mr_raw.get("maintenance_logs.failure_code", 0.15),
            maintenance_logs_root_cause=mr_raw.get("maintenance_logs.root_cause", 0.70),
            maintenance_logs_repair_cost=mr_raw.get("maintenance_logs.repair_cost", 0.25),
            quality_inspections_defect_type_code=mr_raw.get("quality_inspections.defect_type_code", 0.08),
            quality_inspections_measurement_value=mr_raw.get("quality_inspections.measurement_value", 0.30),
            sensor_readings_data_quality_score=mr_raw.get("sensor_readings.data_quality_score", 0.15),
        )
        dr_raw = dq.get("duplicate_rates", {})
        dr = DuplicateRates(
            sensor_readings=dr_raw.get("sensor_readings", 0.001),
            quality_inspections=dr_raw.get("quality_inspections", 0.002),
        )
        ar_raw = dq.get("anomaly_rates", {})
        ar = AnomalyRates(
            temperature=ar_raw.get("sensor_readings.temperature", 0.025),
            vibration=ar_raw.get("sensor_readings.vibration", 0.030),
            rpm=ar_raw.get("sensor_readings.rpm", 0.015),
            pressure=ar_raw.get("sensor_readings.pressure", 0.020),
            power=ar_raw.get("sensor_readings.power", 0.010),
            cutting_force=ar_raw.get("sensor_readings.cutting_force", 0.035),
            coolant_flow=ar_raw.get("sensor_readings.coolant_flow", 0.018),
        )
        cfg.data_quality = DataQualitySettings(
            missing_rates=mr,
            duplicate_rates=dr,
            anomaly_rates=ar,
        )

        # Sensor ranges
        sr_raw = raw.get("sensor_ranges", {})
        def _sr(name: str, defaults: SensorRange) -> SensorRange:
            d = sr_raw.get(name, {})
            return SensorRange(
                normal_min=d.get("normal_min", defaults.normal_min),
                normal_max=d.get("normal_max", defaults.normal_max),
                anomaly_low=d.get("anomaly_low", defaults.anomaly_low),
                anomaly_high=d.get("anomaly_high", defaults.anomaly_high),
                unit=d.get("unit", defaults.unit),
            )
        cfg.sensor_ranges = SensorRanges(
            temperature=_sr("temperature", SensorRanges().temperature),
            vibration=_sr("vibration", SensorRanges().vibration),
            rpm=_sr("rpm", SensorRanges().rpm),
            pressure=_sr("pressure", SensorRanges().pressure),
            power=_sr("power", SensorRanges().power),
            cutting_force=_sr("cutting_force", SensorRanges().cutting_force),
            coolant_flow=_sr("coolant_flow", SensorRanges().coolant_flow),
        )

        return cfg

    def get_sensor_range(self, sensor_type: str) -> SensorRange | None:
        """Return the SensorRange for a given sensor_type string."""
        return getattr(self.sensor_ranges, sensor_type.replace("-", "_"), None)
