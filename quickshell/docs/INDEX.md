# QuickShell Documentation Index

> **Repository:** `/home/yemi/.config/quickshell`  
> **Framework:** Quickshell / Qt 6.10 QML  
> **Last Updated:** 2026-08-05

---

## Directory Structure

```
docs/
├── INDEX.md                    # This index file
├── README.md                   # Project overview
│
├── color-system/               # Color and wallpaper system documentation
│   ├── INIR_THEME_SYSTEM_MAP.md
│   ├── YEMI_COLOR_WALLPAPER_AUDIT.md
│   ├── UNIFIED_PIPELINE.md
│   └── COLOR_FIX_PLAN.md
│
├── architecture/               # Architecture and system blueprints
│   ├── INIR_SETTINGS_BLUEPRINT_MASTER.md
│   └── INIR_THEME_SYSTEM_MAP.md (copy / symlink)
│
├── audit/                      # Audit reports and findings
│   └── audit-report.md
│
├── config/                     # Configuration documentation (to be added)
│
└── .kiro/, .lingma/, .roo/     # Agent configuration (not user docs)
```

---

## Quick Links

| Category | Document | Description |
|----------|----------|-------------|
| **Color System** | [color-system/INIR_THEME_SYSTEM_MAP.md](color-system/INIR_THEME_SYSTEM_MAP.md) | Color token hierarchy, Theme/Dyn/Flags singletons |
| **Color System** | [color-system/YEMI_COLOR_WALLPAPER_AUDIT.md](color-system/YEMI_COLOR_WALLPAPER_AUDIT.md) | Wallpaper color extraction pipeline audit |
| **Color System** | [color-system/UNIFIED_PIPELINE.md](color-system/UNIFIED_PIPELINE.md) | Single-source-of-truth color architecture |
| **Color System** | [color-system/COLOR_FIX_PLAN.md](color-system/COLOR_FIX_PLAN.md) | Incremental color system fix plan |
| **Architecture** | [architecture/INIR_SETTINGS_BLUEPRINT_MASTER.md](architecture/INIR_SETTINGS_BLUEPRINT_MASTER.md) | iNiR settings system blueprint |
| **Audit** | [audit/audit-report.md](audit/audit-report.md) | Comprehensive codebase audit report |

---

## Overview

This project is a Quickshell-based dynamic shell interface for Linux desktops (Hyprland/Niri). Key systems documented:

### 1. Color System (`docs/color-system/`)
- **Theme Singleton**: 31 color tokens with dynamic/static toggle (`singletons/Theme.qml`)
- **Dyn Singleton**: Wallpaper-derived colors from `colors.json` (`singletons/Dyn.qml`)
- **Flags Singleton**: Session flags including `paletteMode` and `systemMood` (`singletons/Flags.qml`)
- **Wallpaper Processing**: `wallcolors.py` extracts colors via ImageMagick histogram

### 2. Configuration (`config/`)
- **Config.qml**: Main configuration singleton (37 lines - simplified from iNiR's 2282 lines)
- **Appearance.qml**: Appearance singleton with color tokens

### 3. Architecture (`docs/architecture/`)
Documentation from the iNiR project, showing the more complete feature set that inspired this workspace

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
| Bar panel | `modules/bar/Bar.qml` |
| Pill UI | `modules/pill/` |
| OSD | `modules/osd/` |
| Services | `services/` |
| Scripts | `scripts/` |

---

## Recent Changes

### 2026-08-05 - Documentation Organization
- Created `docs/` directory structure
- Organized markdown files by category
- Added this INDEX.md for navigation

### 2026-08-05 - Color System Audit Complete
- Updated `INIR_THEME_SYSTEM_MAP.md` with actual workspace state
- Documented missing `AdaptedMaterialScheme.qml` file
- Identified schema path discrepancy between Matugen and Dyn.qml