"""
DashboardView — main workspace with:
- Left panel: dynamic N reference file zones + fixed calibration/template zones
- Configuration: cert number, cert width, dates, template placeholders
- Time ranges: configurable per temperature target (-40, 5, 40 °C)
- Output directory: configurable (defaults to sibling of calibration XLSX)
- Bottom panel: Real-time animated processing log
- Generate button with CrossFade → progress animation
- Staggered entrance animations
- Shake animation on validation errors
"""

import asyncio
import threading
from datetime import datetime
from pathlib import Path

import flet as ft
import openpyxl

from ..theme import (
    BG_PRIMARY, BG_SECONDARY, BG_CARD, BG_GLASS_STRONG,
    ACCENT_PRIMARY, ACCENT_SECONDARY, ACCENT_TERTIARY, ACCENT_DANGER,
    TEXT_PRIMARY, TEXT_SECONDARY, TEXT_MUTED,
    BORDER_DEFAULT, BORDER_ACTIVE,
    GRADIENT_HERO,
    RADIUS_SM, RADIUS_MD, RADIUS_LG, RADIUS_XL,
    SPACING_SM, SPACING_MD, SPACING_LG, SPACING_XL, SPACING_XXL,
    DURATION_NORMAL, DURATION_SLOW, DURATION_HERO,
    CURVE_DEFAULT, CURVE_BOUNCE, STAGGER_DELAY,
    SHADOW_CARD,
    WINDOW_TITLE,
)
from ..components.file_drop_zone import FileDropZone
from ..components.processing_log import ProcessingLog
from ..engine import CalibrationEngine


# Default time ranges (pre-filled from original session; user can change)
_DEFAULT_TIME_RANGES = {
    -40.0: ("2026/03/04 17:41", "2026/03/05 13:00"),
    5.0:   ("2026/03/04 14:50", "2026/03/04 16:45"),
    40.0:  ("2026/03/04 16:46", "2026/03/04 17:40"),
}

_DATETIME_FMT = "%Y/%m/%d %H:%M"


def _make_section_title(text: str) -> ft.Text:
    return ft.Text(text, size=14, color=TEXT_PRIMARY, weight=ft.FontWeight.W_600)


def _make_subsection_title(text: str) -> ft.Text:
    return ft.Text(text, size=12, color=TEXT_SECONDARY, weight=ft.FontWeight.W_500)


def _make_field(label: str, value: str, width: int = 200, hint: str = "") -> ft.TextField:
    return ft.TextField(
        label=label,
        value=value,
        hint_text=hint,
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


class DashboardView(ft.Container):
    """Main dashboard view with file inputs, config, and processing log."""

    def __init__(self, page: ft.Page, **kwargs):
        super().__init__(**kwargs)
        self._page = page

        # ── State ──
        # Reference zones are dynamic: list of (zone_key, FileDropZone, file_path)
        self._ref_zones: list[dict] = []   # each dict: {key, zone, path}
        self._ref_counter = 0              # monotone counter for unique keys

        self._calibration_path: str | None = None
        self._template_path: str | None = None
        self._output_dir: str | None = None   # None = auto (sibling of calib XLSX)
        self._sheet_count: int = 0            # set when XLSX is loaded

        self._is_processing = False
        self._pending_zone_key: str | None = None

        # ── Single shared FilePicker (Flet 0.82) ──
        self._file_picker = ft.FilePicker()
        self._dir_picker = ft.FilePicker()

        # ── Extension map per zone type ──
        self._zone_extensions = {
            "ref": ["csv"],
            "calibration": ["xlsx"],
            "template": ["docx"],
        }

        # ── Header ──
        self._header = ft.Container(
            content=ft.Row(
                controls=[
                    ft.Icon(ft.Icons.SCIENCE_ROUNDED, size=24, color=ACCENT_PRIMARY),
                    ft.Text(
                        WINDOW_TITLE,
                        size=18,
                        color=TEXT_PRIMARY,
                        weight=ft.FontWeight.W_700,
                    ),
                    ft.Container(expand=True),
                    ft.Text("Dashboard", size=12, color=TEXT_MUTED, weight=ft.FontWeight.W_500),
                ],
                vertical_alignment=ft.CrossAxisAlignment.CENTER,
            ),
            padding=ft.padding.symmetric(horizontal=SPACING_LG, vertical=SPACING_MD),
            animate_opacity=ft.Animation(DURATION_SLOW, CURVE_DEFAULT),
            opacity=0,
        )

        # ── Reference zones row (dynamic) ──
        self._ref_zones_row = ft.Row(
            controls=[],
            spacing=SPACING_MD,
            wrap=True,
            alignment=ft.MainAxisAlignment.START,
        )

        self._add_ref_btn = ft.TextButton(
            content=ft.Row(
                [
                    ft.Icon(ft.Icons.ADD_ROUNDED, size=16, color=ACCENT_PRIMARY),
                    ft.Text("Add Reference File", size=12, color=ACCENT_PRIMARY),
                ],
                spacing=4,
                tight=True,
            ),
            on_click=self._add_ref_zone,
            style=ft.ButtonStyle(
                padding=ft.padding.symmetric(horizontal=SPACING_MD, vertical=SPACING_SM),
            ),
        )

        # Fixed calibration + template zones
        self._drop_calib = FileDropZone(
            label="Calibration Data (XLSX)",
            zone_key="calibration",
            icon=ft.Icons.TABLE_CHART_ROUNDED,
            on_browse=self._browse_for_zone,
        )
        self._drop_template = FileDropZone(
            label="Certificate Template",
            zone_key="template",
            icon=ft.Icons.DESCRIPTION_ROUNDED,
            on_browse=self._browse_for_zone,
        )
        self._fixed_zones_row = ft.Row(
            controls=[self._drop_calib, self._drop_template],
            spacing=SPACING_MD,
            wrap=True,
        )

        self._files_section = ft.Container(
            content=ft.Column(
                controls=[
                    _make_section_title("Input Files"),
                    ft.Container(height=SPACING_SM),
                    _make_subsection_title("Reference Logger(s)"),
                    ft.Container(height=4),
                    self._ref_zones_row,
                    self._add_ref_btn,
                    ft.Container(height=SPACING_SM),
                    _make_subsection_title("Calibration & Template"),
                    ft.Container(height=4),
                    self._fixed_zones_row,
                ],
            ),
            animate_opacity=ft.Animation(DURATION_SLOW, CURVE_DEFAULT),
            opacity=0,
        )

        # ── Output directory ──
        self._output_path_label = ft.Text(
            "Auto (same folder as Calibration XLSX / output)",
            size=11,
            color=TEXT_MUTED,
            italic=True,
            expand=True,
        )
        self._output_dir_row = ft.Row(
            controls=[
                ft.Icon(ft.Icons.FOLDER_ROUNDED, size=16, color=TEXT_SECONDARY),
                ft.Text("Output Folder:", size=12, color=TEXT_SECONDARY),
                self._output_path_label,
                ft.TextButton(
                    "Browse",
                    on_click=lambda e: self._page.run_task(self._browse_output_dir, e),
                    style=ft.ButtonStyle(
                        color=ACCENT_PRIMARY,
                        padding=ft.padding.symmetric(horizontal=SPACING_SM),
                    ),
                ),
            ],
            spacing=SPACING_SM,
            vertical_alignment=ft.CrossAxisAlignment.CENTER,
        )

        # ── Certificate configuration ──
        self._cert_no_input = _make_field("Start Certificate No", "1700", width=180)
        self._cert_width_input = _make_field("Cert Width (zero-pad)", "10", width=160)
        self._template_cert_no_input = _make_field(
            "Template Cert No (in .docx)", "0000001644", width=220,
            hint="The cert number currently in your template"
        )

        self._cert_preview = ft.Text(
            "",
            size=11,
            color=TEXT_MUTED,
            italic=True,
        )

        # Update preview when cert fields change
        self._cert_no_input.on_change = self._update_cert_preview
        self._cert_width_input.on_change = self._update_cert_preview

        # ── Date configuration ──
        self._test_date_input = _make_field("Test Date (Japanese)", "2026年3月4日", width=200)
        self._doc_date_input = _make_field("Document Date (Japanese)", "2026年3月6日", width=200)

        # Template placeholder dates
        self._tmpl_serial_input = _make_field(
            "Template Serial (placeholder)", "190124110002449", width=220
        )
        self._tmpl_testdate_input = _make_field(
            "Template Test Date (placeholder)", "2025年11月07日", width=220
        )
        self._tmpl_docdate_input = _make_field(
            "Template Doc Date (placeholder)", "2025年11月13日", width=220
        )

        # ── Time range configuration ──
        # One pair of start/end fields per temperature target
        # Display order: 5°C, 40°C, -40°C (chronological order of the session)
        self._time_range_fields: dict[float, dict] = {}
        time_range_rows = []

        for target in [5.0, 40.0, -40.0]:
            defaults = _DEFAULT_TIME_RANGES[target]
            label_color = {5.0: ACCENT_SECONDARY, 40.0: ACCENT_TERTIARY, -40.0: ACCENT_PRIMARY}[target]
            label_text = {5.0: "  5 °C", 40.0: " 40 °C", -40.0: "-40 °C"}[target]

            start_field = _make_field("", defaults[0], width=175, hint="YYYY/MM/DD HH:MM")
            end_field = _make_field("", defaults[1], width=175, hint="YYYY/MM/DD HH:MM")
            start_field.label = "Start"
            end_field.label = "End"

            self._time_range_fields[target] = {"start": start_field, "end": end_field}

            time_range_rows.append(
                ft.Row(
                    controls=[
                        ft.Container(
                            content=ft.Text(label_text, size=13, color=label_color,
                                            weight=ft.FontWeight.W_600),
                            width=60,
                        ),
                        start_field,
                        ft.Icon(ft.Icons.ARROW_FORWARD_ROUNDED, size=16, color=TEXT_MUTED),
                        end_field,
                    ],
                    spacing=SPACING_SM,
                    vertical_alignment=ft.CrossAxisAlignment.CENTER,
                )
            )

        self._config_section = ft.Container(
            content=ft.Column(
                controls=[
                    _make_section_title("Configuration"),
                    ft.Container(height=SPACING_SM),

                    _make_subsection_title("Certificate Numbers"),
                    ft.Container(height=4),
                    ft.Row(
                        controls=[
                            self._cert_no_input,
                            self._cert_width_input,
                            self._template_cert_no_input,
                        ],
                        spacing=SPACING_MD,
                        wrap=True,
                    ),
                    self._cert_preview,
                    ft.Container(height=SPACING_SM),

                    _make_subsection_title("Dates"),
                    ft.Container(height=4),
                    ft.Row(
                        controls=[
                            self._test_date_input,
                            self._doc_date_input,
                        ],
                        spacing=SPACING_MD,
                        wrap=True,
                    ),
                    ft.Container(height=SPACING_SM),

                    _make_subsection_title("Template Placeholders"),
                    ft.Container(height=4),
                    ft.Row(
                        controls=[
                            self._tmpl_serial_input,
                            self._tmpl_testdate_input,
                            self._tmpl_docdate_input,
                        ],
                        spacing=SPACING_MD,
                        wrap=True,
                    ),
                    ft.Container(height=SPACING_SM),

                    _make_subsection_title("Temperature Time Ranges (YYYY/MM/DD HH:MM)"),
                    ft.Container(height=4),
                    *time_range_rows,
                    ft.Container(height=SPACING_SM),

                    self._output_dir_row,
                ],
            ),
            animate_opacity=ft.Animation(DURATION_SLOW, CURVE_DEFAULT),
            opacity=0,
        )

        # ── Generate Button ──
        self._gen_text = ft.Text(
            "Generate Certificates",
            size=14,
            color="#FFFFFF",
            weight=ft.FontWeight.W_600,
        )
        self._gen_spinner = ft.ProgressRing(
            width=18, height=18, stroke_width=2.5, color="#FFFFFF", visible=False
        )
        self._generate_btn = ft.Container(
            content=ft.Row(
                [
                    ft.Icon(ft.Icons.PLAY_ARROW_ROUNDED, color="#FFFFFF", size=20),
                    self._gen_text,
                    self._gen_spinner,
                ],
                alignment=ft.MainAxisAlignment.CENTER,
                spacing=SPACING_SM,
            ),
            width=260,
            height=48,
            border_radius=RADIUS_LG,
            gradient=ft.LinearGradient(
                colors=[ACCENT_PRIMARY, "#4090E0"],
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
        )

        # ── Processing Log ──
        self._log = ProcessingLog()
        self._log_section = ft.Container(
            content=self._log,
            height=250,
            animate_opacity=ft.Animation(DURATION_SLOW, CURVE_DEFAULT),
            opacity=0,
        )

        # ── Snackbar for errors ──
        self._snackbar = ft.SnackBar(
            content=ft.Text(""),
            bgcolor=ACCENT_DANGER,
            duration=3000,
        )

        # ── Main layout ──
        self.content = ft.Container(
            content=ft.Column(
                controls=[
                    self._header,
                    ft.Container(
                        content=ft.Column(
                            controls=[
                                self._files_section,
                                ft.Divider(height=1, color=BORDER_DEFAULT),
                                self._config_section,
                                ft.Container(height=SPACING_SM),
                                ft.Row(
                                    [self._generate_btn],
                                    alignment=ft.MainAxisAlignment.CENTER,
                                ),
                                ft.Container(height=SPACING_MD),
                                self._log_section,
                            ],
                            spacing=SPACING_MD,
                            scroll=ft.ScrollMode.AUTO,
                            expand=True,
                        ),
                        padding=ft.padding.symmetric(
                            horizontal=SPACING_XL, vertical=SPACING_MD
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

    # ──────────────────────────────────────────────────────────
    # Lifecycle
    # ──────────────────────────────────────────────────────────

    def did_mount(self):
        """Register pickers and trigger staggered entrance. Add initial ref zone."""
        self._page.overlay.append(self._snackbar)
        self._page.overlay.append(self._file_picker)
        self._page.overlay.append(self._dir_picker)
        self._page.update()

        # Add the first reference zone
        self._add_ref_zone(None)

        self._page.run_task(self._animate_entrance)

    async def _animate_entrance(self):
        """Stagger elements in from top to bottom."""
        await asyncio.sleep(0.1)
        elements = [
            self._header,
            self._files_section,
            self._config_section,
            self._generate_btn,
            self._log_section,
        ]
        for el in elements:
            el.opacity = 1
            el.update()
            await asyncio.sleep(STAGGER_DELAY / 1000 * 3)

    # ──────────────────────────────────────────────────────────
    # Dynamic reference zones
    # ──────────────────────────────────────────────────────────

    def _add_ref_zone(self, e):
        """Add a new reference file zone to the dynamic list."""
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

        # Show remove button on all zones if there are 2+
        self._sync_remove_buttons()

        if self._page:
            self._ref_zones_row.update()

    def _remove_ref_zone(self, zone_key: str):
        """Remove a reference zone by key."""
        if len(self._ref_zones) <= 1:
            return  # always keep at least one

        entry = next((z for z in self._ref_zones if z["key"] == zone_key), None)
        if not entry:
            return

        self._ref_zones.remove(entry)
        self._ref_zones_row.controls.remove(entry["zone"])

        # Renumber labels
        for i, z in enumerate(self._ref_zones):
            z["zone"]._label.value = f"Reference Logger {i + 1}"
            z["zone"]._label.update()

        self._sync_remove_buttons()
        self._ref_zones_row.update()

    def _sync_remove_buttons(self):
        """Show remove buttons only when there are 2+ reference zones."""
        show = len(self._ref_zones) > 1
        for z in self._ref_zones:
            z["zone"].show_remove_button(show)

    # ──────────────────────────────────────────────────────────
    # File picking
    # ──────────────────────────────────────────────────────────

    def _browse_for_zone(self, zone_key: str):
        """Called when a FileDropZone is clicked."""
        self._pending_zone_key = zone_key
        self._page.run_task(self._async_pick, zone_key)

    async def _async_pick(self, zone_key: str):
        """Use shared FilePicker, then route result to the correct zone."""
        if zone_key.startswith("ref_"):
            extensions = self._zone_extensions["ref"]
        elif zone_key == "calibration":
            extensions = self._zone_extensions["calibration"]
        else:
            extensions = self._zone_extensions["template"]

        try:
            result = await self._file_picker.pick_files(
                allow_multiple=False,
                allowed_extensions=extensions,
            )
            if result and len(result) > 0:
                picked = result[0]

                if zone_key.startswith("ref_"):
                    entry = next((z for z in self._ref_zones if z["key"] == zone_key), None)
                    if entry:
                        entry["path"] = picked.path
                        entry["zone"].accept_file(picked.path, picked.name)
                        self._log.add_entry(
                            f"Selected reference: {picked.name}", "success"
                        )

                elif zone_key == "calibration":
                    self._calibration_path = picked.path
                    self._drop_calib.accept_file(picked.path, picked.name)
                    self._log.add_entry(f"Selected calibration: {picked.name}", "success")
                    # Peek at sheet count for cert preview
                    self._page.run_task(self._peek_xlsx_sheets, picked.path)

                elif zone_key == "template":
                    self._template_path = picked.path
                    self._drop_template.accept_file(picked.path, picked.name)
                    self._log.add_entry(f"Selected template: {picked.name}", "success")

        except Exception as ex:
            self._log.add_entry(f"File pick error: {str(ex)}", "error")

    async def _peek_xlsx_sheets(self, path: str):
        """Read sheet count from XLSX to update cert number preview."""
        try:
            wb = openpyxl.load_workbook(path, read_only=True, data_only=True)
            self._sheet_count = len(wb.sheetnames)
            wb.close()
            self._update_cert_preview(None)
        except Exception:
            pass

    async def _browse_output_dir(self, _e=None):
        """Open directory picker for output folder."""
        try:
            result = await self._dir_picker.get_directory_path(
                dialog_title="Select Output Folder"
            )
            if result:
                self._output_dir = result
                self._output_path_label.value = result
                self._output_path_label.update()
                self._log.add_entry(f"Output folder: {result}", "info")
        except Exception as ex:
            self._log.add_entry(f"Folder pick error: {str(ex)}", "error")

    # ──────────────────────────────────────────────────────────
    # UI helpers
    # ──────────────────────────────────────────────────────────

    def _update_cert_preview(self, e):
        """Update the live cert number preview label."""
        try:
            start = int(self._cert_no_input.value.strip())
            width = int(self._cert_width_input.value.strip())
            count = self._sheet_count
            if count > 0:
                first = str(start).zfill(width)
                last = str(start + count - 1).zfill(width)
                self._cert_preview.value = (
                    f"Will generate {count} certificate(s): {first} → {last}"
                )
            else:
                first = str(start).zfill(width)
                self._cert_preview.value = f"First certificate will be: {first}"
        except ValueError:
            self._cert_preview.value = ""

        if self._page:
            try:
                self._cert_preview.update()
            except Exception:
                pass

    def _on_gen_hover(self, e: ft.HoverEvent):
        if not self._is_processing:
            self._generate_btn.scale = 1.05 if e.data == "true" else 1.0
            self._generate_btn.update()

    def _show_snackbar(self, message: str):
        self._snackbar.content = ft.Text(message, color="#FFFFFF")
        self._snackbar.open = True
        self._page.update()

    # ──────────────────────────────────────────────────────────
    # Validation
    # ──────────────────────────────────────────────────────────

    def _validate(self) -> bool:
        """Validate all required inputs. Shake invalid drop zones."""
        valid = True
        missing = []

        # Validate each reference zone has a file
        for z in self._ref_zones:
            if not z["path"]:
                z["zone"].shake()
                missing.append("reference file")
                valid = False

        if not self._calibration_path:
            self._drop_calib.shake()
            missing.append("calibration XLSX")
            valid = False

        if not self._template_path:
            self._drop_template.shake()
            missing.append("certificate template")
            valid = False

        # Validate cert number
        try:
            val = int(self._cert_no_input.value.strip())
            if val <= 0:
                raise ValueError
            self._cert_no_input.error_text = None
        except (ValueError, AttributeError):
            self._cert_no_input.error_text = "Must be a positive integer"
            self._cert_no_input.update()
            valid = False

        # Validate cert width
        try:
            w = int(self._cert_width_input.value.strip())
            if w <= 0 or w > 20:
                raise ValueError
            self._cert_width_input.error_text = None
        except (ValueError, AttributeError):
            self._cert_width_input.error_text = "1–20"
            self._cert_width_input.update()
            valid = False

        # Validate time ranges
        for target, fields in self._time_range_fields.items():
            for field_name, field in [("Start", fields["start"]), ("End", fields["end"])]:
                try:
                    datetime.strptime(field.value.strip(), _DATETIME_FMT)
                    field.error_text = None
                    field.update()
                except (ValueError, AttributeError):
                    field.error_text = f"Use {_DATETIME_FMT}"
                    field.update()
                    valid = False

        if not valid and missing:
            self._show_snackbar(f"Missing: {', '.join(missing)}")
        elif not valid:
            self._show_snackbar("Please fix the highlighted fields")

        return valid

    # ──────────────────────────────────────────────────────────
    # Processing
    # ──────────────────────────────────────────────────────────

    def _handle_generate(self, e):
        """Validate, then run the engine in a background thread."""
        if self._is_processing:
            return
        if not self._validate():
            return

        self._is_processing = True
        self._gen_text.value = "Processing..."
        self._gen_spinner.visible = True
        self._generate_btn.update()
        self._log.clear()

        thread = threading.Thread(target=self._run_engine, daemon=True)
        thread.start()

    def _run_engine(self):
        """Run the calibration engine (called from background thread)."""
        try:
            # Parse time ranges from UI fields
            time_ranges = {}
            for target, fields in self._time_range_fields.items():
                t_start = datetime.strptime(fields["start"].value.strip(), _DATETIME_FMT)
                t_end = datetime.strptime(fields["end"].value.strip(), _DATETIME_FMT)
                time_ranges[target] = (t_start, t_end)

            # Resolve output directory
            if self._output_dir:
                output_dir = self._output_dir
            else:
                output_dir = str(
                    Path(self._calibration_path).parent / "output"
                )

            # Collect reference paths
            ref_paths = [z["path"] for z in self._ref_zones if z["path"]]

            config = {
                "start_cert_no": int(self._cert_no_input.value.strip()),
                "cert_width": int(self._cert_width_input.value.strip()),
                "test_date_jp": self._test_date_input.value.strip(),
                "doc_date_jp": self._doc_date_input.value.strip(),
                "template_path": self._template_path,
                "calibration_xlsx": self._calibration_path,
                "ref_csvs": ref_paths,
                "output_dir": output_dir,
                "template_serial": self._tmpl_serial_input.value.strip(),
                "template_testdate": self._tmpl_testdate_input.value.strip(),
                "template_docdate": self._tmpl_docdate_input.value.strip(),
                "template_cert_no": self._template_cert_no_input.value.strip(),
                "time_ranges": time_ranges,
            }

            engine = CalibrationEngine(config)

            def log_callback(msg, level="info"):
                self._log.add_entry(msg, level)

            engine.load_data(callback=log_callback)
            engine.process(callback=log_callback)

            self._log.add_entry("\n✅ All certificates generated successfully!", "success")
            self._log.add_entry(f"Output: {output_dir}", "info")

        except Exception as ex:
            self._log.add_entry(f"\n❌ ERROR: {str(ex)}", "error")

        finally:
            self._is_processing = False
            self._gen_text.value = "Generate Certificates"
            self._gen_spinner.visible = False
            try:
                self._generate_btn.update()
            except Exception:
                pass
