"""
HistoryView — browse past generation sessions.

Features:
- Session-level glassmorphic cards with cert count, warnings, elapsed time
- Expandable to show individual certificates with colour-coded temperature diffs
- Search/filter by serial or cert number
- Delete sessions with CASCADE cleanup
- Lazy-loading of certificate details on first expansion
"""

import platform
import subprocess
from pathlib import Path

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


def _diff_color(diff: float) -> str:
    """Colour-code a temperature difference."""
    if abs(diff) <= 0.3:
        return ACCENT_SECONDARY   # green
    if abs(diff) <= 0.5:
        return ACCENT_TERTIARY    # amber
    return ACCENT_DANGER          # red


def _format_datetime(iso_str: str) -> str:
    """Format ISO datetime to human readable."""
    try:
        from datetime import datetime
        dt = datetime.fromisoformat(iso_str)
        return dt.strftime("%Y-%m-%d  %H:%M")
    except Exception:
        return iso_str


class SessionCard(ft.Container):
    """An expandable card for a single generation session."""

    def __init__(self, session: dict, on_delete=None):
        super().__init__()
        self._session = session
        self._on_delete = on_delete
        self._expanded = False
        self._certs_loaded = False

        sid = session["id"]
        date_str = _format_datetime(session["created_at"])
        certs = session["cert_count"]
        warns = session["warning_count"]
        elapsed = session.get("elapsed_sec", 0)
        output_dir = session.get("output_dir", "")

        # Badges
        cert_badge = ft.Container(
            content=ft.Text(f"{certs} certs", size=11, color="#FFFFFF",
                            weight=ft.FontWeight.W_600),
            bgcolor=ACCENT_PRIMARY, border_radius=10,
            padding=ft.Padding.symmetric(horizontal=8, vertical=2),
        )
        warn_badge = ft.Container(
            content=ft.Text(f"{warns} ⚠", size=11, color="#FFFFFF",
                            weight=ft.FontWeight.W_600),
            bgcolor=ACCENT_TERTIARY if warns > 0 else ACCENT_SECONDARY,
            border_radius=10,
            padding=ft.Padding.symmetric(horizontal=8, vertical=2),
        )
        time_badge = ft.Container(
            content=ft.Text(f"{elapsed:.1f}s", size=11, color=TEXT_SECONDARY),
            bgcolor="#30363D60", border_radius=10,
            padding=ft.Padding.symmetric(horizontal=8, vertical=2),
        )

        # Action buttons
        folder_btn = ft.IconButton(
            icon=ft.Icons.FOLDER_OPEN_OUTLINED,
            icon_size=16, icon_color=TEXT_MUTED,
            tooltip="Open output folder",
            on_click=lambda _: self._open_folder(output_dir),
        )
        delete_btn = ft.IconButton(
            icon=ft.Icons.DELETE_OUTLINE_ROUNDED,
            icon_size=16, icon_color=TEXT_MUTED,
            tooltip="Delete session",
            on_click=lambda _: self._handle_delete(),
        )

        self._expand_icon = ft.Icon(
            ft.Icons.EXPAND_MORE_ROUNDED, size=20, color=TEXT_MUTED,
            rotate=ft.Rotate(0), animate_rotation=ft.Animation(DURATION_NORMAL, CURVE_DEFAULT),
        )

        # Header row
        self._header = ft.Container(
            content=ft.Row(
                [
                    ft.Column([
                        ft.Text(date_str, size=14, color=TEXT_PRIMARY,
                                weight=ft.FontWeight.W_600),
                        ft.Text(f"Session #{sid}", size=11, color=TEXT_MUTED),
                    ], spacing=2),
                    ft.Container(expand=True),
                    cert_badge, warn_badge, time_badge,
                    folder_btn, delete_btn,
                    self._expand_icon,
                ],
                vertical_alignment=ft.CrossAxisAlignment.CENTER,
                spacing=SPACING_SM,
            ),
            padding=ft.Padding.all(SPACING_MD),
            on_click=lambda _: self._toggle(),
        )

        # Certificate details (initially hidden)
        self._cert_table_container = ft.Container(
            visible=False,
            padding=ft.Padding.only(left=SPACING_MD, right=SPACING_MD, bottom=SPACING_MD),
        )

        self.content = ft.Column(
            [self._header, self._cert_table_container],
            spacing=0,
        )
        self.bgcolor = BG_GLASS_STRONG
        self.border_radius = RADIUS_LG
        self.border = ft.Border.all(1, "#30363D40")
        self.shadow = SHADOW_CARD
        self.animate = ft.Animation(DURATION_NORMAL, CURVE_DEFAULT)

    def _toggle(self):
        self._expanded = not self._expanded
        self._expand_icon.rotate = ft.Rotate(3.14159 if self._expanded else 0)

        if self._expanded and not self._certs_loaded:
            self._load_certificates()

        self._cert_table_container.visible = self._expanded
        try:
            self.update()
        except Exception:
            pass

    def _load_certificates(self):
        """Lazy-load certificate details from the database."""
        try:
            store = HistoryStore()
            certs = store.get_certificates(self._session["id"])
            store.close()
        except Exception:
            certs = []

        if not certs:
            self._cert_table_container.content = ft.Text(
                "No certificate data available", size=12, color=TEXT_MUTED,
            )
            self._certs_loaded = True
            return

        # Build data table
        columns = [
            ft.DataColumn(ft.Text("Cert No", size=11, color=TEXT_SECONDARY, weight=ft.FontWeight.W_600)),
            ft.DataColumn(ft.Text("Serial", size=11, color=TEXT_SECONDARY, weight=ft.FontWeight.W_600)),
            ft.DataColumn(ft.Text("-40°C", size=11, color=TEXT_SECONDARY, weight=ft.FontWeight.W_600)),
            ft.DataColumn(ft.Text("5°C", size=11, color=TEXT_SECONDARY, weight=ft.FontWeight.W_600)),
            ft.DataColumn(ft.Text("40°C", size=11, color=TEXT_SECONDARY, weight=ft.FontWeight.W_600)),
            ft.DataColumn(ft.Text("Status", size=11, color=TEXT_SECONDARY, weight=ft.FontWeight.W_600)),
        ]

        rows = []
        for cert in certs:
            cells = [
                ft.DataCell(ft.Text(cert["cert_no"], size=11, color=TEXT_PRIMARY)),
                ft.DataCell(ft.Text(cert["serial"], size=11, color=TEXT_PRIMARY)),
            ]

            # Temperature cells, ordered by target
            all_within = True
            target_map = {}
            for rec in cert.get("records", []):
                target_map[rec["target_c"]] = rec

            for target in [-40.0, 5.0, 40.0]:
                rec = target_map.get(target)
                if rec:
                    diff = rec["difference_c"]
                    color = _diff_color(diff)
                    cells.append(ft.DataCell(
                        ft.Text(f"{diff:+.2f}", size=11, color=color,
                                weight=ft.FontWeight.W_600)
                    ))
                    if rec["within_tolerance"] == 0:
                        all_within = False
                else:
                    cells.append(ft.DataCell(ft.Text("—", size=11, color=TEXT_MUTED)))

            status_text = "✅ Pass" if all_within else "⚠️ Review"
            status_color = ACCENT_SECONDARY if all_within else ACCENT_TERTIARY
            cells.append(ft.DataCell(
                ft.Text(status_text, size=11, color=status_color, weight=ft.FontWeight.W_600)
            ))

            rows.append(ft.DataRow(cells=cells))

        table = ft.DataTable(
            columns=columns,
            rows=rows,
            heading_row_height=32,
            data_row_min_height=36,
            column_spacing=SPACING_LG,
            border=ft.Border.all(1, "#30363D20"),
            border_radius=RADIUS_SM,
        )

        self._cert_table_container.content = ft.Column([
            ft.Container(height=1, bgcolor="#30363D20"),
            ft.Container(
                content=table,
                padding=ft.Padding.only(top=SPACING_SM),
            ),
        ], spacing=0)
        self._certs_loaded = True

    def _handle_delete(self):
        try:
            store = HistoryStore()
            store.delete_session(self._session["id"])
            store.close()
            if self._on_delete:
                self._on_delete(self._session["id"])
        except Exception:
            pass

    def _open_folder(self, output_dir):
        try:
            path = Path(output_dir)
            if platform.system() == "Darwin":
                subprocess.Popen(["open", str(path)])
            elif platform.system() == "Windows":
                subprocess.Popen(["explorer", str(path)])
            else:
                subprocess.Popen(["xdg-open", str(path)])
        except Exception:
            pass


class HistoryView(ft.Container):
    """Browse and manage past generation sessions."""

    def __init__(self, page: ft.Page, **kwargs):
        super().__init__(**kwargs)
        self._page = page
        self._all_sessions = []

        # Search field
        self._search = ft.TextField(
            hint_text="Filter by serial or cert number...",
            width=280, height=40, text_size=13,
            prefix_icon=ft.Icons.SEARCH_ROUNDED,
            border_color=BORDER_DEFAULT,
            focused_border_color=ACCENT_PRIMARY,
            color=TEXT_PRIMARY,
            on_change=self._on_search,
        )

        # Header
        self._header = ft.Container(
            content=ft.Row([
                ft.Icon(ft.Icons.HISTORY_ROUNDED, size=20, color=ACCENT_PRIMARY),
                ft.Text("History", size=18, color=TEXT_PRIMARY,
                        weight=ft.FontWeight.W_700, expand=True),
                self._search,
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

        # Sessions list
        self._sessions_list = ft.ListView(
            spacing=SPACING_SM,
            padding=ft.Padding.symmetric(horizontal=SPACING_XL, vertical=SPACING_SM),
            expand=True,
        )

        # Empty state
        self._empty_state = ft.Container(
            content=ft.Column([
                ft.Icon(ft.Icons.HISTORY_ROUNDED, size=64, color="#30363D60"),
                ft.Text("No generation history yet", size=16, color=TEXT_MUTED,
                        weight=ft.FontWeight.W_500),
                ft.Text("Run a generation to see sessions here", size=12,
                        color=TEXT_MUTED),
            ], horizontal_alignment=ft.CrossAxisAlignment.CENTER,
               alignment=ft.MainAxisAlignment.CENTER,
               spacing=SPACING_SM),
            expand=True, alignment=ft.Alignment(0, 0),
            visible=False,
        )

        # Loading indicator
        self._loading = ft.Container(
            content=ft.Column([
                ft.ProgressRing(width=32, height=32, color=ACCENT_PRIMARY),
                ft.Text("Loading history...", size=12, color=TEXT_MUTED),
            ], horizontal_alignment=ft.CrossAxisAlignment.CENTER,
               alignment=ft.MainAxisAlignment.CENTER,
               spacing=SPACING_SM),
            expand=True, alignment=ft.Alignment(0, 0),
            visible=True,
        )

        self.content = ft.Column([
            self._header,
            ft.Container(height=1, bgcolor="#30363D20"),
            ft.Stack([self._sessions_list, self._empty_state, self._loading],
                     expand=True),
        ], spacing=0, expand=True)
        self.expand = True
        self.bgcolor = BG_PRIMARY

    def did_mount(self):
        self._page.run_task(self._load_sessions)

    async def _load_sessions(self):
        import asyncio
        try:
            store = HistoryStore()
            self._all_sessions = store.list_sessions()
            store.close()
        except Exception:
            self._all_sessions = []

        self._loading.visible = False
        self._render_sessions(self._all_sessions)

    def _render_sessions(self, sessions: list):
        self._sessions_list.controls.clear()
        if not sessions:
            self._empty_state.visible = True
            self._sessions_list.visible = False
        else:
            self._empty_state.visible = False
            self._sessions_list.visible = True
            for s in sessions:
                card = SessionCard(s, on_delete=self._on_session_deleted)
                self._sessions_list.controls.append(card)

        try:
            self._sessions_list.update()
            self._empty_state.update()
            self._loading.update()
        except Exception:
            pass

    def _on_session_deleted(self, session_id: int):
        """Remove deleted session card from the list."""
        self._all_sessions = [s for s in self._all_sessions if s["id"] != session_id]
        self._render_sessions(self._all_sessions)

    def _on_search(self, e):
        query = (e.control.value or "").strip().lower()
        if not query:
            self._render_sessions(self._all_sessions)
            return

        # Filter by searching in certificates
        matching_session_ids = set()
        try:
            store = HistoryStore()
            for session in self._all_sessions:
                certs = store.get_certificates(session["id"])
                for cert in certs:
                    if (query in cert.get("cert_no", "").lower() or
                            query in cert.get("serial", "").lower()):
                        matching_session_ids.add(session["id"])
                        break
            store.close()
        except Exception:
            pass

        filtered = [s for s in self._all_sessions if s["id"] in matching_session_ids]
        self._render_sessions(filtered)

    def refresh(self):
        """Reload sessions from database."""
        self._loading.visible = True
        try:
            self._loading.update()
        except Exception:
            pass
        self._page.run_task(self._load_sessions)
