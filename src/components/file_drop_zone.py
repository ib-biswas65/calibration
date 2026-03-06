"""
FileDropZone — file selector component.
Animated hover highlight, green checkmark on accept.
Does NOT own a FilePicker — the parent view handles file picking
and calls accept_file() on this component.
"""

import asyncio
import flet as ft
from pathlib import Path
from ..theme import (
    ACCENT_PRIMARY, ACCENT_SECONDARY, ACCENT_DANGER,
    BG_CARD, BG_CARD_HOVER, BORDER_DEFAULT, BORDER_ACTIVE,
    TEXT_PRIMARY, TEXT_SECONDARY, TEXT_MUTED,
    RADIUS_LG, SPACING_MD, SPACING_SM,
    DURATION_NORMAL, DURATION_FAST, CURVE_DEFAULT,
)


class FileDropZone(ft.Container):
    """
    A file zone with:
    - Hover animation
    - Click triggers parent's on_browse callback
    - Green checkmark when file is accepted
    - Shake animation for validation errors
    """

    def __init__(
        self,
        label: str,
        zone_key: str,
        icon: str = ft.Icons.UPLOAD_FILE_ROUNDED,
        on_browse=None,
        **kwargs,
    ):
        super().__init__(**kwargs)
        self.label_text = label
        self.zone_key = zone_key
        self.icon_name = icon
        self._on_browse = on_browse
        self.selected_path: str = ""

        # State
        self._is_hovered = False
        self._is_accepted = False

        # UI elements
        self._icon = ft.Icon(
            icon,
            size=32,
            color=TEXT_SECONDARY,
            animate_opacity=ft.Animation(DURATION_NORMAL, CURVE_DEFAULT),
            animate_scale=ft.Animation(DURATION_NORMAL, CURVE_DEFAULT),
        )
        self._label = ft.Text(
            label,
            size=13,
            color=TEXT_SECONDARY,
            weight=ft.FontWeight.W_500,
            text_align=ft.TextAlign.CENTER,
        )
        self._sublabel = ft.Text(
            "Click to browse",
            size=11,
            color=TEXT_MUTED,
            text_align=ft.TextAlign.CENTER,
        )
        self._filename_text = ft.Text(
            "",
            size=11,
            color=ACCENT_SECONDARY,
            weight=ft.FontWeight.W_600,
            text_align=ft.TextAlign.CENTER,
            max_lines=1,
            overflow=ft.TextOverflow.ELLIPSIS,
            visible=False,
        )
        self._check_icon = ft.Icon(
            ft.Icons.CHECK_CIRCLE_ROUNDED,
            size=28,
            color=ACCENT_SECONDARY,
            visible=False,
            animate_opacity=ft.Animation(DURATION_NORMAL, CURVE_DEFAULT),
            animate_scale=ft.Animation(DURATION_NORMAL, CURVE_DEFAULT),
        )

        # Build container
        self.content = ft.Column(
            controls=[
                self._icon,
                self._check_icon,
                self._label,
                self._sublabel,
                self._filename_text,
            ],
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            alignment=ft.MainAxisAlignment.CENTER,
            spacing=SPACING_SM,
        )

        self.width = 240
        self.height = 160
        self.border_radius = RADIUS_LG
        self.bgcolor = BG_CARD
        self.border = ft.border.all(1.5, BORDER_DEFAULT)
        self.padding = SPACING_MD
        self.alignment = ft.Alignment(0, 0)
        self.animate = ft.Animation(DURATION_NORMAL, CURVE_DEFAULT)
        self.on_click = self._on_click
        self.on_hover = self._on_hover

    def _on_hover(self, e: ft.HoverEvent):
        self._is_hovered = e.data == "true"
        if not self._is_accepted:
            self.bgcolor = BG_CARD_HOVER if self._is_hovered else BG_CARD
            self.border = ft.border.all(
                1.5, ACCENT_PRIMARY if self._is_hovered else BORDER_DEFAULT
            )
            self._icon.color = ACCENT_PRIMARY if self._is_hovered else TEXT_SECONDARY
            self._icon.scale = 1.1 if self._is_hovered else 1.0
        self.update()

    def _on_click(self, e):
        """Notify parent to open file picker for this zone."""
        if self._on_browse:
            self._on_browse(self.zone_key)

    def accept_file(self, file_path: str, file_name: str):
        """Called by parent when a file is selected for this zone."""
        self._is_accepted = True
        self.selected_path = file_path

        # Switch visuals
        self._icon.visible = False
        self._check_icon.visible = True
        self._check_icon.opacity = 1.0
        self._check_icon.scale = 1.0
        self._sublabel.visible = False
        self._filename_text.value = file_name
        self._filename_text.visible = True
        self._label.color = TEXT_PRIMARY
        self.bgcolor = BG_CARD
        self.border = ft.border.all(1.5, ACCENT_SECONDARY)
        self.update()

    def reset(self):
        """Reset to initial state."""
        self._is_accepted = False
        self.selected_path = ""
        self._icon.visible = True
        self._icon.color = TEXT_SECONDARY
        self._icon.scale = 1.0
        self._check_icon.visible = False
        self._sublabel.visible = True
        self._filename_text.visible = False
        self._label.color = TEXT_SECONDARY
        self.bgcolor = BG_CARD
        self.border = ft.border.all(1.5, BORDER_DEFAULT)
        self.update()

    def shake(self):
        """Shake animation for validation error."""
        async def _shake():
            offsets = [10, -10, 8, -8, 4, -4, 0]
            for dx in offsets:
                self.offset = ft.Offset(dx / 100, 0)
                self.update()
                await asyncio.sleep(0.04)
            self.border = ft.border.all(1.5, ACCENT_DANGER)
            self.update()

        if self.page:
            self.page.run_task(_shake)
