"""
generators/product_generator.py
SMAP Synthetic Dataset Generator — Product Generator.

Generates product records matching the 8 products seeded in 08_seed.sql.
Registers all product codes in the Registry for use by production order
and quality inspection generators.
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from generators.base_generator import BaseGenerator
from utils.registry import Registry
from utils.timestamp_utils import format_iso_utc


class ProductGenerator(BaseGenerator):
    """Generates product/SKU master records matching 08_seed.sql."""

    entity_name = "products"

    # Matches 08_seed.sql products INSERT exactly
    _PRODUCTS: list[dict[str, Any]] = [
        {"product_code": "PRD-001", "product_name": "Crankshaft Bearing Journal — Type A", "product_family": "Powertrain Components", "product_category": "Automotive", "standard_cycle_time_sec": 150.0, "standard_material_cost": 42.50, "standard_labor_cost": 8.75,  "is_active": True, "erp_material_code": "MAT-PWR-001"},
        {"product_code": "PRD-002", "product_name": "Transmission Gear Blank — Grade 5",   "product_family": "Powertrain Components", "product_category": "Automotive", "standard_cycle_time_sec": 228.0, "standard_material_cost": 38.20, "standard_labor_cost": 9.10,  "is_active": True, "erp_material_code": "MAT-PWR-002"},
        {"product_code": "PRD-003", "product_name": "Brake Caliper Housing — Type B2",     "product_family": "Brake Components",      "product_category": "Automotive", "standard_cycle_time_sec": 228.0, "standard_material_cost": 61.80, "standard_labor_cost": 12.40, "is_active": True, "erp_material_code": "MAT-BRK-003"},
        {"product_code": "PRD-004", "product_name": "Brake Bracket Precision Bore",        "product_family": "Brake Components",      "product_category": "Automotive", "standard_cycle_time_sec": 192.0, "standard_material_cost": 29.90, "standard_labor_cost": 7.60,  "is_active": True, "erp_material_code": "MAT-BRK-004"},
        {"product_code": "PRD-005", "product_name": "Steering Housing — Precision Turn",   "product_family": "Steering Components",   "product_category": "Automotive", "standard_cycle_time_sec": 252.0, "standard_material_cost": 55.30, "standard_labor_cost": 11.20, "is_active": True, "erp_material_code": "MAT-STR-005"},
        {"product_code": "PRD-006", "product_name": "Suspension Knuckle — CNC Turned",     "product_family": "Suspension Components", "product_category": "Automotive", "standard_cycle_time_sec": 204.0, "standard_material_cost": 48.70, "standard_labor_cost": 10.80, "is_active": True, "erp_material_code": "MAT-SUS-006"},
        {"product_code": "PRD-007", "product_name": "Industrial Flange — 4-Bolt Pattern",  "product_family": "Industrial Components", "product_category": "Industrial", "standard_cycle_time_sec": 180.0, "standard_material_cost": 31.50, "standard_labor_cost": 6.90,  "is_active": True, "erp_material_code": "MAT-IND-007"},
        {"product_code": "PRD-008", "product_name": "Precision Shaft Assembly — 250mm",    "product_family": "Industrial Components", "product_category": "Industrial", "standard_cycle_time_sec": 510.0, "standard_material_cost": 74.20, "standard_labor_cost": 18.50, "is_active": True, "erp_material_code": "MAT-IND-008"},
    ]

    def generate(self) -> list[dict[str, Any]]:
        created_ts = format_iso_utc(datetime(2024, 1, 15, 0, 0, 0, tzinfo=timezone.utc))
        rows = []
        for p in self._PRODUCTS:
            row = dict(p)
            row["created_at"] = created_ts
            row["updated_at"] = created_ts
            rows.append(row)

        Registry.register(self.entity_name, [r["product_code"] for r in rows])
        self.log_generated(len(rows))
        return rows
