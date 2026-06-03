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

    return run_migration(cfg, template=args.template)


def run_migration(cfg: MigrationConfig, *, template: Path) -> int:
    # Imports are local so `--dry-run` works without the ite_api package installed.
    from ite_api.calibration.cal_loader import load_calibration_sheet, load_workbook
    from ite_api.calibration.engine import RunConfig, SetpointWindow, run_one_logger
    from ite_api.calibration.matcher import find_values_for_target
    from ite_api.calibration.ref_loader import combine_refs, load_ref_auto
    from ite_api.config import get_settings
    from ite_api.db.models import AuditLog
    from ite_api.db.models.calibration import (
        CalibrationRun,
        Logger,
        LoggerResult,
        RunCalibrationFile,
        RunReferenceFile,
    )
    from ite_api.db.session import _init, _SessionLocal
    from ite_api.storage import save_file

    settings = get_settings()
    _init()
    assert _SessionLocal is not None

    setpoint_windows_by_batch: dict[str, list[SetpointWindow]] = {}
    for b in cfg.batches:
        setpoint_windows_by_batch[b.name] = [
            SetpointWindow(target=t, start=b.testing_start, end=b.testing_end)
            for t in cfg.setpoints_c
        ]

    total_migrated = 0
    total_skipped = 0

    for batch in cfg.batches:
        print(f"\n=== {batch.name} ===")
        with _SessionLocal() as db:
            run = CalibrationRun(
                batch_name=batch.name,
                status="complete",
                testing_start=batch.testing_start,
                testing_end=batch.testing_end,
                certificate_date=batch.certificate_date,
                threshold_c=cfg.threshold_c,
                setpoints=[
                    {
                        "target_c": sp.target,
                        "start_at": sp.start.isoformat(),
                        "end_at": sp.end.isoformat(),
                    }
                    for sp in setpoint_windows_by_batch[batch.name]
                ],
                template_path=str(template),
                start_cert_no=batch.start_cert_no,
                cert_width=batch.cert_width,
                test_date_jp=batch.test_date_jp,
                doc_date_jp=batch.doc_date_jp,
                completed_at=datetime.now(tz=batch.testing_end.tzinfo) if batch.testing_end.tzinfo else datetime.utcnow(),
            )
            db.add(run)
            db.flush()

            cal_bytes = batch.workbook.read_bytes()
            cal_stored, cal_sha = save_file(
                cal_bytes, run_id=run.id, sub="calibration",
                original_name=batch.workbook.name, data_dir=settings.data_dir,
            )
            wb, sheet_names = load_workbook(cal_stored)
            db.add(RunCalibrationFile(
                run_id=run.id, original_name=batch.workbook.name,
                stored_path=str(cal_stored), sha256=cal_sha,
                sheet_names=sheet_names,
            ))

            for ref_path in batch.references:
                rbytes = ref_path.read_bytes()
                rstored, rsha = save_file(
                    rbytes, run_id=run.id, sub="references",
                    original_name=ref_path.name, data_dir=settings.data_dir,
                )
                db.add(RunReferenceFile(
                    run_id=run.id, original_name=ref_path.name,
                    stored_path=str(rstored), sha256=rsha,
                ))

            db.flush()

            ref_df = combine_refs([load_ref_auto(p) for p in batch.references])
            setpoints = setpoint_windows_by_batch[batch.name]
            start = int(batch.start_cert_no)
            certs_dir = settings.data_dir / "runs" / str(run.id) / "certificates"
            certs_dir.mkdir(parents=True, exist_ok=True)

            migrated_in_batch = 0
            skipped_in_batch = 0

            for idx, name in enumerate(sheet_names):
                serial = name.strip()
                existing = db.query(Logger).filter_by(serial_no=serial).first()
                if existing is not None:
                    print(f"  skip serial={serial} (already in DB)")
                    skipped_in_batch += 1
                    continue

                cert_no = str(start + idx).zfill(batch.cert_width)
                run_cfg = RunConfig(
                    cert_no=cert_no,
                    serial=serial,
                    test_date_jp=batch.test_date_jp,
                    doc_date_jp=batch.doc_date_jp,
                    template_path=template,
                    output_dir=certs_dir,
                    setpoints=setpoints,
                )
                out_path = run_one_logger(run_cfg, sheet_name=name, wb=wb, ref_df=ref_df)

                logger = Logger(serial_no=serial)
                db.add(logger)
                db.flush()

                cal_df = load_calibration_sheet(wb, name)
                per_sp = []
                deviations: list[float] = []
                for sp in setpoints:
                    ref_v, cal_v, _ = find_values_for_target(
                        cal_df, ref_df, sp.target, sp.start, sp.end
                    )
                    dev = abs(ref_v - cal_v) if (ref_v is not None and cal_v is not None) else None
                    per_sp.append({
                        "target_c": sp.target,
                        "ref_c": ref_v,
                        "cal_c": cal_v,
                        "dev_c": round(dev, 3) if dev is not None else None,
                        "within_tol": bool(dev is not None and dev <= cfg.threshold_c),
                    })
                    if dev is not None:
                        deviations.append(dev)

                max_dev = max(deviations) if deviations else None
                verdict = "pass" if (max_dev is not None and max_dev <= cfg.threshold_c) else "fail"

                db.add(LoggerResult(
                    run_id=run.id,
                    logger_id=logger.id,
                    sheet_name=name,
                    verdict=verdict,
                    max_deviation_c=max_dev,
                    per_setpoint=per_sp,
                    cert_no=cert_no,
                    cert_path=str(out_path),
                ))
                migrated_in_batch += 1

            db.add(AuditLog(
                user_id=None,
                action="run.migrated",
                run_id=run.id,
                detail={
                    "source": "scripts/migrate_historical.py",
                    "workbook": batch.workbook.name,
                    "migrated": migrated_in_batch,
                    "skipped": skipped_in_batch,
                },
            ))
            db.commit()
            print(f"  migrated={migrated_in_batch}, skipped={skipped_in_batch}, run_id={run.id}")
            total_migrated += migrated_in_batch
            total_skipped += skipped_in_batch

    print(f"\nTotal migrated: {total_migrated}, total skipped: {total_skipped}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
