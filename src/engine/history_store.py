"""
HistoryStore — SQLite persistence for generation sessions.

Stores every generation session, certificate, temperature measurement,
and log line. Database is at ~/.calibration_pro/history.db (WAL mode).
No external dependencies — uses sqlite3 (built-in).
"""

import json
import sqlite3
from datetime import datetime
from pathlib import Path
from typing import List, Optional

import pandas as pd


class HistoryStore:
    """Persistent storage for calibration certificate generation history."""

    DB_PATH = Path.home() / ".calibration_pro" / "history.db"

    def __init__(self):
        self.DB_PATH.parent.mkdir(parents=True, exist_ok=True)
        self._conn = sqlite3.connect(str(self.DB_PATH))
        self._conn.row_factory = sqlite3.Row
        self._conn.execute("PRAGMA journal_mode=WAL")
        self._conn.execute("PRAGMA foreign_keys=ON")
        self._create_tables()

    def _create_tables(self):
        self._conn.executescript("""
            CREATE TABLE IF NOT EXISTS sessions (
                id            INTEGER PRIMARY KEY AUTOINCREMENT,
                created_at    TEXT NOT NULL,
                completed_at  TEXT,
                cert_count    INTEGER DEFAULT 0,
                warning_count INTEGER DEFAULT 0,
                elapsed_sec   REAL DEFAULT 0,
                output_dir    TEXT,
                status        TEXT DEFAULT 'completed',
                config_json   TEXT
            );

            CREATE TABLE IF NOT EXISTS certificates (
                id         INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
                cert_no    TEXT,
                serial     TEXT,
                filename   TEXT
            );

            CREATE TABLE IF NOT EXISTS temperature_records (
                id               INTEGER PRIMARY KEY AUTOINCREMENT,
                certificate_id   INTEGER NOT NULL REFERENCES certificates(id) ON DELETE CASCADE,
                target_c         REAL,
                reference_c      REAL,
                actual_c         REAL,
                difference_c     REAL,
                within_tolerance INTEGER
            );

            CREATE TABLE IF NOT EXISTS log_entries (
                id         INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
                timestamp  TEXT,
                level      TEXT,
                message    TEXT
            );
        """)
        self._conn.commit()

    def save_session(
        self,
        config: dict,
        summary_df: pd.DataFrame,
        log_entries: list,
        elapsed: float,
        output_dir: str,
        generated_files: list,
    ) -> int:
        """
        Save a complete generation session to the database.

        Args:
            config: The configuration dict used for generation
            summary_df: DataFrame from engine.get_summary()
            log_entries: List of LogEntry objects from ProcessingLog
            elapsed: Total processing time in seconds
            output_dir: Output directory path
            generated_files: List of generated filenames

        Returns:
            The new session_id
        """
        cur = self._conn.cursor()

        # Count warnings from summary
        warning_count = 0
        if not summary_df.empty and "Difference (°C)" in summary_df.columns:
            warning_count = int(
                (summary_df["Difference (°C)"].abs() > 0.5).sum()
            )

        # Serialize config (remove non-serializable items)
        safe_config = {}
        for k, v in config.items():
            if k == "time_ranges":
                safe_config[k] = {
                    str(target): [s.isoformat(), e.isoformat()]
                    for target, (s, e) in v.items()
                }
            else:
                safe_config[k] = str(v) if not isinstance(v, (str, int, float, bool, type(None))) else v

        now = datetime.now().isoformat()
        cur.execute(
            """INSERT INTO sessions
               (created_at, completed_at, cert_count, warning_count,
                elapsed_sec, output_dir, status, config_json)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                now, now,
                len(generated_files),
                warning_count,
                round(elapsed, 2),
                str(output_dir),
                "completed",
                json.dumps(safe_config, ensure_ascii=False),
            ),
        )
        session_id = cur.lastrowid

        # Group summary rows by certificate
        if not summary_df.empty:
            for cert_no, group in summary_df.groupby("Certificate No"):
                serial = group.iloc[0].get("Serial", "")
                # Find matching filename
                filename = ""
                for fn in generated_files:
                    if str(cert_no) in fn and str(serial) in fn:
                        filename = fn
                        break

                cur.execute(
                    "INSERT INTO certificates (session_id, cert_no, serial, filename) VALUES (?, ?, ?, ?)",
                    (session_id, str(cert_no), str(serial), filename),
                )
                cert_id = cur.lastrowid

                for _, row in group.iterrows():
                    cur.execute(
                        """INSERT INTO temperature_records
                           (certificate_id, target_c, reference_c, actual_c,
                            difference_c, within_tolerance)
                           VALUES (?, ?, ?, ?, ?, ?)""",
                        (
                            cert_id,
                            float(row.get("Target (°C)", 0)),
                            float(row.get("Reference (°C)", 0)),
                            float(row.get("Actual (°C)", 0)),
                            float(row.get("Difference (°C)", 0)),
                            1 if row.get("Within ±0.5") == "Yes" else 0,
                        ),
                    )

        # Save log entries
        for entry in log_entries:
            ts = getattr(entry, "_timestamp", "")
            level = getattr(entry, "_level", "info")
            message = getattr(entry, "_message", str(entry))
            cur.execute(
                "INSERT INTO log_entries (session_id, timestamp, level, message) VALUES (?, ?, ?, ?)",
                (session_id, ts, level, message),
            )

        self._conn.commit()
        return session_id

    def list_sessions(self, limit: int = 100) -> list:
        """
        Returns list of session dicts, newest first.

        Each dict has: id, created_at, cert_count, warning_count,
                       elapsed_sec, output_dir, status
        """
        rows = self._conn.execute(
            """SELECT id, created_at, cert_count, warning_count,
                      elapsed_sec, output_dir, status
               FROM sessions
               ORDER BY created_at DESC
               LIMIT ?""",
            (limit,),
        ).fetchall()
        return [dict(r) for r in rows]

    def get_certificates(self, session_id: int) -> list:
        """
        Returns certificates for a session, with nested temperature records.

        Each dict: {id, cert_no, serial, filename, records: [{target_c, reference_c, ...}]}
        """
        certs = self._conn.execute(
            "SELECT id, cert_no, serial, filename FROM certificates WHERE session_id = ?",
            (session_id,),
        ).fetchall()

        result = []
        for c in certs:
            cert = dict(c)
            records = self._conn.execute(
                """SELECT target_c, reference_c, actual_c, difference_c, within_tolerance
                   FROM temperature_records WHERE certificate_id = ?
                   ORDER BY target_c""",
                (cert["id"],),
            ).fetchall()
            cert["records"] = [dict(r) for r in records]
            result.append(cert)

        return result

    def get_analytics(self) -> dict:
        """
        Returns aggregated analytics data.

        Returns dict with:
            total_sessions, total_certs, warning_rate_pct, avg_abs_diff,
            per_session_stats (last 20), per_target_stats (all 3 targets)
        """
        # Basic counts
        total_sessions = self._conn.execute(
            "SELECT COUNT(*) FROM sessions"
        ).fetchone()[0]

        total_certs = self._conn.execute(
            "SELECT COUNT(*) FROM certificates"
        ).fetchone()[0]

        # Warning rate
        total_records = self._conn.execute(
            "SELECT COUNT(*) FROM temperature_records"
        ).fetchone()[0]
        warnings = self._conn.execute(
            "SELECT COUNT(*) FROM temperature_records WHERE within_tolerance = 0"
        ).fetchone()[0]
        warning_rate = round(warnings / total_records * 100, 1) if total_records > 0 else 0.0

        # Average absolute difference
        avg_row = self._conn.execute(
            "SELECT AVG(ABS(difference_c)) FROM temperature_records"
        ).fetchone()
        avg_abs_diff = round(avg_row[0], 4) if avg_row[0] is not None else 0.0

        # Per-session stats (last 20)
        per_session = self._conn.execute(
            """SELECT s.id, s.created_at, s.cert_count, s.warning_count,
                      s.elapsed_sec,
                      COALESCE(AVG(ABS(tr.difference_c)), 0) as avg_diff
               FROM sessions s
               LEFT JOIN certificates c ON c.session_id = s.id
               LEFT JOIN temperature_records tr ON tr.certificate_id = c.id
               GROUP BY s.id
               ORDER BY s.created_at DESC
               LIMIT 20""",
        ).fetchall()

        # Per-target stats
        per_target = self._conn.execute(
            """SELECT target_c,
                      AVG(reference_c) as avg_ref,
                      AVG(actual_c) as avg_actual,
                      AVG(ABS(difference_c)) as avg_abs_diff,
                      ROUND(SUM(within_tolerance) * 100.0 / COUNT(*), 1) as pct_within
               FROM temperature_records
               GROUP BY target_c
               ORDER BY target_c""",
        ).fetchall()

        return {
            "total_sessions": total_sessions,
            "total_certs": total_certs,
            "warning_rate_pct": warning_rate,
            "avg_abs_diff": avg_abs_diff,
            "per_session_stats": [dict(r) for r in per_session],
            "per_target_stats": [dict(r) for r in per_target],
        }

    def get_last_session_files(self) -> dict | None:
        """
        Returns file paths from the most recent completed session's config_json,
        or None if no history or any file no longer exists on disk.

        Returns dict with keys: ref_paths (list[str]), calibration_path (str), template_path (str)
        """
        import ast

        row = self._conn.execute(
            "SELECT config_json FROM sessions WHERE status='completed' "
            "ORDER BY created_at DESC LIMIT 1"
        ).fetchone()
        if not row:
            return None

        cfg = json.loads(row[0])

        # ref_csvs was serialized as str(list) in save_session, so use ast.literal_eval
        raw_refs = cfg.get("ref_csvs", "[]")
        try:
            if isinstance(raw_refs, list):
                ref_paths = raw_refs
            else:
                ref_paths = ast.literal_eval(raw_refs)
            ref_paths = [p for p in ref_paths if Path(p).exists()]
        except (ValueError, SyntaxError):
            ref_paths = []

        cal_path = cfg.get("calibration_xlsx", "")
        tmpl_path = cfg.get("template_path", "")

        if (
            not ref_paths
            or not cal_path
            or not Path(cal_path).exists()
            or not tmpl_path
            or not Path(tmpl_path).exists()
        ):
            return None

        return {
            "ref_paths": ref_paths,
            "calibration_path": cal_path,
            "template_path": tmpl_path,
        }

    def delete_session(self, session_id: int):
        """Delete a session and all its children (CASCADE)."""
        self._conn.execute("DELETE FROM sessions WHERE id = ?", (session_id,))
        self._conn.commit()

    def close(self):
        """Close the database connection."""
        self._conn.close()
