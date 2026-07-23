"""
generators/production_order_generator.py
SMAP Synthetic Dataset Generator — Production Order Generator.

Generates production order records with:
  - Realistic planned/actual timestamps within shift windows
  - Unit counts matching documented OEE baseline (~68% OEE fleet average)
  - Configurable order status distribution
  - Referential integrity via Registry

Order generation uses a sequential walk through the temporal scope,
creating 2-5 orders per machine per shift per working day (scaled to
the configured total count).
"""

from __future__ import annotations

import math
from datetime import date, datetime, timedelta, timezone
from typing import Any

from generators.base_generator import BaseGenerator
from utils.anomaly_injector import AnomalyInjector
from utils.id_factory import IDFactory
from utils.registry import Registry
from utils.timestamp_utils import (
    format_iso_utc,
    random_utc_in_shift,
    shift_end_utc,
    shift_start_utc,
    working_dates_in_range,
)


# OEE component targets (per KPI_DEFINITIONS.md — baseline, not target)
OEE_AVAILABILITY_MEAN = 0.78    # 78% current baseline
OEE_AVAILABILITY_STD  = 0.08
OEE_PERFORMANCE_MEAN  = 0.84    # 84% current baseline
OEE_PERFORMANCE_STD   = 0.07
OEE_QUALITY_MEAN      = 0.972   # 97.2% current baseline
OEE_QUALITY_STD       = 0.018

STATUS_WEIGHTS = [
    ("Complete",   0.88),
    ("In Progress", 0.05),
    ("Cancelled",  0.04),
    ("Pending",    0.03),
]


class ProductionOrderGenerator(BaseGenerator):
    """Generates production order records with realistic OEE-consistent unit counts."""

    entity_name = "production_orders"

    def generate(self) -> list[dict[str, Any]]:
        count = self.config.entities.production_orders
        start = date.fromisoformat(self.config.temporal.start_date)
        end = date.fromisoformat(self.config.temporal.end_date)
        working_days = working_dates_in_range(start, end)

        machines = Registry.get_all("machines")
        products = Registry.get_all("products")
        shifts_det = Registry.get_all("shifts_det")
        operators = Registry.get_all("employees_opr_mch")

        if not (machines and products and shifts_det and operators):
            raise RuntimeError(
                "ProductionOrderGenerator requires machines, products, shifts_det, "
                "and employees_opr_mch to be registered first."
            )

        rows: list[dict[str, Any]] = []
        order_seq = 1
        erp_seq = 1

        statuses, status_weights = zip(*STATUS_WEIGHTS)

        while len(rows) < count:
            work_date = self.rng.choice(working_days)
            machine_id = self.rng.choice(machines)
            product_code = self.rng.choice(products)
            shift_code = self.rng.choice(shifts_det)
            operator_id = self.rng.choice(operators) if self.rng.random() > 0.15 else "EMP-ROBOT"

            order_id = IDFactory.order_id(work_date, order_seq)
            erp_order_id = IDFactory.erp_order_id(work_date, erp_seq)

            # Planned start: start of shift
            planned_start = shift_start_utc(work_date, shift_code)
            # Planned duration: full shift less 30 min buffer
            planned_duration_min = 7.0 * 60  # 420 min

            # Actual start: within first 30 min of shift
            actual_start = planned_start + timedelta(
                minutes=self.rng.randint(5, 30)
            )

            # Availability — fraction of shift actually running
            availability = max(0.3, min(1.0,
                self.rng.gauss(OEE_AVAILABILITY_MEAN, OEE_AVAILABILITY_STD)))
            run_time_min = planned_duration_min * availability

            # Actual end
            actual_end = actual_start + timedelta(minutes=planned_duration_min + self.rng.randint(-10, 30))

            # Performance — how fast relative to standard
            performance = max(0.3, min(1.1,
                self.rng.gauss(OEE_PERFORMANCE_MEAN, OEE_PERFORMANCE_STD)))

            # Determine planned units from shift duration and standard cycle time
            # We need a product cycle time — use registry if available, else default
            planned_units = max(10, int((run_time_min * 60 * performance) / 150))

            # Quality
            quality = max(0.7, min(1.0,
                self.rng.gauss(OEE_QUALITY_MEAN, OEE_QUALITY_STD)))
            actual_units = max(1, int(planned_units * self.rng.uniform(0.85, 1.05)))
            good_units = max(0, int(actual_units * quality))
            scrap_units = max(0, int((actual_units - good_units) * self.rng.uniform(0.3, 0.7)))
            rework_units = max(0, actual_units - good_units - scrap_units)

            status = self.rng.choices(list(statuses), weights=list(status_weights), k=1)[0]

            # For non-complete orders, null out some actuals
            if status == "Pending":
                actual_start = actual_end = actual_units = good_units = scrap_units = rework_units = None
            elif status == "In Progress":
                actual_end = actual_units = good_units = scrap_units = rework_units = None
            elif status == "Cancelled":
                actual_end = actual_units = good_units = scrap_units = rework_units = None

            rows.append({
                "order_id": order_id,
                "machine_id": machine_id,
                "product_code": product_code,
                "shift_code": shift_code,
                "operator_id": operator_id,
                "planned_start": format_iso_utc(planned_start),
                "actual_start": format_iso_utc(actual_start) if actual_start else None,
                "actual_end": format_iso_utc(actual_end) if actual_end else None,
                "planned_units": planned_units,
                "actual_units": actual_units,
                "good_units": good_units,
                "scrap_units": scrap_units,
                "rework_units": rework_units,
                "status": status,
                "erp_order_id": erp_order_id,
                "created_at": format_iso_utc(planned_start - timedelta(hours=2)),
                "updated_at": format_iso_utc(actual_end if actual_end else planned_start + timedelta(hours=1)),
            })

            order_seq += 1
            erp_seq += 1

        Registry.register(self.entity_name, [r["order_id"] for r in rows])
        self.log_generated(len(rows))
        return rows
