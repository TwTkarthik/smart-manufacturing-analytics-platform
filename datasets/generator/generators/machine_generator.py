"""
generators/machine_generator.py
SMAP Synthetic Dataset Generator — Machine Generator.

Generates 48 machines for PLT-DET matching the machine count and type
distribution in MANUFACTURING_PROCESS.md §3.1. Each machine is assigned
to the correct production line per the documented line-machine mapping.
"""

from __future__ import annotations

from datetime import date, timezone
from typing import Any

from generators.base_generator import BaseGenerator
from utils.id_factory import IDFactory
from utils.registry import Registry
from utils.timestamp_utils import format_iso_utc
from datetime import datetime


# PLT-DET machine type distribution per MANUFACTURING_PROCESS.md §3.1
# (type_code, count, line_assignments, rated_cap_min, rated_cap_max, oee_target)
MACHINE_SPEC: list[tuple[str, str, int, str, float, float, float]] = [
    # (type_code, type_name, count, line_code, cap_min, cap_max, oee_target)
    ("MCH-LATHE", "CNC Turning Center",   14, "LINE-A",  14.0, 22.0, 0.7900),
    ("MCH-MILL",  "CNC Machining Center", 11, "LINE-B",   8.0, 15.0, 0.7600),
    ("MCH-GRIND", "CNC Grinding Machine",  6, "LINE-A",   5.0, 10.0, 0.7400),
    ("MCH-PRESS", "Hydraulic Press",       4, "LINE-D",  20.0, 45.0, 0.8200),
    ("MCH-CMM",   "CMM Inspection",        3, "LINE-B",   4.0,  8.0, 0.9100),
    ("MCH-CONV",  "Conveyor System",       6, "LINE-A",   0.0,  0.0, 0.9100),
    ("MCH-ASSY",  "Assembly Station",      4, "LINE-D",   8.0, 14.0, 0.8000),
]

MANUFACTURERS: dict[str, list[str]] = {
    "MCH-LATHE":  ["Mazak", "DMG Mori", "Okuma", "Doosan"],
    "MCH-MILL":   ["Mazak", "DMG Mori", "Haas", "Makino"],
    "MCH-GRIND":  ["JTEKT", "Kellenberger", "Okamoto", "STUDER"],
    "MCH-PRESS":  ["Schuler", "Aida", "Cincinnati", "Bliss"],
    "MCH-CMM":    ["Zeiss", "Hexagon", "Renishaw"],
    "MCH-CONV":   ["Hytrol", "Jervis Webb", "Dorner"],
    "MCH-ASSY":   ["Bosch Rexroth", "Deprag", "Staufen"],
}


class MachineGenerator(BaseGenerator):
    """Generates 48 PLT-DET machines with correct type distribution and line assignment."""

    entity_name = "machines"

    def generate(self) -> list[dict[str, Any]]:
        rows: list[dict[str, Any]] = []
        seq = 1
        asset_seq = 42  # Start asset tag numbering at AT-0042

        for type_code, type_name, count, line_code, cap_min, cap_max, oee_tgt in MACHINE_SPEC:
            mfr_options = MANUFACTURERS[type_code]
            for i in range(count):
                machine_id = IDFactory.machine_id(seq)
                mfr = self.rng.choice(mfr_options)
                install_year = self.rng.randint(2008, 2022)
                install_date = date(install_year, self.rng.randint(1, 12), self.rng.randint(1, 28))
                cap = round(self.rng.uniform(cap_min, cap_max), 2) if cap_min > 0 else None

                # SCADA tag: CELL_A1_LATHE_01 format
                line_letter = line_code.replace("LINE-", "")
                type_short = type_code.replace("MCH-", "")
                scada_tag = f"CELL_{line_letter}{(i+1):01d}_{type_short}_{seq:02d}"

                rows.append({
                    "machine_id": machine_id,
                    "machine_name": f"{type_name} #{seq:03d} — {line_code}",
                    "machine_type_code": type_code,
                    "line_code": line_code,
                    "plant_code": "PLT-DET",
                    "manufacturer": mfr,
                    "model_number": f"{mfr[:3].upper()}-{type_short}-{seq:04d}",
                    "rated_capacity_per_hour": cap,
                    "install_date": install_date.isoformat(),
                    "is_active": True,
                    "scada_tag_name": scada_tag,
                    "asset_tag_number": IDFactory.asset_tag(asset_seq),
                    "erp_work_center_code": IDFactory.erp_work_center(line_code, seq),
                    "created_at": format_iso_utc(datetime(2024, 1, 15, 0, 0, 0, tzinfo=timezone.utc)),
                    "updated_at": format_iso_utc(datetime(2024, 1, 15, 0, 0, 0, tzinfo=timezone.utc)),
                })
                seq += 1
                asset_seq += 1

        Registry.register(self.entity_name, [r["machine_id"] for r in rows])
        # Also register by line for FK-constrained queries
        for line in ["LINE-A", "LINE-B", "LINE-C", "LINE-D"]:
            Registry.register(
                f"machines_{line}",
                [r["machine_id"] for r in rows if r["line_code"] == line],
            )
        self.log_generated(len(rows))
        return rows
