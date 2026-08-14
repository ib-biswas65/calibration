"""
AppShell — main application shell with NavigationRail.

Provides VS Code / LabVIEW aesthetic left nav with:
- Generate (DashboardView)
- History (HistoryView, lazy-loaded)
- Analytics (AnalyticsView, lazy-loaded)

Content area uses fade transitions on view switch.
"""

import flet as ft

from ..theme import (
    BG_PRIMARY, BG_SECONDARY,
    ACCENT_PRIMARY,
    TEXT_PRIMARY, TEXT_MUTED,
    BORDER_DEFAULT,
    SPACING_SM, SPACING_MD,
    DURATION_NORMAL, CURVE_DEFAULT,
)
from .dashboard_view import DashboardView


class AppShell(ft.Container):
    """Main shell with NavigationRail and content area."""

    def __init__(self, page: ft.Page, **kwargs):
        super().__init__(**kwargs)
        self._page = page
        self._history_view = None   # lazy-created
        self._analytics_view = None  # lazy-created

        self._dashboard = DashboardView(
            page,
            on_generation_complete=self._on_generation_complete,
        )

        self._nav_rail = ft.NavigationRail(
            selected_index=0,
            extended=False,
            min_width=64,
            min_extended_width=170,
            bgcolor=BG_SECONDARY,
            indicator_color=f"{ACCENT_PRIMARY}22",
            leading=ft.Container(
                content=ft.Column([
                    ft.Icon(ft.Icons.SCIENCE_ROUNDED, color=ACCENT_PRIMARY, size=24),
                    ft.Text("v0.0.2", size=9, color=TEXT_MUTED),
                ], horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=2),
                padding=ft.Padding.only(top=SPACING_MD, bottom=SPACING_SM),
            ),
            destinations=[
                ft.NavigationRailDestination(
                    icon=ft.Icons.SCIENCE_OUTLINED,
                    selected_icon=ft.Icons.SCIENCE_ROUNDED,
                    label="Generate",
                ),
                ft.NavigationRailDestination(
                    icon=ft.Icons.HISTORY_OUTLINED,
                    selected_icon=ft.Icons.HISTORY_ROUNDED,
                    label="History",
                ),
                ft.NavigationRailDestination(
                    icon=ft.Icons.BAR_CHART_OUTLINED,
                    selected_icon=ft.Icons.BAR_CHART_ROUNDED,
                    label="Analytics",
                ),
            ],
            on_change=self._on_nav_change,
        )

        self._content_area = ft.Container(
            content=self._dashboard,
            expand=True,
            animate_opacity=ft.Animation(DURATION_NORMAL, CURVE_DEFAULT),
        )

        self.content = ft.Row(
            [
                self._nav_rail,
                ft.VerticalDivider(width=1, color=BORDER_DEFAULT),
                self._content_area,
            ],
            expand=True,
            spacing=0,
        )
        self.expand = True

    def _on_nav_change(self, e):
        idx = e.control.selected_index

        # Fade out
        self._content_area.opacity = 0
        self._content_area.update()

        if idx == 0:
            self._content_area.content = self._dashboard
        elif idx == 1:
            if not self._history_view:
                from .history_view import HistoryView
                self._history_view = HistoryView(self._page)
            else:
                self._history_view.refresh()
            self._content_area.content = self._history_view
        else:
            if not self._analytics_view:
                from .analytics_view import AnalyticsView
                self._analytics_view = AnalyticsView(self._page)
            else:
                self._analytics_view.refresh()
            self._content_area.content = self._analytics_view

        # Fade in
        self._content_area.opacity = 1
        self._content_area.update()

    def _on_generation_complete(self, session_id: int):
        """Called by DashboardView after a successful run."""
        if self._history_view:
            self._history_view.refresh()
        if self._analytics_view:
            self._analytics_view.refresh()
