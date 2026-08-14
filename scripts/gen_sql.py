#!/usr/bin/env python3
"""
Generate SQL INSERT statements for historical calibration data.
Pipe output to: docker exec -i ite-calibration-postgres-1 psql -U ite -d ite
"""
import re
import sys
import uuid
from datetime import date, datetime, timezone
from pathlib import Path

CERT_RE = re.compile(r"Calibration_Certificate_(\d+)_(\d+)\.(docx|pdf)$", re.IGNORECASE)

ONEDRIVE = Path.home() / "Library/CloudStorage/OneDrive-Personal/Ice Battery Intern"
CURRENT  = ONEDRIVE / "Current Work/Calibration"

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
    {
        "batch_name": "April 15th 2026 — ITE Calibration",
        "cert_date": date(2026, 4, 15),
        "dirs": [CURRENT / "April 15th"],
    },
]


def q(s: str) -> str:
    return "'" + s.replace("'", "''") + "'"


def scan(dirs):
    rows = []
    for d in dirs:
        if not d.exists():
            print(f"-- WARN: dir not found: {d}", file=sys.stderr)
            continue
        for f in sorted(d.iterdir()):
            m = CERT_RE.match(f.name)
            if m:
                rows.append((m.group(1), m.group(2), str(f)))
    return rows


print("BEGIN;")

all_serial = {}  # serial_no -> logger_uuid (to dedup across batches)

for batch in BATCHES:
    certs = scan(batch["dirs"])
    if not certs:
        print(f"-- no certs in: {batch['batch_name']}", file=sys.stderr)
        continue

    cd = batch["cert_date"]
    ts = f"{cd.isoformat()} 09:00:00+00"
    test_jp = f"{cd.year}年{cd.month}月{cd.day}日"
    run_id = str(uuid.uuid4())
    start_cert = certs[0][0]

    print(f"\n-- === {batch['batch_name']} ({len(certs)} certs) ===")
    print(
        f"INSERT INTO calibration_runs "
        f"(id, batch_name, status, testing_start, testing_end, certificate_date, "
        f"threshold_c, setpoints, start_cert_no, cert_width, test_date_jp, doc_date_jp, "
        f"created_at, completed_at) VALUES ("
        f"{q(run_id)}, {q(batch['batch_name'])}, 'complete', "
        f"{q(ts)}, {q(ts)}, {q(cd.isoformat())}, "
        f"0.5, '[]'::jsonb, {q(start_cert)}, 10, {q(test_jp)}, {q(test_jp)}, "
        f"{q(ts)}, {q(ts)}) ON CONFLICT DO NOTHING;"
    )

    for cert_no, serial_no, file_path in certs:
        if serial_no not in all_serial:
            lg_id = str(uuid.uuid4())
            all_serial[serial_no] = lg_id
            print(
                f"INSERT INTO loggers (id, serial_no, created_at) VALUES "
                f"({q(lg_id)}, {q(serial_no)}, {q(ts)}) ON CONFLICT (serial_no) DO NOTHING;"
            )

        lg_id_ref = all_serial[serial_no]
        res_id = str(uuid.uuid4())
        print(
            f"INSERT INTO logger_results "
            f"(id, run_id, logger_id, sheet_name, verdict, per_setpoint, cert_no, cert_path, created_at) "
            f"SELECT {q(res_id)}, {q(run_id)}, id, {q(serial_no)}, 'pass', "
            f"'[]'::jsonb, {q(cert_no)}, {q(file_path)}, {q(ts)} "
            f"FROM loggers WHERE serial_no = {q(serial_no)} ON CONFLICT DO NOTHING;"
        )

print("\nCOMMIT;")
