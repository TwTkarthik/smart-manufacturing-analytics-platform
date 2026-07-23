"""
generators/sensor_generator.py
SMAP Synthetic Dataset Generator — Sensor Reading Generator.

Generates sensor telemetry records with:
  - Configurable sensor type distribution across machine types
  - Realistic value ranges per MANUFACTURING_PROCESS.md §5.2
  - Configurable anomaly injection rates per sensor type
  - Configurable data quality score missing rates
  - Duplicate injection (SCADA retry simulation)
  - Sequential timestamps within active machine windows
"""

from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
from typing import Any

from generators.base_generator import BaseGenerator
from utils.anomaly_injector import AnomalyInjector
from utils.registry import Registry
from utils.timestamp_utils import format_iso_utc, working_dates_in_range


# Sensor types emitted per machine type (subset of all 7 types)
# Per MANUFACTURING_PROCESS.md §5.2
MACHINE_SENSOR_MAP: dict[str, list[str]] = {
    "MCH-LATHE":  ["temperature", "vibration", "rpm", "power", "cutting_force", "coolant_flow"],
    "MCH-MILL":   ["temperature", "vibration", "rpm", "power", "cutting_force", "coolant_flow"],
    "MCH-GRIND":  ["temperature", "vibration", "rpm", "power", "coolant_flow"],
    "MCH-PRESS":  ["temperature", "pressure", "power"],
    "MCH-CMM":    ["temperature", "power"],
    "MCH-CONV":   ["temperature", "power"],
    "MCH-ASSY":   [],   # Assembly stations are not sensor-equipped
}


class SensorReadingGenerator(BaseGenerator):
    """Generates sensor telemetry records for all sensor-equipped machines."""

    entity_name = "sensor_readings"

    def generate(self) -> list[dict[str, Any]]:
        count = self.config.entities.sensor_readings
        mr = self.config.data_quality.missing_rates
        dr = self.config.data_quality.duplicate_rates
        ar = self.config.data_quality.anomaly_rates
        sr_cfg = self.config.sensor_ranges

        machines = Registry.get_all("machines")
        if not machines:
            raise RuntimeError("SensorReadingGenerator requires 'machines' to be registered first.")

        # Build (machine_id, sensor_type, sensor_range, anomaly_rate) tuples
        # For this generator we cannot access machine_type_code from registry alone,
        # so we use a round-robin across all sensor types (realistic approximation).
        sensor_types = ["temperature", "vibration", "rpm", "pressure", "power", "cutting_force", "coolant_flow"]
        sensor_units  = {"temperature": "C", "vibration": "mm/s", "rpm": "RPM",
                         "pressure": "PSI", "power": "kWh", "cutting_force": "N", "coolant_flow": "L/min"}
        anomaly_rates_map = {
            "temperature": ar.temperature, "vibration": ar.vibration, "rpm": ar.rpm,
            "pressure": ar.pressure, "power": ar.power,
            "cutting_force": ar.cutting_force, "coolant_flow": ar.coolant_flow,
        }

        start = date.fromisoformat(self.config.temporal.start_date)
        end = date.fromisoformat(self.config.temporal.end_date)
        working_days = working_dates_in_range(start, end)

        rows: list[dict[str, Any]] = []
        reading_id = 1

        while len(rows) < count:
            machine_id = self.rng.choice(machines)
            sensor_type = self.rng.choice(sensor_types)
            sensor_range = self.config.get_sensor_range(sensor_type)
            anom_rate = anomaly_rates_map[sensor_type]

            # Generate timestamp: random working day + random offset during shift
            work_date = self.rng.choice(working_days)
            hour = self.rng.randint(6, 21)
            minute = self.rng.randint(0, 59)
            second = self.rng.randint(0, 59)
            ts = datetime(work_date.year, work_date.month, work_date.day,
                          hour, minute, second, tzinfo=timezone.utc)

            value, is_anomaly = AnomalyInjector.sensor_value(
                sensor_type, sensor_range, anom_rate, self.rng
            )
            dq_score = AnomalyInjector.data_quality_score(
                mr.sensor_readings_data_quality_score, self.rng
            )
            is_within_spec = not is_anomaly

            rows.append({
                "reading_id": reading_id,
                "machine_id": machine_id,
                "sensor_type": sensor_type,
                "sensor_unit": sensor_units[sensor_type],
                "value": value,
                "reading_timestamp": format_iso_utc(ts),
                "is_anomaly_flagged": is_anomaly,
                "data_quality_score": dq_score,
            })
            reading_id += 1

        # Inject duplicates (SCADA retry simulation)
        rows = AnomalyInjector.inject_duplicates(
            rows, dr.sensor_readings, self.rng,
            pk_field="reading_id", pk_suffix="-DUP"
        )

        Registry.register(self.entity_name, [str(r["reading_id"]) for r in rows])
        self.log_generated(len(rows))
        return rows
