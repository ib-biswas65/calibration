"""
DashboardView — main workspace with:
- Dynamic N reference file zones + fixed calibration/template zones
- Configuration: cert number, cert width, dates, template placeholders
- Time ranges: configurable per temperature target (-40, 5, 40 °C)
- Output directory: configurable (defaults to sibling of calibration XLSX)
- Real-time animated processing log
- Generate button with CrossFade → progress animation
- Staggered entrance animations + shake on validation errors
"""

import asyncio
import logging
import platform
import subprocess
import time
import threading
from datetime import datetime
from pathlib import Path

import flet as ft
import openpyxl

from ..theme import (
    BG_PRIMARY, BG_SECONDARY, BG_CARD, BG_GLASS_STRONG,
    ACCENT_PRIMARY, ACCENT_SECONDARY, ACCENT_TERTIARY, ACCENT_DANGER,
    TEXT_PRIMARY, TEXT_SECONDARY, TEXT_MUTED,
    BORDER_DEFAULT,
    RADIUS_SM, RADIUS_MD, RADIUS_LG, RADIUS_XL,
    SPACING_XS, SPACING_SM, SPACING_MD, SPACING_LG, SPACING_XL,
    DURATION_NORMAL, DURATION_SLOW,
    CURVE_DEFAULT, CURVE_BOUNCE, STAGGER_DELAY,
    SHADOW_CARD,
    WINDOW_TITLE,
)
from ..components.file_drop_zone import FileDropZone
from ..components.processing_log import ProcessingLog
from ..components.bulk_assign_panel import BulkAssignPanel, auto_assign
from ..engine import CalibrationEngine, HistoryStore

logger = logging.getLogger(__name__)


# ── Default time ranges (pre-filled; user edits per session) ──────────────
_DEFAULT_TIME_RANGES = {
    -40.0: ("2026/03/04 17:41", "2026/03/05 13:00"),
    5.0:   ("2026/03/04 14:50", "2026/03/04 16:45"),
    40.0:  ("2026/03/04 16:46", "2026/03/04 17:40"),
}
_DATETIME_FMT = "%Y/%m/%d %H:%M"

# Ordered for display (chronological within a typical session)
_TARGET_DISPLAY_ORDER = [5.0, 40.0, -40.0]
_TARGET_LABELS   = {5.0: "  5 °C", 40.0: " 40 °C", -40.0: "-40 °C"}
_TARGET_COLORS   = {5.0: ACCENT_SECONDARY, 40.0: ACCENT_TERTIARY, -40.0: ACCENT_PRIMARY}


# ── Helpers ──────────────────────────────────────────────────────────────────

def _section(text: str) -> ft.Text:
    return ft.Text(text, size=14, color=TEXT_PRIMARY, weight=ft.FontWeight.W_600)


def _subsection(text: str) -> ft.Text:
    return ft.Text(text, size=12, color=TEXT_SECONDARY, weight=ft.FontWeight.W_500)


def _field(label: str, value: str, width: int = 200, hint: str = "") -> ft.TextField:
    return ft.TextField(
        label=label,
        value=value,
        hint_text=hint or None,
        width=width,
        height=50,
        text_size=13,
        label_style=ft.TextStyle(size=12, color=TEXT_SECONDARY),
        border_color=BORDER_DEFAULT,
        focused_border_color=ACCENT_PRIMARY,
        color=TEXT_PRIMARY,
        cursor_color=ACCENT_PRIMARY,
        bgcolor=BG_CARD,
        border_radius=RADIUS_SM,
    )


def _divider() -> ft.Divider:
    return ft.Divider(height=1, color=BORDER_DEFAULT)


# ── View ─────────────────────────────────────────────────────────────────────

class DashboardView(ft.Container):
    """Main dashboard — file inputs, config panel, processing log."""

    def __init__(self, page: ft.Page, on_generation_complete=None, **kwargs):
        super().__init__(**kwargs)
        self._page = page
        self._on_generation_complete = on_generation_complete

        # ── State ────────────────────────────────────────────────────────────
        self._ref_zones: list[dict] = []   # {key, zone, path}
        self._ref_counter = 0

        self._calibration_path: str | None = None
        self._template_path: str | None = None
        self._output_dir: str | None = None
        self._sheet_count: int = 0

        self._is_processing = False

        # ── File pickers (registered in did_mount via page.overlay) ──────────
        self._file_picker = ft.FilePicker()
        self._dir_picker  = ft.FilePicker()
        self._bulk_picker = ft.FilePicker()   # multi-select for bulk upload

        # Bulk panel state
        self._bulk_panel: BulkAssignPanel | None = None
        self._last_session_data: dict | None = None

        self._zone_exts = {"ref": ["csv"], "calibration": ["xlsx"], "template": ["docx"]}

        # ── Header ───────────────────────────────────────────────────────────
        self._header = ft.Container(
            content=ft.Row(
                [
                    ft.Icon(ft.Icons.SCIENCE_ROUNDED, size=24, color=ACCENT_PRIMARY),
                    ft.Text(WINDOW_TITLE, size=18, color=TEXT_PRIMARY,
                            weight=ft.FontWeight.W_700),
                    ft.Container(expand=True),
                    ft.Text("Dashboard", size=12, color=TEXT_MUTED,
                            weight=ft.FontWeight.W_500),
                ],
                vertical_alignment=ft.CrossAxisAlignment.CENTER,
            ),
            padding=ft.Padding.symmetric(horizontal=SPACING_LG, vertical=SPACING_MD),
            animate_opacity=ft.Animation(DURATION_SLOW, CURVE_DEFAULT),
            opacity=0,
        )

        # ── Dynamic Reference zones row ───────────────────────────────────────
        self._ref_zones_row = ft.Row(
            controls=[], spacing=SPACING_MD, wrap=True,
            alignment=ft.MainAxisAlignment.START,
        )
        self._add_ref_btn = ft.TextButton(
            content=ft.Row(
                [
                    ft.Icon(ft.Icons.ADD_CIRCLE_OUTLINE_ROUNDED, size=16, color=ACCENT_PRIMARY),
                    ft.Text("Add Reference File", size=12, color=ACCENT_PRIMARY,
                            weight=ft.FontWeight.W_500),
                ],
                spacing=6, tight=True,
            ),
            on_click=self._on_add_ref_clicked,
            style=ft.ButtonStyle(
                padding=ft.Padding.symmetric(horizontal=SPACING_MD, vertical=SPACING_SM),
                overlay_color={ft.ControlState.HOVERED: f"{ACCENT_PRIMARY}18"},
            ),
        )

        # Fixed zones: calibration XLSX + certificate template
        self._drop_calib = FileDropZone(
            label="Calibration Data (XLSX)", zone_key="calibration",
            icon=ft.Icons.TABLE_CHART_ROUNDED, on_browse=self._browse_for_zone,
        )
        self._drop_template = FileDropZone(
            label="Certificate Template (.docx)", zone_key="template",
            icon=ft.Icons.DESCRIPTION_ROUNDED, on_browse=self._browse_for_zone,
        )

        # ── Bulk upload button ────────────────────────────────────────────────
        self._bulk_btn_text = ft.Text(
            "Bulk Upload All Files", size=12, color=ACCENT_PRIMARY,
            weight=ft.FontWeight.W_500,
        )
        self._bulk_btn = ft.TextButton(
            content=ft.Row(
                [
                    ft.Icon(ft.Icons.UPLOAD_FILE_ROUNDED, size=16, color=ACCENT_PRIMARY),
                    self._bulk_btn_text,
                ],
                spacing=6, tight=True,
            ),
            on_click=lambda e: self._page.run_task(self._async_bulk_pick),
            tooltip="Select all files at once and assign roles  (⌘U)",
            style=ft.ButtonStyle(
                padding=ft.Padding.symmetric(horizontal=SPACING_MD, vertical=SPACING_SM),
                side={ft.ControlState.DEFAULT: ft.BorderSide(1, ACCENT_PRIMARY)},
                shape=ft.RoundedRectangleBorder(radius=RADIUS_SM),
                overlay_color={ft.ControlState.HOVERED: f"{ACCENT_PRIMARY}18"},
            ),
        )

        # ── "Load Last Session" chip ──────────────────────────────────────────
        self._last_session_chip = ft.Container(
            content=ft.Row(
                [
                    ft.Icon(ft.Icons.HISTORY_ROUNDED, size=14, color=ACCENT_PRIMARY),
                    ft.Text(
                        "Load files from last session",
                        size=12, color=ACCENT_PRIMARY, weight=ft.FontWeight.W_500,
                    ),
                    ft.Container(
                        content=ft.Icon(ft.Icons.CLOSE_ROUNDED, size=12, color=TEXT_MUTED),
                        width=20, height=20, border_radius=10,
                        bgcolor="transparent",
                        alignment=ft.Alignment(0, 0),
                        on_click=self._dismiss_last_session_chip,
                        tooltip="Dismiss",
                    ),
                ],
                spacing=SPACING_XS,
                vertical_alignment=ft.CrossAxisAlignment.CENTER,
                tight=True,
            ),
            bgcolor=f"{ACCENT_PRIMARY}18",
            border_radius=RADIUS_LG,
            border=ft.Border.all(1, f"{ACCENT_PRIMARY}40"),
            padding=ft.Padding.symmetric(horizontal=SPACING_MD, vertical=SPACING_SM),
            on_click=self._on_load_last_session,
            visible=False,   # shown only when history files exist on disk
            animate_opacity=ft.Animation(DURATION_NORMAL, CURVE_DEFAULT),
            opacity=0,
        )

        self._files_section = ft.Container(
            content=ft.Column(
                [
                    _section("Input Files"),
                    ft.Container(height=4),
                    self._last_session_chip,
                    _subsection("Reference Logger(s)"),
                    ft.Container(height=6),
                    self._ref_zones_row,
                    ft.Row(
                        [self._add_ref_btn, self._bulk_btn],
                        spacing=SPACING_SM,
                    ),
                    ft.Container(height=SPACING_SM),
                    _divider(),
                    ft.Container(height=SPACING_SM),
                    _subsection("Calibration Data & Template"),
                    ft.Container(height=6),
                    ft.Row(
                        [self._drop_calib, self._drop_template],
                        spacing=SPACING_MD, wrap=True,
                    ),
                ],
            ),
        )

        # ── Output directory ──────────────────────────────────────────────────
        self._output_path_label = ft.Text(
            "Auto — same folder as Calibration XLSX / output",
            size=11, color=TEXT_MUTED, italic=True, expand=True,
        )
        self._output_dir_row = ft.Row(
            [
                ft.Icon(ft.Icons.FOLDER_OPEN_ROUNDED, size=15, color=TEXT_SECONDARY),
                ft.Text("Output:", size=12, color=TEXT_SECONDARY,
                        weight=ft.FontWeight.W_500),
                self._output_path_label,
                ft.TextButton(
                    "Browse",
                    on_click=lambda e: self._page.run_task(self._browse_output_dir),
                    style=ft.ButtonStyle(
                        color=ACCENT_PRIMARY,
                        padding=ft.Padding.symmetric(horizontal=SPACING_SM, vertical=4),
                        overlay_color={ft.ControlState.HOVERED: f"{ACCENT_PRIMARY}18"},
                    ),
                ),
            ],
            spacing=SPACING_SM,
            vertical_alignment=ft.CrossAxisAlignment.CENTER,
        )

        # ── Certificate config ────────────────────────────────────────────────
        self._cert_no_input    = _field("Start Certificate No", "1700", width=180)
        self._cert_width_input = _field("Cert Width (zero-pad)", "10", width=150)
        self._tmpl_cert_no_input = _field(
            "Template Cert No (in .docx)", "0000001644", width=230,
            hint="Cert number currently in your template",
        )
        self._cert_preview = ft.Text(
            "", size=11, color=ACCENT_SECONDARY, italic=True,
        )
        self._cert_no_input.on_change    = self._refresh_cert_preview
        self._cert_width_input.on_change = self._refresh_cert_preview

        # ── Date fields ───────────────────────────────────────────────────────
        self._test_date_input = _field("Test Date (Japanese)", "2026年3月4日", width=200)
        self._doc_date_input  = _field("Document Date (Japanese)", "2026年3月6日", width=200)

        # ── Template placeholder fields ───────────────────────────────────────
        self._tmpl_serial_input   = _field("Template Serial", "190124110002449", width=210)
        self._tmpl_testdate_input = _field("Template Test Date", "2025年11月07日", width=210)
        self._tmpl_docdate_input  = _field("Template Doc Date", "2025年11月13日", width=210)

        # ── Time range fields (one row per target) ────────────────────────────
        self._time_range_fields: dict[float, dict[str, ft.TextField]] = {}
        time_range_rows: list[ft.Row] = []

        for target in _TARGET_DISPLAY_ORDER:
            s_field = _field("Start", _DEFAULT_TIME_RANGES[target][0],
                              width=180, hint=_DATETIME_FMT)
            e_field = _field("End",   _DEFAULT_TIME_RANGES[target][1],
                              width=180, hint=_DATETIME_FMT)
            self._time_range_fields[target] = {"start": s_field, "end": e_field}

            time_range_rows.append(
                ft.Row(
                    [
                        ft.Container(
                            content=ft.Text(
                                _TARGET_LABELS[target], size=13,
                                color=_TARGET_COLORS[target],
                                weight=ft.FontWeight.W_600,
                            ),
                            width=62,
                        ),
                        s_field,
                        ft.Icon(ft.Icons.ARROW_FORWARD_ROUNDED, size=14, color=TEXT_MUTED),
                        e_field,
                    ],
                    spacing=SPACING_SM,
                    vertical_alignment=ft.CrossAxisAlignment.CENTER,
                )
            )

        # ── Config section ────────────────────────────────────────────────────
        self._config_section = ft.Container(
            content=ft.Column(
                [
                    _section("Configuration"),
                    ft.Container(height=4),

                    _subsection("Certificate Numbers"),
                    ft.Container(height=6),
                    ft.Row(
                        [self._cert_no_input, self._cert_width_input,
                         self._tmpl_cert_no_input],
                        spacing=SPACING_MD, wrap=True,
                    ),
                    self._cert_preview,
                    ft.Container(height=SPACING_SM),

                    _divider(),
                    ft.Container(height=SPACING_SM),
                    _subsection("Session Dates"),
                    ft.Container(height=6),
                    ft.Row([self._test_date_input, self._doc_date_input],
                           spacing=SPACING_MD, wrap=True),
                    ft.Container(height=SPACING_SM),

                    _divider(),
                    ft.Container(height=SPACING_SM),
                    _subsection("Template Placeholders (values currently in your .docx)"),
                    ft.Container(height=6),
                    ft.Row(
                        [self._tmpl_serial_input, self._tmpl_testdate_input,
                         self._tmpl_docdate_input],
                        spacing=SPACING_MD, wrap=True,
                    ),
                    ft.Container(height=SPACING_SM),

                    _divider(),
                    ft.Container(height=SPACING_SM),
                    _subsection("Temperature Capture Time Ranges  (YYYY/MM/DD HH:MM)"),
                    ft.Container(height=6),
                    *time_range_rows,
                    ft.Container(height=SPACING_SM),

                    _divider(),
                    ft.Container(height=SPACING_SM),
                    self._output_dir_row,
                ],
            ),
        )

        # ── Generate button ───────────────────────────────────────────────────
        self._gen_text    = ft.Text("Generate Certificates", size=14,
                                    color="#FFFFFF", weight=ft.FontWeight.W_600)
        self._gen_spinner = ft.ProgressRing(
            width=18, height=18, stroke_width=2.5, color="#FFFFFF", visible=False,
        )
        self._generate_btn = ft.Container(
            content=ft.Row(
                [
                    ft.Icon(ft.Icons.PLAY_CIRCLE_ROUNDED, color="#FFFFFF", size=22),
                    self._gen_text,
                    self._gen_spinner,
                ],
                alignment=ft.MainAxisAlignment.CENTER,
                spacing=SPACING_SM,
            ),
            width=280,
            height=52,
            border_radius=RADIUS_LG,
            gradient=ft.LinearGradient(
                colors=[ACCENT_PRIMARY, "#3A88E8"],
                begin=ft.Alignment(-1, 0),
                end=ft.Alignment(1, 0),
            ),
            alignment=ft.Alignment(0, 0),
            on_click=self._handle_generate,
            on_hover=self._on_gen_hover,
            animate=ft.Animation(DURATION_NORMAL, CURVE_DEFAULT),
            animate_scale=ft.Animation(DURATION_NORMAL, CURVE_DEFAULT),
            animate_opacity=ft.Animation(DURATION_SLOW, CURVE_DEFAULT),
            scale=1.0,
            shadow=SHADOW_CARD,
            opacity=0,
            tooltip="Generate Certificates (⌘G)",
        )

        # ── Progress bar ───────────────────────────────────────────────────────
        self._progress_bar = ft.ProgressBar(
            value=0,
            color=ACCENT_PRIMARY,
            bgcolor="#30363D40",
            border_radius=RADIUS_SM,
        )
        self._progress_text = ft.Text(
            "", size=12, color=TEXT_SECONDARY,
            text_align=ft.TextAlign.CENTER,
        )
        self._progress_section = ft.Container(
            content=ft.Column(
                [self._progress_bar, self._progress_text],
                spacing=SPACING_XS,
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            ),
            padding=ft.Padding.symmetric(horizontal=SPACING_XL),
            visible=False,
        )

        # ── Processing log ────────────────────────────────────────────────────
        self._log = ProcessingLog()
        self._log_section = ft.Container(
            content=self._log, height=260,
            animate_opacity=ft.Animation(DURATION_SLOW, CURVE_DEFAULT),
            opacity=0,
        )

        # ── Snackbar ──────────────────────────────────────────────────────────
        self._snackbar = ft.SnackBar(
            content=ft.Text("", color="#FFFFFF"),
            bgcolor=ACCENT_DANGER,
            duration=4000,
        )

        # ── Main layout ───────────────────────────────────────────────────────
        # Wrap sections in glassmorphic cards for industry-grade look
        files_card = ft.Container(
            content=self._files_section,
            bgcolor=BG_GLASS_STRONG,
            border_radius=RADIUS_LG,
            border=ft.Border.all(1, "#30363D40"),
            padding=ft.Padding.all(SPACING_MD),
            shadow=SHADOW_CARD,
            animate_opacity=ft.Animation(DURATION_SLOW, CURVE_DEFAULT),
            opacity=0,
        )
        config_card = ft.Container(
            content=self._config_section,
            bgcolor=BG_GLASS_STRONG,
            border_radius=RADIUS_LG,
            border=ft.Border.all(1, "#30363D40"),
            padding=ft.Padding.all(SPACING_MD),
            shadow=SHADOW_CARD,
            animate_opacity=ft.Animation(DURATION_SLOW, CURVE_DEFAULT),
            opacity=0,
        )
        self._files_card = files_card
        self._config_card = config_card

        self.content = ft.Container(
            content=ft.Column(
                [
                    self._header,
                    ft.Container(
                        content=ft.Column(
                            [
                                files_card,
                                config_card,
                                ft.Container(height=SPACING_SM),
                                ft.Row([self._generate_btn],
                                       alignment=ft.MainAxisAlignment.CENTER),
                                self._progress_section,
                                ft.Container(height=SPACING_MD),
                                self._log_section,
                            ],
                            spacing=SPACING_MD,
                            scroll=ft.ScrollMode.AUTO,
                            expand=True,
                        ),
                        padding=ft.Padding.symmetric(
                            horizontal=SPACING_XL, vertical=SPACING_MD,
                        ),
                        expand=True,
                    ),
                ],
                spacing=0,
                expand=True,
            ),
            expand=True,
            bgcolor=BG_PRIMARY,
        )
        self.expand = True

    # ── Lifecycle ─────────────────────────────────────────────────────────────

    def did_mount(self):
        """
        Register overlay controls (snackbar + file pickers) then animate entrance.
        Also restores previous session values and registers keyboard shortcuts.
        """
        self._page.overlay.extend([self._snackbar, self._bulk_picker])
        self._page.update()

        # Add the first (mandatory) reference zone
        self._add_ref_zone()

        # Restore session values
        self._restore_session()

        # Register keyboard shortcuts
        self._page.on_keyboard_event = self._on_keyboard

        # Check last-session files in background (don't block the UI)
        threading.Thread(target=self._check_last_session, daemon=True).start()

        # Staggered entrance animation
        self._page.run_task(self._animate_entrance)

    async def _animate_entrance(self):
        await asyncio.sleep(0.08)
        for el in [self._header, self._files_card, self._config_card,
                   self._generate_btn, self._log_section]:
            el.opacity = 1
            el.update()
            await asyncio.sleep(STAGGER_DELAY / 1000 * 3)

    def _on_keyboard(self, e: ft.KeyboardEvent):
        """Handle keyboard shortcuts:
          ⌘/Ctrl+G → Generate certificates
          ⌘/Ctrl+L → Clear log
          ⌘/Ctrl+U → Bulk upload all files
        """
        if (e.meta or e.ctrl):
            if e.key == "G" or e.key == "g":
                self._handle_generate(None)
            elif e.key == "L" or e.key == "l":
                self._log.clear()
            elif e.key == "U" or e.key == "u":
                self._page.run_task(self._async_bulk_pick)

    # ── Dynamic reference zones ───────────────────────────────────────────────

    def _on_add_ref_clicked(self, e):
        self._add_ref_zone()

    def _add_ref_zone(self):
        """Append a new reference file drop zone."""
        self._ref_counter += 1
        key = f"ref_{self._ref_counter}"

        zone = FileDropZone(
            label=f"Reference Logger {len(self._ref_zones) + 1}",
            zone_key=key,
            icon=ft.Icons.SENSORS_ROUNDED,
            on_browse=self._browse_for_zone,
            on_remove=self._remove_ref_zone,
        )
        self._ref_zones.append({"key": key, "zone": zone, "path": None})
        self._ref_zones_row.controls.append(zone)
        self._sync_remove_buttons()

        if self.page:          # only update if already mounted
            self._ref_zones_row.update()

    def _remove_ref_zone(self, zone_key: str):
        """Remove the reference zone with the given key (minimum 1 zone)."""
        if len(self._ref_zones) <= 1:
            return
        entry = next((z for z in self._ref_zones if z["key"] == zone_key), None)
        if not entry:
            return

        self._ref_zones.remove(entry)
        self._ref_zones_row.controls.remove(entry["zone"])

        # Renumber remaining labels
        for i, z in enumerate(self._ref_zones):
            z["zone"]._label.value = f"Reference Logger {i + 1}"

        self._sync_remove_buttons()
        self._ref_zones_row.update()

    def _sync_remove_buttons(self):
        """Show ✕ on all zones only when there are 2 or more."""
        show = len(self._ref_zones) > 1
        for z in self._ref_zones:
            z["zone"].show_remove_button(show)

    # ── File picking ──────────────────────────────────────────────────────────

    def _browse_for_zone(self, zone_key: str):
        """Delegate file picking to the shared FilePicker."""
        logger.debug("Click on file drop zone: %s", zone_key)
        self._page.run_task(self._async_pick, zone_key)

    async def _async_pick(self, zone_key: str):
        """Open file picker, then route the result to the correct zone."""
        logger.debug("Picking files for zone: %s", zone_key)
        if zone_key.startswith("ref_"):
            exts = self._zone_exts["ref"]
        elif zone_key == "calibration":
            exts = self._zone_exts["calibration"]
        else:
            exts = self._zone_exts["template"]

        try:
            files = await self._file_picker.pick_files(
                allow_multiple=False,
                allowed_extensions=exts,
            )
            logger.debug("FilePicker result: %s", files)
        except Exception as ex:
            logger.exception("FilePicker error for zone %s", zone_key)
            self._log.add_entry(f"File picker error: {ex}", "error")
            return

        # User cancelled or no files selected
        if not files:
            return

        picked = files[0]

        if zone_key.startswith("ref_"):
            entry = next((z for z in self._ref_zones if z["key"] == zone_key), None)
            if entry:
                entry["path"] = picked.path
                entry["zone"].accept_file(picked.path, picked.name)
                self._log.add_entry(f"✓ Reference: {picked.name}", "success")

        elif zone_key == "calibration":
            self._calibration_path = picked.path
            self._drop_calib.accept_file(picked.path, picked.name)
            self._log.add_entry(f"✓ Calibration: {picked.name}", "success")
            # Peek at sheet count → update cert preview
            self._page.run_task(self._peek_xlsx_sheets, picked.path)

        elif zone_key == "template":
            self._template_path = picked.path
            self._drop_template.accept_file(picked.path, picked.name)
            self._log.add_entry(f"✓ Template: {picked.name}", "success")

    async def _peek_xlsx_sheets(self, path: str):
        """Read sheet count from XLSX so the cert preview can be accurate."""
        try:
            wb = openpyxl.load_workbook(path, read_only=True, data_only=True)
            self._sheet_count = len(wb.sheetnames)
            wb.close()
        except Exception:
            self._sheet_count = 0
        self._refresh_cert_preview(None)

    async def _browse_output_dir(self):
        """Open a directory picker for the output folder."""
        try:
            path = await self._dir_picker.get_directory_path(
                dialog_title="Select Output Folder",
            )
        except Exception as ex:
            self._log.add_entry(f"Folder picker error: {ex}", "error")
            return

        if path:
            self._output_dir = path
            self._output_path_label.value = path
            self._output_path_label.italic = False
            self._output_path_label.color = TEXT_SECONDARY
            self._output_path_label.update()
            self._log.add_entry(f"Output folder set: {path}", "info")

    # ── Bulk upload ───────────────────────────────────────────────────────────

    async def _async_bulk_pick(self):
        """Open a multi-select file picker then show the BulkAssignPanel."""
        try:
            files = await self._bulk_picker.pick_files(
                allow_multiple=True,
                allowed_extensions=["csv", "xlsx", "docx"],
                dialog_title="Select all calibration files",
            )
        except Exception as ex:
            logger.exception("Bulk picker error")
            self._log.add_entry(f"Bulk picker error: {ex}", "error")
            return

        if not files:
            return

        assignments = auto_assign(files)
        panel = BulkAssignPanel(
            assignments=assignments,
            on_confirm=self._apply_bulk_assignment,
            on_dismiss=self._dismiss_bulk_panel,
        )
        self._bulk_panel = panel
        self._page.overlay.append(panel)
        self._page.update()

    def _apply_bulk_assignment(
        self, ref_paths: list, calibration_path: str, template_path: str
    ):
        """Apply confirmed bulk assignments to all drop zones."""
        # Clear all existing reference zones
        while self._ref_zones:
            entry = self._ref_zones.pop()
            if entry["zone"] in self._ref_zones_row.controls:
                self._ref_zones_row.controls.remove(entry["zone"])

        # Rebuild reference zones from selected paths
        for path in ref_paths:
            self._ref_counter += 1
            key = f"ref_{self._ref_counter}"
            zone = FileDropZone(
                label=f"Reference Logger {len(self._ref_zones) + 1}",
                zone_key=key,
                icon=ft.Icons.SENSORS_ROUNDED,
                on_browse=self._browse_for_zone,
                on_remove=self._remove_ref_zone,
            )
            zone.accept_file(path, Path(path).name)
            self._ref_zones.append({"key": key, "zone": zone, "path": path})
            self._ref_zones_row.controls.append(zone)

        self._sync_remove_buttons()
        try:
            self._ref_zones_row.update()
        except Exception:
            pass

        # Calibration zone
        self._calibration_path = calibration_path
        self._drop_calib.accept_file(calibration_path, Path(calibration_path).name)
        self._page.run_task(self._peek_xlsx_sheets, calibration_path)

        # Template zone
        self._template_path = template_path
        self._drop_template.accept_file(template_path, Path(template_path).name)

        # Update bulk button label to confirm N files loaded
        total = len(ref_paths) + 2  # refs + calibration + template
        self._bulk_btn_text.value = f"⬆ {total} files loaded ✓"
        self._bulk_btn_text.color = ACCENT_SECONDARY
        try:
            self._bulk_btn_text.update()
        except Exception:
            pass

        self._log.add_entry(
            f"✓ Bulk assigned: {len(ref_paths)} reference + calibration + template",
            "success",
        )
        self._dismiss_bulk_panel()

    def _dismiss_bulk_panel(self):
        """Remove the BulkAssignPanel from the page overlay."""
        try:
            if self._bulk_panel and self._bulk_panel in self._page.overlay:
                self._page.overlay.remove(self._bulk_panel)
            self._bulk_panel = None
            self._page.update()
        except Exception:
            pass

    # ── Load Last Session chip ────────────────────────────────────────────────

    def _check_last_session(self):
        """Background thread — show the chip only if last-session files exist on disk."""
        try:
            store = HistoryStore()
            last = store.get_last_session_files()
            store.close()
            if last:
                self._last_session_data = last
                self._last_session_chip.visible = True
                self._last_session_chip.opacity = 1.0
                try:
                    if self.page:
                        self._last_session_chip.update()
                except Exception:
                    pass
        except Exception:
            logger.debug("Could not check last session files", exc_info=True)

    def _on_load_last_session(self, e):
        """Apply last session's file paths to all drop zones."""
        if not self._last_session_data:
            return
        self._apply_bulk_assignment(
            self._last_session_data["ref_paths"],
            self._last_session_data["calibration_path"],
            self._last_session_data["template_path"],
        )
        self._dismiss_last_session_chip(None)

    def _dismiss_last_session_chip(self, e):
        """Hide the 'Load Last Session' chip."""
        self._last_session_chip.visible = False
        try:
            self._last_session_chip.update()
        except Exception:
            pass

    # ── UI helpers ────────────────────────────────────────────────────────────

    def _refresh_cert_preview(self, e):
        """Update live cert-number preview label."""
        try:
            start = int(self._cert_no_input.value.strip())
            width = int(self._cert_width_input.value.strip())
            if start <= 0 or width <= 0:
                raise ValueError
        except (ValueError, AttributeError):
            self._cert_preview.value = ""
            try:
                self._cert_preview.update()
            except Exception:
                pass
            return

        if self._sheet_count > 0:
            first = str(start).zfill(width)
            last  = str(start + self._sheet_count - 1).zfill(width)
            self._cert_preview.value = (
                f"→ {self._sheet_count} certificates: {first} … {last}"
            )
        else:
            self._cert_preview.value = f"→ First certificate: {str(start).zfill(width)}"

        try:
            self._cert_preview.update()
        except Exception:
            pass

    def _on_gen_hover(self, e: ft.HoverEvent):
        if not self._is_processing:
            self._generate_btn.scale = 1.04 if e.data == "true" else 1.0
            self._generate_btn.update()

    def _snack(self, message: str, is_error: bool = True):
        self._snackbar.bgcolor = ACCENT_DANGER if is_error else ACCENT_SECONDARY
        self._snackbar.content = ft.Text(message, color="#FFFFFF")
        self._snackbar.open = True
        self._page.update()

    # ── Validation ────────────────────────────────────────────────────────────

    def _validate(self) -> bool:
        ok = True
        missing: list[str] = []

        # Reference zones
        for z in self._ref_zones:
            if not z["path"]:
                z["zone"].shake()
                missing.append("reference CSV")
                ok = False

        # Fixed zones
        if not self._calibration_path:
            self._drop_calib.shake()
            missing.append("calibration XLSX")
            ok = False
        if not self._template_path:
            self._drop_template.shake()
            missing.append("certificate template")
            ok = False

        # Certificate number
        try:
            if int(self._cert_no_input.value.strip()) > 0:
                self._cert_no_input.error_text = None
                self._cert_no_input.update()
            else:
                raise ValueError
        except (ValueError, AttributeError):
            self._cert_no_input.error_text = "Must be a positive integer"
            self._cert_no_input.update()
            ok = False

        # Cert width
        try:
            w = int(self._cert_width_input.value.strip())
            if 1 <= w <= 20:
                self._cert_width_input.error_text = None
                self._cert_width_input.update()
            else:
                raise ValueError
        except (ValueError, AttributeError):
            self._cert_width_input.error_text = "1 – 20"
            self._cert_width_input.update()
            ok = False

        # Time ranges
        for target, flds in self._time_range_fields.items():
            for name, fld in [("Start", flds["start"]), ("End", flds["end"])]:
                try:
                    datetime.strptime(fld.value.strip(), _DATETIME_FMT)
                    fld.error_text = None
                    fld.update()
                except (ValueError, AttributeError):
                    fld.error_text = _DATETIME_FMT
                    fld.update()
                    ok = False

        if not ok:
            msg = (f"Missing: {', '.join(missing)}" if missing
                   else "Fix the highlighted fields")
            self._snack(msg)

        return ok

    # ── Processing ────────────────────────────────────────────────────────────

    def _handle_generate(self, e):
        if self._is_processing:
            return
        if not self._validate():
            return

        self._is_processing = True
        self._gen_text.value = "Processing…"
        self._gen_spinner.visible = True
        self._generate_btn.update()
        self._log.clear()

        # Show progress bar
        self._progress_bar.value = 0
        self._progress_text.value = "Preparing..."
        self._progress_section.visible = True
        try:
            self._progress_section.update()
        except Exception:
            pass

        threading.Thread(target=self._run_engine, daemon=True).start()

    def _on_progress(self, current: int, total: int, serial: str):
        """Callback from CalibrationEngine.process() for each certificate."""
        try:
            self._progress_bar.value = current / total if total else 0
            elapsed = time.time() - self._gen_start_time
            if current > 0:
                eta_secs = (elapsed / current) * (total - current)
                eta_str = f" — ETA {int(eta_secs)}s"
            else:
                eta_str = ""
            self._progress_text.value = (
                f"Processing {current + 1} / {total} — {serial}{eta_str}"
            )
            self._progress_bar.update()
            self._progress_text.update()
        except Exception:
            pass

    def _run_engine(self):
        self._gen_start_time = time.time()
        try:
            # Parse time ranges
            time_ranges = {}
            for target, flds in self._time_range_fields.items():
                time_ranges[target] = (
                    datetime.strptime(flds["start"].value.strip(), _DATETIME_FMT),
                    datetime.strptime(flds["end"].value.strip(), _DATETIME_FMT),
                )

            # Output directory (default: sibling of calibration XLSX)
            output_dir = self._output_dir or str(
                Path(self._calibration_path).parent / "output"
            )

            config = {
                "start_cert_no":    int(self._cert_no_input.value.strip()),
                "cert_width":       int(self._cert_width_input.value.strip()),
                "test_date_jp":     self._test_date_input.value.strip(),
                "doc_date_jp":      self._doc_date_input.value.strip(),
                "template_path":    self._template_path,
                "calibration_xlsx": self._calibration_path,
                "ref_csvs":         [z["path"] for z in self._ref_zones if z["path"]],
                "output_dir":       output_dir,
                "template_serial":  self._tmpl_serial_input.value.strip(),
                "template_testdate": self._tmpl_testdate_input.value.strip(),
                "template_docdate":  self._tmpl_docdate_input.value.strip(),
                "template_cert_no":  self._tmpl_cert_no_input.value.strip(),
                "time_ranges":      time_ranges,
            }

            engine = CalibrationEngine(config)
            engine.load_data(callback=self._log.add_entry)
            engine.process(
                callback=self._log.add_entry,
                progress_callback=self._on_progress,
            )

            # Final progress = 100%
            elapsed = time.time() - self._gen_start_time
            self._progress_bar.value = 1.0
            self._progress_text.value = f"Completed in {elapsed:.1f}s"
            try:
                self._progress_bar.update()
                self._progress_text.update()
            except Exception:
                pass

            self._log.add_entry("✅  All certificates generated successfully!", "success")
            self._log.add_entry(f"📁  Output: {output_dir}", "info")

            # Count warnings and show overlay
            warning_count = sum(
                1 for e in self._log._entries if e._level == "warning"
            )
            cert_count = len(engine.generated_files)
            self._show_success_overlay(cert_count, warning_count, elapsed, output_dir)

            # Persist session for next run
            self._save_session()

            # Save to history database
            try:
                store = HistoryStore()
                session_id = store.save_session(
                    config=config,
                    summary_df=engine.get_summary(),
                    log_entries=self._log._entries,
                    elapsed=elapsed,
                    output_dir=output_dir,
                    generated_files=engine.generated_files,
                )
                store.close()
                if self._on_generation_complete:
                    self._page.run_task(
                        lambda: self._on_generation_complete(session_id)
                    )
            except Exception:
                logger.exception("Failed to save session to history")

        except Exception as ex:
            logger.exception("Certificate generation failed")
            self._log.add_entry(f"❌  ERROR: {ex}", "error")

        finally:
            self._is_processing = False
            self._gen_text.value = "Generate Certificates"
            self._gen_spinner.visible = False
            try:
                self._generate_btn.update()
            except Exception:
                pass

    # ── Session persistence ───────────────────────────────────────────────────

    _SESSION_KEYS = [
        ("cal_cert_no", "_cert_no_input"),
        ("cal_cert_width", "_cert_width_input"),
        ("cal_test_date", "_test_date_input"),
        ("cal_doc_date", "_doc_date_input"),
        ("cal_tmpl_serial", "_tmpl_serial_input"),
        ("cal_tmpl_testdate", "_tmpl_testdate_input"),
        ("cal_tmpl_docdate", "_tmpl_docdate_input"),
        ("cal_tmpl_cert_no", "_tmpl_cert_no_input"),
    ]

    def _save_session(self):
        """Save config field values to page.client_storage for next session."""
        try:
            for storage_key, attr_name in self._SESSION_KEYS:
                field = getattr(self, attr_name, None)
                if field and field.value:
                    self._page.client_storage.set(storage_key, field.value.strip())
            # Save time ranges
            for target, flds in self._time_range_fields.items():
                self._page.client_storage.set(
                    f"cal_tr_{target}_start", flds["start"].value.strip()
                )
                self._page.client_storage.set(
                    f"cal_tr_{target}_end", flds["end"].value.strip()
                )
        except Exception:
            pass

    def _restore_session(self):
        """Restore config field values from page.client_storage."""
        try:
            for storage_key, attr_name in self._SESSION_KEYS:
                val = self._page.client_storage.get(storage_key)
                if val:
                    field = getattr(self, attr_name, None)
                    if field:
                        field.value = val
            # Restore time ranges
            for target, flds in self._time_range_fields.items():
                start_val = self._page.client_storage.get(f"cal_tr_{target}_start")
                end_val = self._page.client_storage.get(f"cal_tr_{target}_end")
                if start_val:
                    flds["start"].value = start_val
                if end_val:
                    flds["end"].value = end_val
            self._page.update()
        except Exception:
            pass

    # ── Success overlay ───────────────────────────────────────────────────────

    def _show_success_overlay(self, cert_count, warning_count, elapsed, output_dir):
        """Show frosted-glass success card as a page overlay."""
        self._last_output_dir = output_dir

        stat_items = [
            ("✅", f"{cert_count} certificates generated", ACCENT_SECONDARY),
        ]
        if warning_count > 0:
            stat_items.append(
                ("⚠️", f"{warning_count} warnings (±0.5°C exceeded)", ACCENT_TERTIARY)
            )
        stat_items.append(("⏱", f"Completed in {elapsed:.1f}s", TEXT_SECONDARY))
        stat_items.append(("📂", str(output_dir), TEXT_MUTED))

        stat_controls = []
        for emoji, text, color in stat_items:
            stat_controls.append(
                ft.Row([
                    ft.Text(emoji, size=16),
                    ft.Text(text, size=13, color=color, expand=True),
                ], spacing=SPACING_SM)
            )

        open_btn = ft.Container(
            content=ft.Row(
                [ft.Icon(ft.Icons.FOLDER_OPEN_ROUNDED, color="#FFFFFF", size=18),
                 ft.Text("Open Output Folder", size=13, color="#FFFFFF",
                         weight=ft.FontWeight.W_600)],
                alignment=ft.MainAxisAlignment.CENTER, spacing=SPACING_SM,
            ),
            width=200, height=42, border_radius=RADIUS_LG,
            gradient=ft.LinearGradient(
                colors=[ACCENT_PRIMARY, "#3A88E8"],
                begin=ft.Alignment(-1, 0), end=ft.Alignment(1, 0),
            ),
            alignment=ft.Alignment(0, 0),
            on_click=lambda _: self._open_output_folder(),
            shadow=SHADOW_CARD,
        )

        again_btn = ft.Container(
            content=ft.Row(
                [ft.Icon(ft.Icons.REFRESH_ROUNDED, color=TEXT_PRIMARY, size=18),
                 ft.Text("Generate Again", size=13, color=TEXT_PRIMARY,
                         weight=ft.FontWeight.W_500)],
                alignment=ft.MainAxisAlignment.CENTER, spacing=SPACING_SM,
            ),
            width=180, height=42, border_radius=RADIUS_LG,
            bgcolor=BG_CARD,
            border=ft.Border.all(1, BORDER_DEFAULT),
            alignment=ft.Alignment(0, 0),
            on_click=lambda _: self._dismiss_overlay(),
        )

        card = ft.Container(
            content=ft.Column(
                [
                    ft.Icon(ft.Icons.CELEBRATION_ROUNDED, size=48,
                            color=ACCENT_SECONDARY),
                    ft.Text("Generation Complete!", size=22, color=TEXT_PRIMARY,
                            weight=ft.FontWeight.W_700,
                            text_align=ft.TextAlign.CENTER),
                    ft.Container(height=SPACING_SM),
                    *stat_controls,
                    ft.Container(height=SPACING_MD),
                    ft.Row([open_btn, again_btn],
                           alignment=ft.MainAxisAlignment.CENTER,
                           spacing=SPACING_MD),
                ],
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                spacing=SPACING_SM,
            ),
            width=440, padding=ft.Padding.all(SPACING_XL),
            border_radius=RADIUS_XL,
            bgcolor=BG_GLASS_STRONG,
            border=ft.Border.all(1, "#30363D60"),
            shadow=SHADOW_CARD,
            blur=ft.Blur(15, 15, ft.BlurTileMode.CLAMP),
            animate_scale=ft.Animation(DURATION_SLOW, CURVE_BOUNCE),
            animate_opacity=ft.Animation(DURATION_SLOW, CURVE_DEFAULT),
            scale=0.9, opacity=0,
        )

        overlay_bg = ft.Container(
            content=ft.Column(
                [card],
                alignment=ft.MainAxisAlignment.CENTER,
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                expand=True,
            ),
            bgcolor="#00000088", expand=True,
            on_click=lambda _: self._dismiss_overlay(),
        )

        self._success_overlay = overlay_bg
        try:
            self._page.overlay.append(overlay_bg)
            self._page.update()
            # Animate in
            card.scale = 1.0
            card.opacity = 1.0
            card.update()
        except Exception:
            pass

    def _dismiss_overlay(self):
        """Remove the success overlay."""
        try:
            if hasattr(self, "_success_overlay") and self._success_overlay:
                if self._success_overlay in self._page.overlay:
                    self._page.overlay.remove(self._success_overlay)
                self._success_overlay = None
                self._page.update()
        except Exception:
            pass

    def _open_output_folder(self):
        """Open the output directory in the system file manager."""
        try:
            path = Path(self._last_output_dir)
            if platform.system() == "Darwin":
                subprocess.Popen(["open", str(path)])
            elif platform.system() == "Windows":
                subprocess.Popen(["explorer", str(path)])
            else:
                subprocess.Popen(["xdg-open", str(path)])
        except Exception:
            pass


