#!/usr/bin/env python3
"""
One-time migration: copy historical cert files from Mac/OneDrive paths
into the Docker volume (cal_data) and update cert_path in the DB.

Run from the project root:
  python3 scripts/migrate_certs_to_volume.py
"""
import subprocess
import sys
from pathlib import Path

DB_CONTAINER  = "ite-calibration-postgres-1"
API_CONTAINER = "ite-calibration-api-1"
CONTAINER_BASE = "/var/lib/ite-calibration/data"


def psql_query(sql: str) -> str:
    r = subprocess.run(
        ["docker", "exec", DB_CONTAINER,
         "psql", "-U", "ite", "-d", "ite", "-t", "-A", "-F", "\t", "-c", sql],
        capture_output=True, text=True,
    )
    if r.returncode != 0:
        print(f"SQL ERROR: {r.stderr}", file=sys.stderr)
        sys.exit(1)
    return r.stdout.strip()


def psql_exec(sql: str) -> None:
    r = subprocess.run(
        ["docker", "exec", "-i", DB_CONTAINER,
         "psql", "-U", "ite", "-d", "ite"],
        input=sql, capture_output=True, text=True,
    )
    if r.returncode != 0:
        print(f"SQL ERROR: {r.stderr}", file=sys.stderr)
        sys.exit(1)
    print(r.stdout.strip())


def docker_mkdir(path: str) -> None:
    subprocess.run(
        ["docker", "exec", API_CONTAINER, "mkdir", "-p", path],
        check=True,
    )


def docker_cp(src: Path, dst: str) -> None:
    subprocess.run(
        ["docker", "cp", str(src), f"{API_CONTAINER}:{dst}"],
        check=True,
    )


# ── Fetch all results that have cert_path ─────────────────────────────────
rows_raw = psql_query(
    "SELECT lr.id, lr.run_id, lr.cert_path "
    "FROM logger_results lr "
    "WHERE lr.cert_path IS NOT NULL "
    "ORDER BY lr.run_id;"
)

rows = []
for line in rows_raw.splitlines():
    parts = line.split("\t")
    if len(parts) == 3:
        rows.append((parts[0].strip(), parts[1].strip(), parts[2].strip()))

print(f"Found {len(rows)} results with cert_path to migrate\n")

updates: list[tuple[str, str]] = []
copied  = 0
skipped = 0
errors  = 0

prev_run_id = None

for result_id, run_id, cert_path in rows:
    src = Path(cert_path)

    if not src.exists():
        print(f"  SKIP (not on disk): {src.name}", file=sys.stderr)
        skipped += 1
        continue

    # Create destination directory once per run_id
    container_dir = f"{CONTAINER_BASE}/runs/{run_id}/certificates"
    if run_id != prev_run_id:
        docker_mkdir(container_dir)
        prev_run_id = run_id

    container_path = f"{container_dir}/{src.name}"

    try:
        docker_cp(src, container_path)
        updates.append((result_id, container_path))
        copied += 1
        print(f"  [{copied:>3}] {src.name}")
    except subprocess.CalledProcessError as e:
        print(f"  ERROR copying {src.name}: {e}", file=sys.stderr)
        errors += 1

print(f"\n{'─'*60}")
print(f"Copied : {copied}")
print(f"Skipped: {skipped}  (file not on disk)")
print(f"Errors : {errors}")

if not updates:
    print("Nothing to update in the database.")
    sys.exit(0)

# ── Update cert_path in the database ──────────────────────────────────────
print(f"\nUpdating {len(updates)} cert_path records in the database…")

stmts = ["BEGIN;"]
for result_id, new_path in updates:
    escaped = new_path.replace("'", "''")
    stmts.append(
        f"UPDATE logger_results SET cert_path = '{escaped}' WHERE id = '{result_id}';"
    )
stmts.append("COMMIT;")

psql_exec("\n".join(stmts))
print(f"\nDone. {len(updates)} records now point to the Docker volume.")
print("The cal_data volume is now the single source of truth for cert files.")
