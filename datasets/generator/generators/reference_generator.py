"""
generators/reference_generator.py
SMAP Synthetic Dataset Generator — Reference / Static Entity Generators.

Generates static reference data that matches the seed data in 08_seed.sql.
These generators return data consistent with the seeded business facts
(defect types, spare parts) rather than random data.

Entities covered:
  - DefectTypeGenerator    (matches 08_seed.sql defect_types INSERT)
  - SparePartsGenerator    (matches 08_seed.sql spare_parts INSERT)
  - ProductionLineGenerator (matches 08_seed.sql production_lines INSERT)
  - ShiftGenerator         (matches 08_seed.sql shifts INSERT)
"""

from __future__ import annotations

from typing import Any

from generators.base_generator import BaseGenerator
from utils.registry import Registry


class ProductionLineGenerator(BaseGenerator):
    """Generates production line records matching 08_seed.sql."""

    entity_name = "production_lines"

    def generate(self) -> list[dict[str, Any]]:
        rows = [
            {"line_code": "LINE-A", "line_name": "Powertrain Turning Cell",      "plant_code": "PLT-DET", "primary_operation": "CNC Turning and Grinding",     "shift_pattern": "3-shift, 6 days/week", "oee_target": 0.8100, "is_active": True},
            {"line_code": "LINE-B", "line_name": "Brake Components Cell",        "plant_code": "PLT-DET", "primary_operation": "CNC Milling and Boring",       "shift_pattern": "3-shift, 6 days/week", "oee_target": 0.7800, "is_active": True},
            {"line_code": "LINE-C", "line_name": "Steering and Suspension Cell", "plant_code": "PLT-DET", "primary_operation": "CNC Turning and Boring",       "shift_pattern": "3-shift, 5 days/week", "oee_target": 0.7600, "is_active": True},
            {"line_code": "LINE-D", "line_name": "Multi-Process / Assembly",     "plant_code": "PLT-DET", "primary_operation": "Mixed Machining and Assembly", "shift_pattern": "2-shift, 5 days/week", "oee_target": 0.7200, "is_active": True},
            {"line_code": "LINE-E", "line_name": "CLV High-Volume Turning A",    "plant_code": "PLT-CLV", "primary_operation": "High-Volume CNC Turning",      "shift_pattern": "3-shift, 7 days/week", "oee_target": 0.8400, "is_active": True},
            {"line_code": "LINE-F", "line_name": "CLV High-Volume Turning B",    "plant_code": "PLT-CLV", "primary_operation": "High-Volume CNC Turning",      "shift_pattern": "3-shift, 7 days/week", "oee_target": 0.8400, "is_active": True},
            {"line_code": "LINE-G", "line_name": "CLV Gauging and Finish",       "plant_code": "PLT-CLV", "primary_operation": "Automated Gauging and Finish", "shift_pattern": "3-shift, 7 days/week", "oee_target": 0.8600, "is_active": True},
            {"line_code": "LINE-H", "line_name": "CHI Stamping Line A",          "plant_code": "PLT-CHI", "primary_operation": "Progressive Die Stamping",     "shift_pattern": "2-shift, 5 days/week", "oee_target": 0.7800, "is_active": True},
            {"line_code": "LINE-I", "line_name": "CHI Forming Line B",           "plant_code": "PLT-CHI", "primary_operation": "Deep Drawing and Roll Forming","shift_pattern": "2-shift, 5 days/week", "oee_target": 0.7500, "is_active": True},
            {"line_code": "LINE-J", "line_name": "MTY Finishing Line A",         "plant_code": "PLT-MTY", "primary_operation": "Electroplating and Coating",   "shift_pattern": "3-shift, 5 days/week", "oee_target": 0.8000, "is_active": True},
            {"line_code": "LINE-K", "line_name": "MTY Sub-Assembly Line B",      "plant_code": "PLT-MTY", "primary_operation": "Sub-Assembly and Packaging",   "shift_pattern": "2-shift, 5 days/week", "oee_target": 0.7700, "is_active": True},
        ]
        Registry.register(self.entity_name, [r["line_code"] for r in rows])
        self.log_generated(len(rows))
        return rows


class ShiftGenerator(BaseGenerator):
    """Generates shift records matching 08_seed.sql."""

    entity_name = "shifts"

    def generate(self) -> list[dict[str, Any]]:
        rows = [
            {"shift_code": "SHIFT-A", "shift_name": "Day Shift",       "shift_start_time": "06:00:00", "shift_end_time": "14:00:00", "shift_duration_hours": 8.00, "planned_production_hours": 7.50, "plant_code": "PLT-DET"},
            {"shift_code": "SHIFT-B", "shift_name": "Afternoon Shift",  "shift_start_time": "14:00:00", "shift_end_time": "22:00:00", "shift_duration_hours": 8.00, "planned_production_hours": 7.50, "plant_code": "PLT-DET"},
            {"shift_code": "SHIFT-C", "shift_name": "Night Shift",      "shift_start_time": "22:00:00", "shift_end_time": "06:00:00", "shift_duration_hours": 8.00, "planned_production_hours": 7.50, "plant_code": "PLT-DET"},
            {"shift_code": "SHIFT-D", "shift_name": "Day Shift",        "shift_start_time": "06:00:00", "shift_end_time": "14:00:00", "shift_duration_hours": 8.00, "planned_production_hours": 7.75, "plant_code": "PLT-CLV"},
            {"shift_code": "SHIFT-E", "shift_name": "Afternoon Shift",  "shift_start_time": "14:00:00", "shift_end_time": "22:00:00", "shift_duration_hours": 8.00, "planned_production_hours": 7.75, "plant_code": "PLT-CLV"},
            {"shift_code": "SHIFT-F", "shift_name": "Night Shift",      "shift_start_time": "22:00:00", "shift_end_time": "06:00:00", "shift_duration_hours": 8.00, "planned_production_hours": 7.75, "plant_code": "PLT-CLV"},
            {"shift_code": "SHIFT-G", "shift_name": "Day Shift",        "shift_start_time": "06:00:00", "shift_end_time": "16:00:00", "shift_duration_hours": 10.00, "planned_production_hours": 9.50, "plant_code": "PLT-CHI"},
            {"shift_code": "SHIFT-H", "shift_name": "Afternoon Shift",  "shift_start_time": "16:00:00", "shift_end_time": "02:00:00", "shift_duration_hours": 10.00, "planned_production_hours": 9.50, "plant_code": "PLT-CHI"},
            {"shift_code": "SHIFT-I", "shift_name": "Day Shift",        "shift_start_time": "07:00:00", "shift_end_time": "15:00:00", "shift_duration_hours": 8.00, "planned_production_hours": 7.50, "plant_code": "PLT-MTY"},
            {"shift_code": "SHIFT-J", "shift_name": "Afternoon Shift",  "shift_start_time": "15:00:00", "shift_end_time": "23:00:00", "shift_duration_hours": 8.00, "planned_production_hours": 7.50, "plant_code": "PLT-MTY"},
        ]
        Registry.register(self.entity_name, [r["shift_code"] for r in rows])
        # DET-only shifts for production order generation
        Registry.register("shifts_det", [r["shift_code"] for r in rows if r["plant_code"] == "PLT-DET"])
        self.log_generated(len(rows))
        return rows


class DefectTypeGenerator(BaseGenerator):
    """Generates defect_type reference data matching 08_seed.sql."""

    entity_name = "defect_types"

    def generate(self) -> list[dict[str, Any]]:
        rows = [
            {"defect_type_code": "DFT-DIM-OOS",  "defect_type_name": "Dimensional Out-of-Specification",   "defect_category": "Dimensional", "severity_level": "Critical", "is_customer_escape_risk": True,  "description": "Part dimension outside drawing tolerance.",         "is_active": True},
            {"defect_type_code": "DFT-DIM-TPR",  "defect_type_name": "Taper or Runout Error",              "defect_category": "Dimensional", "severity_level": "Major",    "is_customer_escape_risk": True,  "description": "Geometric tolerance violation.",                    "is_active": True},
            {"defect_type_code": "DFT-DIM-THR",  "defect_type_name": "Thread Form Defect",                 "defect_category": "Dimensional", "severity_level": "Critical", "is_customer_escape_risk": True,  "description": "Thread pitch, diameter, or form outside specification.", "is_active": True},
            {"defect_type_code": "DFT-SURF-SCR", "defect_type_name": "Surface Scratch or Score",           "defect_category": "Surface",     "severity_level": "Minor",    "is_customer_escape_risk": False, "description": "Surface mark from handling or machining.",          "is_active": True},
            {"defect_type_code": "DFT-SURF-PIT", "defect_type_name": "Pitting or Porosity",                "defect_category": "Surface",     "severity_level": "Major",    "is_customer_escape_risk": True,  "description": "Material porosity breaking through machined surface.", "is_active": True},
            {"defect_type_code": "DFT-SURF-RGH", "defect_type_name": "Surface Roughness Out-of-Spec",      "defect_category": "Surface",     "severity_level": "Major",    "is_customer_escape_risk": True,  "description": "Ra/Rz surface roughness exceeds specification.",     "is_active": True},
            {"defect_type_code": "DFT-SURF-BRN", "defect_type_name": "Thermal Burn (Grinding)",            "defect_category": "Surface",     "severity_level": "Critical", "is_customer_escape_risk": True,  "description": "Heat-induced surface damage from grinding.",         "is_active": True},
            {"defect_type_code": "DFT-STRUCT-CRK","defect_type_name": "Crack (Surface or Sub-surface)",    "defect_category": "Structural",  "severity_level": "Critical", "is_customer_escape_risk": True,  "description": "Material crack detected by MPI or dye penetrant.",  "is_active": True},
            {"defect_type_code": "DFT-STRUCT-HAR","defect_type_name": "Hardness Out-of-Specification",     "defect_category": "Structural",  "severity_level": "Critical", "is_customer_escape_risk": True,  "description": "Hardness outside specification after heat treatment.", "is_active": True},
            {"defect_type_code": "DFT-STRUCT-MAT","defect_type_name": "Wrong Material / Mix-up",           "defect_category": "Structural",  "severity_level": "Critical", "is_customer_escape_risk": True,  "description": "Material grade does not match specification.",       "is_active": True},
            {"defect_type_code": "DFT-FUNC-PRES", "defect_type_name": "Failed Pressure Test",              "defect_category": "Functional",  "severity_level": "Critical", "is_customer_escape_risk": True,  "description": "Component fails pressure/leak test.",               "is_active": True},
            {"defect_type_code": "DFT-FUNC-ASSY", "defect_type_name": "Assembly Interference or Mis-fit",  "defect_category": "Functional",  "severity_level": "Major",    "is_customer_escape_risk": True,  "description": "Component does not assemble correctly with mating part.", "is_active": True},
            {"defect_type_code": "DFT-OTHER-CONT","defect_type_name": "Contamination (Foreign Material)",  "defect_category": "Other",       "severity_level": "Major",    "is_customer_escape_risk": False, "description": "Foreign material present on or in the part.",       "is_active": True},
            {"defect_type_code": "DFT-OTHER-MARK","defect_type_name": "Missing or Incorrect Marking",      "defect_category": "Other",       "severity_level": "Minor",    "is_customer_escape_risk": False, "description": "Part number stamp or traceability mark missing.",    "is_active": True},
            {"defect_type_code": "DFT-OTHER-UNK", "defect_type_name": "Defect - Unclassified",             "defect_category": "Other",       "severity_level": "Minor",    "is_customer_escape_risk": False, "description": "Defect not yet classified by QA technician.",       "is_active": True},
        ]
        Registry.register(self.entity_name, [r["defect_type_code"] for r in rows])
        self.log_generated(len(rows))
        return rows
