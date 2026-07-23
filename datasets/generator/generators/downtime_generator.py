"""
generators/downtime_generator.py
SMAP Synthetic Dataset Generator — Downtime Event Generator.

Generates machine stop events with realistic distributions of:
  - Event type (Planned / Unplanned / Emergency)
  - Downtime duration
  - Reason codes
  - Association to production orders
"""

from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
from typing import Any

from generators.base_generator import BaseGenerator
from utils.anomaly_injector import AnomalyInjector
from utils.id_factory import IDFactory
from utils.registry import Registry
from utils.timestamp_utils import format_iso_utc, working_dates_in_range


EVENT_TYPE_WEIGHTS = [("Planned", 0.40), ("Unplanned", 0.45), ("Emergency", 0.15)]

REASON_CODES = {
    "Planned":   ["PM-WINDOW", "SETUP", "CHANGEOVER", "TOOL-CHANGE"],
    "Unplanned": ["MECH-FAIL", "TOOL-BREAK", "COOLANT-FAULT", "SPINDLE-FAULT", "HYDRAULIC-LEAK", "AXIS-FAULT"],
    "Emergency": ["SPINDLE-CRASH", "FIRE-STOP", "SAFETY-ESTOP", "POWER-OUTAGE"],
}

DOWNTIME_RANGES: dict[str, tuple[float, float]] = {
    "Planned":   (20.0, 120.0),
    "Unplanned": (15.0, 360.0),
    "Emergency": (60.0, 720.0),
}


class DowntimeEventGenerator(BaseGenerator):
    entity_name = "downtime_events"

    def generate(self) -> list[dict[str, Any]]:
        count = self.config.entities.downtime_events
        mr = self.config.data_quality.missing_rates
        machines = Registry.get_all("machines")
        orders = Registry.get_all("production_orders")
        operators = Registry.get_all("employees_opr_mch")
        start = date.fromisoformat(self.config.temporal.start_date)
        working_days = working_dates_in_range(
            start, date.fromisoformat(self.config.temporal.end_date)
        )

        rows: list[dict[str, Any]] = []
        seq = 1
        event_types, et_weights = zip(*EVENT_TYPE_WEIGHTS)

        while len(rows) < count:
            work_date = self.rng.choice(working_days)
            machine_id = self.rng.choice(machines)
            event_type = self.rng.choices(list(event_types), weights=list(et_weights), k=1)[0]

            hour = self.rng.randint(6, 22)
            ds = datetime(work_date.year, work_date.month, work_date.day,
                          hour, self.rng.randint(0, 59), tzinfo=timezone.utc)

            downtime_min = round(self.rng.uniform(*DOWNTIME_RANGES[event_type]), 2)
            # Simulate open events (no end time) ~3% of the time
            is_open = self.rng.random() < mr.downtime_events_downtime_minutes
            de = None if is_open else ds + timedelta(minutes=downtime_min)

            reason_code = AnomalyInjector.maybe_null(
                self.rng.choice(REASON_CODES[event_type]),
                mr.downtime_events_reason_code, self.rng,
            )

            # Associate to an order ~75% of the time
            order_id = self.rng.choice(orders) if orders and self.rng.random() < 0.75 else None
            reporter = self.rng.choice(operators) if operators and self.rng.random() > 0.10 else None

            rows.append({
                "event_id": IDFactory.downtime_event_id(work_date, seq),
                "machine_id": machine_id,
                "order_id": order_id,
                "event_type": event_type,
                "reason_code": reason_code,
                "reason_description": None,
                "downtime_start": format_iso_utc(ds),
                "downtime_end": format_iso_utc(de) if de else None,
                "downtime_minutes": None if is_open else downtime_min,
                "reported_by": reporter,
                "is_planned": event_type == "Planned",
                "created_at": format_iso_utc(ds),
            })
            seq += 1

        Registry.register(self.entity_name, [r["event_id"] for r in rows])
        self.log_generated(len(rows))
        return rows
