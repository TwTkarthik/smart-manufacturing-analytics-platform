"""
main.py
SMAP Synthetic Dataset Generator — CLI Entry Point.

Usage:
    python main.py --help
    python main.py --config config/generator_config.yaml
    python main.py --entities machines,employees --count 100
    python main.py --all --seed 99 --format csv

All entities are generated in dependency order to maintain referential integrity.
"""

from __future__ import annotations

import logging
import sys
from pathlib import Path
from typing import Any

import click
from rich.console import Console
from rich.table import Table
from tqdm import tqdm

# Add generator directory to path
sys.path.insert(0, str(Path(__file__).parent))

from config.settings import GeneratorConfig
from utils.registry import Registry

console = Console()

# Generator import map (in dependency order)
def _build_generator_map(config: GeneratorConfig) -> dict[str, Any]:
    from generators.reference_generator import (
        ProductionLineGenerator, ShiftGenerator, DefectTypeGenerator,
    )
    from generators.machine_generator import MachineGenerator
    from generators.employee_generator import EmployeeGenerator
    from generators.product_generator import ProductGenerator
    from generators.production_order_generator import ProductionOrderGenerator
    from generators.downtime_generator import DowntimeEventGenerator
    from generators.sensor_generator import SensorReadingGenerator
    from generators.quality_generator import QualityInspectionGenerator
    from generators.maintenance_generator import (
        PMScheduleGenerator, MaintenanceLogGenerator, MaterialMovementGenerator,
    )

    return {
        "production_lines":   ProductionLineGenerator(config),
        "shifts":             ShiftGenerator(config),
        "defect_types":       DefectTypeGenerator(config),
        "machines":           MachineGenerator(config),
        "employees":          EmployeeGenerator(config),
        "products":           ProductGenerator(config),
        "production_orders":  ProductionOrderGenerator(config),
        "downtime_events":    DowntimeEventGenerator(config),
        "sensor_readings":    SensorReadingGenerator(config),
        "quality_inspections": QualityInspectionGenerator(config),
        "pm_schedules":       PMScheduleGenerator(config),
        "maintenance_logs":   MaintenanceLogGenerator(config),
        "material_movements": MaterialMovementGenerator(config),
    }


# Dependency order — must generate parent entities before children
GENERATION_ORDER = [
    "production_lines",
    "shifts",
    "defect_types",
    "machines",
    "employees",
    "products",
    "production_orders",
    "downtime_events",
    "sensor_readings",
    "quality_inspections",
    "pm_schedules",
    "maintenance_logs",
    "material_movements",
]


def _setup_logging(log_level: str) -> None:
    logging.basicConfig(
        level=getattr(logging, log_level.upper(), logging.INFO),
        format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )


def _write_csv(rows: list[dict[str, Any]], output_path: Path) -> None:
    import csv
    if not rows:
        return
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)


@click.command()
@click.option(
    "--config", "-c",
    default="config/generator_config.yaml",
    show_default=True,
    help="Path to generator_config.yaml.",
)
@click.option(
    "--entities", "-e",
    default=",".join(GENERATION_ORDER),
    show_default=False,
    help="Comma-separated list of entities to generate. Defaults to all.",
)
@click.option(
    "--seed", "-s",
    default=None,
    type=int,
    help="Override global random seed (overrides config file).",
)
@click.option(
    "--format", "-f",
    "output_format",
    default=None,
    type=click.Choice(["csv", "parquet"]),
    help="Output format (overrides config file).",
)
@click.option(
    "--dry-run",
    is_flag=True,
    default=False,
    help="Print generation plan without writing any files.",
)
@click.option(
    "--verbose", "-v",
    is_flag=True,
    default=False,
    help="Enable DEBUG logging.",
)
def generate(
    config: str,
    entities: str,
    seed: int | None,
    output_format: str | None,
    dry_run: bool,
    verbose: bool,
) -> None:
    """SMAP Synthetic Dataset Generator — generates production-realistic datasets."""

    # Load config
    config_path = Path(config)
    if not config_path.exists():
        console.print(f"[red]Config file not found: {config_path}[/red]")
        sys.exit(1)

    cfg = GeneratorConfig.from_yaml(config_path)

    # Override from CLI
    if seed is not None:
        cfg.global_.random_seed = seed
    if output_format is not None:
        cfg.global_.output_format = output_format

    log_level = "DEBUG" if verbose else cfg.global_.log_level
    _setup_logging(log_level)
    logger = logging.getLogger("main")

    # Parse requested entities (maintain dependency order)
    requested = [e.strip() for e in entities.split(",")]
    to_generate = [e for e in GENERATION_ORDER if e in requested]

    if dry_run:
        console.print("[bold yellow]DRY RUN — no files will be written.[/bold yellow]")

    console.print(f"[bold cyan]SMAP Synthetic Dataset Generator[/bold cyan]")
    console.print(f"Temporal scope: {cfg.temporal.start_date} → {cfg.temporal.end_date}")
    console.print(f"Random seed:    {cfg.global_.random_seed}")
    console.print(f"Output format:  {cfg.global_.output_format}")
    console.print(f"Entities:       {', '.join(to_generate)}")
    console.print("")

    # Clear registry before run
    Registry.clear()

    # Build generators
    generator_map = _build_generator_map(cfg)

    # Generate and write
    results: list[tuple[str, int]] = []
    for entity in tqdm(to_generate, desc="Generating entities", unit="entity"):
        gen = generator_map[entity]
        rows = gen.generate()

        if not dry_run:
            if cfg.global_.output_format == "csv":
                out_path = gen.output_path()
                _write_csv(rows, out_path)
                logger.info("Written: %s (%d rows)", out_path, len(rows))
            elif cfg.global_.output_format == "parquet":
                import pandas as pd
                out_path = gen.output_path(f"{entity}.parquet")
                pd.DataFrame(rows).to_parquet(out_path, index=False)
                logger.info("Written: %s (%d rows)", out_path, len(rows))

        results.append((entity, len(rows)))

    # Summary table
    table = Table(title="Generation Summary", show_header=True)
    table.add_column("Entity", style="cyan")
    table.add_column("Rows Generated", justify="right", style="green")
    table.add_column("Status", justify="center")
    for entity, row_count in results:
        table.add_row(entity, f"{row_count:,}", "DRY RUN" if dry_run else "[green]Written[/green]")
    console.print(table)

    if not dry_run:
        console.print(f"[green]All files written to: {cfg.global_.output_dir}/[/green]")


if __name__ == "__main__":
    generate()
