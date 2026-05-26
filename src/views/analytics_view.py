"""
AnalyticsView — aggregated insights from generation history.

Features:
- Stat cards: total sessions, total certs, warning rate, avg |Δ temp|
- Recent trends table (last 10 sessions)
- Per-temperature-target performance cards with left-accent border
- Async loading with progress ring
"""

import flet as ft

from ..theme import (
    BG_PRIMARY, BG_SECONDARY, BG_CARD, BG_GLASS_STRONG,
    ACCENT_PRIMARY, ACCENT_SECONDARY, ACCENT_TERTIARY, ACCENT_DANGER,
    TEXT_PRIMARY, TEXT_SECONDARY, TEXT_MUTED,
    BORDER_DEFAULT,
    RADIUS_SM, RADIUS_MD, RADIUS_LG,
    SPACING_XS, SPACING_SM, SPACING_MD, SPACING_LG, SPACING_XL,
    DURATION_NORMAL, DURATION_SLOW,
    CURVE_DEFAULT, STAGGER_DELAY,
    SHADOW_CARD,
)
from ..engine import HistoryStore


def _format_date_short(iso_str: str) -> str:
    try:
        from datetime import datetime
        dt = datetime.fromisoformat(iso_str)
        return dt.strftime("%m/%d %H:%M")
    except Exception:
        return iso_str[:10]


class StatCard(ft.Container):
    """A single stat card with large number and label."""

    def __init__(self, label: str, value: str, color: str = ACCENT_PRIMARY):
        super().__init__()
        self.content = ft.Column(
            [
                ft.Text(value, size=28, color=color, weight=ft.FontWeight.W_700),
                ft.Text(label, size=12, color=TEXT_SECONDARY),
            ],
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            spacing=SPACING_XS,
        )
        self.bgcolor = BG_GLASS_STRONG
        self.border_radius = RADIUS_LG
        self.border = ft.Border.all(1, "#30363D40")
        self.padding = ft.Padding.all(SPACING_LG)
        self.shadow = SHADOW_CARD
        self.expand = True
        self.alignment = ft.Alignment(0, 0)


class TempPerformanceCard(ft.Container):
    """Performance card for a specific temperature target."""

    def __init__(self, target_label: str, accent_color: str, stats: dict):
        super().__init__()

        avg_ref = stats.get("avg_ref", 0)
        avg_actual = stats.get("avg_actual", 0)
        avg_diff = stats.get("avg_abs_diff", 0)
        pct_within = stats.get("pct_within", 0)

        rows = [
            ("Avg Reference", f"{avg_ref:.2f}°C"),
            ("Avg Actual", f"{avg_actual:.2f}°C"),
            ("Avg |Δ|", f"{avg_diff:.3f}°C"),
            ("Within ±0.5", f"{pct_within:.1f}%"),
        ]

        row_controls = []
        for label, val in rows:
            row_controls.append(
                ft.Row([
                    ft.Text(label, size=11, color=TEXT_MUTED, expand=True),
                    ft.Text(val, size=11, color=TEXT_PRIMARY, weight=ft.FontWeight.W_600),
                ], spacing=SPACING_SM)
            )

        self.content = ft.Column(
            [
                ft.Text(target_label, size=14, color=accent_color,
                        weight=ft.FontWeight.W_700),
                ft.Container(height=SPACING_XS),
                *row_controls,
            ],
            spacing=SPACING_XS,
        )
        self.bgcolor = BG_GLASS_STRONG
        self.border_radius = RADIUS_LG
        self.border = ft.Border(
            left=ft.BorderSide(3, accent_color),
            top=ft.BorderSide(1, "#30363D40"),
            right=ft.BorderSide(1, "#30363D40"),
            bottom=ft.BorderSide(1, "#30363D40"),
        )
        self.padding = ft.Padding.all(SPACING_MD)
        self.shadow = SHADOW_CARD
        self.expand = True


class AnalyticsView(ft.Container):
    """Aggregated analytics and insights from generation history."""

    def __init__(self, page: ft.Page, **kwargs):
        super().__init__(**kwargs)
        self._page = page

        # Header
        self._header = ft.Container(
            content=ft.Row([
                ft.Icon(ft.Icons.BAR_CHART_ROUNDED, size=20, color=ACCENT_PRIMARY),
                ft.Text("Analytics & Insights", size=18, color=TEXT_PRIMARY,
                        weight=ft.FontWeight.W_700, expand=True),
                ft.IconButton(
                    icon=ft.Icons.REFRESH_ROUNDED,
                    icon_size=20, icon_color=TEXT_MUTED,
                    tooltip="Refresh",
                    on_click=lambda _: self.refresh(),
                ),
            ], vertical_alignment=ft.CrossAxisAlignment.CENTER,
               spacing=SPACING_SM),
            padding=ft.Padding.symmetric(horizontal=SPACING_XL, vertical=SPACING_MD),
        )

        # Content area (populated after loading)
        self._content_area = ft.Container(expand=True)

        # Loading indicator
        self._loading = ft.Container(
            content=ft.Column([
                ft.ProgressRing(width=32, height=32, color=ACCENT_PRIMARY),
                ft.Text("Loading analytics...", size=12, color=TEXT_MUTED),
            ], horizontal_alignment=ft.CrossAxisAlignment.CENTER,
               alignment=ft.MainAxisAlignment.CENTER,
               spacing=SPACING_SM),
            expand=True, alignment=ft.Alignment(0, 0),
        )

        # Empty state
        self._empty_state = ft.Container(
            content=ft.Column([
                ft.Icon(ft.Icons.BAR_CHART_ROUNDED, size=64, color="#30363D60"),
                ft.Text("No data yet", size=16, color=TEXT_MUTED,
                        weight=ft.FontWeight.W_500),
                ft.Text("Complete a generation session to see analytics", size=12,
                        color=TEXT_MUTED),
            ], horizontal_alignment=ft.CrossAxisAlignment.CENTER,
               alignment=ft.MainAxisAlignment.CENTER,
               spacing=SPACING_SM),
            expand=True, alignment=ft.Alignment(0, 0),
            visible=False,
        )

        self.content = ft.Column([
            self._header,
            ft.Container(height=1, bgcolor="#30363D20"),
            ft.Stack([self._content_area, self._loading, self._empty_state],
                     expand=True),
        ], spacing=0, expand=True)
        self.expand = True
        self.bgcolor = BG_PRIMARY

    def did_mount(self):
        self._page.run_task(self._load_analytics)

    async def _load_analytics(self):
        try:
            store = HistoryStore()
            data = store.get_analytics()
            store.close()
        except Exception:
            data = None

        self._loading.visible = False

        if not data or data["total_sessions"] == 0:
            self._empty_state.visible = True
            try:
                self._empty_state.update()
                self._loading.update()
            except Exception:
                pass
            return

        self._empty_state.visible = False
        self._build_dashboard(data)
        try:
            self._content_area.update()
            self._loading.update()
            self._empty_state.update()
        except Exception:
            pass

    def _build_dashboard(self, data: dict):
        """Build the analytics dashboard from aggregated data."""

        # Stat cards
        warn_color = ACCENT_TERTIARY if data["warning_rate_pct"] > 0 else ACCENT_SECONDARY
        stat_row = ft.Row([
            StatCard("Total Sessions", str(data["total_sessions"]), ACCENT_PRIMARY),
            StatCard("Total Certificates", str(data["total_certs"]), ACCENT_SECONDARY),
            StatCard("Warning Rate", f"{data['warning_rate_pct']}%", warn_color),
            StatCard("Avg |Δ Temp|", f"{data['avg_abs_diff']:.3f}°C", ACCENT_PRIMARY),
        ], spacing=SPACING_MD)

        # Recent trends table
        trends_columns = [
            ft.DataColumn(ft.Text("Date", size=11, color=TEXT_SECONDARY, weight=ft.FontWeight.W_600)),
            ft.DataColumn(ft.Text("Certs", size=11, color=TEXT_SECONDARY, weight=ft.FontWeight.W_600)),
            ft.DataColumn(ft.Text("Warnings", size=11, color=TEXT_SECONDARY, weight=ft.FontWeight.W_600)),
            ft.DataColumn(ft.Text("Avg Δ", size=11, color=TEXT_SECONDARY, weight=ft.FontWeight.W_600)),
            ft.DataColumn(ft.Text("Duration", size=11, color=TEXT_SECONDARY, weight=ft.FontWeight.W_600)),
        ]

        trends_rows = []
        for s in data["per_session_stats"][:10]:
            avg_diff = s.get("avg_diff", 0)
            diff_color = ACCENT_SECONDARY if avg_diff <= 0.3 else (
                ACCENT_TERTIARY if avg_diff <= 0.5 else ACCENT_DANGER
            )
            trends_rows.append(ft.DataRow(cells=[
                ft.DataCell(ft.Text(_format_date_short(s["created_at"]), size=11, color=TEXT_PRIMARY)),
                ft.DataCell(ft.Text(str(s["cert_count"]), size=11, color=TEXT_PRIMARY)),
                ft.DataCell(ft.Text(str(s["warning_count"]), size=11,
                                    color=ACCENT_TERTIARY if s["warning_count"] > 0 else TEXT_PRIMARY)),
                ft.DataCell(ft.Text(f"{avg_diff:.3f}°C", size=11, color=diff_color,
                                    weight=ft.FontWeight.W_600)),
                ft.DataCell(ft.Text(f"{s['elapsed_sec']:.1f}s", size=11, color=TEXT_MUTED)),
            ]))

        trends_card = ft.Container(
            content=ft.Column([
                ft.Text("Recent Trends", size=14, color=TEXT_PRIMARY,
                        weight=ft.FontWeight.W_600),
                ft.DataTable(
                    columns=trends_columns,
                    rows=trends_rows,
                    heading_row_height=32,
                    data_row_min_height=36,
                    column_spacing=SPACING_XL,
                    border=ft.Border.all(1, "#30363D20"),
                    border_radius=RADIUS_SM,
                ) if trends_rows else ft.Text("No sessions yet", size=12, color=TEXT_MUTED),
            ], spacing=SPACING_SM),
            bgcolor=BG_GLASS_STRONG,
            border_radius=RADIUS_LG,
            border=ft.Border.all(1, "#30363D40"),
            padding=ft.Padding.all(SPACING_MD),
            shadow=SHADOW_CARD,
        )

        # Per-target performance cards
        target_colors = {-40.0: ACCENT_PRIMARY, 5.0: ACCENT_SECONDARY, 40.0: ACCENT_TERTIARY}
        target_labels = {-40.0: "-40 °C", 5.0: "5 °C", 40.0: "40 °C"}

        target_cards = []
        for target_stat in data["per_target_stats"]:
            tc = target_stat["target_c"]
            color = target_colors.get(tc, ACCENT_PRIMARY)
            label = target_labels.get(tc, f"{tc}°C")
            target_cards.append(TempPerformanceCard(label, color, target_stat))

        if not target_cards:
            target_cards = [ft.Text("No temperature data yet", size=12, color=TEXT_MUTED)]

        temp_section = ft.Container(
            content=ft.Column([
                ft.Text("Temperature Performance", size=14, color=TEXT_PRIMARY,
                        weight=ft.FontWeight.W_600),
                ft.Container(height=SPACING_XS),
                ft.Row(target_cards, spacing=SPACING_MD),
            ], spacing=SPACING_SM),
            bgcolor=BG_GLASS_STRONG,
            border_radius=RADIUS_LG,
            border=ft.Border.all(1, "#30363D40"),
            padding=ft.Padding.all(SPACING_MD),
            shadow=SHADOW_CARD,
        )

        self._content_area.content = ft.Column([
            ft.Container(
                content=ft.Column([
                    stat_row,
                    ft.Container(height=SPACING_MD),
                    trends_card,
                    ft.Container(height=SPACING_MD),
                    temp_section,
                ], spacing=0),
                padding=ft.Padding.symmetric(horizontal=SPACING_XL, vertical=SPACING_MD),
                expand=True,
            ),
        ], scroll=ft.ScrollMode.AUTO, expand=True)

    def refresh(self):
        """Reload analytics from database."""
        self._loading.visible = True
        self._content_area.content = None
        try:
            self._loading.update()
            self._content_area.update()
        except Exception:
            pass
        self._page.run_task(self._load_analytics)
