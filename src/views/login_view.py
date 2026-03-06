"""
LoginView — premium splash/login screen with:
- Frosted glass card centered on gradient background
- Staggered entrance: logo → title → subtitle → button (50ms delays)
- CrossFade button → spinner transition (300ms)
- Hero transition: logo animates to corner on navigate
"""

import asyncio
import flet as ft
from ..theme import (
    BG_PRIMARY, BG_GLASS_STRONG, ACCENT_PRIMARY, ACCENT_SECONDARY,
    TEXT_PRIMARY, TEXT_SECONDARY, TEXT_MUTED,
    GRADIENT_HERO, RADIUS_XL, RADIUS_LG,
    SPACING_SM, SPACING_MD, SPACING_LG, SPACING_XL,
    DURATION_NORMAL, DURATION_SLOW, DURATION_HERO,
    CURVE_DEFAULT, CURVE_BOUNCE, STAGGER_DELAY,
    SHADOW_CARD, SHADOW_GLOW,
    WINDOW_TITLE,
)


class LoginView(ft.Container):
    """Animated login/splash screen."""

    def __init__(self, page: ft.Page, on_enter=None, **kwargs):
        super().__init__(**kwargs)
        self._page = page
        self._on_enter = on_enter

        # ── Animated elements (start invisible) ──
        self._logo_icon = ft.Icon(
            ft.Icons.SCIENCE_ROUNDED,
            size=64,
            color=ACCENT_PRIMARY,
        )
        self._logo_container = ft.Container(
            content=self._logo_icon,
            width=100,
            height=100,
            border_radius=RADIUS_XL,
            bgcolor="#58A6FF15",
            alignment=ft.Alignment(0, 0),
            animate=ft.Animation(DURATION_HERO, CURVE_DEFAULT),
            animate_scale=ft.Animation(DURATION_SLOW, CURVE_BOUNCE),
            animate_opacity=ft.Animation(DURATION_SLOW, CURVE_DEFAULT),
            scale=0.5,
            opacity=0,
        )

        self._title = ft.Text(
            WINDOW_TITLE,
            size=28,
            color=TEXT_PRIMARY,
            weight=ft.FontWeight.W_700,
            text_align=ft.TextAlign.CENTER,
            animate_opacity=ft.Animation(DURATION_SLOW, CURVE_DEFAULT),
            opacity=0,
        )

        self._subtitle = ft.Text(
            "Calibration Certificate Generator",
            size=14,
            color=TEXT_SECONDARY,
            text_align=ft.TextAlign.CENTER,
            animate_opacity=ft.Animation(DURATION_SLOW, CURVE_DEFAULT),
            opacity=0,
        )

        self._version_text = ft.Text(
            "v1.0.0  ·  Cross-Platform",
            size=11,
            color=TEXT_MUTED,
            text_align=ft.TextAlign.CENTER,
            animate_opacity=ft.Animation(DURATION_SLOW, CURVE_DEFAULT),
            opacity=0,
        )

        # Enter button with CrossFade to spinner
        self._enter_text = ft.Text(
            "Enter Dashboard",
            size=14,
            color="#FFFFFF",
            weight=ft.FontWeight.W_600,
        )
        self._spinner = ft.ProgressRing(
            width=20, height=20, stroke_width=2.5, color="#FFFFFF", visible=False
        )
        self._enter_btn = ft.Container(
            content=ft.Row(
                [self._enter_text, self._spinner],
                alignment=ft.MainAxisAlignment.CENTER,
                spacing=SPACING_SM,
            ),
            width=220,
            height=48,
            border_radius=RADIUS_LG,
            gradient=ft.LinearGradient(
                colors=[ACCENT_PRIMARY, "#4090E0"],
                begin=ft.Alignment(-1, 0),
                end=ft.Alignment(1, 0),
            ),
            alignment=ft.Alignment(0, 0),
            on_click=self._handle_enter,
            on_hover=self._on_btn_hover,
            animate=ft.Animation(DURATION_NORMAL, CURVE_DEFAULT),
            animate_scale=ft.Animation(DURATION_NORMAL, CURVE_DEFAULT),
            animate_opacity=ft.Animation(DURATION_SLOW, CURVE_DEFAULT),
            opacity=0,
            scale=1.0,
            shadow=SHADOW_CARD,
        )

        # ── Glass card ──
        self._card = ft.Container(
            content=ft.Column(
                controls=[
                    self._logo_container,
                    ft.Container(height=SPACING_SM),
                    self._title,
                    self._subtitle,
                    ft.Container(height=SPACING_LG),
                    self._enter_btn,
                    ft.Container(height=SPACING_SM),
                    self._version_text,
                ],
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                alignment=ft.MainAxisAlignment.CENTER,
                spacing=SPACING_SM,
            ),
            width=400,
            padding=ft.Padding.symmetric(horizontal=48, vertical=48),
            border_radius=RADIUS_XL,
            bgcolor=BG_GLASS_STRONG,
            border=ft.Border.all(1, "#30363D60"),
            shadow=SHADOW_CARD,
            blur=ft.Blur(15, 15, ft.BlurTileMode.CLAMP),
            animate=ft.Animation(DURATION_HERO, CURVE_DEFAULT),
            animate_scale=ft.Animation(DURATION_HERO, CURVE_DEFAULT),
            animate_opacity=ft.Animation(DURATION_HERO, CURVE_DEFAULT),
            scale=0.95,
            opacity=0,
        )

        # ── Full-screen layout ──
        self.content = ft.Container(
            content=ft.Column(
                controls=[self._card],
                alignment=ft.MainAxisAlignment.CENTER,
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                expand=True,
            ),
            expand=True,
            gradient=GRADIENT_HERO,
        )
        self.expand = True

    def did_mount(self):
        """Trigger staggered entrance animation."""
        self._page.run_task(self._animate_entrance)

    async def _animate_entrance(self):
        """Stagger elements in: card → logo → title → subtitle → button → version."""
        await asyncio.sleep(0.1)

        # Card fades in
        self._card.opacity = 1
        self._card.scale = 1.0
        self._card.update()
        await asyncio.sleep(STAGGER_DELAY / 1000 * 4)

        # Logo
        self._logo_container.opacity = 1
        self._logo_container.scale = 1.0
        self._logo_container.update()
        await asyncio.sleep(STAGGER_DELAY / 1000 * 3)

        # Title
        self._title.opacity = 1
        self._title.update()
        await asyncio.sleep(STAGGER_DELAY / 1000 * 2)

        # Subtitle
        self._subtitle.opacity = 1
        self._subtitle.update()
        await asyncio.sleep(STAGGER_DELAY / 1000 * 3)

        # Button
        self._enter_btn.opacity = 1
        self._enter_btn.update()
        await asyncio.sleep(STAGGER_DELAY / 1000 * 2)

        # Version
        self._version_text.opacity = 1
        self._version_text.update()

    def _on_btn_hover(self, e: ft.HoverEvent):
        self._enter_btn.scale = 1.05 if e.data == "true" else 1.0
        self._enter_btn.update()

    def _handle_enter(self, e):
        """CrossFade: button text → spinner, then navigate."""
        self._enter_text.value = "Loading..."
        self._spinner.visible = True
        self._enter_btn.update()
        self._page.run_task(self._transition_out)

    async def _transition_out(self):
        """Animate out, then call on_enter callback."""
        await asyncio.sleep(0.8)

        # Shrink card
        self._card.scale = 0.9
        self._card.opacity = 0
        self._card.update()
        await asyncio.sleep(0.4)

        if self._on_enter:
            await self._on_enter()
