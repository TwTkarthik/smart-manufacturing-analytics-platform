"""
generators/quality_generator.py
SMAP Synthetic Dataset Generator — Quality Inspection Generator.

Generates quality inspection records with:
  - Defect rates matching baseline (2.8% overall defect rate)
  - Multiple inspection types per order
  - Configurable missing rate for defect_type_code and measurement_value
  - Near-duplicate injection
"""

from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
from typing import Any

from generators.base_generator import BaseGenerator
from utils.anomaly_injector import AnomalyInjector
from utils.id_factory import IDFactory
from utils.registry import Registry
from utils.timestamp_utils import format_iso_utc, working_dates_in_range


INSPECTION_TYPES = [
    ("FIRST-ARTICLE", 0.15),
    ("IN-PROCESS",    0.60),
    ("FINAL",         0.20),
    ("FUNCTIONAL",    0.05),
]

DEFECT_RATE_MEAN = 0.028    # 2.8% overall baseline (KPI_DEFINITIONS.md)
DEFECT_RATE_STD  = 0.015


class QualityInspectionGenerator(BaseGenerator):
    entity_name = "quality_inspections"

    def generate(self) -> list[dict[str, Any]]:
        count = self.config.entities.quality_inspections
        mr = self.config.data_quality.missing_rates
        dr_rate = self.config.data_quality.duplicate_rates.quality_inspections

        orders = Registry.get_all("production_orders")
        machines = Registry.get_all("machines")
        inspectors = Registry.get_all("employees_qa_tech")
        defect_codes = Registry.get_all("defect_types")

        if not orders:
            raise RuntimeError("QualityInspectionGenerator requires production_orders to be registered.")

        start = date.fromisoformat(self.config.temporal.start_date)
        rows: list[dict[str, Any]] = []
        seq = 1
        insp_types, insp_weights = zip(*INSPECTION_TYPES)

        while len(rows) < count:
            order_id = self.rng.choice(orders)
            machine_id = self.rng.choice(machines)
            inspector_id = (
                self.rng.choice(inspectors) if inspectors and self.rng.random() > 0.12 else None
            )

            work_date = start + timedelta(days=self.rng.randint(0, 202))
            hour = self.rng.randint(7, 21)
            ts = datetime(work_date.year, work_date.month, work_date.day,
                          hour, self.rng.randint(0, 59), tzinfo=timezone.utc)

            inspection_type = self.rng.choices(list(insp_types), weights=list(insp_weights), k=1)[0]
            sample_size = self.rng.randint(5, 50)

            defect_rate = max(0.0, min(1.0, self.rng.gauss(DEFECT_RATE_MEAN, DEFECT_RATE_STD)))
            defects_found = int(sample_size * defect_rate)
            pass_fail = "F" if defects_found > 0 else "P"

            defect_type_code = None
            if defects_found > 0 and defect_codes:
                raw = self.rng.choice(defect_codes)
                defect_type_code = AnomalyInjector.maybe_null(
                    raw, mr.quality_inspections_defect_type_code, self.rng
                )

            meas_value = AnomalyInjector.maybe_null(
                round(self.rng.gauss(25.0, 0.05), 6),
                mr.quality_inspections_measurement_value, self.rng,
            )

            rows.append({
                "inspection_id": IDFactory.inspection_id(work_date, seq),
                "order_id": order_id,
                "machine_id": machine_id,
                "inspector_id": inspector_id,
                "inspection_type_code": inspection_type,
                "inspection_timestamp": format_iso_utc(ts),
                "sample_size": sample_size,
                "defects_found": defects_found,
                "defect_type_code": defect_type_code,
                "defect_description": None,
                "measurement_value": meas_value,
                "measurement_unit": "mm" if meas_value is not None else None,
                "pass_fail": pass_fail,
                "created_at": format_iso_utc(ts),
            })
            seq += 1

        rows = AnomalyInjector.inject_duplicates(
            rows, dr_rate, self.rng, pk_field="inspection_id", pk_suffix="-DUP"
        )

        Registry.register(self.entity_name, [r["inspection_id"] for r in rows])
        self.log_generated(len(rows))
        return rows
