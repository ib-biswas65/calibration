"""
DashboardView — main workspace with:
- Left panel: 4 file drop zones for required input files
- Right panel: Configuration inputs (cert no, dates)
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


class DashboardView(ft.Container):
    """Main dashboard view with file inputs, config, and processing log."""

    def __init__(self, page: ft.Page, **kwargs):
        super().__init__(**kwargs)
        self._page = page

        # State
        self._file_paths = {
            "ref1": None,
            "ref2": None,
            "calibration": None,
            "template": None,
        }
        self._is_processing = False
        self._pending_zone_key = None  # tracks which zone requested a file pick

        # Single shared FilePicker (Flet 0.82)
        self._file_picker = ft.FilePicker()

        # Extension map per zone
        self._zone_extensions = {
            "ref1": ["csv"],
            "ref2": ["csv"],
            "calibration": ["xlsx"],
            "template": ["docx"],
        }

        # ── Header with hero logo ──
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
                    ft.Text(
                        "Dashboard",
                        size=12,
                        color=TEXT_MUTED,
                        weight=ft.FontWeight.W_500,
                    ),
                ],
                vertical_alignment=ft.CrossAxisAlignment.CENTER,
            ),
            padding=ft.padding.symmetric(horizontal=SPACING_LG, vertical=SPACING_MD),
            animate_opacity=ft.Animation(DURATION_SLOW, CURVE_DEFAULT),
            opacity=0,
        )

        # ── File Drop Zones (new API: zone_key + on_browse) ──
        self._drop_ref1 = FileDropZone(
            label="Reference Logger 1",
            zone_key="ref1",
            icon=ft.Icons.SENSORS_ROUNDED,
            on_browse=self._browse_for_zone,
        )
        self._drop_ref2 = FileDropZone(
            label="Reference Logger 2",
            zone_key="ref2",
            icon=ft.Icons.SENSORS_ROUNDED,
            on_browse=self._browse_for_zone,
        )
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

        self._files_section = ft.Container(
            content=ft.Column(
                controls=[
                    ft.Text(
                        "Input Files",
                        size=14,
                        color=TEXT_PRIMARY,
                        weight=ft.FontWeight.W_600,
                    ),
                    ft.Container(height=SPACING_SM),
                    ft.Row(
                        controls=[
                            self._drop_ref1,
                            self._drop_ref2,
                            self._drop_calib,
                            self._drop_template,
                        ],
                        spacing=SPACING_MD,
                        wrap=True,
                        alignment=ft.MainAxisAlignment.START,
                    ),
                ],
            ),
            animate_opacity=ft.Animation(DURATION_SLOW, CURVE_DEFAULT),
            opacity=0,
        )

        # ── Configuration Inputs ──
        self._cert_no_input = ft.TextField(
            label="Start Certificate No",
            value="1700",
            width=200,
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
        self._test_date_input = ft.TextField(
            label="Test Date (Japanese)",
            value="2026年3月4日",
            width=200,
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
        self._doc_date_input = ft.TextField(
            label="Document Date (Japanese)",
            value="2026年3月6日",
            width=200,
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

        # Template placeholders
        self._tmpl_serial_input = ft.TextField(
            label="Template Serial (placeholder)",
            value="190124110002449",
            width=200,
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
        self._tmpl_testdate_input = ft.TextField(
            label="Template Test Date (placeholder)",
            value="2025年11月07日",
            width=200,
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
        self._tmpl_docdate_input = ft.TextField(
            label="Template Doc Date (placeholder)",
            value="2025年11月13日",
            width=200,
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

        # ── Time Range Inputs ──
        self._time_info = ft.Text(
            "Time ranges are hardcoded for March 4, 2026 calibration session.\n"
            "5°C: 14:50–16:45 | 40°C: 16:46–17:40 | -40°C: 17:41–13:00(+1d)",
            size=11,
            color=TEXT_MUTED,
            italic=True,
        )

        self._config_section = ft.Container(
            content=ft.Column(
                controls=[
                    ft.Text(
                        "Configuration",
                        size=14,
                        color=TEXT_PRIMARY,
                        weight=ft.FontWeight.W_600,
                    ),
                    ft.Container(height=SPACING_SM),
                    ft.Row(
                        controls=[
                            self._cert_no_input,
                            self._test_date_input,
                            self._doc_date_input,
                        ],
                        spacing=SPACING_MD,
                        wrap=True,
                    ),
                    ft.Container(height=SPACING_SM),
                    ft.Text(
                        "Template Placeholders",
                        size=12,
                        color=TEXT_SECONDARY,
                        weight=ft.FontWeight.W_500,
                    ),
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
                    self._time_info,
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

    def did_mount(self):
        """Register shared file picker and trigger staggered entrance."""
        self._page.overlay.append(self._snackbar)
        self._page.overlay.append(self._file_picker)
        self._page.update()
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

    def _browse_for_zone(self, zone_key: str):
        """Called when a FileDropZone is clicked — open file picker for that zone."""
        self._pending_zone_key = zone_key
        self._page.run_task(self._async_pick, zone_key)

    async def _async_pick(self, zone_key: str):
        """Use shared FilePicker to pick a file, then route to the correct zone."""
        extensions = self._zone_extensions.get(zone_key)
        try:
            result = await self._file_picker.pick_files(
                allow_multiple=False,
                allowed_extensions=extensions,
            )
            if result and len(result) > 0:
                picked = result[0]
                self._file_paths[zone_key] = picked.path

                # Find the right drop zone and accept the file
                zone_map = {
                    "ref1": self._drop_ref1,
                    "ref2": self._drop_ref2,
                    "calibration": self._drop_calib,
                    "template": self._drop_template,
                }
                zone = zone_map.get(zone_key)
                if zone:
                    zone.accept_file(picked.path, picked.name)
                self._log.add_entry(f"Selected {zone_key}: {picked.name}", "success")
        except Exception as ex:
            self._log.add_entry(f"File pick error: {str(ex)}", "error")

    def _on_gen_hover(self, e: ft.HoverEvent):
        if not self._is_processing:
            self._generate_btn.scale = 1.05 if e.data == "true" else 1.0
            self._generate_btn.update()

    def _validate(self) -> bool:
        """Validate all required inputs. Shake invalid drop zones."""
        valid = True
        missing = []

        for key, drop in [
            ("ref1", self._drop_ref1),
            ("ref2", self._drop_ref2),
            ("calibration", self._drop_calib),
            ("template", self._drop_template),
        ]:
            if not self._file_paths.get(key):
                drop.shake()
                missing.append(key)
                valid = False

        if not self._cert_no_input.value.strip():
            self._cert_no_input.error_text = "Required"
            self._cert_no_input.update()
            valid = False

        if not valid:
            self._show_snackbar(f"Missing files: {', '.join(missing)}")

        return valid

    def _show_snackbar(self, message: str):
        self._snackbar.content = ft.Text(message, color="#FFFFFF")
        self._snackbar.open = True
        self._page.update()

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

        # Run engine in background thread
        thread = threading.Thread(target=self._run_engine, daemon=True)
        thread.start()

    def _run_engine(self):
        """Run the calibration engine (called from background thread)."""
        try:
            # Build time ranges (hardcoded for March 4, 2026 session)
            time_ranges = {
                5.0: (
                    datetime(2026, 3, 4, 14, 50),
                    datetime(2026, 3, 4, 16, 45),
                ),
                40.0: (
                    datetime(2026, 3, 4, 16, 46),
                    datetime(2026, 3, 4, 17, 40),
                ),
                -40.0: (
                    datetime(2026, 3, 4, 17, 41),
                    datetime(2026, 3, 5, 13, 0),
                ),
            }

            config = {
                "start_cert_no": int(self._cert_no_input.value.strip()),
                "cert_width": 10,
                "test_date_jp": self._test_date_input.value.strip(),
                "doc_date_jp": self._doc_date_input.value.strip(),
                "template_path": self._file_paths["template"],
                "calibration_xlsx": self._file_paths["calibration"],
                "ref1_csv": self._file_paths["ref1"],
                "ref2_csv": self._file_paths["ref2"],
                "output_dir": "output",
                "template_serial": self._tmpl_serial_input.value.strip(),
                "template_testdate": self._tmpl_testdate_input.value.strip(),
                "template_docdate": self._tmpl_docdate_input.value.strip(),
                "time_ranges": time_ranges,
            }

            engine = CalibrationEngine(config)

            def log_callback(msg, level="info"):
                self._log.add_entry(msg, level)

            engine.load_data(callback=log_callback)
            engine.process(callback=log_callback)

            # Done!
            self._log.add_entry(
                "\n✅ All certificates generated successfully!", "success"
            )

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
