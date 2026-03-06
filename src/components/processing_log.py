"""
ProcessingLog — real-time animated log panel.
Each entry slides in from bottom with color-coding:
  info (white), warning (amber), success (green), error (red).
"""

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
    """A single animated log entry."""

    def __init__(self, message: str, level: str = "info"):
        super().__init__()
        color = LEVEL_COLORS.get(level, TEXT_SECONDARY)
        icon = LEVEL_ICONS.get(level, ft.Icons.INFO_OUTLINE_ROUNDED)

        self.content = ft.Row(
            controls=[
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
        self.padding = ft.padding.symmetric(horizontal=12, vertical=4)
        self.animate_opacity = ft.Animation(DURATION_NORMAL, CURVE_DEFAULT)
        self.opacity = 0


class ProcessingLog(ft.Container):
    """
    Real-time processing log panel with:
    - Animated entry slide-in
    - Color-coded levels
    - Auto-scroll to bottom
    - Monospace font for alignment
    """

    def __init__(self, max_visible: int = 200, **kwargs):
        super().__init__(**kwargs)
        self.max_visible = max_visible
        self._entries = []

        self._header = ft.Row(
            controls=[
                ft.Icon(ft.Icons.TERMINAL_ROUNDED, size=16, color=ACCENT_PRIMARY),
                ft.Text(
                    "Processing Log",
                    size=13,
                    color=TEXT_PRIMARY,
                    weight=ft.FontWeight.W_600,
                ),
            ],
            spacing=SPACING_SM,
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
        self.padding = ft.padding.all(12)
        self.expand = True

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
