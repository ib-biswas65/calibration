#!/usr/bin/env python3
"""
Calibration Pro Desktop — main entry point.

A premium cross-platform desktop application for generating
calibration certificates. Built with Flet (Flutter-backed).

Usage:
    python -m src.main
    # or
    flet run src/main.py
"""

import sys
import platform
from pathlib import Path
import flet as ft

# Ensure project root is in sys.path so 'flet run src/main.py' works
project_root = str(Path(__file__).parent.parent.absolute())
if project_root not in sys.path:
    sys.path.insert(0, project_root)

from src.theme import (
    BG_PRIMARY, ACCENT_PRIMARY, TEXT_PRIMARY,
    WINDOW_MIN_WIDTH, WINDOW_MIN_HEIGHT, WINDOW_TITLE,
    IS_WINDOWS, FONT_PRIMARY, FONT_FALLBACK,
)
from src.components.custom_title_bar import CustomTitleBar
from src.views.login_view import LoginView
from src.views.dashboard_view import DashboardView


async def main(page: ft.Page):
    """Configure the Flet page and show the login screen."""

    # ── Window Configuration ──
    page.title = WINDOW_TITLE
    page.bgcolor = BG_PRIMARY
    page.padding = 0
    page.spacing = 0

    page.window.min_width = WINDOW_MIN_WIDTH
    page.window.min_height = WINDOW_MIN_HEIGHT
    page.window.width = 1200
    page.window.height = 800
    page.window.center()

    # Windows: frameless for custom title bar and prevent accidental close
    if IS_WINDOWS:
        page.window.title_bar_hidden = True
        page.window.prevent_close = True

        def on_window_event(e):
            if e.data == "close":
                page.window.destroy()

        page.window.on_event = on_window_event

    # ── Theme ──
    page.theme = ft.Theme(
        color_scheme_seed=ACCENT_PRIMARY,
        font_family=FONT_PRIMARY,
    )
    page.theme_mode = ft.ThemeMode.DARK

    # ── Custom title bar (Windows only) ──
    title_bar = CustomTitleBar(page)

    # ── Navigation ──
    async def navigate_to_dashboard():
        """Called by LoginView after enter animation completes."""
        page.controls.clear()
        page.overlay.clear()  # FIX: Prevent overlay accumulation
        if IS_WINDOWS:
            page.controls.append(title_bar)
        dashboard = DashboardView(page)
        page.controls.append(dashboard)
        page.update()

    # ── Initial View: Login ──
    login = LoginView(page, on_enter=navigate_to_dashboard)

    if IS_WINDOWS:
        page.controls.append(title_bar)
    page.controls.append(login)
    page.update()


if __name__ == "__main__":
    ft.app(target=main)
