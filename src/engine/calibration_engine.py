"""
CalibrationEngine — main orchestrator class.

Wraps all engine sub-modules and provides a callback-driven API
so the Flet UI can display real-time processing logs.
"""

from datetime import datetime
from pathlib import Path
from typing import Callable, Optional

import pandas as pd

from .ref_loader import load_ref1, load_ref2, combine_refs
from .cal_loader import load_workbook, load_calibration_sheet
from .matcher import TARGETS, find_values_for_target
from .docx_filler import fill_certificate


class CalibrationEngine:
    """
    High-level orchestrator for calibration certificate generation.

    Usage:
        engine = CalibrationEngine(config)
        engine.load_data(callback=log_fn)
        engine.process(callback=log_fn)
        summary_df = engine.get_summary()
    """

    def __init__(self, config: dict):
        """
        Initialize with configuration dict containing:
            - start_cert_no: int
            - cert_width: int (zero-pad width)
            - test_date_jp: str (e.g. "2026年3月4日")
            - doc_date_jp: str
            - template_path: Path or str
            - calibration_xlsx: Path or str
            - ref1_csv: Path or str
            - ref2_csv: Path or str
            - output_dir: Path or str
            - template_serial: str (placeholder serial in template)
            - template_testdate: str (placeholder test date in template)
            - template_docdate: str (placeholder doc date in template)
            - time_ranges: dict mapping float → (datetime, datetime)
        """
        self.config = config
        self.start_cert_no = config["start_cert_no"]
        self.cert_width = config.get("cert_width", 10)
        self.test_date_jp = config["test_date_jp"]
        self.doc_date_jp = config["doc_date_jp"]
        self.template_path = Path(config["template_path"])
        self.calibration_xlsx = Path(config["calibration_xlsx"])
        self.ref1_csv = Path(config["ref1_csv"])
        self.ref2_csv = Path(config["ref2_csv"])
        self.output_dir = Path(config["output_dir"])
        self.template_serial = config["template_serial"]
        self.template_testdate = config["template_testdate"]
        self.template_docdate = config["template_docdate"]
        self.time_ranges = config["time_ranges"]

        # state populated during load_data / process
        self.ref_all: Optional[pd.DataFrame] = None
        self.wb = None
        self.sheet_names: list = []
        self.summary_rows: list = []
        self.generated_files: list = []

    def _log(self, callback: Optional[Callable], msg: str, level: str = "info"):
        """Emit a log message via callback if provided."""
        if callback:
            callback(msg, level)

    def load_data(self, callback: Optional[Callable] = None):
        """
        Load reference loggers and calibration workbook.
        callback(message: str, level: str) is called for real-time logging.
        """
        self._log(callback, "Loading reference logger 1...", "info")
        ref1_df = load_ref1(self.ref1_csv)
        self._log(
            callback,
            f"  Ref1: {len(ref1_df)} readings "
            f"({ref1_df.timestamp.min()} → {ref1_df.timestamp.max()})",
            "info",
        )

        self._log(callback, "Loading reference logger 2...", "info")
        ref2_df = load_ref2(self.ref2_csv)
        self._log(
            callback,
            f"  Ref2: {len(ref2_df)} readings "
            f"({ref2_df.timestamp.min()} → {ref2_df.timestamp.max()})",
            "info",
        )

        self.ref_all = combine_refs(ref1_df, ref2_df)
        self._log(
            callback, f"  Combined: {len(self.ref_all)} readings", "info"
        )

        self._log(callback, "\nLoading calibration loggers...", "info")
        self.wb, self.sheet_names = load_workbook(self.calibration_xlsx)
        self._log(
            callback,
            f"  Found {len(self.sheet_names)} loggers: "
            f"{self.sheet_names[0]} ... {self.sheet_names[-1]}",
            "info",
        )

    def process(self, callback: Optional[Callable] = None):
        """
        Process all loggers: match values and generate certificates.
        callback(message: str, level: str) is called for each step.
        Returns list of generated filenames.
        """
        if self.ref_all is None or self.wb is None:
            raise RuntimeError("Call load_data() before process()")

        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.summary_rows = []
        self.generated_files = []

        total = len(self.sheet_names)
        self._log(callback, f"\n{'=' * 50}", "info")
        self._log(callback, f"GENERATING {total} CERTIFICATES", "info")
        self._log(callback, f"{'=' * 50}", "info")

        for i, serial in enumerate(self.sheet_names):
            cert_no = str(self.start_cert_no + i).zfill(self.cert_width)

            # Load this logger's data
            cal_df = load_calibration_sheet(self.wb, serial)
            self._log(
                callback,
                f"\n[{i + 1}/{total}] Serial: {serial} | "
                f"Cert: {cert_no} | Readings: {len(cal_df)}",
                "info",
            )

            # Compute values for each temperature target
            values = {}
            for target in TARGETS:
                t_start, t_end = self.time_ranges[target]
                final_ref, cal_val, adjusted = find_values_for_target(
                    cal_df, self.ref_all, target, t_start, t_end
                )
                if cal_val is None:
                    self._log(
                        callback,
                        f"  ⚠ WARNING: No calibration data for {target}°C range!",
                        "warning",
                    )
                    cal_val = final_ref  # fallback

                values[target] = (final_ref, cal_val)
                adj_marker = " [ref adjusted]" if adjusted else ""
                diff = cal_val - final_ref
                level = "warning" if abs(diff) > 0.5 else "success"
                self._log(
                    callback,
                    f"  {target:>6.1f}°C: ref={final_ref:.2f}, "
                    f"cal={cal_val:.2f}, diff={diff:+.2f}{adj_marker}",
                    level,
                )

            # Fill certificate
            outname = f"Calibration_Certificate_{cert_no}_{serial}.docx"
            outpath = self.output_dir / outname

            entries = fill_certificate(
                template_path=self.template_path,
                output_path=outpath,
                cert_no=cert_no,
                serial=serial,
                values=values,
                targets=TARGETS,
                template_serial=self.template_serial,
                test_date_jp=self.test_date_jp,
                doc_date_jp=self.doc_date_jp,
                template_testdate=self.template_testdate,
                template_docdate=self.template_docdate,
            )
            self.summary_rows.extend(entries)
            self.generated_files.append(outname)
            self._log(callback, f"  ✓ Saved: {outname}", "success")

        # Save summary CSV
        summary_df = pd.DataFrame(self.summary_rows)
        csv_path = self.output_dir / "certificates_summary.csv"
        summary_df.to_csv(csv_path, index=False, encoding="utf-8-sig")

        self._log(callback, f"\n{'=' * 50}", "info")
        self._log(
            callback,
            f"DONE! Generated {len(self.generated_files)} certificates.",
            "success",
        )
        self._log(callback, f"Summary CSV: {csv_path}", "info")
        self._log(callback, f"{'=' * 50}", "info")

        return self.generated_files

    def get_summary(self) -> pd.DataFrame:
        """Return the summary DataFrame after processing."""
        return pd.DataFrame(self.summary_rows)
