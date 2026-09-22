# Design system — ITE Calibration

Approved 2026-09-21 (supersedes the 2026-09-16 "institutional-clinical
glass" pass). Visual mockup: the "ITE Calibration — Redesign Mockups"
canvas, row C ("Index"), tightened twice for density —
https://claude.ai/artifact/4xN8SVQW3YJwSj4TJTe6cF

## Why this exists

The 2026-09-16 glass redesign was reviewed against two other directions
(a dense enterprise-BI style and a rounded Fluent-style) via a mockup
canvas. The user picked Direction C — "Index" — explicitly requesting it
denser than first drawn. This document replaces the glass system with
that flat, high-contrast, Swiss-minimal direction.

## Identity

**Swiss minimal, high contrast, dense.** Flat black-on-white, no blur, no
shadows, no rounded corners. Structure comes from rules (1–2px borders),
not cards. A single accent color (the brand green) used sparingly — for
links, the active nav marker, and primary actions — not spread across the
UI. Large mono numerals for key stats. Reads as precise and serious, in
keeping with a calibration lab issuing traceable certificates.

## Brand

Unchanged from the 2026-09-16 pass: ITE's corporate mark (green
droplet/leaf icon) plus the red/amber/blue/green accent quartet, still
shown as a decorative stripe. Only the green (`#0f6b26`, already
darkened for contrast) is used as a functional UI accent; the other three
stay decorative/status-only.

## Tokens

Same **variable names** as today's `tokens.css` — only `:root` values
change.

```css
--color-boardroom-navy:  #0a0a0a;   /* was sidebar-ink dark navy — now heading/primary text black */
--color-brand-electric:  #0f6b26;   /* unchanged — brand green, already audited */
--color-feedback-yellow: #835408;   /* unchanged — audited warn color */
--color-accent-orange:   #ad2823;   /* unchanged — audited fail color; do NOT swap in the mockup's unaudited #a92a22 */
--color-lilac-accent:    #f7f7f5;   /* was soft green tint — now a neutral hover-row tint */

--c-bg:        #ffffff;   /* was warm neutral #eceee6 — now pure white */
--c-surface:   #ffffff;   /* was translucent glass — now opaque white, no blur anywhere */
--c-surface-strong: #ffffff;
--c-border:    #e2e2e2;   /* hairline row/cell separator, was a black-tinted rgba hairline */
--c-border-strong: #0a0a0a;  /* NEW — 2px structural rules: sidebar edge, header edge, stat-grid edges */
--c-text:      #0a0a0a;
--c-text-soft: #3a3a3a;
--c-text-mute: #6e6e6e;

--c-pass: #0f6b26;   /* unchanged, already audited */
--c-warn: #835408;   /* unchanged, already audited */
--c-fail: #ad2823;   /* unchanged, already audited */
--c-info: #136679;   /* unchanged, already audited */

/* Ambient gradients removed entirely — Direction C is flat white, no
   color pools. The four --ambient-* tokens and the .main background-image
   gradient stack that consumed them are deleted, not just zeroed, so
   nothing pays their paint cost. */
```

**Radius**: every radius token (`--radius-input`, `--radius-sm`,
`--radius-md`, `--radius-badge`, `--radius-card`, `--radius-lg`,
`--radius-pill`) becomes `0`. Nothing in this UI is rounded.

**Shadows**: `--shadow-1` and `--shadow-2` become `none`. No elevation —
structure comes from borders only.

**Contrast rule for this palette**: identical rule to the 2026-09-16
pass — any of the four status hues used as text must use the token
value above, never a raw brand hex. Since the ground is now pure white
(harder to fail against than the old translucent glass), if any new
usage needs checking, re-verify at 4.5:1 against `#ffffff` specifically,
not against the old glass-surface numbers.

## Typography

- UI/body/headings: **Archivo** (replaces Instrument Sans) —
  `--font-sans`, `--font-heading`. Weights 400–900 loaded (headings lean
  on 700–900, dense uppercase labels use 700 with `letter-spacing`).
- Numeric/technical data (cert numbers, logger serials, temperatures,
  deviations, dates in tables): **Space Mono** (replaces JetBrains
  Mono) — `--font-mono`. Anywhere digits line up in a column, pair with
  `font-variant-numeric: tabular-nums`.
- Load both from Google Fonts in `apps/web/index.html`, replacing the
  existing `Instrument+Sans`/`JetBrains+Mono` `css2` link.
- Dense uppercase labels (column headers, nav item micro-labels, form
  labels) use `text-transform: uppercase; letter-spacing: 0.04–0.06em`
  at 10.5–12px — this is a recurring pattern across every screen in the
  mockup, not a one-off.
- **Primary page headings** (the `<h1>`-equivalent at the top of a page,
  e.g. History, Run Detail, Overview): `15px / weight 800 / uppercase /
  0.04em letter-spacing`, `--font-heading`, `--color-boardroom-navy`.
  Login's equivalent is `13px/800/uppercase` — same pattern, smaller for
  its narrower context. Every page carrying this treatment applies it
  explicitly; don't leave a page's heading at the old 28px/500-weight/
  sentence-case style by omission.

## Component patterns

- **No glass, no blur**: every `backdrop-filter`/`-webkit-backdrop-filter`
  declaration in the codebase is deleted (see Task 3). Surfaces are flat
  `#ffffff`.
- **Structural rules over cards**: a "card" in the old system (StatTile,
  DataTable wrapper, ConfirmDialog) loses its border-radius, shadow, and
  independent border in favor of shared 1–2px rules with its neighbors —
  e.g. the Overview stat tiles share a top+left border on the grid
  container and each cell adds only its own right+bottom edge, so
  adjacent tiles don't double up their border.
- **Status pills**: no more dot + tinted badge. Verdicts/statuses render
  as plain uppercase `--font-mono` text in the semantic color (pass
  green, fail red, warn amber, info blue), no background fill, no
  border-radius.
- **Sidebar**: flat white, no dark ink panel. A 2px solid
  `--c-border-strong` right edge separates it from content. Nav items are
  plain text links with `padding: 3px 12px`; the active item gets a 3px
  solid `--color-brand-electric` left border plus bold text — no filled
  background.
- **Topbar/header**: dense (30–36px tall, was 56px), 2px solid
  `--c-border-strong` bottom edge, no blur, no translucency.
- **Tables (div-tables and `<table>` alike)**: header row uses a 2px
  solid `--c-border-strong` bottom rule (not a card border); body rows
  use a 1px `--c-border` hairline; cell padding drops to 4–6px vertical
  (was 12px) — this is the single biggest density change from the
  2026-09-16 system.
- **Buttons/links**: primary actions can stay solid-fill (black or
  brand green) but square-cornered (radius 0, inherited from the token
  change); secondary actions read as plain uppercase text links,
  matching the mockup's "Export CSV" / "+ New calibration" treatment on
  the History page.

## What's out of scope for this pass

- Dark theme — still not built (same note as 2026-09-16).
- Information architecture — sidebar nav items and page structure are
  unchanged; this is a visual redesign, not a restructuring of what
  exists where.
- Per-page bespoke layouts beyond what shared components and tokens
  already produce, for the eight pages not explicitly mocked (Loggers,
  Upcoming, Settings, Logger Profile, New Calibration, Certificate,
  Admin Users, Register/Reset Password) — Task 10 only sweeps for
  leftover hardcoded glass-era values, it does not redesign these pages'
  layouts from scratch.
- Of those, 5 pages (Loggers, Settings, New Calibration, Certificate,
  Admin Users) are explicitly parked here as known follow-up, not an
  oversight — they still carry pre-redesign chrome (headings, spacing)
  and are intentionally deferred to a later pass.
