"""
ProcessingLog — real-time animated log panel.
Each entry slides in from bottom with color-coding:
  info (white), warning (amber), success (green), error (red).
Includes HH:MM:SS timestamps, Copy Log, and Export Log buttons.
"""

from datetime import datetime
from pathlib import Path

import flet as ft
from ..theme import (
    ACCENT_PRIMARY, ACCENT_SECONDARY, ACCENT_TERTIARY, ACCENT_DANGER,
    BG_SECONDARY, TEXT_PRIMARY, TEXT_SECONDARY, TEXT_MUTED,
    RADIUS_MD, SPACING_SM, SPACING_XS,
    DURATION_NORMAL, DURATION_FAST, CURVE_DEFAULT, STAGGER_DELAY,
)


LEVEL_COLORS = {
    "info": TEXT_SECONDARY,
    "warning": ACCENT_TERTIARY,
    "success": ACCENT_SECONDARY,
    "error": ACCENT_DANGER,
}

LEVEL_ICONS = {
    "info": ft.Icons.INFO_OUTLINE_ROUNDED,
    "warning": ft.Icons.WARNING_AMBER_ROUNDED,
    "success": ft.Icons.CHECK_CIRCLE_OUTLINE_ROUNDED,
    "error": ft.Icons.ERROR_OUTLINE_ROUNDED,
}


class LogEntry(ft.Container):
    """A single animated log entry with timestamp."""

    def __init__(self, message: str, level: str = "info"):
        super().__init__()
        color = LEVEL_COLORS.get(level, TEXT_SECONDARY)
        icon = LEVEL_ICONS.get(level, ft.Icons.INFO_OUTLINE_ROUNDED)
        timestamp = datetime.now().strftime("%H:%M:%S")

        self.content = ft.Row(
            controls=[
                ft.Text(
                    timestamp, size=11, color=TEXT_MUTED,
                    font_family="monospace", width=65,
                ),
                ft.Icon(icon, size=14, color=color),
                ft.Text(
                    message,
                    size=12,
                    color=color,
                    font_family="monospace",
                    selectable=True,
                    expand=True,
                    max_lines=2,
                    overflow=ft.TextOverflow.ELLIPSIS,
                ),
            ],
            spacing=SPACING_SM,
            vertical_alignment=ft.CrossAxisAlignment.START,
        )
        self.padding = ft.Padding.symmetric(horizontal=12, vertical=4)
        self.animate_opacity = ft.Animation(DURATION_NORMAL, CURVE_DEFAULT)
        self.opacity = 0
        # Store raw data for export
        self._timestamp = timestamp
        self._message = message
        self._level = level


class ProcessingLog(ft.Container):
    """
    Real-time processing log panel with:
    - HH:MM:SS timestamps on every entry
    - Animated entry slide-in
    - Color-coded levels
    - Auto-scroll to bottom
    - Copy Log and Export Log buttons
    """

    def __init__(self, max_visible: int = 200, **kwargs):
        super().__init__(**kwargs)
        self.max_visible = max_visible
        self._entries: list[LogEntry] = []
        self._page_ref = None

        self._copy_btn = ft.IconButton(
            icon=ft.Icons.CONTENT_COPY_ROUNDED,
            icon_size=14,
            icon_color=TEXT_MUTED,
            tooltip="Copy log to clipboard",
            on_click=self._copy_log,
        )
        self._export_btn = ft.IconButton(
            icon=ft.Icons.SAVE_ALT_ROUNDED,
            icon_size=14,
            icon_color=TEXT_MUTED,
            tooltip="Export log as .txt",
            on_click=self._export_log,
        )

        self._header = ft.Row(
            controls=[
                ft.Icon(ft.Icons.TERMINAL_ROUNDED, size=16, color=ACCENT_PRIMARY),
                ft.Text(
                    "Processing Log",
                    size=13,
                    color=TEXT_PRIMARY,
                    weight=ft.FontWeight.W_600,
                    expand=True,
                ),
                self._copy_btn,
                self._export_btn,
            ],
            spacing=SPACING_SM,
            vertical_alignment=ft.CrossAxisAlignment.CENTER,
        )

        self._log_column = ft.Column(
            controls=[],
            spacing=2,
            scroll=ft.ScrollMode.AUTO,
            auto_scroll=True,
            expand=True,
        )

        self.content = ft.Column(
            controls=[
                self._header,
                ft.Container(height=1, bgcolor="#30363D20"),
                self._log_column,
            ],
            spacing=SPACING_SM,
            expand=True,
        )

        self.bgcolor = BG_SECONDARY
        self.border_radius = RADIUS_MD
        self.padding = ft.Padding.all(12)
        self.expand = True

    def _get_log_text(self) -> str:
        """Build plain-text representation of the log."""
        lines = []
        for e in self._entries:
            lines.append(f"[{e._timestamp}] [{e._level.upper():7s}] {e._message}")
        return "\n".join(lines)

    def _copy_log(self, e):
        """Copy log to clipboard."""
        try:
            page = e.page or self._page_ref
            if page:
                page.set_clipboard(self._get_log_text())
                page.open(ft.SnackBar(
                    content=ft.Text("Log copied to clipboard", color="#FFFFFF"),
                    bgcolor=ACCENT_SECONDARY, duration=2000,
                ))
        except Exception:
            pass

    def _export_log(self, e):
        """Export log as .txt file alongside certificates."""
        try:
            text = self._get_log_text()
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            path = Path.home() / "Desktop" / f"calibration_log_{timestamp}.txt"
            path.write_text(text, encoding="utf-8")
            page = e.page or self._page_ref
            if page:
                page.open(ft.SnackBar(
                    content=ft.Text(f"Log saved to {path.name}", color="#FFFFFF"),
                    bgcolor=ACCENT_SECONDARY, duration=3000,
                ))
        except Exception:
            pass

    def add_entry(self, message: str, level: str = "info"):
        """Add a log entry with animation."""
        entry = LogEntry(message, level)
        self._entries.append(entry)

        # Trim if too many
        if len(self._entries) > self.max_visible:
            removed = self._entries.pop(0)
            if removed in self._log_column.controls:
                self._log_column.controls.remove(removed)

        self._log_column.controls.append(entry)

        try:
            self.update()
            # Animate opacity after adding
            entry.opacity = 1.0
            entry.update()
        except Exception:
            pass

    def clear(self):
        """Clear all entries."""
        self._entries.clear()
        self._log_column.controls.clear()
        try:
            self.update()
        except Exception:
            pass
