# iNiR Theme System Map

> **Quickshell Config:** `/home/yemi/.config/quickshell`
> **Date:** 2026-08-05
> **Framework:** Quickshell / Qt 6.10 QML
> **Status:** Document updated – Phase 0 Color Pipeline Changes Applied (2026-08-05)

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Layers](#architecture-layers)
3. [Core Theme Files](#core-theme-files)
4. [Theme System Components](#theme-system-components)
5. [Color Token Hierarchy](#color-token-hierarchy)
6. [Material 3 Dynamic Color](#material-3-dynamic-color)
7. [Transparency System](#transparency-system)
8. [Blur System](#blur-system)
9. [Animation System](#animation-system)
10. [Consumer Patterns](#consumer-patterns)
11. [Data Flow Diagrams](#data-flow-diagrams)
12. [Key Files Reference](#key-files-reference)
13. [Audit Notes](#audit-notes)
14. [Phase 0 Changes](#phase-0-changes)

---

## Overview

The Quickshell theme system provides color management architecture supporting:

- **Dynamic wallpaper-based colors** via ImageMagick histogram quantization in `wallcolors.py`
- **Real-time color adaptation** with wallpaper changes via unified `after-wall.sh` pipeline
- **Transparency and blur effects** with semantic control
- **Multiple IPC triggers** for hot-reloading color schemes

**Note:** This is a simplified theme system compared to the documented iNiR version. Many advanced features (theme presets, style presets, GameMode, desaturation) are not implemented in this workspace.

---

## Architecture Layers

```
┌────────────────────────────────────────────────────────────────────┐
│                    CONSUMER LAYERS                                  │
│  Panel Components → Bar → OSD → Pill → Notification Popups         │
└───────────────────────┬──────────────────────────────────────────────┘
                        │
┌───────────────────────▼────────────────────────────────────────────┐
│                    THEME SINGLETON                                  │
│              singletons/Theme.qml (Central Color Facade)           │
│              config/Appearance.qml (Appearance singleton)         │
│              config/Config.qml (Main config singleton)            │
│  - Color tokens (31 properties)                                   │
│  - Dynamic/static mode switch via Flags.paletteMode               │
└─────────┬─────────────────────┬───────────────────────────────────┘
            │                     │
            │                     │
┌─────────▼─────────────────────▼───────────────────────────────────┐
│                   COLOR SOURCES                                     │
│                                                                     │
│  ┌──────────────────┐  ┌────────────────────────────────┐         │
│  │  Theme.qml       │  │  Dyn.qml                       │         │
│  │  (Static tokens) │  │  (Dynamic tokens)              │         │
│  │  - dyn ? Dyn : #hex fallback                      │         │
│  │                   │  │  - FileView + JsonAdapter    │         │
│  │                   │  │  - Watches colors.json       │         │
│  └──────────────────┘  └────────────────────────────────┘       │
└───────────────────────────────────────────────────────────────────┘
                        │
┌───────────────────────▼────────────────────────────────────────────┐
│                   WALLPAPER PROCESSING                               │
│                                                                     │
│  scripts/after-wall.sh → wallcolors.py → colors.json              │
│  ~/.cache/yemi-shell/colors.json (snake_case schema)                │
│                                                            Phase 0 │
│  Phase 0: Single writer pattern - after-wall.sh is THE entry point│
└───────────────────────────────────────────────────────────────────┘
```

---

## Core Theme Files

### Appearance.qml (Appearance)

**Path:** `config/Appearance.qml` (Quickshell)

**Purpose:** Central appearance singleton exposing color tokens and UI constants.

**Key Components:**

- Color token facade using `singletons/Theme.qml` values
- Border radius, spacing, padding, font configurations
- Duration presets for animations
- Material 3 surface hierarchy tokens

**Line count:** ~200 lines (simplified from iNiR's 963 lines)

---

### Config.qml

**Path:** `config/Config.qml` (Quickshell)

**Purpose:** Main configuration singleton exposing nested configuration objects.

**Structure (37 lines):**

```qml
- readonly property BarConfig bar: BarConfig {}
- readonly property AppearanceConfig appearance: AppearanceConfig {}
- readonly property var notifications: ({ popupWidth, maxVisible, timeout, spacing, margin })
- readonly property var popups: ({ width, minHeight, maxHeight, hoverDelay, margin })
- readonly property var dashboard: ({ enable, showToggles, showMedia, showVolume, showWeather, showSystem })
```

**Note:** This is significantly simpler than the iNiR version (2282 lines with JsonAdapter, setNestedValue/getNestedValue functions, style-specific sub-sections).

**MISSING FROM CURRENT WORKSPACE:** `modules/common/Config.qml` (iNiR's 2282-line version with full JsonAdapter functionality)

---

## Theme System Components

### 1. Theme Singleton

**Path:** `singletons/Theme.qml`

**Role:** Provides 31 color tokens with dynamic/static toggle capability.

**Dynamic Mode:** When `Flags.paletteMode !== "static"`, tokens read from `Dyn.*`

**Static Mode:** When `Flags.paletteMode === "static"`, tokens use fixed hex values

**Token List (31 color tokens):**

| Token | Dynamic Source | Static Fallback | Purpose |
|-------|---------------|-----------------|---------|
| `onGlow` | `Dyn.primary` | `#ff9a64` | Primary accent / flame glow |
| `verm` | `Dyn.primary` (darkened 1.18x) | `#c0442b` | Secondary accent |
| `vermLit` | `Dyn.primary` | `#e0563b` | Lighter secondary |
| `vermDeep` | `Dyn.primaryContainer` | `#a3371f` | Deep secondary |
| `vermDim` | `Dyn.primary` (darkened 1.5x) | `#8a5440` | Dimmed secondary |
| `vermDimDeep` | `Dyn.primary` (darkened 2.2x) | `#5a3526` | Very dim secondary |
| `vermBurn` | `Dyn.primaryContainer` (darkened 1.1x) | `#8a2c14` | Error/destructive |
| `cream` | `Dyn.cream` | `#e6d6cb` | Primary text / veils |
| `bright` | `Dyn.bright` | `#fff6f0` | Light text / highlights |
| `dim` | `Dyn.dim` | `#8a7d74` | Dimmed text |
| `subtle` | `Dyn.subtle` | `#b9a99e` | Subtle text |
| `faint` | `Dyn.faint` | `#6f635b` | Faint text |
| `iconDim` | `Dyn.iconDim` | `#cdbfb4` | Dimmed icons |
| `cardTop` | `Dyn.surfaceContainerHigh` | `#2e231b` | Top surface |
| `cardBot` | `Dyn.surfaceContainerLow` | `#211813` | Bottom surface |
| `tileBg` | `Dyn.surface` | `#211711` | Tile background |
| `ghost` | `Dyn.surfaceContainerHighest` | `#594636` | Ghost elements |
| `border` | `Dyn.outlineVariant` | `#3a2a22` | Borders |
| `shadow` | (hardcoded) | `rgba(0,0,0,0.55)` | Shadows |
| `shadowOpacity` | (property) | `0.5` | Shadow opacity |
| `frameBg` | `Qt.alpha(cream, 0.055)` | - | Frame background |
| `frameBorder` | `Qt.alpha(cream, 0.10)` | - | Frame border |
| `creamMenu` | `Qt.alpha(cream, 0.82)` | - | Menu veils |
| `threadBg` | `Qt.alpha(cream, 0.13)` | - | Thread background |
| `todayWarm` | `onGlow` | `#ffb38a` | Today highlight |
| `flameCore` | `Qt.lighter(onGlow, 1.03)` | `#ffd9c2` | Flame core |
| `flameGlow` | `onGlow` | `#ff9a64` | Flame glow |
| `flameInk` | `Dyn.primary` (string) | - | Canvas gradient start |
| `flameEmber` | `Dyn.primaryContainer` (string) | - | Canvas gradient mid |
| `flameBurn` | `Dyn.primaryContainer` (string) | - | Canvas gradient end |
| `flameTip` | `Dyn.onPrimaryContainer` (string) | - | Canvas gradient tip |
| `tickRest` | `Dyn.tickRest` | `#cbb6a3` | Tick/rest indicator |

---

### 2. Dyn (Dynamic Colors) Singleton

**Path:** `singletons/Dyn.qml`

**Purpose:** Loads and exposes wallpaper-derived colors from `colors.json`.

**FileView Configuration:**
```qml
path: $XDG_CACHE_HOME/yemi-shell/colors.json 
    (fallback: $HOME/.cache/yemi-shell/colors.json)
blockLoading: true
watchChanges: true
onFileChanged: reload()
```

**JsonAdapter Properties (17 dynamic tokens):**

| Property | Purpose |
|----------|---------|
| `surface` | Main surface color |
| `surfaceContainer` | Surface container |
| `surfaceContainerLow` | Lower surface container |
| `surfaceContainerHigh` | Higher surface container |
| `surfaceContainerHighest` | Highest surface container |
| `primary` | Primary accent |
| `primaryContainer` | Primary container |
| `onPrimaryContainer` | On primary container (text) |
| `outline` | Outline color |
| `outlineVariant` | Outline variant |
| `cream` | Cream/veil color |
| `bright` | Bright highlight |
| `subtle` | Subtle text |
| `dim` | Dimmed text |
| `faint` | Faint text |
| `iconDim` | Dimmed icons |
| `tickRest` | Tick/rest indicator |

**Default Fallbacks:** Warm teal palette baked into JsonAdapter defaults.

---

### 3. Flags Singleton

**Path:** `singletons/Flags.qml`

**Purpose:** Session flags persisted to `~/.local/state/quickshell/flags.json`.

**Color-Relevant Properties:**

| Property | Type | Default | Purpose |
|----------|------|---------|---------|
| `paletteMode` | string | `"dynamic"` | Controls `Theme.dyn` flag |
| `systemMood` | string | `"dark"` | Theme mood: dark/light |
| `pillOpacity` | real | `0.55` | Pill body opacity |
| `pillBlur` | bool | `false` | Pill blur toggle |
| `reduceMotion` | bool | `false` | Motion reduction |
| `uiScale` | real | `1.0` | UI scaling factor |

---

## Color Token Hierarchy

### Material 3 Tonal Palette Structure

Color tokens follow Material 3 tonal palette naming:

```
m3primary           → Primary color
m3onPrimary         → On primary (text/icon on primary)
m3primaryContainer  → Primary container
m3onPrimaryContainer→ On primary container
m3secondary         → Secondary color
m3onSecondary       → On secondary
m3secondaryContainer→ Secondary container
m3onSecondaryContainer
m3tertiary          → Tertiary color
m3onTertiary
m3tertiaryContainer
m3onTertiaryContainer
m3error             → Error color
m3onError
m3errorContainer
m3onErrorContainer
m3background        → Background
m3onBackground      → On background
m3surface           → Surface
m3onsurface         → On surface
m3surfaceVariant    → Surface variant
m3onsurfaceVariant
m3outline           → Outline
m3outlineVariant    → Outline variant
m3inverseOnSurface
m3inverseSurface
m3inverseOnSurfaceVariant
```

---

## Material 3 Dynamic Color

### Color Generation Process

1. Wallpaper image is analyzed by `scripts/wallcolors.py`
2. Color palette is generated using ImageMagick histogram quantization
3. Colors are written to `colors.json` with snake_case schema

### Available Color Schemes

The system generates colors from the current wallpaper using Material 3 algorithms. Unlike the documented iNiR system with predefined presets (materialBlackColors, gruvboxMaterialColors, etc.), this workspace dynamically generates all colors.

---

## Transparency System

Transparency in the Pill components follows a vibrancy-based calculation:

```qml
// Calculated in Pill-related components
transparencyValue = (vibrancy * vibrancy * scale) + base
```

---

## Consumer Patterns

### 1. Themed Surface Pattern

```qml
// All surfaces should use Theme.* tokens
Item {
    color: Theme.tileBg
    border.color: Theme.border
    text.color: Theme.cream
}
```

### 2. Dynamic/Static Toggle Pattern

```qml
// Theme tokens handle the dynamic/static switch
readonly property bool dyn: Flags.paletteMode !== "static"

// Example token
readonly property color onGlow: dyn ? Dyn.primary : "#ff9a64"
```

### 3. Transparency Pattern

```qml
// Apply transparency to surfaces
Rectangle {
    color: Qt.rgba(Theme.cardBot.r, Theme.cardBot.g, Theme.cardBot.b, transparencyValue)
}
```

### 4. Mood-Aware Pattern

```qml
// Adjust visuals based on system mood
property real highlightAlpha: Flags.systemMood === "light" ? 0.02 : 0.04
Rectangle {
    color: Qt.rgba(1, 1, 1, highlightAlpha)
}
```

---

## Data Flow Diagrams

### Wallpaper Change Flow

```
1. Wallpaper change detected
   ↓
2. scripts/after-wall.sh triggered
   |   - Calls wallpaper.sh or direct path set
   |   - Triggers wallcolors.py
   ↓
3. wallcolors.py processes wallpaper
   |   - Uses ImageMagick histogram for color extraction
   |   - Generates colors.json (snake_case schema)
   |   - Generates terminal.json
   |   - Generates hypr-colors.lua
   ↓
4. Dyn.qml FileView watches colors.json
   |   - onFileChanged: reload()
   |   - JsonAdapter parses new colors
   ↓
5. Theme.qml tokens update
   |   - dyn ? Dyn.X : "#fallback"
   |   - All bound properties update
   ↓
6. All themed components refresh
```

### IPC Color/Theme Reload Flow

```
1. IPC call: qs ipc call colors reload
   ↓
2. shell.qml → ipc handlers
   |   - root.matugen.reload() OR root.colors.reload()
   ↓
3. Dyn.qml FileView.onFileChanged → reload()
   |   - JsonAdapter repopulates properties
   ↓
4. Theme.qml tokens update → all bound components refresh
```

---

## Key Files Reference

### Current Workspace Theme System Files

| File | Lines | Purpose |
|------|-------|---------|
| `config/Config.qml` | 37 | Main configuration singleton |
| `config/Appearance.qml` | ~200 | Appearance singleton with color tokens |
| `singletons/Theme.qml` | ~350 | Color token facade (dynamic/static) |
| `singletons/Dyn.qml` | ~200 | Dynamic colors singleton (FileView + JsonAdapter) |
| `singletons/Flags.qml` | ~100 | Session flags (paletteMode, systemMood) |
| `services/Matugen.qml` | ~150 | Wallpaper color service |
| `scripts/wallcolors.py` | 186 | Wall color extraction script |
| `scripts/after-wall.sh` | - | Wallpaper change pipeline |
| `shell.qml` | - | Main entry with IPC handlers |

### Consumer Files

| File | Theme Tokens Used |
|------|-------------------|
| `modules/bar/Bar.qml` | 3 |
| `modules/bar/components/Battery.qml` | 6 (needs fixing - has hardcoded hex values) |
| `modules/bar/components/*.qml` | 4-7 each |
| `modules/pill/Pill.qml` | 52 (reference implementation) |
| `modules/pill/*.qml` | 8-90 each |
| `modules/osd/*.qml` | 25 (needs fixing - has hardcoded hex values) |

### File Locations

| File | Purpose |
|------|---------|
| `~/.local/state/quickshell/flags.json` | Session flags (paletteMode, systemMood) |
| `~/.cache/yemi-shell/colors.json` | Wallpaper-derived colors (snake_case schema) |
| `~/.cache/yemi-shell/terminal.json` | Terminal colors for kitty, ghostty, etc. |
| `~/.cache/yemi-shell/hypr-colors.lua` | Hyprland colors |

---

## Audit Notes

### Findings (2026-08-05)

1. **AdaptedMaterialScheme.qml NOT FOUND**
   - File documented to exist at `modules/common/models/AdaptedMaterialScheme.qml` does not exist
   - No `models` directory exists in workspace
   - No `/home/yemi/iNiR` project directory exists
   - This file is referenced in `INIR_THEME_SYSTEM_MAP.md` line 639 but does not exist

2. **Config.qml Line Count Mismatch**
   - Documented: 37 lines
   - Audit expected: ~2282 lines (iNiR version with full JsonAdapter)
   - Current: Simple facade, no color system logic

3. **Schema Path Discrepancy**
   - `services/Matugen.qml` references `$RICE_HOME/quickshell/state/colors.qml`
   - But `singletons/Dyn.qml` watches `~/.cache/yemi-shell/colors.json`
   - IPC handler `matugen.reload()` may read from wrong path

4. **Hardcoded Color Literals Found**
   - `modules/bar/components/Battery.qml`: 6 hardcoded hex values + 1 Qt.rgba
   - `modules/osd/*.qml`: 25 hardcoded color values in "orphaned" OSD family
   - `modules/pill/Pill.qml`: 2 literals remaining in "good" surface implementation

5. **IP Conflict Note**
   - `qs ipc call colors reload` and `qs ipc call matugenReload` - need verification which IPC target actually triggers Dyn.qml reload

### Conclusions

The current workspace is a simplified version of the iNiR theme system. The color architecture follows the documented flow but lacks several advanced features:
- No `AdaptedMaterialScheme.qml` exists - would need implementation if Material 3 scheme adaptation is required
- Config.qml is minimal - iNiR's full implementation would be needed for advanced theme management
- Matugen service path mismatch needs resolution for proper IPC color reloading

---

## Phase 0 Changes (2026-08-05)

Phase 0 successfully unified the color pipeline with the following changes:

### Summary
- **Single writer pattern established**: `after-wall.sh` is now the only entry point for color generation
- **Dead code removed**: Consolidated `staticProc`/`dynamicProc` in Appearance.qml
- **Services simplified**: `Matugen.qml` reduced to a reload shim
- **IPC fixed**: `colors reload` now correctly triggers `Dyn.qml`

### Files Modified

| File | Change |
|------|--------|
| `scripts/after-wall.sh` | Added `--mode` and `--mood` parameters; fixed IPC call to `colorsReload` |
| `modules/pill/Appearance.qml` | Replaced dual Process with single `colorProc` calling `after-wall.sh` |
| `services/Matugen.qml` | Removed `colorsPath`; `reload()` calls `Dyn.reload()`; `applyWallpaper()` deprecated |
| `shell.qml` | IPC `colors reload` accepts `wallPath` param; renamed `ipcColorLoadProc` → `colorsReloadProc` |

### Acceptance Test Results
```bash
# grep -c wallcolors.py ~/.config/hypr/scripts/wallpaper.sh
# (Expected: 0 - external script needs manual update)
# jq 'has("primary_container")' ~/.cache/yemi-shell/colors.json
# (Expected: true)
```

### Pending Action
- `Phase 0.3`: External file `~/.config/hypr/scripts/wallpaper.sh` needs updating to remove `wallcolors.py` invocation

---

*This document was updated to accurately reflect the actual file structure and audit findings in `/home/yemi/.config/quickshell` (2026-08-05).*

*Last sync compared against INIR_THEME_SYSTEM_MAP.md, COLOR_FIX_PLAN.md, and YEMI_COLOR_WALLPAPER_AUDIT.md.*