"""
utils/id_factory.py
SMAP Synthetic Dataset Generator — Deterministic ID Generation.

All IDs follow the naming conventions defined in DATABASE_DESIGN.md §6.
IDs are generated deterministically based on a sequence number so that
repeated runs with the same seed produce identical datasets.
"""

from __future__ import annotations

from datetime import date


class IDFactory:
    """
    Generates business-format primary key strings matching source system
    ID formats documented in the SMAP data dictionary.

    All methods are stateless — pass the sequence number explicitly.
    """

    # ── Production system IDs ────────────────────────────────────────────────

    @staticmethod
    def machine_id(seq: int) -> str:
        """MCH-001 through MCH-048. seq is 1-based."""
        return f"MCH-{seq:03d}"

    @staticmethod
    def employee_id(seq: int) -> str:
        """EMP-NNNN. seq is 1-based."""
        return f"EMP-{seq:04d}"

    @staticmethod
    def product_code(seq: int) -> str:
        """PRD-NNN. seq is 1-based."""
        return f"PRD-{seq:03d}"

    @staticmethod
    def order_id(event_date: date, seq: int) -> str:
        """MES-YYYYMMDD-NNNNN."""
        return f"MES-{event_date.strftime('%Y%m%d')}-{seq:05d}"

    @staticmethod
    def downtime_event_id(event_date: date, seq: int) -> str:
        """DT-YYYYMMDD-NNNNN."""
        return f"DT-{event_date.strftime('%Y%m%d')}-{seq:05d}"

    @staticmethod
    def inspection_id(event_date: date, seq: int) -> str:
        """QI-YYYYMMDD-NNNNN."""
        return f"QI-{event_date.strftime('%Y%m%d')}-{seq:05d}"

    @staticmethod
    def work_order_id(event_date: date, seq: int) -> str:
        """WO-YYYYMMDD-NNNN."""
        return f"WO-{event_date.strftime('%Y%m%d')}-{seq:04d}"

    @staticmethod
    def erp_order_id(event_date: date, seq: int) -> str:
        """PP-YYYYMMDD-XXXXX (ERP format)."""
        return f"PP-{event_date.strftime('%Y%m%d')}-{seq:05d}"

    @staticmethod
    def scada_tag(line_prefix: str, machine_type_short: str, seq: int) -> str:
        """CELL_A1_LATHE_01 format. line_prefix e.g. 'A', machine_type_short e.g. 'LATHE'."""
        return f"CELL_{line_prefix}{seq:01d}_{machine_type_short}_{seq:02d}"

    @staticmethod
    def asset_tag(seq: int) -> str:
        """AT-NNNN."""
        return f"AT-{seq:04d}"

    @staticmethod
    def erp_work_center(line_code: str, seq: int) -> str:
        """WC-LINE-NN."""
        line = line_code.replace("LINE-", "")
        return f"WC-{line}-{seq:02d}"
