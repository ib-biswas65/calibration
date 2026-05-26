"""
BulkAssignPanel — glassmorphic overlay for bulk file assignment.

Shows after the user selects multiple files in one dialog. Auto-assigns roles
by extension, lets the user adjust via dropdowns, validates conflicts in real
time, then fires on_confirm(ref_paths, calibration_path, template_path).
"""

import asyncio
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, List, Optional

import flet as ft

from ..theme import (
    ACCENT_PRIMARY, ACCENT_SECONDARY, ACCENT_TERTIARY, ACCENT_DANGER,
    BG_CARD, BG_GLASS_STRONG, BORDER_DEFAULT,
    TEXT_PRIMARY, TEXT_SECONDARY, TEXT_MUTED,
    RADIUS_SM, RADIUS_MD, RADIUS_LG, RADIUS_XL,
    SPACING_XS, SPACING_SM, SPACING_MD, SPACING_LG, SPACING_XL,
    DURATION_NORMAL, DURATION_SLOW,
    CURVE_DEFAULT, CURVE_BOUNCE,
    SHADOW_CARD,
)


# ── Data model ────────────────────────────────────────────────────────────────

@dataclass
class FileAssignment:
    """Represents one file and its assigned processing role."""
    path: str
    name: str
    ext: str          # "csv" | "xlsx" | "docx" | other
    role: str         # "ref" | "calibration" | "template" | "unassigned"
    label_hint: str   # "" | "ref" | "template" | "cal" — detected from filename


ROLE_OPTIONS = [
    ("Reference Logger",  "ref"),
    ("Calibration Data",  "calibration"),
    ("Template (.docx)",  "template"),
    ("— Skip file —",     "unassigned"),
]

_EXT_ICONS = {
    "csv":  ft.Icons.SENSORS_ROUNDED,
    "xlsx": ft.Icons.TABLE_CHART_ROUNDED,
    "docx": ft.Icons.DESCRIPTION_ROUNDED,
}
_EXT_COLORS = {
    "csv":  ACCENT_SECONDARY,
    "xlsx": ACCENT_TERTIARY,
    "docx": ACCENT_PRIMARY,
}


# ── Auto-assignment logic ─────────────────────────────────────────────────────

def auto_assign(files) -> List[FileAssignment]:
    """
    Automatically assign roles to picked files based on their extensions.

    Rules:
    - .csv  → "ref"  (all CSVs become reference loggers)
    - First .xlsx → "calibration"
    - First .docx → "template"
    - Duplicates and unknown extensions → "unassigned"

    Args:
        files: list of ft.FilePickerFile (any object with .path and .name attrs)

    Returns:
        list[FileAssignment] — in the same order as input files
    """
    assignments: List[FileAssignment] = []
    calibration_taken = False
    template_taken = False

    for f in files:
        name_lower = f.name.lower()
        ext = Path(f.name).suffix.lower().lstrip(".")

        if ext == "csv":
            role = "ref"
        elif ext == "xlsx":
            if not calibration_taken:
                role = "calibration"
                calibration_taken = True
            else:
                role = "unassigned"
        elif ext == "docx":
            if not template_taken:
                role = "template"
                template_taken = True
            else:
                role = "unassigned"
        else:
            role = "unassigned"

        # Detect filename hints for smart label badges
        if "ref" in name_lower or "reference" in name_lower:
            hint = "ref"
        elif "template" in name_lower or "templ" in name_lower:
            hint = "template"
        elif "cal" in name_lower or "calib" in name_lower:
            hint = "cal"
        else:
            hint = ""

        assignments.append(FileAssignment(
            path=f.path,
            name=f.name,
            ext=ext,
            role=role,
            label_hint=hint,
        ))

    return assignments


# ── Panel component ───────────────────────────────────────────────────────────

class BulkAssignPanel(ft.Container):
    """
    Full-screen glassmorphic overlay panel for reviewing and confirming
    bulk file assignments.

    Usage:
        panel = BulkAssignPanel(assignments, on_confirm, on_dismiss)
        page.overlay.append(panel)
        page.update()
    """

    def __init__(
        self,
        assignments: List[FileAssignment],
        on_confirm: Callable,   # on_confirm(ref_paths, calibration_path, template_path)
        on_dismiss: Callable,   # on_dismiss()
        **kwargs,
    ):
        super().__init__(**kwargs)
        self._assignments = list(assignments)  # mutable working copy
        self._on_confirm_cb = on_confirm
        self._on_dismiss_cb = on_dismiss

        # Index → ft.Dropdown, for live role updates
        self._row_dropdowns: dict[int, ft.Dropdown] = {}

        # ── Conflict / validation banner ──────────────────────────────────────
        self._warning_text = ft.Text(
            "", size=12, color=ACCENT_TERTIARY, expand=True,
        )
        self._warning_banner = ft.Container(
            content=ft.Row(
                [
                    ft.Icon(ft.Icons.WARNING_AMBER_ROUNDED, size=16, color=ACCENT_TERTIARY),
                    self._warning_text,
                ],
                spacing=SPACING_SM,
                vertical_alignment=ft.CrossAxisAlignment.CENTER,
            ),
            bgcolor=f"{ACCENT_TERTIARY}18",
            border_radius=RADIUS_SM,
            border=ft.Border.all(1, f"{ACCENT_TERTIARY}40"),
            padding=ft.Padding.symmetric(horizontal=SPACING_MD, vertical=SPACING_SM),
            visible=False,
        )

        # ── Confirm button ────────────────────────────────────────────────────
        self._confirm_btn = ft.Container(
            content=ft.Row(
                [
                    ft.Icon(ft.Icons.CHECK_CIRCLE_ROUNDED, color="#FFFFFF", size=18),
                    ft.Text(
                        "Confirm Assignment", size=13, color="#FFFFFF",
                        weight=ft.FontWeight.W_600,
                    ),
                ],
                alignment=ft.MainAxisAlignment.CENTER,
                spacing=SPACING_SM,
            ),
            width=200, height=42,
            border_radius=RADIUS_LG,
            gradient=ft.LinearGradient(
                colors=[ACCENT_PRIMARY, "#3A88E8"],
                begin=ft.Alignment(-1, 0),
                end=ft.Alignment(1, 0),
            ),
            alignment=ft.Alignment(0, 0),
            on_click=self._on_confirm_click,
            on_hover=self._on_confirm_hover,
            animate_scale=ft.Animation(DURATION_NORMAL, CURVE_DEFAULT),
            animate_opacity=ft.Animation(DURATION_NORMAL, CURVE_DEFAULT),
            scale=1.0,
            opacity=1.0,
            shadow=SHADOW_CARD,
            tooltip="Assign files and close",
        )

        cancel_btn = ft.Container(
            content=ft.Row(
                [
                    ft.Icon(ft.Icons.CLOSE_ROUNDED, color=TEXT_SECONDARY, size=18),
                    ft.Text(
                        "Cancel", size=13, color=TEXT_SECONDARY,
                        weight=ft.FontWeight.W_500,
                    ),
                ],
                alignment=ft.MainAxisAlignment.CENTER,
                spacing=SPACING_SM,
            ),
            width=120, height=42,
            border_radius=RADIUS_LG,
            bgcolor=BG_CARD,
            border=ft.Border.all(1, BORDER_DEFAULT),
            alignment=ft.Alignment(0, 0),
            on_click=lambda _: self._on_dismiss_cb(),
            tooltip="Cancel bulk assignment",
        )

        # ── File rows ─────────────────────────────────────────────────────────
        file_rows_col = ft.Column(
            controls=self._build_file_rows(),
            spacing=SPACING_SM,
            scroll=ft.ScrollMode.AUTO,
        )

        n = len(self._assignments)
        subtitle = f"{n} file{'s' if n != 1 else ''} detected — assign each to a role:"

        # Close ✕ button (top-right of card)
        self._close_btn = ft.Container(
            content=ft.Icon(ft.Icons.CLOSE_ROUNDED, size=16, color=TEXT_MUTED),
            width=28, height=28,
            border_radius=14,
            bgcolor="transparent",
            alignment=ft.Alignment(0, 0),
            on_click=lambda _: self._on_dismiss_cb(),
            on_hover=self._on_close_hover,
            tooltip="Close",
        )

        # ── Glassmorphic card ─────────────────────────────────────────────────
        self._card = ft.Container(
            content=ft.Column(
                [
                    # Header row
                    ft.Row(
                        [
                            ft.Icon(
                                ft.Icons.UPLOAD_FILE_ROUNDED, size=20,
                                color=ACCENT_PRIMARY,
                            ),
                            ft.Text(
                                "Bulk File Assignment", size=16,
                                color=TEXT_PRIMARY, weight=ft.FontWeight.W_700,
                                expand=True,
                            ),
                            self._close_btn,
                        ],
                        spacing=SPACING_SM,
                        vertical_alignment=ft.CrossAxisAlignment.CENTER,
                    ),
                    ft.Text(subtitle, size=12, color=TEXT_SECONDARY),
                    ft.Divider(height=1, color=BORDER_DEFAULT),

                    # File rows (scrollable)
                    ft.Container(
                        content=file_rows_col,
                        max_height=300,
                    ),

                    self._warning_banner,
                    ft.Divider(height=1, color=BORDER_DEFAULT),

                    # Action buttons (right-aligned)
                    ft.Row(
                        [cancel_btn, self._confirm_btn],
                        alignment=ft.MainAxisAlignment.END,
                        spacing=SPACING_MD,
                    ),
                ],
                spacing=SPACING_MD,
            ),
            width=540,
            padding=ft.Padding.all(SPACING_XL),
            border_radius=RADIUS_XL,
            bgcolor=BG_GLASS_STRONG,
            border=ft.Border.all(1, "#30363D60"),
            shadow=SHADOW_CARD,
            blur=ft.Blur(15, 15, ft.BlurTileMode.CLAMP),
            animate_scale=ft.Animation(DURATION_SLOW, CURVE_BOUNCE),
            animate_opacity=ft.Animation(DURATION_SLOW, CURVE_DEFAULT),
            scale=0.88,
            opacity=0,
        )

        # ── Outer backdrop (semi-transparent, full screen) ────────────────────
        self.content = ft.Column(
            [self._card],
            alignment=ft.MainAxisAlignment.CENTER,
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            expand=True,
        )
        self.bgcolor = "#00000088"
        self.expand = True

        # Kick off initial validation
        self._refresh_validation()

    # ── Lifecycle ─────────────────────────────────────────────────────────────

    def did_mount(self):
        """Animate card in after mounting."""
        self.page.run_task(self._animate_in)

    async def _animate_in(self):
        await asyncio.sleep(0.04)
        self._card.scale = 1.0
        self._card.opacity = 1.0
        self._card.update()

    # ── Row building ──────────────────────────────────────────────────────────

    def _build_file_rows(self) -> list:
        """Build one row per file assignment with icon, name, dropdown, chip."""
        rows = []
        for i, a in enumerate(self._assignments):
            icon = _EXT_ICONS.get(a.ext, ft.Icons.INSERT_DRIVE_FILE_ROUNDED)
            icon_color = _EXT_COLORS.get(a.ext, TEXT_MUTED)

            # Role selector dropdown
            dd = ft.Dropdown(
                value=a.role,
                width=190,
                height=42,
                text_size=12,
                options=[
                    ft.dropdown.Option(key=v, text=label)
                    for label, v in ROLE_OPTIONS
                ],
                border_color=BORDER_DEFAULT,
                focused_border_color=ACCENT_PRIMARY,
                bgcolor=BG_CARD,
                color=TEXT_PRIMARY,
                on_change=lambda e, idx=i: self._on_role_change(idx, e.data),
            )
            self._row_dropdowns[i] = dd

            # Extension badge chip
            ext_chip = ft.Container(
                content=ft.Text(
                    f".{a.ext.upper()}" if a.ext else "?",
                    size=10, color=icon_color, weight=ft.FontWeight.W_700,
                ),
                bgcolor=f"{icon_color}18",
                border_radius=RADIUS_SM,
                padding=ft.Padding.symmetric(horizontal=6, vertical=2),
                border=ft.Border.all(1, f"{icon_color}40"),
                width=52,
                alignment=ft.Alignment(0, 0),
            )

            # Filename column (name + optional hint badge)
            name_controls = [
                ft.Text(
                    a.name, size=12, color=TEXT_PRIMARY,
                    weight=ft.FontWeight.W_500,
                    overflow=ft.TextOverflow.ELLIPSIS,
                    max_lines=1,
                    width=155,
                ),
            ]
            _hint_map = {
                "ref":      ("🏷 suggests: Reference", ACCENT_SECONDARY),
                "template": ("🏷 suggests: Template",  ACCENT_PRIMARY),
                "cal":      ("🏷 suggests: Calibration", ACCENT_TERTIARY),
            }
            if a.label_hint in _hint_map:
                hint_text, hint_color = _hint_map[a.label_hint]
                name_controls.append(
                    ft.Text(hint_text, size=10, color=hint_color, italic=True),
                )

            name_col = ft.Column(
                controls=name_controls,
                spacing=2,
                tight=True,
            )

            row = ft.Container(
                content=ft.Row(
                    [
                        ft.Icon(icon, size=18, color=icon_color),
                        ft.Container(content=name_col, expand=True),
                        dd,
                        ext_chip,
                    ],
                    spacing=SPACING_SM,
                    vertical_alignment=ft.CrossAxisAlignment.CENTER,
                ),
                bgcolor=f"{BG_CARD}88",
                border_radius=RADIUS_MD,
                border=ft.Border.all(1, "#30363D40"),
                padding=ft.Padding.symmetric(horizontal=SPACING_MD, vertical=SPACING_SM),
            )
            rows.append(row)
        return rows

    # ── Interactivity ─────────────────────────────────────────────────────────

    def _on_role_change(self, idx: int, new_role: str):
        """Update assignment and re-validate."""
        self._assignments[idx].role = new_role
        self._refresh_validation()

    def _refresh_validation(self):
        """Recompute conflicts, update warning banner and confirm button opacity."""
        refs  = [a for a in self._assignments if a.role == "ref"]
        cals  = [a for a in self._assignments if a.role == "calibration"]
        tmpls = [a for a in self._assignments if a.role == "template"]

        warnings = []
        if not refs:
            warnings.append("No reference logger assigned")
        if len(cals) == 0:
            warnings.append("No calibration file assigned")
        elif len(cals) > 1:
            warnings.append(f"{len(cals)} files assigned as Calibration — keep only 1")
        if len(tmpls) == 0:
            warnings.append("No template file assigned")
        elif len(tmpls) > 1:
            warnings.append(f"{len(tmpls)} files assigned as Template — keep only 1")

        is_valid = len(warnings) == 0

        if warnings:
            self._warning_text.value = " · ".join(warnings)
            self._warning_banner.visible = True
        else:
            self._warning_banner.visible = False

        # Dim the confirm button when invalid
        self._confirm_btn.opacity = 1.0 if is_valid else 0.38

        try:
            if self.page:
                self._warning_banner.update()
                self._confirm_btn.update()
        except Exception:
            pass

    def _on_confirm_click(self, e):
        """Gather confirmed assignments and fire the callback if valid."""
        refs  = [a for a in self._assignments if a.role == "ref"]
        cals  = [a for a in self._assignments if a.role == "calibration"]
        tmpls = [a for a in self._assignments if a.role == "template"]

        if not refs or len(cals) != 1 or len(tmpls) != 1:
            return  # Safety guard — button should look dimmed already

        self._on_confirm_cb(
            [a.path for a in refs],
            cals[0].path,
            tmpls[0].path,
        )

    def _on_confirm_hover(self, e: ft.HoverEvent):
        self._confirm_btn.scale = 1.04 if e.data == "true" else 1.0
        try:
            self._confirm_btn.update()
        except Exception:
            pass

    def _on_close_hover(self, e: ft.HoverEvent):
        btn = e.control
        btn.bgcolor = f"{ACCENT_DANGER}30" if e.data == "true" else "transparent"
        try:
            btn.update()
        except Exception:
            pass
