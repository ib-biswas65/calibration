# Design system — ITE Calibration

Approved 2026-09-16. Visual mockup: see the "Calibration Redesign" artifact
referenced in that session's chat (Overview / History / Run Detail screens).

## Why this exists

The app's previous palette (`--color-boardroom-navy`, `--color-brand-electric`,
etc. in `apps/web/src/theme/tokens.css`) was labeled "Officevibe brand
palette" in a code comment — a placeholder that was never swapped for ITE's
actual identity. This document replaces it with ITE's real, confirmed
branding.

## Identity

**Institutional-clinical glass.** Translucent panels over a warm neutral
ground with faint color-pool ambient gradients in the brand's four accent
hues. Reads as credible/scientific (fits a calibration lab tool measuring
against traceable standards) without being cold.

## Brand

ITE's corporate mark is a green droplet/leaf icon, paired with a four-color
accent quartet — **red, amber, blue, green**, always in that order — confirmed
live on icebattery.jp and independently matched in two other shipped ITE
products (`logger-app-ibtrace`, `carbon-dashboard`). This app adopts the same
mark and quartet.

## Tokens

Same **variable names** as today's `tokens.css` (so no CSS Module needs
touching for the palette swap itself, only the `:root` values) plus a small
set of new glass/ambient tokens.

```css
/* Retint existing names. Values are darkened from the brand kit's literal
   hex (#179e38 green, #fab72b amber, #1fa9c9 blue, #e83f3a red) — the raw
   brand hues only clear WCAG AA (4.5:1) as large/decorative elements, not
   as button/link/pill text on these light glass surfaces. Full contrast
   audit (before/after ratios) done 2026-09-16; the raw brand green is
   still used verbatim for the decorative logo mark and the accent-quartet
   stripe in Sidebar.tsx, since those aren't text. */
--color-boardroom-navy:  #17181a;   /* was navy #0c1754 — now the sidebar ink */
--color-brand-electric:  #0f6b26;   /* brand green, darkened for text/button contrast */
--color-feedback-yellow: #835408;   /* amber, darkened — raw #fab72b was 1.5:1 as text */
--color-accent-orange:   #ad2823;   /* red — reused for fail/error, darkened */
--color-lilac-accent:    #eaf3ec;   /* soft green-tinted neutral, was lilac */

--c-bg:        #eceee6;   /* warm neutral ground (was #f9f8f6) */
--c-surface:   rgba(255,255,255,.66);   /* glass, was opaque white */
--c-border:    rgba(25,23,24,.09);      /* hairline, was solid light-gray */
--c-text:      #191718;
--c-text-soft: #4a4d47;
--c-text-mute: #5f645b;   /* darkened — #7a7f76 was 3.50:1, below the 4.5:1 floor */

--c-pass: #0f6b26;
--c-warn: #835408;   /* used for both "adjusted" and the new "invalid"/"partial" states */
--c-fail: #ad2823;
--c-info: #136679;   /* blue accent, wasn't semantically used before */

/* New: glass + ambient */
--glass-strong: rgba(255,255,255,.82);
--glass-border: rgba(255,255,255,.75);
--ambient-green: rgba(23,158,56,.16);
--ambient-blue:  rgba(31,169,201,.15);
--ambient-amber: rgba(250,183,43,.14);
--ambient-red:   rgba(232,63,58,.09);
```

**Contrast rule for this palette**: any of these four status hues used as
*text* (pill labels, `.dueWarn`, `StatTile`'s `.warn`/`.pass`/`.fail`
variants) must use the darkened token value above, never the raw brand hex
from the "Brand" section. The raw hex is for decorative/large elements only
(the logo mark, the accent-quartet stripe, anything ≥24px bold where the
3:1 large-text floor applies instead of 4.5:1).

Radii, spacing (`--s-*`), and easing/transition tokens are unchanged — the
layout rhythm already matches this direction, only color and surface
treatment change.

## Typography

- UI/body: **Instrument Sans** (replaces Inter) — `--font-sans`, `--font-heading`.
- Numeric/technical data (cert numbers, logger serials, temperatures,
  deviations): **JetBrains Mono** (replaces the generic `ui-monospace` stack)
  — `--font-mono`. Anywhere digits line up in a column, pair with
  `font-variant-numeric: tabular-nums`.
- Load both from Google Fonts in `index.html`.

## Component patterns

- **Glass surface**: any element currently using `background: var(--c-surface)`
  (`StatTile`, `DataTable` wrapper, `ConfirmDialog`, `FileDropZone`) adds
  `backdrop-filter: blur(16px)` (`-webkit-backdrop-filter` too) so the
  translucency actually reads against the ambient ground behind it.
- **Ambient ground**: the main content area (`AppShell`'s `.main`) gets four
  low-opacity radial gradients in the brand quartet, anchored near the
  corners, `background-attachment: fixed` so they don't scroll with content.
  Without this, glass panels read as flat gray, not translucent.
- **Status pills**: dot-style — a small colored dot + label, not a solid-fill
  badge. One consistent color mapping across every screen: pass/complete →
  green, fail/failed → red, adjusted/invalid/partial → amber, processing →
  blue (pulsing dot), draft → neutral.
- **Sidebar**: dark ink gradient panel (`--color-boardroom-navy` → a slightly
  lighter shade), for wayfinding contrast against the light glass content —
  this is the one place full boldness is spent; the rest of the UI stays
  quiet.
- **Div-tables**: header row + data rows pattern already in use (`DataTable`,
  the runs/results lists) — keep the pattern, just retint through the tokens
  above.

## What's out of scope for this pass

- Dark theme — the reference system (ITE's `carbon-dashboard`) has none built
  yet either; revisit as a separate decision, not assumed as part of this
  refresh.
- Information architecture — sidebar nav items and page structure are
  unchanged; this is a visual refresh, not a redesign of what exists where.
