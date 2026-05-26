# CLAUDE.md — Calibration Pro Desktop (Cross-Platform)

## Project Vision
A premium desktop application for Windows and macOS. The goal is "Single Codebase, Zero Compromise"—ensuring Windows users experience the same high-end fluid animations as macOS users.

## Tech Stack & Compatibility
- **UI Engine**: Flet (Flutter-backed) for hardware-accelerated rendering on Windows.
- **Windows Specifics**: Supports Windows 10/11 with Acrylic/Mica effect integration.
- **Mac Specifics**: Optimized for Apple Silicon (M4 Pro) with ProMotion (120Hz) support.

## UI/UX Standards
- **Motion**: Use `ft.AnimationCurve.EASE_OUT_EXPO` for all transitions to give a "luxury" software feel.
- **Windows Performance**: Force hardware acceleration in `settings.json`.
- **Bilingual**: Support Japanese/English UI for IUJ/Sato Sangyo stakeholders.

## Build Commands
- `flet build windows` (Run on Windows to generate .exe)
- `flet build macos` (Run on Mac to generate .app)