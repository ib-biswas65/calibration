"""
CustomTitleBar — Windows 11-style custom title bar.
Hidden on macOS in favor of native title bar.
Includes app icon, title, and window control buttons (minimize, maximize, close).
"""

import flet as ft
from ..theme import (
    BG_PRIMARY, TEXT_PRIMARY, TEXT_SECONDARY, TEXT_MUTED,
    ACCENT_DANGER, ACCENT_PRIMARY,
    SPACING_SM, SPACING_MD,
    DURATION_FAST, CURVE_DEFAULT,
    IS_WINDOWS, WINDOW_TITLE,
)


class TitleBarButton(ft.Container):
    """A single window control button (minimize/maximize/close)."""

    def __init__(self, icon: str, on_click=None, is_close: bool = False, **kwargs):
        super().__init__(**kwargs)
        self._is_close = is_close
        self._icon = ft.Icon(icon, size=16, color=TEXT_SECONDARY)

        self.content = self._icon
        self.width = 46
        self.height = 32
        self.alignment = ft.Alignment(0, 0)
        self.border_radius = 0
        self.on_click = on_click
        self.on_hover = self._on_hover
        self.animate = ft.Animation(DURATION_FAST, CURVE_DEFAULT)

    def _on_hover(self, e: ft.HoverEvent):
        if e.data == "true":
            self.bgcolor = ACCENT_DANGER if self._is_close else "#ffffff15"
            self._icon.color = "#FFFFFF"
        else:
            self.bgcolor = None
            self._icon.color = TEXT_SECONDARY
        self.update()


class CustomTitleBar(ft.Container):
    """
    Windows 11-style title bar with:
    - App icon and title
    - Minimize, Maximize, Close buttons
    - Draggable area
    - Only visible on Windows
    """

    def __init__(self, page: ft.Page, **kwargs):
        super().__init__(**kwargs)
        self._page = page

        # Title area (draggable)
        title_area = ft.WindowDragArea(
            content=ft.Row(
                controls=[
                    ft.Icon(
                        ft.Icons.SCIENCE_ROUNDED,
                        size=18,
                        color=ACCENT_PRIMARY,
                    ),
                    ft.Text(
                        WINDOW_TITLE,
                        size=12,
                        color=TEXT_PRIMARY,
                        weight=ft.FontWeight.W_500,
                    ),
                ],
                spacing=SPACING_SM,
                vertical_alignment=ft.CrossAxisAlignment.CENTER,
            ),
            expand=True,
        )

        # Window control buttons
        controls_row = ft.Row(
            controls=[
                TitleBarButton(
                    ft.Icons.MINIMIZE_ROUNDED,
                    on_click=self._minimize,
                ),
                TitleBarButton(
                    ft.Icons.CROP_SQUARE_ROUNDED,
                    on_click=self._maximize,
                ),
                TitleBarButton(
                    ft.Icons.CLOSE_ROUNDED,
                    on_click=self._close,
                    is_close=True,
                ),
            ],
            spacing=0,
        )

        self.content = ft.Row(
            controls=[title_area, controls_row],
            vertical_alignment=ft.CrossAxisAlignment.CENTER,
        )
        self.height = 32
        self.bgcolor = BG_PRIMARY
        self.padding = ft.Padding.only(left=SPACING_MD)

        # Only show on Windows
        self.visible = IS_WINDOWS

    def _minimize(self, e):
        self._page.window.minimized = True
        self._page.update()

    def _maximize(self, e):
        self._page.window.maximized = not self._page.window.maximized
        self._page.update()

    def _close(self, e):
        self._page.window.close()
