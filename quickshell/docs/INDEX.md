# QuickShell Documentation Index

> **Repository:** `/home/yemi/.config/quickshell`
> **Framework:** Quickshell / Qt 6.10 QML
> **Last Updated:** 2026-08-22

---

## Directory Structure

```
docs/
├── INDEX.md                              # This index file
├── PROJECT_MAP.md                        # High-level project map / generated-doc manifest
│
├── color-system/                         # Color + wallpaper (Dominance) engine docs
│   ├── THEME_SYSTEM_MAP_CURRENT.md
│   ├── MATUGEN_CLI_NOTES.md
│   ├── MATUGEN_OUTPUT_CONTRACT.md
│   ├── YEMISHELL_THEME_REBUILD_CHECKLIST.md
│   └── matugen-samples/                  # Sample matugen outputs (dark.json, light.json)
│
├── architecture/                         # System blueprints (iNiR-inspired)
│   └── INIR_SETTINGS_BLUEPRINT_MASTER.md
│
├── components/                           # Per-component reference docs (auto-generated)
│   ├── index.md                          # Component index
│   ├── Appearance.md  Audio.md  Bar.md  Battery.md  ...
│   └── (one .md per QML component)
│
├── plans/                                # Active planning docs
│   ├── YEMISHELL_THEME_REBUILD_PLAN.md
│   └── Yemi-Shell Theme Rebuild Checklist.md
│
└── reference/                            # External / scope reference material
    ├── INIR_WAFFLE_SCOPE.md              # Waffle porting scope (see `whole-waffle` branch)
    └── iNiR-settings-General-section.md
```

> Project overview lives at `quickshell/README.md` (repo root of the shell).

---

## Quick Links

| Category | Document | Description |
|----------|----------|-------------|
| **Color System** | [color-system/THEME_SYSTEM_MAP_CURRENT.md](color-system/THEME_SYSTEM_MAP_CURRENT.md) | Current theme token map (Theme/Dyn/Flags + Dominance) |
| **Color System** | [color-system/YEMISHELL_THEME_REBUILD_CHECKLIST.md](color-system/YEMISHELL_THEME_REBUILD_CHECKLIST.md) | Dominance engine rebuild checklist |
| **Color System** | [color-system/MATUGEN_CLI_NOTES.md](color-system/MATUGEN_CLI_NOTES.md) | Matugen CLI notes |
| **Color System** | [color-system/MATUGEN_OUTPUT_CONTRACT.md](color-system/MATUGEN_OUTPUT_CONTRACT.md) | Matugen output contract |
| **Architecture** | [architecture/INIR_SETTINGS_BLUEPRINT_MASTER.md](architecture/INIR_SETTINGS_BLUEPRINT_MASTER.md) | iNiR settings system blueprint |
| **Components** | [components/index.md](components/index.md) | Index of per-component reference docs |
| **Plans** | [plans/YEMISHELL_THEME_REBUILD_PLAN.md](plans/YEMISHELL_THEME_REBUILD_PLAN.md) | Theme rebuild plan |
| **Reference** | [reference/INIR_WAFFLE_SCOPE.md](reference/INIR_WAFFLE_SCOPE.md) | Waffle port scope (reference only) |

---

## Overview

Quickshell-based dynamic shell for Linux (Hyprland/Niri). Documented systems:

### 1. Color System (`docs/color-system/`)
- **Dominance engine** — `scripts/dominance-extract.py` + `scripts/dominance-engine.py` → `~/.cache/yemi-shell/colors.json`
- **Theme / Dyn / Flags** singletons consume that palette
- Matugen retained only as legacy/reference

### 2. Components (`docs/components/`)
Auto-generated reference for each QML component (Bar, Pill, Mixer, Battery, etc.). Start at `components/index.md`.

### 3. Architecture (`docs/architecture/`)
Blueprints from the iNiR project that inspired this workspace.

### 4. Reference (`docs/reference/`)
External scope material. `INIR_WAFFLE_SCOPE.md` describes the Waffle port; the actual Waffle code is preserved on the **`whole-waffle`** branch for reference and must NOT be merged.

---

## File Locations (Current Workspace)

| Component | Path |
|-----------|------|
| Main entry | `shell.qml` |
| Config | `config/Config.qml` |
| Appearance | `config/Appearance.qml` |
| Theme singleton | `singletons/Theme.qml` |
| Dyn singleton | `singletons/Dyn.qml` |
| Flags singleton | `singletons/Flags.qml` |
| Pill UI | `modules/pill/` |
| OSD | `modules/osd/` |
| Services | `services/` |
| Scripts | `scripts/` |

---

## Recent Changes

### 2026-08-22 - Documentation Reorganization
- Moved `YEMI SHELL DOC/doc/` → `docs/components/`
- Moved `YEMI SHELL DOC/PROJECT_MAP.md` → `docs/PROJECT_MAP.md`
- Moved `quickshell/plans/` → `docs/plans/`
- Moved root `INIR_WAFFLE_SCOPE.md` + `docs/iNiR-settings-General-section.md` → `docs/reference/`
- Rewrote this INDEX to match the real layout
