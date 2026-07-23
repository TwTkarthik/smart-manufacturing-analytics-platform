"""
generators/employee_generator.py
SMAP Synthetic Dataset Generator — Employee Generator.

Generates anonymized employee records. No PII is stored.
Includes the EMP-ROBOT pseudo-employee record for automated cycles.
"""

from __future__ import annotations

from datetime import date, datetime, timezone
from typing import Any

from generators.base_generator import BaseGenerator
from utils.anomaly_injector import AnomalyInjector
from utils.id_factory import IDFactory
from utils.registry import Registry
from utils.timestamp_utils import format_iso_utc


# Role distribution: role_code, role_name, dept_code, fraction
ROLE_DISTRIBUTION = [
    ("OPR-MCH", "Machine Operator",        "DEPT-OPS", 0.50),
    ("OPR-SET", "Setup Technician",        "DEPT-OPS", 0.15),
    ("QA-TECH", "Quality Technician",      "DEPT-QA",  0.20),
    ("MNT-TECH", "Maintenance Technician", "DEPT-MNT", 0.10),
    ("MNT-PLNR", "Maintenance Planner",    "DEPT-MNT", 0.05),
]

SHIFT_CODES = ["SHIFT-A", "SHIFT-B", "SHIFT-C"]
SKILL_LEVELS = ["Junior", "Senior", "Expert"]
SKILL_WEIGHTS = [0.35, 0.45, 0.20]
CERTIFICATIONS = ["IATF-16949", "Lock-Out-Tag-Out", "Forklift", "CMM Operation", "SPC Charting", "5S", "OSHA-30"]


class EmployeeGenerator(BaseGenerator):
    """Generates anonymized employee records for the SMAP operational database."""

    entity_name = "employees"

    def generate(self) -> list[dict[str, Any]]:
        count = self.config.entities.employees
        mr = self.config.data_quality.missing_rates
        rows: list[dict[str, Any]] = []

        # Pre-calculate role pool from distribution fractions
        role_pool: list[tuple[str, str, str]] = []
        for role_code, role_name, dept, frac in ROLE_DISTRIBUTION:
            n = max(1, round(count * frac))
            role_pool.extend([(role_code, role_name, dept)] * n)
        self.rng.shuffle(role_pool)

        created_ts = format_iso_utc(datetime(2024, 1, 15, 0, 0, 0, tzinfo=timezone.utc))

        for seq in range(1, count + 1):
            role_code, role_name, dept = role_pool[(seq - 1) % len(role_pool)]

            skill = self.rng.choices(SKILL_LEVELS, weights=SKILL_WEIGHTS, k=1)[0]
            skill = AnomalyInjector.maybe_null(skill, mr.employees_skill_level, self.rng)

            hire_year = self.rng.randint(2005, 2025)
            hire_date = date(hire_year, self.rng.randint(1, 12), self.rng.randint(1, 28))
            hire_date_str = AnomalyInjector.maybe_null(hire_date.isoformat(), mr.employees_hire_date, self.rng)

            certs = self.rng.sample(CERTIFICATIONS, k=self.rng.randint(0, 3))
            cert_str = ", ".join(certs) if certs else None

            rows.append({
                "employee_id": IDFactory.employee_id(seq),
                "role_code": role_code,
                "role_name": role_name,
                "department_code": dept,
                "shift_assignment": self.rng.choice(SHIFT_CODES),
                "skill_level": skill,
                "training_certifications": cert_str,
                "hire_date": hire_date_str,
                "is_active": True if self.rng.random() > 0.05 else False,
                "is_automated": False,
                "created_at": created_ts,
                "updated_at": created_ts,
            })

        # Add the EMP-ROBOT pseudo-employee (required for automated cycles)
        rows.append({
            "employee_id": "EMP-ROBOT",
            "role_code": "OPR-MCH",
            "role_name": "Automated Cycle",
            "department_code": "DEPT-OPS",
            "shift_assignment": "SHIFT-A",
            "skill_level": None,
            "training_certifications": None,
            "hire_date": None,
            "is_active": True,
            "is_automated": True,
            "created_at": created_ts,
            "updated_at": created_ts,
        })

        Registry.register(self.entity_name, [r["employee_id"] for r in rows])
        # Separate registries by role for FK-constrained sampling
        for role, _, dept in ROLE_DISTRIBUTION:
            Registry.register(
                f"employees_{role.lower().replace('-', '_')}",
                [r["employee_id"] for r in rows if r["role_code"] == role and r["is_active"]],
            )
        self.log_generated(len(rows))
        return rows
