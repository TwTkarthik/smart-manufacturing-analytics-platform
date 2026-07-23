"""
utils/timestamp_utils.py
SMAP Synthetic Dataset Generator — Shift-Aware Timestamp Utilities.

Generates realistic UTC timestamps constrained to active shift windows
over the configured temporal scope. Handles shift boundaries, overnight
shifts (SHIFT-C: 22:00–06:00), and plant operating calendars.
"""

from __future__ import annotations

import logging
import random
from datetime import date, datetime, time, timedelta, timezone
from typing import Sequence

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Shift windows — matches seeds in 08_seed.sql
# (shift_code, start_hour, end_hour) where end_hour < start_hour = overnight
# ---------------------------------------------------------------------------
SHIFT_WINDOWS: dict[str, tuple[int, int]] = {
    "SHIFT-A": (6, 14),    # Day shift:       06:00–14:00
    "SHIFT-B": (14, 22),   # Afternoon shift: 14:00–22:00
    "SHIFT-C": (22, 30),   # Night shift:     22:00–06:00 next day (30 = 24+6)
    "SHIFT-D": (6, 14),    # CLV Day
    "SHIFT-E": (14, 22),   # CLV Afternoon
    "SHIFT-F": (22, 30),   # CLV Night
    "SHIFT-G": (6, 16),    # CHI Day (10-hour)
    "SHIFT-H": (16, 26),   # CHI Afternoon (10-hour, 16:00–02:00 next day)
    "SHIFT-I": (7, 15),    # MTY Day
    "SHIFT-J": (15, 23),   # MTY Afternoon
}


def _date_range(start: date, end: date) -> list[date]:
    """Return a list of dates from start (inclusive) to end (inclusive)."""
    days: list[date] = []
    current = start
    while current <= end:
        days.append(current)
        current += timedelta(days=1)
    return days


def random_utc_in_shift(
    base_date: date,
    shift_code: str,
    rng: random.Random,
) -> datetime:
    """
    Return a random UTC datetime within the specified shift window on the given date.

    For overnight shifts (SHIFT-C, SHIFT-F), the start is on base_date and
    the end crosses midnight.

    Args:
        base_date:   The calendar date of the shift START.
        shift_code:  One of the defined shift codes.
        rng:         Seeded random.Random instance.

    Returns:
        A timezone-aware datetime in UTC.
    """
    if shift_code not in SHIFT_WINDOWS:
        raise ValueError(f"Unknown shift_code: '{shift_code}'. Known: {list(SHIFT_WINDOWS)}")

    start_hour, end_hour = SHIFT_WINDOWS[shift_code]

    # Convert to minutes since midnight on base_date
    start_min = start_hour * 60
    end_min = end_hour * 60  # may be > 1440 for overnight shifts

    # Exclude first 15 min (shift handover) and last 5 min of shift
    start_min += 15
    end_min -= 5

    offset_minutes = rng.randint(start_min, end_min)
    base_midnight = datetime.combine(base_date, time.min, tzinfo=timezone.utc)
    return base_midnight + timedelta(minutes=offset_minutes)


def random_utc_in_range(
    start: datetime,
    end: datetime,
    rng: random.Random,
) -> datetime:
    """
    Return a random UTC datetime uniformly distributed between start and end.

    Args:
        start: Start datetime (inclusive), timezone-aware (UTC).
        end:   End datetime (inclusive), timezone-aware (UTC).
        rng:   Seeded random.Random instance.

    Returns:
        Timezone-aware datetime in UTC.
    """
    delta_seconds = int((end - start).total_seconds())
    if delta_seconds <= 0:
        return start
    offset = rng.randint(0, delta_seconds)
    return start + timedelta(seconds=offset)


def shift_start_utc(base_date: date, shift_code: str) -> datetime:
    """Return the UTC datetime of the shift start (after handover)."""
    start_hour, _ = SHIFT_WINDOWS.get(shift_code, (6, 14))
    return datetime.combine(
        base_date, time(start_hour % 24, 15), tzinfo=timezone.utc
    )


def shift_end_utc(base_date: date, shift_code: str) -> datetime:
    """Return the UTC datetime of the shift end (5 min before scheduled end)."""
    _, end_hour = SHIFT_WINDOWS.get(shift_code, (6, 14))
    end_minutes = (end_hour % 24) * 60 - 5
    base_midnight = datetime.combine(base_date, time.min, tzinfo=timezone.utc)
    # Adjust for overnight shifts
    if end_hour >= 24:
        base_midnight += timedelta(days=1)
    return base_midnight + timedelta(minutes=end_minutes % (24 * 60))


def working_dates_in_range(
    start: date,
    end: date,
    exclude_weekends: bool = True,
) -> list[date]:
    """
    Return all working dates in [start, end] range.
    PLT-DET operates Mon–Sat; SHIFT-C runs Mon–Fri nights.
    Simple approximation: exclude Sundays (index 6).
    """
    all_dates = _date_range(start, end)
    if not exclude_weekends:
        return all_dates
    # Exclude Sundays (weekday() == 6)
    return [d for d in all_dates if d.weekday() != 6]


def format_iso_utc(dt: datetime) -> str:
    """Format a datetime as ISO 8601 UTC string for CSV output."""
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.strftime("%Y-%m-%dT%H:%M:%S+00:00")
