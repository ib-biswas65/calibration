#!/usr/bin/env python3
"""
Ingest historical calibration certificates from OneDrive folders into the database.

Parses cert_no and serial_no from filename pattern:
  Calibration_Certificate_XXXXXXXXXX_YYYYYYYYYYYYYYY.docx

Run via:
  docker exec -i calibration-api-1 python /scripts/ingest_historical.py
Or directly (requires DATABASE_URL env):
  DATABASE_URL=postgresql+psycopg://ite:changeme@localhost:5432/ite python scripts/ingest_historical.py
"""

import os
import re
import sys
import uuid
from datetime import date, datetime, timezone
from pathlib import Path

CERT_RE = re.compile(r"Calibration_Certificate_(\d+)_(\d+)\.docx$", re.IGNORECASE)

ONEDRIVE = Path.home() / "Library/CloudStorage/OneDrive-Personal/Ice Battery Intern"
CURRENT  = ONEDRIVE / "Current Work/Calibration"
OLD      = ONEDRIVE / "Old Work/Caliberation"

BATCHES = [
    {
        "batch_name": "March 6th 2026 — ITE Calibration",
        "cert_date": date(2026, 3, 6),
        "dirs": [CURRENT / "March 6th" / "output"],
    },
    {
        "batch_name": "March 12th 2026 — ITE Calibration",
        "cert_date": date(2026, 3, 12),
        "dirs": [
            CURRENT / "March 12th" / "Output",
            CURRENT / "March 12th" / "Output 2",
        ],
    },
    {
        "batch_name": "Alfresa October 2025 — ITE Calibration",
        "cert_date": date(2025, 10, 1),
        "dirs": [CURRENT / "2025" / "Alfresa October Calibration"],
    },
    {
        "batch_name": "June 13th 2025 — ITE Calibration",
        "cert_date": date(2025, 6, 13),
        "dirs": [CURRENT / "2025" / "June 13th"],
    },
]


def scan_batch(dirs: list[Path]) -> list[tuple[str, str, str]]:
    """Return list of (cert_no, serial_no, file_path) tuples from a set of dirs."""
    results = []
    for d in dirs:
        if not d.exists():
            print(f"  [skip] dir not found: {d}", file=sys.stderr)
            continue
        for f in sorted(d.iterdir()):
            m = CERT_RE.match(f.name)
            if m:
                cert_no, serial_no = m.group(1), m.group(2)
                results.append((cert_no, serial_no, str(f)))
    return results


def main() -> None:
    db_url = os.environ.get(
        "DATABASE_URL",
        "postgresql+psycopg://ite:changeme@localhost:5432/ite",
    )

    try:
        import sqlalchemy as sa
        from sqlalchemy.orm import Session
    except ImportError:
        print("sqlalchemy not installed — run inside the API container.", file=sys.stderr)
        sys.exit(1)

    engine = sa.create_engine(db_url)

    with Session(engine) as session:
        for batch in BATCHES:
            certs = scan_batch(batch["dirs"])
            if not certs:
                print(f"[skip] no certs found for: {batch['batch_name']}")
                continue

            print(f"\n[batch] {batch['batch_name']}  ({len(certs)} certs)")

            cert_date = batch["cert_date"]
            testing_ts = datetime(cert_date.year, cert_date.month, cert_date.day,
                                  9, 0, 0, tzinfo=timezone.utc)
            test_date_jp = f"{cert_date.year}年{cert_date.month}月{cert_date.day}日"

            run_id = uuid.uuid4()
            session.execute(
                sa.text("""
                    INSERT INTO calibration_runs
                        (id, batch_name, status, testing_start, testing_end,
                         certificate_date, threshold_c, setpoints,
                         start_cert_no, cert_width,
                         test_date_jp, doc_date_jp, created_at, completed_at)
                    VALUES
                        (:id, :batch_name, 'done', :ts, :ts,
                         :cert_date, 0.5, '[]'::jsonb,
                         :start_cert_no, 10,
                         :test_date_jp, :test_date_jp, :ts, :ts)
                    ON CONFLICT DO NOTHING
                """),
                {
                    "id": str(run_id),
                    "batch_name": batch["batch_name"],
                    "ts": testing_ts,
                    "cert_date": cert_date,
                    "start_cert_no": certs[0][0],
                    "test_date_jp": test_date_jp,
                },
            )

            inserted_loggers = 0
            inserted_results = 0

            for cert_no, serial_no, file_path in certs:
                # Upsert logger by serial_no
                logger_id = uuid.uuid4()
                result = session.execute(
                    sa.text("""
                        INSERT INTO loggers (id, serial_no, created_at)
                        VALUES (:id, :serial_no, NOW())
                        ON CONFLICT (serial_no) DO NOTHING
                        RETURNING id
                    """),
                    {"id": str(logger_id), "serial_no": serial_no},
                )
                row = result.fetchone()
                if row:
                    inserted_loggers += 1
                else:
                    # logger already exists — fetch its id
                    row = session.execute(
                        sa.text("SELECT id FROM loggers WHERE serial_no = :sn"),
                        {"sn": serial_no},
                    ).fetchone()
                    logger_id = uuid.UUID(str(row[0]))

                # Insert logger result
                session.execute(
                    sa.text("""
                        INSERT INTO logger_results
                            (id, run_id, logger_id, sheet_name, verdict,
                             cert_no, cert_path, created_at)
                        VALUES
                            (:id, :run_id, :logger_id, :sheet_name, 'pass',
                             :cert_no, :cert_path, NOW())
                        ON CONFLICT DO NOTHING
                    """),
                    {
                        "id": str(uuid.uuid4()),
                        "run_id": str(run_id),
                        "logger_id": str(logger_id),
                        "sheet_name": serial_no,
                        "cert_no": cert_no,
                        "cert_path": file_path,
                    },
                )
                inserted_results += 1

            session.commit()
            print(f"  loggers inserted: {inserted_loggers}")
            print(f"  results inserted: {inserted_results}")

    print("\n[done] ingestion complete.")


if __name__ == "__main__":
    main()
