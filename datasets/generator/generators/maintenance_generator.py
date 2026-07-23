"""
generators/maintenance_generator.py
SMAP Synthetic Dataset Generator — Maintenance and PM Generators.

Covers:
  - PMScheduleGenerator    — One record per machine per PM type
  - MaintenanceLogGenerator — Work order records (planned, unplanned, emergency)
  - MaterialMovementGenerator — Parts consumed per work order
"""

from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
from typing import Any

from generators.base_generator import BaseGenerator
from utils.anomaly_injector import AnomalyInjector
from utils.id_factory import IDFactory
from utils.registry import Registry
from utils.timestamp_utils import format_iso_utc, working_dates_in_range


PM_TYPES = [
    ("Lubrication",         30,  None),
    ("Filter Service",      60,  None),
    ("Spindle Inspection",  None, 500.0),
]

FAILURE_CODES = ["FC-MECH", "FC-ELEC", "FC-HYD", "FC-PROC", "FC-TOOL"]

EVENT_TYPE_WEIGHTS = [
    ("Planned",   0.50),
    ("Unplanned", 0.38),
    ("Emergency", 0.12),
]

REPAIR_COST_RANGES: dict[str, tuple[float, float]] = {
    "Planned":   (150.0, 800.0),
    "Unplanned": (400.0, 3500.0),
    "Emergency": (1200.0, 8000.0),
}

MTTR_RANGES: dict[str, tuple[float, float]] = {
    "Planned":   (45.0, 240.0),
    "Unplanned": (60.0, 480.0),
    "Emergency": (120.0, 960.0),
}


class PMScheduleGenerator(BaseGenerator):
    entity_name = "pm_schedules"

    def generate(self) -> list[dict[str, Any]]:
        machines = Registry.get_all("machines")
        rows: list[dict[str, Any]] = []
        pk_seq = 1
        created_ts = format_iso_utc(datetime(2024, 1, 15, 0, 0, 0, tzinfo=timezone.utc))

        for machine_id in machines:
            for pm_type, interval_days, interval_hours in PM_TYPES:
                last_performed = date(2026, self.rng.randint(1, 6), self.rng.randint(1, 28))
                if interval_days:
                    next_due = last_performed + timedelta(days=interval_days)
                else:
                    next_due = last_performed + timedelta(days=30)

                rows.append({
                    "pm_schedule_id": pk_seq,
                    "machine_id": machine_id,
                    "pm_type": pm_type,
                    "interval_days": interval_days,
                    "interval_hours": interval_hours,
                    "last_performed_date": last_performed.isoformat(),
                    "next_due_date": next_due.isoformat(),
                    "is_active": True,
                    "created_at": created_ts,
                    "updated_at": created_ts,
                })
                pk_seq += 1

        Registry.register(self.entity_name, [str(r["pm_schedule_id"]) for r in rows])
        self.log_generated(len(rows))
        return rows


class MaintenanceLogGenerator(BaseGenerator):
    entity_name = "maintenance_logs"

    def generate(self) -> list[dict[str, Any]]:
        count = self.config.entities.maintenance_logs
        mr = self.config.data_quality.missing_rates
        machines = Registry.get_all("machines")
        technicians = Registry.get_all("employees_mnt_tech")
        pm_schedules = Registry.get_all("pm_schedules")
        start = date.fromisoformat(self.config.temporal.start_date)
        end = date.fromisoformat(self.config.temporal.end_date)
        working_days = working_dates_in_range(start, end)

        rows: list[dict[str, Any]] = []
        seq = 1
        event_types, et_weights = zip(*EVENT_TYPE_WEIGHTS)

        while len(rows) < count:
            work_date = self.rng.choice(working_days)
            machine_id = self.rng.choice(machines)
            event_type = self.rng.choices(list(event_types), weights=list(et_weights), k=1)[0]

            hour = self.rng.randint(6, 20)
            ds = datetime(work_date.year, work_date.month, work_date.day, hour,
                          self.rng.randint(0, 59), tzinfo=timezone.utc)

            mttr_min = self.rng.uniform(*MTTR_RANGES[event_type])
            de = ds + timedelta(minutes=mttr_min)

            failure_code = (
                AnomalyInjector.maybe_null(
                    self.rng.choice(FAILURE_CODES),
                    mr.maintenance_logs_failure_code,
                    self.rng,
                )
                if event_type in ("Unplanned", "Emergency") else None
            )

            repair_cost = AnomalyInjector.maybe_null(
                round(self.rng.uniform(*REPAIR_COST_RANGES[event_type]), 4),
                mr.maintenance_logs_repair_cost, self.rng,
            )

            root_cause = AnomalyInjector.maybe_null(
                f"Root cause investigation notes for WO-{seq:04d}.",
                mr.maintenance_logs_root_cause, self.rng,
            )

            pm_schedule_id = (
                int(self.rng.choice(pm_schedules))
                if event_type == "Planned" and pm_schedules
                else None
            )

            rows.append({
                "work_order_id": IDFactory.work_order_id(work_date, seq),
                "machine_id": machine_id,
                "technician_id": self.rng.choice(technicians) if technicians else None,
                "event_type": event_type,
                "failure_code": failure_code,
                "description": f"{event_type} maintenance event on {machine_id} — {work_date}",
                "downtime_start": format_iso_utc(ds),
                "downtime_end": format_iso_utc(de),
                "downtime_minutes": round(mttr_min, 2),
                "repair_cost": repair_cost,
                "root_cause": root_cause,
                "pm_schedule_id": pm_schedule_id,
                "created_at": format_iso_utc(ds),
            })
            seq += 1

        Registry.register(self.entity_name, [r["work_order_id"] for r in rows])
        self.log_generated(len(rows))
        return rows


class MaterialMovementGenerator(BaseGenerator):
    entity_name = "material_movements"

    def generate(self) -> list[dict[str, Any]]:
        count = self.config.entities.material_movements
        work_orders = Registry.get_all("maintenance_logs")
        spare_parts_keys = Registry.get_all("spare_parts")
        rows: list[dict[str, Any]] = []
        seq = 1

        movement_types = ["GOODS_ISSUE", "GOODS_RECEIPT", "STOCK_TRANSFER", "RETURN"]
        movement_weights = [0.65, 0.20, 0.10, 0.05]

        for i in range(count):
            movement_type = self.rng.choices(movement_types, weights=movement_weights, k=1)[0]
            work_order_id = (
                self.rng.choice(work_orders)
                if movement_type == "GOODS_ISSUE" and work_orders
                else None
            )
            part_code = self.rng.choice(spare_parts_keys) if spare_parts_keys else "SP-BEAR-6205"
            qty = round(self.rng.uniform(1, 5), 4)
            unit_cost = round(self.rng.uniform(5.0, 400.0), 4)
            total_cost = round(qty * unit_cost, 4)
            move_date = date.fromisoformat(self.config.temporal.start_date) + timedelta(
                days=self.rng.randint(0, 200)
            )

            rows.append({
                "movement_id": seq,
                "part_code": part_code,
                "work_order_id": work_order_id,
                "movement_type": movement_type,
                "qty": qty,
                "unit_cost": unit_cost,
                "total_cost": total_cost,
                "movement_date": move_date.isoformat(),
                "created_by": None,
                "created_at": format_iso_utc(datetime.combine(move_date, datetime.min.time(), timezone.utc)),
            })
            seq += 1

        self.log_generated(len(rows))
        return rows
