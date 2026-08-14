"""
Design system — color palette, fonts, animation curves, and spacing tokens.
Cross-platform: Segoe UI (Windows) / San Francisco (Mac).
"""

import platform
import flet as ft


# ─── Platform Detection ────────────────────────────────────────
IS_WINDOWS = platform.system() == "Windows"
IS_MAC = platform.system() == "Darwin"

# ─── Font Families ──────────────────────────────────────────────
FONT_PRIMARY = "Segoe UI" if IS_WINDOWS else "San Francisco"
FONT_MONO = "Cascadia Code" if IS_WINDOWS else "SF Mono"
FONT_FALLBACK = "Roboto"

# ─── Color Palette (Dark Mode) ─────────────────────────────────
# Deep navy/slate dark mode with vibrant cyan/teal accents
BG_PRIMARY = "#0D1117"         # Deep dark background
BG_SECONDARY = "#161B22"      # Slightly lighter panels
BG_CARD = "#1C2333"            # Card backgrounds
BG_CARD_HOVER = "#242D3D"     # Card hover state
BG_GLASS = "#1C233380"         # Frosted glass (50% opacity)
BG_GLASS_STRONG = "#1C2333CC" # Stronger glass (80%)

ACCENT_PRIMARY = "#58A6FF"     # Bright blue accent
ACCENT_SECONDARY = "#3FB950"   # Green for success
ACCENT_TERTIARY = "#D29922"    # Amber for warnings
ACCENT_DANGER = "#F85149"      # Red for errors
ACCENT_GLOW = "#58A6FF40"      # Subtle glow effect

TEXT_PRIMARY = "#F0F6FC"       # Primary text (bright white)
TEXT_SECONDARY = "#8B949E"     # Secondary text (muted)
TEXT_MUTED = "#6E7681"         # Muted/placeholder text

BORDER_DEFAULT = "#30363D"     # Default border color
BORDER_ACTIVE = "#58A6FF"      # Active/focused border
BORDER_DASHED = "#30363D80"    # Dashed borders (50% opacity)

# ─── Gradients ──────────────────────────────────────────────────
GRADIENT_HERO = ft.LinearGradient(
    begin=ft.Alignment(-1, -1),
    end=ft.Alignment(1, 1),
    colors=["#0D1117", "#1A1E2E", "#162030"],
)

GRADIENT_ACCENT = ft.LinearGradient(
    begin=ft.Alignment(-1, 0),
    end=ft.Alignment(1, 0),
    colors=["#58A6FF", "#3FB950"],
)

GRADIENT_CARD = ft.LinearGradient(
    begin=ft.Alignment(0, -1),
    end=ft.Alignment(0, 1),
    colors=[BG_CARD, "#151C28"],
)

# ─── Animation ──────────────────────────────────────────────────
# All transitions use EASE_OUT_EXPO for a "luxury" feel
CURVE_DEFAULT = ft.AnimationCurve.EASE_OUT_EXPO
CURVE_BOUNCE = ft.AnimationCurve.EASE_OUT_BACK

DURATION_FAST = 200       # Quick micro-interactions
DURATION_NORMAL = 300     # Standard transitions
DURATION_SLOW = 500       # Entrance animations
DURATION_HERO = 600       # Hero/page transitions

STAGGER_DELAY = 50        # ms between staggered items

# ─── Spacing & Sizing ──────────────────────────────────────────
SPACING_XS = 4
SPACING_SM = 8
SPACING_MD = 16
SPACING_LG = 24
SPACING_XL = 32
SPACING_XXL = 48

RADIUS_SM = 8
RADIUS_MD = 12
RADIUS_LG = 16
RADIUS_XL = 24

# ─── Shadows ────────────────────────────────────────────────────
SHADOW_CARD = ft.BoxShadow(
    spread_radius=0,
    blur_radius=20,
    color="#00000040",
    offset=ft.Offset(0, 4),
)

SHADOW_GLOW = ft.BoxShadow(
    spread_radius=2,
    blur_radius=30,
    color=ACCENT_GLOW,
    offset=ft.Offset(0, 0),
)

# ─── Window Config ──────────────────────────────────────────────
WINDOW_MIN_WIDTH = 1100
WINDOW_MIN_HEIGHT = 750
WINDOW_TITLE = "Calibration Pro"
