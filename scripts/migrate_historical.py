"""One-shot migration: re-process legacy Excel calibration batches into the live DB.

Idempotent by `Logger.serial_no` — re-running skips already-migrated loggers.

Usage (inside the api container):
    python -m scripts.migrate_historical \\
        --config scripts/historical_batches.json \\
        --inputs-root /tmp/old_method \\
        --template /tmp/old_method/template.docx
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from datetime import date, datetime
from pathlib import Path


@dataclass(frozen=True)
class BatchConfig:
    name: str
    workbook: Path
    references: list[Path]
    start_cert_no: str
    cert_width: int
    test_date_jp: str
    doc_date_jp: str
    certificate_date: date
    testing_start: datetime
    testing_end: datetime


@dataclass(frozen=True)
class MigrationConfig:
    batches: list[BatchConfig]
    threshold_c: float
    setpoints_c: list[float]


def _resolve(path_str: str, inputs_root: Path) -> Path:
    """Resolve a config path against the inputs root unless it's absolute."""
    p = Path(path_str)
    return p if p.is_absolute() else inputs_root / p


def load_config(config_path: Path, inputs_root: Path) -> MigrationConfig:
    raw = json.loads(config_path.read_text())
    batches = [
        BatchConfig(
            name=b["name"],
            workbook=_resolve(b["workbook"], inputs_root),
            references=[_resolve(r, inputs_root) for r in b["references"]],
            start_cert_no=b["start_cert_no"],
            cert_width=int(b["cert_width"]),
            test_date_jp=b["test_date_jp"],
            doc_date_jp=b["doc_date_jp"],
            certificate_date=date.fromisoformat(b["certificate_date"]),
            testing_start=datetime.fromisoformat(b["testing_start"]),
            testing_end=datetime.fromisoformat(b["testing_end"]),
        )
        for b in raw["batches"]
    ]
    return MigrationConfig(
        batches=batches,
        threshold_c=float(raw["threshold_c"]),
        setpoints_c=[float(t) for t in raw["setpoints_c"]],
    )


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--config", type=Path, required=True)
    p.add_argument("--inputs-root", type=Path, required=True,
                   help="Root directory the workbook/reference relative paths are resolved against.")
    p.add_argument("--template", type=Path, required=True,
                   help="Path to template.docx — same one the live UI uses.")
    p.add_argument("--dry-run", action="store_true",
                   help="Parse config and print per-batch sheet counts; do not touch DB or files.")
    args = p.parse_args()

    cfg = load_config(args.config, args.inputs_root)

    if not args.template.exists():
        print(f"ERROR: template not found at {args.template}", file=sys.stderr)
        return 2

    for b in cfg.batches:
        if not b.workbook.exists():
            print(f"ERROR: workbook missing for '{b.name}': {b.workbook}", file=sys.stderr)
            return 2
        for r in b.references:
            if not r.exists():
                print(f"ERROR: reference missing for '{b.name}': {r}", file=sys.stderr)
                return 2

    print(f"Loaded {len(cfg.batches)} batches from {args.config}")
    for b in cfg.batches:
        print(f"  - {b.name}: workbook={b.workbook.name}, refs={len(b.references)}")

    if args.dry_run:
        print("Dry run — exiting before any DB or file changes.")
        return 0

    print("ERROR: real migration not yet implemented — stop here.", file=sys.stderr)
    return 99


if __name__ == "__main__":
    sys.exit(main())
