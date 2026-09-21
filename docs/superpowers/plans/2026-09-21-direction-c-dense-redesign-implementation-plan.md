# Direction C (Index) Dense Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the app's current "institutional-clinical glass" visual design (approved 2026-09-16, `/DESIGN.md`) with **Direction C — Index**, the flat, high-contrast, Swiss-minimal, dense direction approved from the mockup canvas review on 2026-09-21 (`https://claude.ai/artifact/4xN8SVQW3YJwSj4TJTe6cF`, row C, tightened twice for density).

**Architecture:** This is a visual-only redesign — information architecture, routes, component structure, and data flow are unchanged (same constraint the 2026-09-16 pass committed to). Nearly the entire visual shift is expressible as `:root` token retints in `apps/web/src/theme/tokens.css`, since almost every component already consumes tokens rather than hardcoded values. Five components hardcode `backdrop-filter` (the "glass" effect) and must be edited directly, not just retinted. Four page-level files (Overview, History, Run Detail, Login) need density-specific overrides beyond what tokens supply, because the mockups use tighter paddings and different heading treatments than the current `--s-*` spacing scale produces by default. All other pages (Loggers, Upcoming, Settings, Logger Profile, New Calibration, Certificate, Admin Users, Register, Reset Password) inherit the new look almost entirely for free through shared components (`StatusPill`, `DataTable`, buttons, inputs) and tokens; Task 10 sweeps them for leftover hardcoded values the token pass can't reach.

**Tech Stack:** React 18 + TypeScript, CSS Modules (no CSS-in-JS, no Tailwind), Vite, Vitest + Testing Library, Google Fonts (Archivo, Space Mono replacing Instrument Sans, JetBrains Mono).

**Spec:** The three-direction mockup canvas, `https://claude.ai/artifact/4xN8SVQW3YJwSj4TJTe6cF` (row C: `C-Overview.dc.html`, `C-History.dc.html`, `C-RunDetail.dc.html`, `C-Login.dc.html`, post density-tightening). This plan's Task 1 turns that mockup into the durable `/DESIGN.md` spec; every later task implements that rewritten `/DESIGN.md`, not the mockup directly.

## Global Constraints

- No dark theme (unchanged from the 2026-09-16 `/DESIGN.md` — still out of scope; the reference system has none either).
- No IA changes — sidebar nav items, routes, and page structure stay exactly as they are today (`apps/web/src/components/Sidebar.tsx`'s `NAV` array is untouched).
- Reuse the existing audited status colors verbatim: `--c-pass: #0f6b26`, `--c-warn: #835408`, `--c-fail: #ad2823`, `--c-info: #136679` (do **not** substitute the mockup's approximate `#a92a22` fail red — that was drawn from memory in the mockup and was never contrast-audited; the token value was, on 2026-09-16, against light glass surfaces, which is a harder contrast bar than pure white, so it clears on the new white background too).
- Every CSS variable **name** stays the same as today (`--color-boardroom-navy`, `--c-bg`, `--radius-card`, etc.) — only `:root` values change, so no CSS Module needs touching for the palette/radius/shadow swap itself, per the project's established retint pattern (see the comment block at the top of `tokens.css`).
- Per `/Users/lux/Work/Calibration/CLAUDE.md`: run `impact({target: "<ComponentName>", direction: "upstream"})` before editing any shared component (`StatusPill`, `DataTable`, `StatTile`, `AppShell`/`Sidebar`) — these have multiple callers and a change ripples further than a page-local edit. Run `detect_changes({scope: "all"})` before each commit in this plan.
- Contrast floor: 4.5:1 for normal text, 3:1 for large text (18pt+/14pt+ bold) and UI components, per the `web-design-guidelines` audit in Task 11. Every dark-on-white swap in this plan starts from already-audited token values, but Task 11 re-verifies against the new pure-white background rather than assuming it.
- Lint scope: this repo has pre-existing, unrelated lint failures (22, drifting) tracked separately in `docs/superpowers/plans/2026-09-16-post-redesign-implementation-plan.md`. Scope `ruff`/`eslint` runs in this plan to files actually touched — do not fix or get blocked by pre-existing failures.

---

## File Structure

| File | Responsibility in this plan |
|---|---|
| `DESIGN.md` (repo root) | Rewritten spec: identity, tokens, typography, component patterns for Direction C. Source of truth for every task below. |
| `apps/web/index.html` | Google Fonts `<link>` swap (Archivo + Space Mono). |
| `apps/web/src/theme/tokens.css` | `:root` retint: colors, radius, shadows, fonts, ambient-gradient removal. |
| `apps/web/src/components/AppShell.module.css` | Sidebar (flat, bordered, text-nav) and Topbar (dense, no blur) restyle. |
| `apps/web/src/components/StatusPill.module.css` | Swap dot+tinted-badge for plain uppercase mono colored text. |
| `apps/web/src/components/StatTile.module.css` | Remove card/blur/hover-lift; become a bordered grid cell with large mono numerals. |
| `apps/web/src/pages/OverviewPage.module.css` | `.tiles` grid restructured to share borders between cells (Swiss rule-grid), rail density. |
| `apps/web/src/components/DataTable.module.css` | Shared table wrapper (used by Loggers/Upcoming pages) — remove blur/radius/card border, add rule-based header. |
| `apps/web/src/pages/HistoryPage.module.css` | Heading treatment, toolbar density, table density — mirrors `C-History.dc.html`. |
| `apps/web/src/pages/RunDetailPage.module.css` | Heading/toolbar/table/card-view density — mirrors `C-RunDetail.dc.html`. |
| `apps/web/src/pages/LoginPage.module.css` | Two-panel layout (brand statement + form) replacing the single centered card — mirrors `C-Login.dc.html`. |
| `apps/web/src/components/ConfirmDialog.module.css`, `FileDropZone.module.css` | Remove `backdrop-filter`, flatten to solid white + rule border. |
| Remaining pages (Loggers, Upcoming, Settings, Logger Profile, New Calibration, Certificate, Admin Users, Register, Reset Password) | No dedicated task — Task 10 sweeps them for hardcoded values the token pass misses. |

---

### Task 1: Rewrite `/DESIGN.md` for Direction C

**Files:**
- Modify: `DESIGN.md` (repo root, currently 119 lines, 2026-09-16 version)

**Interfaces:**
- Produces: the token values, class-pattern descriptions, and "what's out of scope" list that every later task implements. No code interface — this is the spec every other task's diff must match.

- [ ] **Step 1: Replace the file's content**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add DESIGN.md
git commit -m "docs: rewrite DESIGN.md for Direction C dense redesign"
```

---

### Task 2: Swap Google Fonts and retint `tokens.css`

**Files:**
- Modify: `apps/web/index.html:9-12`
- Modify: `apps/web/src/theme/tokens.css:1-100`

**Interfaces:**
- Consumes: nothing (root-level token change).
- Produces: every `var(--color-*)`, `var(--c-*)`, `var(--radius-*)`, `var(--shadow-*)`, `var(--font-*)` reference used across `apps/web/src` now resolves to Direction C's values. This is the change every other task in this plan builds on.

- [ ] **Step 1: Swap the font link**

In `apps/web/index.html`, replace lines 9–12:

```html
    <link
      rel="stylesheet"
      href="https://fonts.googleapis.com/css2?family=Instrument+Sans:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500;600&display=swap"
    />
```

with:

```html
    <link
      rel="stylesheet"
      href="https://fonts.googleapis.com/css2?family=Archivo:wght@400;500;600;700;800;900&family=Space+Mono:wght@400;700&display=swap"
    />
```

- [ ] **Step 2: Retint `tokens.css`**

Replace lines 1–58 of `apps/web/src/theme/tokens.css` (the palette and
semantic-alias block, from `--color-boardroom-navy` through
`--ambient-red`) with:

```css
:root {
  /* ── ITE brand palette — Direction C ("Index") retint ─────────────── */
  /* Supersedes the 2026-09-16 glass palette; see /DESIGN.md. Variable
     names kept stable so every module below still resolves — only the
     hex/keyword values changed. */
  --color-boardroom-navy:   #0a0a0a;   /* was dark navy sidebar ink — now heading/primary text black */
  --color-brand-electric:   #0f6b26;   /* unchanged — already audited, 6.66:1 white-on-this */
  --color-lilac-accent:     #f7f7f5;   /* was soft green tint — now neutral row-hover tint */
  --color-feedback-yellow:  #835408;   /* unchanged — already audited */
  --color-soft-off-white:   #ffffff;   /* was warm neutral #eceee6 — now pure white page ground */
  --color-pure-white:       #ffffff;
  --color-pitch-black:      #0a0a0a;
  --color-medium-gray:      #3a3a3a;
  --color-light-cool-gray:  #f0f0f0;   /* was translucent black hairline */
  --color-input-border:     #0a0a0a;   /* flat inputs use a solid black underline, not a gray border */
  --color-accent-orange:    #ad2823;   /* unchanged — already audited */

  /* ── Semantic aliases (used throughout modules) ───────────────────── */
  --c-accent-50:  #f7f7f5;
  --c-accent-100: #e9f2ec;
  --c-accent-300: #6fc287;
  --c-accent-500: #0f6b26;
  --c-accent-600: #0f6b26;   /* primary CTA — unchanged, 6.66:1 white-on-this */
  --c-accent-700: #0d5c20;   /* hover */
  --c-accent-900: #0a0a0a;

  /* Surface — flat, opaque, no glass */
  --c-bg:        #ffffff;
  --c-surface:   #ffffff;
  --c-surface-strong: #ffffff;
  --c-border:    #e2e2e2;   /* 1px hairline row/cell separator */
  --c-border-strong: #0a0a0a;  /* NEW — 2px structural rules (sidebar edge, header edge, stat-grid) */

  /* Text */
  --c-text:      #0a0a0a;
  --c-text-soft: #3a3a3a;
  --c-text-mute: #6e6e6e;

  /* Status — unchanged from the 2026-09-16 audit; still clears 4.5:1 as
     plain text on the new pure-white ground (an easier bar than the old
     translucent glass surfaces these were originally audited against). */
  --c-pass: #0f6b26;
  --c-warn: #835408;
  --c-fail: #ad2823;
  --c-info: #136679;

  /* ── Typography ──────────────────────────────────────────────────── */
  --font-sans:    'Archivo', ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif;
  --font-heading: 'Archivo', ui-sans-serif, system-ui, sans-serif;
  --font-accent:  Georgia, 'Times New Roman', serif;
  --font-mono:    'Space Mono', ui-monospace, 'Cascadia Code', monospace;

  /* ── Spacing (8px base) — unchanged; density comes from component-level
     overrides using the smallest applicable step, not a new scale ──── */
  --s-1:  4px;
  --s-2:  8px;
  --s-3:  12px;
  --s-4:  16px;
  --s-5:  24px;
  --s-6:  32px;
  --s-8:  48px;
  --s-10: 64px;

  /* ── Border radius — flat everywhere ────────────────────────────── */
  --radius-input:  0;
  --radius-sm:     0;
  --radius-md:     0;
  --radius-badge:  0;
  --radius-card:   0;
  --radius-lg:     0;
  --radius-pill:   0;

  /* ── Shadows — none; structure comes from borders, not elevation ─── */
  --shadow-1: none;
  --shadow-2: none;
```

Leave the transition/easing block (lines 89–99 in the original) and the
`@keyframes`/`.stagger-*` block (lines 102–149) untouched — motion timing
is not part of this visual redesign.

- [ ] **Step 3: Remove the ambient-gradient background from the main shell**

This is completed in Task 4 (it lives in `AppShell.module.css`, not
`tokens.css`) — the `--ambient-*` tokens are simply not carried into the
new `:root` block above, so leaving Task 4 unfinished at this point would
break the build (`var(--ambient-green)` etc. would resolve to nothing,
silently rendering no gradient — not a build error, but confirm Task 4 is
done before calling this plan finished).

- [ ] **Step 4: Verify the app boots and nothing crashes**

```bash
cd apps/web && npm run dev
```

Open `http://localhost:5173` (or whatever port Vite reports) and confirm
the page renders (colors will look wrong until later tasks — that's
expected; this step is only checking for a JS/CSS parse error, not visual
correctness).

- [ ] **Step 5: Commit**

```bash
git add apps/web/index.html apps/web/src/theme/tokens.css
git commit -m "feat(web): retint tokens.css for Direction C dense redesign"
```

---

### Task 3: Remove `backdrop-filter` glass effect from all five components

**Files:**
- Modify: `apps/web/src/components/StatTile.module.css:1-7`
- Modify: `apps/web/src/components/FileDropZone.module.css:1-15`
- Modify: `apps/web/src/components/AppShell.module.css:100-113`
- Modify: `apps/web/src/components/ConfirmDialog.module.css:1-20`
- Modify: `apps/web/src/components/DataTable.module.css:1-8`

**Interfaces:**
- Consumes: `var(--c-surface)`, `var(--c-border)`, `var(--radius-card)` from Task 2 (already resolve to flat/0 values).
- Produces: no `backdrop-filter` declarations remain anywhere in `apps/web/src` — Task 11's `web-design-guidelines` audit checks this.

- [ ] **Step 1: `gitnexus` impact check before touching shared components**

```bash
node .gitnexus/run.cjs impact "StatTile" --direction upstream --repo .
node .gitnexus/run.cjs impact "DataTable" --direction upstream --repo .
```

Confirm risk is not HIGH/CRITICAL before proceeding (these are pure
CSS-module edits with no prop/behavior change, so risk should be
LOW/UNKNOWN at most — if UNKNOWN, confirm by grepping for the component
name across `apps/web/src/pages` per the repo's `UNKNOWN`-is-not-safe
rule).

- [ ] **Step 2: `StatTile.module.css`**

Delete lines 3–4 (`backdrop-filter: blur(16px);` and its `-webkit-`
twin) from `.tile`. Leave the rest of the rule as-is for now — full
`.tile` restyle happens in Task 5.

- [ ] **Step 3: `FileDropZone.module.css`**

Delete the two `backdrop-filter` lines (currently lines 11–12).

- [ ] **Step 4: `AppShell.module.css` (`.topbar`)**

Delete lines 104–105 (`backdrop-filter: blur(16px);` /
`-webkit-backdrop-filter`). Full `.topbar` restyle happens in Task 4.

- [ ] **Step 5: `ConfirmDialog.module.css`**

Delete the two `backdrop-filter: blur(20px)` lines (currently lines
14–15).

- [ ] **Step 6: `DataTable.module.css` (`.wrapper`)**

Delete lines 6–7 (`backdrop-filter: blur(16px);` / `-webkit-` twin).
Full `.wrapper` restyle happens in Task 6.

- [ ] **Step 7: Confirm no `backdrop-filter` remains**

```bash
grep -rn "backdrop-filter" apps/web/src --include="*.css"
```

Expected: no output.

- [ ] **Step 8: Commit**

```bash
git add apps/web/src/components/StatTile.module.css apps/web/src/components/FileDropZone.module.css apps/web/src/components/AppShell.module.css apps/web/src/components/ConfirmDialog.module.css apps/web/src/components/DataTable.module.css
git commit -m "fix(web): remove backdrop-filter glass effect, superseded by Direction C"
```

---

### Task 4: Restyle `AppShell` — flat sidebar, dense topbar, no ambient gradient

**Files:**
- Modify: `apps/web/src/components/AppShell.module.css:1-183`

**Interfaces:**
- Consumes: `var(--c-border-strong)` (new, from Task 2), `var(--color-brand-electric)`, `var(--c-text)`.
- Produces: `.sidebar`, `.navItem`, `.navItemActive`, `.topbar` visual contract that `Sidebar.tsx` and `Topbar.tsx` render into — no markup changes needed in either `.tsx` file, this task is CSS-only.

- [ ] **Step 1: `gitnexus` impact check**

```bash
node .gitnexus/run.cjs impact "AppShell" --direction upstream --repo .
```

`AppShell` wraps every authenticated route — expect this to report
several callers; confirm none of them depend on specific pixel
dimensions (e.g. a page that assumes a 56px topbar or 220px sidebar and
positions something with an explicit offset). Grep to be sure:

```bash
grep -rn "56px\|220px" apps/web/src/pages --include="*.css"
```

If any page hardcodes those dimensions to align with the shell, note it
and adjust that page's CSS in the same commit as this task.

- [ ] **Step 2: Replace `.sidebar` (lines 4–11)**

```css
.sidebar {
  background: #ffffff;
  border-right: 2px solid var(--c-border-strong);
  color: var(--c-text);
  padding: var(--s-3) 0;
  display: flex;
  flex-direction: column;
  animation: fadeIn 400ms var(--ease-out) both;
}
```

- [ ] **Step 3: Replace `.brandBlock`, `.brand`, `.brandQuartet` (lines 13–39)**

```css
.brandBlock {
  margin-bottom: var(--s-2);
  padding: 0 var(--s-4) var(--s-2) var(--s-4);
  border-bottom: 1px solid var(--c-border-strong);
}

.brand {
  font-family: var(--font-heading);
  font-weight: 900;
  font-size: 14px;
  text-transform: uppercase;
  letter-spacing: 0.02em;
  color: var(--c-text);
  display: flex;
  align-items: center;
  gap: var(--s-2);
  animation: staggerIn 380ms 80ms var(--ease-out) both;
}
.brand span { flex: 1; }

.brandMark { width: 22px; height: 22px; flex-shrink: 0; }

.brandQuartet {
  display: flex;
  height: 3px;
  overflow: hidden;
  margin: var(--s-2) 0 0;
}
.brandQuartet span { flex: 1; }
```

- [ ] **Step 4: Replace `.navItem`/`.navItemActive` (lines 53–73)**

```css
.navItem {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 3px var(--s-3);
  border-left: 3px solid transparent;
  color: var(--c-text-soft);
  font-size: 12.5px;
  font-weight: 500;
  margin-bottom: 1px;
  transition: color var(--transition-fast), border-color var(--transition-fast);
  animation: staggerIn 360ms var(--ease-out) both;
}
.navItem svg { flex-shrink: 0; opacity: .85; }
.navItemActive svg { opacity: 1; }
.navItem:hover { color: var(--c-text); }
.navItemActive {
  border-left-color: var(--color-brand-electric);
  color: var(--c-text);
  font-weight: 700;
  background: transparent;
}
.navItemActive:hover { color: var(--c-text); }
```

- [ ] **Step 5: Replace `.main` — remove the ambient gradient (lines 86–98)**

```css
.main {
  display: flex;
  flex-direction: column;
  background-color: var(--c-bg);
}
```

(Deletes the four `radial-gradient(...)` layers and `background-image`/
`background-attachment` declarations entirely — Direction C is flat
white, no ambient color pools.)

- [ ] **Step 6: Replace `.topbar` (lines 100–112, minus the already-deleted blur lines from Task 3)**

```css
.topbar {
  height: 36px;
  border-bottom: 2px solid var(--c-border-strong);
  background: #ffffff;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  padding: 0 var(--s-4);
  gap: var(--s-3);
  animation: fadeIn 350ms 60ms var(--ease-out) both;
}
```

- [ ] **Step 7: Replace `.logout` (lines 122–132) to match the flat-button pattern**

```css
.logout {
  background: transparent;
  border: 1px solid var(--c-border-strong);
  padding: 4px 12px;
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.03em;
  color: var(--c-text-soft);
  transition: border-color var(--transition-fast), color var(--transition-fast);
}
.logout:hover { border-color: var(--color-brand-electric); color: var(--color-brand-electric); }
```

- [ ] **Step 8: Verify visually**

```bash
cd apps/web && npm run dev
```

Load the app, log in, confirm the sidebar is now flat white with a
right-hand rule, nav items show a left-border marker (not a filled pill)
on the active route, and the topbar is dense with no blur.

- [ ] **Step 9: Commit**

```bash
git add apps/web/src/components/AppShell.module.css
git commit -m "feat(web): restyle AppShell sidebar/topbar for Direction C"
```

---

### Task 5: Restyle `StatusPill` and `StatTile`

**Files:**
- Modify: `apps/web/src/components/StatusPill.module.css:1-38`
- Modify: `apps/web/src/components/StatTile.module.css` (post Task 3's blur removal)

**Interfaces:**
- Consumes: `var(--c-pass)`, `var(--c-fail)`, `var(--c-warn)`, `var(--c-info)`, `var(--c-text-mute)`, `var(--font-mono)`.
- Produces: unchanged prop contracts on `StatusPill.tsx` (`value: RunStatus | Verdict | string`) and `StatTile.tsx` — both are pure CSS restyles.

- [ ] **Step 1: Replace `StatusPill.module.css` entirely**

```css
.pill {
  display: inline-flex;
  align-items: center;
  font-family: var(--font-mono);
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--c-text-mute);
  white-space: nowrap;
}

/* Semantic color: pass/complete green, fail/failed red, adjusted/invalid/partial
   amber, processing blue (pulsing), draft neutral — one mapping everywhere.
   No background fill, no dot — Direction C uses plain colored mono text. */
.draft      { color: var(--c-text-mute); }
.processing { color: var(--c-info); }
.complete   { color: var(--c-pass); }
.failed     { color: var(--c-fail); }
.pass       { color: var(--c-pass); }
.fail       { color: var(--c-fail); }
.adjusted   { color: var(--c-warn); }
.invalid    { color: var(--c-warn); }
.partial    { color: var(--c-warn); }

.pulsing {
  animation: processingPulse 1.8s ease-in-out infinite;
}
```

- [ ] **Step 2: Run the existing `StatusPill` test to confirm markup contract is unbroken**

```bash
cd apps/web && npx vitest run src/components/StatusPill.test.tsx
```

Expected: PASS (2/2) — the test only asserts on visible label text
(`"Invalid"`, `"Partial"`), which this CSS-only change doesn't touch.

- [ ] **Step 3: Replace `StatTile.module.css`**

```css
.tile {
  background: #ffffff;
  border-right: 2px solid var(--c-border-strong);
  border-bottom: 2px solid var(--c-border-strong);
  padding: var(--s-2) var(--s-3);
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.label {
  font-size: 10.5px;
  font-weight: 500;
  color: var(--c-text-mute);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.value {
  font-family: var(--font-mono);
  font-size: 22px;
  font-weight: 700;
  color: var(--color-boardroom-navy);
  line-height: 1;
}

.unit {
  font-size: 0.7em;
  font-weight: 400;
  color: var(--c-text-mute);
  margin-left: 2px;
}

.warn .value { color: var(--color-feedback-yellow); }
.fail .value { color: var(--c-fail); }
.pass .value { color: var(--c-pass); }
```

Note: this drops the `:hover` lift/shadow entirely (Direction C has no
elevation) and the tile's own left/top border — those come from the
grid container in Task 6, so an individual `StatTile` isn't
self-bordered on every edge (avoids doubled borders between adjacent
tiles).

- [ ] **Step 4: Commit**

```bash
git add apps/web/src/components/StatusPill.module.css apps/web/src/components/StatTile.module.css
git commit -m "feat(web): restyle StatusPill and StatTile for Direction C"
```

---

### Task 6: Restyle the Overview stat-tile grid and shared `DataTable` wrapper

**Files:**
- Modify: `apps/web/src/pages/OverviewPage.module.css` (`.tiles` rule and surrounding rail styles)
- Modify: `apps/web/src/components/DataTable.module.css` (post Task 3's blur removal)

**Interfaces:**
- Consumes: `.tile` from Task 5 (already missing its own top/left border — this task's `.tiles` container supplies it).
- Produces: `OverviewPage.tsx`'s `<div className={styles.tiles}>` renders four `StatTile`s in a shared-border grid matching `C-Overview.dc.html`.

- [ ] **Step 1: Read the current `.tiles` rule**

```bash
grep -n "^\.tiles" -A 6 apps/web/src/pages/OverviewPage.module.css
```

- [ ] **Step 2: Replace `.tiles` to supply the outer grid border**

```css
.tiles {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  border-top: 2px solid var(--c-border-strong);
  border-left: 2px solid var(--c-border-strong);
  gap: 0;
}
```

(Each `StatTile` from Task 5 supplies its own right+bottom edge, so the
grid as a whole ends up fully ruled without doubled interior borders —
this is the exact technique used in `C-Overview.dc.html`'s stat row.)

- [ ] **Step 3: Find and densify the `.rail`/`.item` rules**

```bash
grep -n "^\.rail\b\|^\.item\b\|^\.railTitle\b" -A 4 apps/web/src/pages/OverviewPage.module.css
```

Reduce whatever `padding`/`gap` values these currently use to match
`C-Overview.dc.html`'s rail density: row padding `5px 0`, section
padding `8–10px`, `.railTitle` `margin-bottom: 6px` and
`text-transform: uppercase; letter-spacing: 0.06em; font-size: 10.5px`.
Replace `border-bottom: 1px solid var(--c-border)` between rail rows
(unchanged pattern, just confirm it still resolves to the new
`--c-border: #e2e2e2` hairline from Task 2, not a leftover hardcoded
color).

- [ ] **Step 4: Replace `DataTable.module.css` `.wrapper` and `.table th`**

```css
.wrapper {
  overflow-x: auto;
  border-top: 2px solid var(--c-border-strong);
  background: #ffffff;
}

.table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}

.table th {
  text-align: left;
  padding: 5px var(--s-3);
  font-size: 10.5px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--c-text-mute);
  border-bottom: 2px solid var(--c-border-strong);
  background: #ffffff;
}

.table td {
  padding: 5px var(--s-3);
  border-bottom: 1px solid var(--c-border);
  color: var(--c-text);
}

.table tbody tr:last-child td { border-bottom: none; }

.clickable { cursor: pointer; }
.clickable:hover td { background: var(--color-lilac-accent); }

.empty {
  text-align: center;
  color: var(--c-text-mute);
  padding: var(--s-8) !important;
}
```

This is the shared wrapper `LoggersPage.tsx` and `UpcomingPage.tsx` both
render through `DataTable.tsx` (confirmed via `gitnexus`: `DataTable`
called by `LoggersPage`, flows through `UpcomingPage → DataTable`) — so
this one edit densifies both of those pages' tables without touching
either page file.

- [ ] **Step 5: Visual check**

```bash
cd apps/web && npm run dev
```

Load `/` (Overview), `/loggers`, and `/upcoming`; confirm the stat grid
is fully ruled with no doubled borders and both table pages are dense
with 2px header rules.

- [ ] **Step 6: Commit**

```bash
git add apps/web/src/pages/OverviewPage.module.css apps/web/src/components/DataTable.module.css
git commit -m "feat(web): restyle Overview stat grid and shared DataTable for Direction C"
```

---

### Task 7: Restyle `HistoryPage`

**Files:**
- Modify: `apps/web/src/pages/HistoryPage.module.css:1-217`

**Interfaces:**
- Consumes: retinted tokens from Task 2, `.pill`/`.table` conventions from Tasks 5–6.
- Produces: no changes to `HistoryPage.tsx` — this is CSS-only.

- [ ] **Step 1: Replace `.page`, `.heading` (lines 1–21)**

```css
.page {
  padding: var(--s-4);
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: var(--s-3);
  animation: fadeSlideUp 400ms var(--ease-out) both;
}

.header { display: flex; align-items: baseline; justify-content: space-between; flex-wrap: wrap; gap: var(--s-3); }

.headerActions { display: flex; align-items: baseline; gap: var(--s-5); }

.heading {
  font-family: var(--font-heading);
  font-size: 15px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--color-boardroom-navy);
  margin: 0;
}
```

- [ ] **Step 2: Replace `.btnPrimary` and `.exportBtn` (lines 23–34, 151–166) with the flat-link pattern**

```css
.btnPrimary {
  background: transparent;
  color: var(--c-text);
  border: none;
  padding: 0;
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  cursor: pointer;
  text-decoration: underline;
  text-underline-offset: 2px;
  transition: color var(--transition-fast);
}
.btnPrimary:hover { color: var(--color-brand-electric); }

.exportBtn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: transparent;
  border: none;
  padding: 0;
  font-size: 12px;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--c-text);
  cursor: pointer;
  text-decoration: underline;
  text-underline-offset: 2px;
  transition: color var(--transition-fast);
}
.exportBtn:hover:not(:disabled) { color: var(--color-brand-electric); }
.exportBtn:disabled { opacity: .4; cursor: not-allowed; text-decoration: none; }
```

- [ ] **Step 3: Replace `.toolbar`, `.search`, `.select` (lines 36–59)**

```css
.toolbar { display: flex; gap: var(--s-5); align-items: baseline; flex-wrap: wrap; border-bottom: 1px solid var(--c-border-strong); padding-bottom: var(--s-2); }

.search {
  flex: 1;
  min-width: 200px;
  padding: 6px 0;
  border: none;
  border-bottom: 1px solid var(--c-border-strong);
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.03em;
  background: transparent;
  color: var(--c-text);
  outline: none;
}
.search:focus { border-bottom-color: var(--color-brand-electric); }

.select {
  padding: 6px 0;
  border: none;
  border-bottom: 1px solid var(--c-border-strong);
  font-size: 12px;
  text-transform: uppercase;
  background: transparent;
  color: var(--c-text);
}
```

- [ ] **Step 4: Replace `.tableWrap`, `.table th/td` (lines 61–97) to match Task 6's density**

```css
.tableWrap {
  background: #ffffff;
  overflow: hidden;
}

.table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}

.table thead tr {
  border-bottom: 2px solid var(--c-border-strong);
}

.table th {
  text-align: left;
  padding: 0 var(--s-3) 5px 0;
  font-size: 10.5px;
  font-weight: 700;
  color: var(--c-text-mute);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  white-space: nowrap;
}

.table td {
  padding: 6px var(--s-3) 6px 0;
  border-bottom: 1px solid var(--c-border);
  color: var(--c-text);
  vertical-align: middle;
}

.table tbody tr:last-child td { border-bottom: none; }
```

- [ ] **Step 5: Replace `.row:hover` (line 104) to use the new neutral hover tint**

```css
.row:hover td { background: var(--color-lilac-accent); }
```

- [ ] **Step 6: Replace `.dateLabel`/`.dateInput` (lines 169–189) to match the flat-underline input pattern**

```css
.dateLabel {
  display: flex;
  align-items: baseline;
  gap: 6px;
  font-size: 11px;
  font-weight: 500;
  text-transform: uppercase;
  color: var(--c-text-mute);
  white-space: nowrap;
}

.dateInput {
  padding: 4px 0;
  border: none;
  border-bottom: 1px solid var(--c-border-strong);
  font-size: 11px;
  background: transparent;
  color: var(--c-text);
  outline: none;
}
.dateInput:focus { border-bottom-color: var(--color-brand-electric); }
```

- [ ] **Step 7: Run the frontend build to catch any missed selector**

```bash
cd apps/web && npx tsc --noEmit && npm run build
```

- [ ] **Step 8: Visual check against the mockup**

```bash
cd apps/web && npm run dev
```

Load `/calibrations`, compare against `C-History.dc.html` (read it back
from the canvas if needed: `Artifact` tool, `action: "read"`, `url`:
`https://claude.ai/artifact/4xN8SVQW3YJwSj4TJTe6cF`, `path`:
`"project/C-History.dc.html"`).

- [ ] **Step 9: Commit**

```bash
git add apps/web/src/pages/HistoryPage.module.css
git commit -m "feat(web): restyle HistoryPage for Direction C"
```

---

### Task 8: Restyle `RunDetailPage`

**Files:**
- Modify: `apps/web/src/pages/RunDetailPage.module.css:1-494`

**Interfaces:**
- Consumes: same token/pattern set as Task 7.
- Produces: no changes to `RunDetailPage.tsx` (table/card view toggle, verdict filter, rename-inline editing all stay behaviorally identical).

- [ ] **Step 1: Grep for every hardcoded pixel/color value not already driven by a token**

```bash
grep -nE "border-radius:\s*[0-9]|box-shadow|backdrop-filter|#[0-9a-fA-F]{3,6}" apps/web/src/pages/RunDetailPage.module.css
```

- [ ] **Step 2: For each `border-radius` hit, replace with the matching token** (`var(--radius-card)`,
`var(--radius-badge)`, `var(--radius-pill)`, etc. — check the surrounding rule to pick the right one; all resolve to `0` after Task 2, so the visual effect is square corners everywhere).

- [ ] **Step 3: For each raw hex color hit, replace with the matching semantic token** — cross-reference
against `tokens.css`'s `--c-pass`/`--c-fail`/`--c-warn`/`--c-text*`
values; if a hex doesn't match any token (e.g. a one-off tint), replace
it with the closest token and confirm visually in Step 6 rather than
inventing a new untracked color.

- [ ] **Step 4: Replace `.page`/`.heading`-equivalent rule (whatever the top-of-file page/header rule is named) to match `HistoryPage`'s Task 7 Step 1 density** (15px, 800 weight, uppercase heading; `var(--s-4)` page padding; `var(--s-3)` gap) — grep first:

```bash
grep -n "^\.page\b\|^\.header\b\|^\.heading\b" -A 8 apps/web/src/pages/RunDetailPage.module.css
```

- [ ] **Step 5: Densify the results table rule (`.table th`/`.table td` or equivalent) to Task 7 Step 4's values** (2px header rule, 6px cell padding, 1px row hairline) — this is the same pattern as `HistoryPage`, applied to whatever the actual class names are in this file (confirmed distinct from `HistoryPage.module.css` since each page owns its table styling independently, per the codebase's existing pattern of page-local `<table>` markup rather than a shared `<Table>` component for these two pages).

- [ ] **Step 6: Densify the card-view rules (`.card`, `.cardFail`, `.cardTop`, `.cardBottom`, `.devBar*`, `.devVal*`)** referenced from `RunDetailPage.tsx`'s `CertCard` component — remove `border-radius`/`box-shadow` (already 0/none via tokens, but confirm no explicit override remains), reduce `.card` padding to match the dense mockup's compact cell proportions (`8-10px`), and confirm `.devBarPass`/`.devBarFail` (the inline deviation bar) render as flat rectangles, not pills (drop any explicit `border-radius` override).

- [ ] **Step 7: Run the frontend build**

```bash
cd apps/web && npx tsc --noEmit && npm run build
```

- [ ] **Step 8: Visual check — both view modes**

```bash
cd apps/web && npm run dev
```

Load a run detail page, toggle Table/Cards, filter by verdict
(pass/fail/invalid), compare against `C-RunDetail.dc.html`.

- [ ] **Step 9: Commit**

```bash
git add apps/web/src/pages/RunDetailPage.module.css
git commit -m "feat(web): restyle RunDetailPage for Direction C"
```

---

### Task 9: Restyle `LoginPage` — two-panel layout

**Files:**
- Modify: `apps/web/src/pages/LoginPage.module.css:1-160`

**Interfaces:**
- Consumes: same tokens as prior tasks.
- Produces: no changes to `LoginPage.tsx` markup structure (`.wrap > form.card`) — the two-panel look in `C-Login.dc.html` is achieved by restyling `.wrap` and `.card` via CSS Grid, not by adding new DOM nodes, so `LoginPage.test.tsx` (which renders the form and asserts on labels/inputs, not layout) stays green.

- [ ] **Step 1: Confirm the existing test doesn't assert on layout**

```bash
cat apps/web/src/pages/LoginPage.test.tsx
```

Confirm it only queries by label/role (email/password inputs, submit
button) — if it does, this task's CSS-only change is safe; if it
asserts on specific class names tied to the single-card layout, note
that in this task's Step 5 review.

- [ ] **Step 2: Replace `.wrap` to a two-column grid**

```css
.wrap {
  min-height: 100vh;
  display: grid;
  grid-template-columns: 480px 1fr;
  background: #ffffff;
}

@media (max-width: 768px) {
  .wrap { grid-template-columns: 1fr; }
}
```

- [ ] **Step 3: Add a `.brandPanel` rule and reference it from `LoginPage.tsx`**

Since `LoginPage.tsx` currently renders only `<main className={styles.wrap}><form className={styles.card}>...`,
add the brand-statement panel as a new sibling `<aside>` before the
`<form>`:

In `apps/web/src/pages/LoginPage.tsx`, wrap the existing `<main>` content:

```tsx
    <main className={styles.wrap}>
      <aside className={styles.brandPanel}>
        <div>
          <span className={styles.brandPanelTitle}>ITE<br />Calibration</span>
          <div className={styles.brandPanelRule} />
          <p className={styles.brandPanelTagline}>
            Traceable temperature calibration records for the fleet. Sign in with your lab credentials.
          </p>
        </div>
      </aside>
      <form
```

(and add the matching closing — the existing `</form></main>` becomes
`</form></main>` unchanged, since `<aside>` is a sibling that closes
itself before `<form>` opens; only the opening tags change).

```css
.brandPanel {
  display: none;
  border-right: 2px solid var(--c-border-strong);
  align-items: center;
  padding: 0 56px;
}
@media (min-width: 769px) {
  .brandPanel { display: flex; }
}

.brandPanelTitle {
  font-family: var(--font-heading);
  font-size: 22px;
  font-weight: 900;
  text-transform: uppercase;
  line-height: 1.15;
  color: var(--c-text);
}

.brandPanelRule {
  margin-top: 20px;
  height: 2px;
  width: 48px;
  background: var(--color-brand-electric);
}

.brandPanelTagline {
  margin-top: 20px;
  font-size: 13px;
  color: var(--c-text-soft);
  line-height: 1.5;
  max-width: 280px;
}
```

- [ ] **Step 4: Replace `.card` to drop the boxed-card look in favor of a plain centered form**

Find the current `.card` rule (`grep -n "^\.card\b" -A 15
apps/web/src/pages/LoginPage.module.css`) and replace its
`background`/`border`/`border-radius`/`box-shadow` declarations with:

```css
.card {
  /* background/border/radius/shadow removed — Direction C has no card
     chrome around the form; layout/centering rules below are unchanged
     from the current file except where noted */
  display: flex;
  align-items: center;
  justify-content: center;
}
```

Keep this task's diff to the chrome properties only — leave whatever
flex/width/animation properties already center the form within the
right-hand column untouched, and adjust `width` to `340px` to match
`C-Login.dc.html` if the current value differs.

- [ ] **Step 5: Densify `.title`, `.field`, `.input`, `.button` to match `C-Login.dc.html`**

- `.title` → drop to `13px`, `font-weight: 800`, `text-transform: uppercase`, `letter-spacing: 0.06em` (replaces "ITE Calibration" as a large heading — the brand name now lives in `.brandPanelTitle` instead, so `.title`'s text content in `LoginPage.tsx` changes from `"ITE Calibration"` to `"Sign in"`).
- `.input` → flat underline: `border: none; border-bottom: 1px solid var(--c-border-strong); padding: 6px 0; background: transparent;` (remove any existing `border-radius`/full-border box style).
- `.button` → square, `background: var(--color-boardroom-navy); border: 2px solid var(--color-boardroom-navy); color: #fff; text-transform: uppercase; letter-spacing: 0.05em; padding: 10px;`.

- [ ] **Step 6: Update the `<h1>` text in `LoginPage.tsx`**

Change:

```tsx
        <h1 className={`${styles.title} ${leaving ? styles.titleLeaving : ""}`}>
          ITE Calibration
        </h1>
```

to:

```tsx
        <h1 className={`${styles.title} ${leaving ? styles.titleLeaving : ""}`}>
          Sign in
        </h1>
```

- [ ] **Step 7: Run the existing test**

```bash
cd apps/web && npx vitest run src/pages/LoginPage.test.tsx
```

Expected: PASS. If it asserts on the literal text `"ITE Calibration"`
anywhere, update that assertion to match Step 6's new copy (the brand
name still appears, just in the new `.brandPanelTitle`, not `.title`).

- [ ] **Step 8: Visual check**

```bash
cd apps/web && npm run dev
```

Load `/login` at desktop width (compare against `C-Login.dc.html`) and
at 375px width (confirm the `.brandPanel` collapses per the
`max-width: 768px` rule in Step 2 and the form stays usable).

- [ ] **Step 9: Commit**

```bash
git add apps/web/src/pages/LoginPage.tsx apps/web/src/pages/LoginPage.module.css
git commit -m "feat(web): restyle LoginPage as two-panel layout for Direction C"
```

---

### Task 10: Sweep remaining pages for leftover glass-era hardcoded values

**Files:**
- Modify (as needed, based on grep results): `apps/web/src/pages/SettingsPage.module.css`, `LoggersPage.module.css`, `LoggerProfilePage` (if it has a CSS module — check first), `NewCalibrationPage.module.css`, `CertificatePage.module.css`, `AdminUsersPage.module.css`, `UpcomingPage.tsx` (if it has inline styles), `RegisterPage`/`ResetPasswordPage` (check for CSS modules)

**Interfaces:**
- Consumes: tokens from Task 2, shared component restyles from Tasks 3–6.
- Produces: no more `backdrop-filter`, no hardcoded hex colors outside `tokens.css`, no hardcoded `border-radius` values, across every remaining page.

- [ ] **Step 1: List every CSS module in the pages directory not already touched by Tasks 1–9**

```bash
ls apps/web/src/pages/*.module.css
```

Cross off `HistoryPage.module.css`, `RunDetailPage.module.css`,
`LoginPage.module.css`, `OverviewPage.module.css` (handled). Check
whether `LoggerProfilePage.tsx`, `UpcomingPage.tsx`, `RegisterPage.tsx`,
`ResetPasswordPage.tsx` have their own `.module.css` (some pages in this
codebase render entirely through shared components — confirm with `ls`
before assuming a file exists).

- [ ] **Step 2: Grep every remaining page CSS module for glass-era leftovers**

```bash
grep -nE "backdrop-filter|border-radius:\s*[0-9]|box-shadow|rgba\(255,\s*255,\s*255" apps/web/src/pages/SettingsPage.module.css apps/web/src/pages/LoggersPage.module.css apps/web/src/pages/NewCalibrationPage.module.css apps/web/src/pages/CertificatePage.module.css apps/web/src/pages/AdminUsersPage.module.css
```

- [ ] **Step 3: For each match, apply the same substitution pattern used in Tasks 3, 7, and 8**:
  - `backdrop-filter`/`-webkit-backdrop-filter` → delete the declaration.
  - Explicit `border-radius: <n>px` → replace with the matching `var(--radius-*)` token (all resolve to `0`), or delete if it's redundant with a parent that already inherits `0`.
  - `box-shadow` → delete (Direction C has no elevation).
  - `rgba(255,255,255,.66)`/`.82`/etc. (translucent white, the glass-era surface pattern) → replace with `var(--c-surface)` (now opaque `#ffffff`).
  - Any raw hex matching one of the old glass-era values (`#eceee6`, `#0c1754`, the pre-2026-09-16 "Officevibe" hexes if any survived, or the pre-Task-2 boardroom-navy `#17181a`) → replace with the matching token from Task 2's new palette.

- [ ] **Step 4: Run the full frontend build and test suite**

```bash
cd apps/web && npx tsc --noEmit && npx vitest run && npm run build
```

Expected: all pass (11/11 or whatever the current suite count is —
confirm against the count reported in the most recent `PROGRESS.md` log
entry before this plan).

- [ ] **Step 5: Visual sweep across every route**

```bash
cd apps/web && npm run dev
```

Load every route once: `/`, `/calibrations`, `/calibrations/:id` (any
existing run), `/new`, `/upcoming`, `/loggers`, `/loggers/:id` (any
existing logger), `/certificate`, `/settings`, `/admin/users` (as an
admin user), `/login`, `/register`, `/reset-password`. Confirm nothing
still shows a rounded corner, a shadow, a blur, or the old warm-neutral
background color.

- [ ] **Step 6: Commit**

```bash
git add apps/web/src/pages
git commit -m "fix(web): sweep remaining pages for leftover glass-era styling"
```

---

### Task 11: Accessibility and quality audit

**Files:** none created — this task verifies Tasks 1–10's output.

**Interfaces:** none — read-only verification task.

- [ ] **Step 1: Run the `web-design-guidelines` skill against the built UI**

Invoke the `web-design-guidelines` skill (fetches Vercel's current
Web Interface Guidelines) against `apps/web` with the dev server running.
Focus on: focus-visible states (Direction C removed several `box-shadow`
focus rings along with the elevation system in Task 2 — confirm inputs
still show a visible focus indicator, e.g. the `border-bottom-color`
change on `:focus` already present in `HistoryPage.module.css`'s
`.search`/`.dateInput` rules is sufficient, or add `outline` back
explicitly where it's missing), redundant status cues (the new
`StatusPill` relies on color + text label, not color alone — confirm
every verdict/status still has its text label visible, not just color),
and empty/dense/error states across History (empty table), Overview (no
runs yet), and Run Detail (all-invalid run).

- [ ] **Step 2: Contrast check every retinted color pairing against pure white**

Use the skill's stated floor (4.5:1 normal text, 3:1 large text/UI
components) and check:
- `--c-text` (`#0a0a0a`) on `--c-bg` (`#ffffff`) — near-black on white, will clear easily.
- `--c-text-mute` (`#6e6e6e`) on `#ffffff` — verify ≥4.5:1 (this is a new value, not carried over from the audited 2026-09-16 palette, since the old mute value `#5f645b` was audited against the old warm-neutral `#eceee6` background, not pure white).
- `--color-brand-electric`/`--c-pass` (`#0f6b26`) as plain text on `#ffffff` — already audited at 6.66:1 white-on-this for buttons; confirm the *text-on-white* direction (this color as foreground, not background) separately, since those are different contrast calculations.
- `--c-warn` (`#835408`), `--c-fail` (`#ad2823`), `--c-info` (`#136679`) as plain text on `#ffffff` — same check.

If any value fails 4.5:1, darken it minimally (same approach the
2026-09-16 audit used — see `tokens.css`'s existing comments for the
precedent) and update both `tokens.css` and this plan's `DESIGN.md`
rewrite (Task 1) to record the corrected value and the measured ratio.

- [ ] **Step 3: Check at the four standard breakpoints**

375px, 768px, 1024px, 1440px — confirm the sidebar's `max-width: 768px`
collapse behavior (unchanged from before this redesign, per
`AppShell.module.css`'s existing `@media` block) still works, and that
`LoginPage`'s new two-panel layout (Task 9) collapses correctly at
375px.

- [ ] **Step 4: Fix any findings, then re-run Step 1**

- [ ] **Step 5: `gitnexus` full change-detection pass before considering the redesign complete**

```bash
node .gitnexus/run.cjs detect-changes --scope all --repo .
```

Confirm no `partial`/`truncated` result and no unexplained HIGH/CRITICAL
risk. If `UNKNOWN` risk appears anywhere, follow the repo's rule: confirm
by text search before treating it as safe, don't proceed on the strength
of a zero.

- [ ] **Step 6: Commit any fixes from Step 4**

```bash
git add -A
git commit -m "fix(web): accessibility/contrast fixes from Direction C audit"
```

---

### Task 12: Update project records

**Files:**
- Modify: `PROGRESS.md` (append one `## Log` line)
- Modify: `HANDOFF.md` (rewrite per the `handoff` skill)
- Create: `logs/DAILY-<today's date>.md` entry (append, don't overwrite if today's file already exists)

**Interfaces:** none — documentation only.

- [ ] **Step 1: Run the `handoff` skill** (or perform its steps manually if run standalone) to log this
plan's execution: what was built, test/build results, any contrast
values corrected in Task 11, and the final state of `main`.

- [ ] **Step 2: Confirm `~/Notes/Work/Calibration/`'s symlinks still resolve** (per this repo's existing
convention — `HANDOFF.md`, `PROGRESS.md`, `logs/` are symlinked into the
Obsidian vault; this plan doesn't add new top-level files, so no `INDEX.md`
update is needed).

- [ ] **Step 3: Commit**

```bash
git add PROGRESS.md HANDOFF.md logs/
git commit -m "docs: log Direction C dense redesign implementation"
```

---

## Self-Review Notes

- **Spec coverage**: every `/DESIGN.md` section from Task 1 (identity, brand, tokens, typography, component patterns, out-of-scope) maps to a task — tokens→Task 2, glass removal→Task 3, sidebar/topbar→Task 4, pills/tiles→Task 5, grid/table→Task 6, per-page density→Tasks 7–9, remaining pages→Task 10, contrast/audit→Task 11.
- **Placeholder scan**: no task in this plan says "add appropriate styling" or "similar to Task N" without showing the actual CSS — Tasks 8 and 10 use grep-driven sweeps instead of pre-written diffs for files not read during planning (494-line `RunDetailPage.module.css` and the eight not-directly-mocked pages), which is a deliberate scope decision, not a placeholder: each grep step names the exact pattern to find and the exact substitution rule to apply, mirroring the concrete examples already shown in Tasks 7 and 3.
- **Type/name consistency**: every CSS variable name referenced across tasks (`--c-border-strong`, `--color-boardroom-navy`, `--c-text-mute`, etc.) is defined once in Task 2 and never redefined differently later. `StatusPill`'s prop contract (`value: RunStatus | Verdict | string`) and `StatTile`'s (`label`, `value`, `unit`, `accent`) are unchanged throughout — confirmed no task alters either component's `.tsx` file, only their `.module.css`.
