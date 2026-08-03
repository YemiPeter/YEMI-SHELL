# Quickshell Settings — Standalone Work Log

## Overview
This document tracks work on the standalone settings pages (settings.qml, 16 sections).
We are working on adding "1 pillow" settings — standalone overlay appearance settings.

Reference: https://github.com/Quickshell-OSS/quickshell (layer-shell settings overlay)

---

## Settings Architecture

### Two Systems
1. **Overlay settings** — `settings/SettingsOverlay.qml` (Scope overlay, toggled via `settings toggle` IPC)
   - Uses `Config.options.settingsUi.overlayMode` + `overlayAppearance` for scrimDim/backgroundOpacity
   - Has `overlayPages` (16 pages matching standalone)

2. **Standalone settings** — `settings/settings.qml` (ApplicationWindow, launched via Alt+S)
   - 16 pages, 9 marked `essential: true` (easy mode shows only these)
   - Already has easy mode toggle button

### Config (`config/Config.qml`)
Currently:
```
settingsUi: {
    overlayMode: true
}
```
**Needs**: `easyMode`, `overlayAppearance: { scrimDim, backgroundOpacity }`

---

## Section 0: Quick (QuickConfig.qml)

### Config Paths
1. `appearance.palette.type` — palette selection (line 240)
2. `appearance.wallpaperTheming.colorStrength` — wallpaper color strength (line 301)
3. `appearance.transparency.enable` — transparency toggle (line 318)
4. `appearance.wallpaperTheming.colorsOnlyMode` — colors only mode (line 330)
5. `appearance.wallpaperTheming.previewSourcePath` — preview source path (line 332)
6. `wallpaperSelector.selectionTarget` — wallpaper target (lines 391, 1405, 1476)
7. `wallpaperSelector.targetMonitor` — target monitor (lines 393, 1406)
8. `background.backdrop.wallpaperPath` — backdrop wallpaper path (line 625)
9. `background.backdrop.useMainWallpaper` — use main wallpaper for backdrop (line 627)
10. `background.multiMonitor.enable` — multi-monitor enable (line 662)
11. `appearance.wallpaperTheming.useBackdropForColors` — use backdrop for colors (line 1492)
12. `bar.bottom` — bar position bottom (line 1538)
13. `bar.vertical` — bar position vertical (line 1539)
14. `bar.cornerStyle` — bar corner style (lines 1573, 1576)
15. `appearance.fakeScreenRounding` — fake screen rounding (line 1606)
16. `background.backdrop.hideWallpaper` — hide wallpaper for backdrop (line 1634)
17. `gameMode.autoDetect` — game mode auto-detect (line 1666)
18. `gameMode.disableAnimations` — disable animations (line 1678)
19. `gameMode.disableEffects` — disable effects (line 1690)
20. `gameMode.disableNiriAnimations` — disable Niri animations (line 1702)
21. `gameMode.disableDiscoverOverlay` — disable Discover overlay (line 1714)
22. `gameMode.minimalMode` — game mode minimal (line 1726)
23. `gameMode.suppressNotifications` — suppress notifications (line 1738)
24. `reloadToasts.enable` — reload toasts (line 1787)
25. `gameMode.disableReloadToasts` — disable reload toasts in game mode (line 1798)
26. `closeConfirm.enabled` — confirm before closing windows (line 1810)

### Sections (SettingsCardSection blocks)
1. **Wallpaper & Colors** (line 37, expanded by default)
2. **Bar & screen** (line 1526)
3. **Game Mode** (line 1655)
4. **Quick Actions** (line 1748)

---

## §1: Wallpaper & Colors — Details (QuickConfig.qml lines 37-654)

### SettingsCardSection
- **Title**: "Wallpaper & Colors"
- **Icon**: "format_paint"
- **Expanded**: true (by default)
- **Layout.fillWidth**: true

### Sub-sections (3 SettingsGroup blocks + 1 ContentSubsection)

#### SettingsGroup 1: Hero wallpaper preview + color controls (lines 43-338)
**UI Elements:**
1. **Hero wallpaper card** (lines 45-234) — large preview rectangle showing current wallpaper (`Wallpapers.effectiveWallpaperUrl`)
   - Top/bottom/right gradients for button contrast
   - Light/Dark mode toggle (ButtonGroup, line 119)
     - Light: `MaterialThemeLoader.setDarkMode(false)` (line 131)
     - Dark: `MaterialThemeLoader.setDarkMode(true)` (line 138)
   - Weeb policy random button (Konachan only) — visible when `Config.options?.policies?.weeb === 1` (line 148)
     - Runs `random_konachan_wall.sh`
   - "Choose file" button (Ctrl+Alt+T shortcut) — runs `wallpaperSwitchScriptPath`

2. **Color scheme variant** (line 236) — `ConfigSelectionArray`
   - Reads: `Config.options?.appearance?.palette?.type ?? "auto"`
   - Writes: `Config.setNestedValue("appearance.palette.type", newValue)` (line 247)
   - Options: auto (only — all scheme variants removed)

3. **Wallpaper color strength** (line 290) — `ConfigSpinBox`
   - Reads: `Config.options?.appearance?.wallpaperTheming?.colorStrength ?? 1.0`
   - Writes: `Config.setNestedValue("appearance.wallpaperTheming.colorStrength", value / 100)` (line 301)
   - Range: 60-180%, step 5%, default 100%
   - Triggers wallpaper regen if auto theme
   - **TODO**: Increasing the value causes noticeable lag (~1-2s) due to wallpaper regen blocking UI thread

4. **Options strip** (line 312) — `ConfigRow`
   - **Transparency** switch (line 313):
     - Reads: `Config.options?.appearance?.transparency?.enable ?? false`
     - Writes: `Config.setNestedValue("appearance.transparency.enable", checked)` (line 318)
     - **Note**: Does NOT affect top bar — transparency setting doesn't propagate to bar component
   - **Colors only** switch (line 325):
     - Reads: `Config.options?.appearance?.wallpaperTheming?.colorsOnlyMode ?? false`
     - Writes: `Config.setNestedValue("appearance.wallpaperTheming.colorsOnlyMode", checked)` (line 330)
     - Clears preview source: `Config.setNestedValue("appearance.wallpaperTheming.previewSourcePath", "")` (line 332)

#### ContentSubsection: Quick select (lines 341-652)
- **Breadcrumb** showing current wallpaper folder
- "Current folder" button — navigates to folder of current wallpaper
- "Selector" button (line 386) — opens full wallpaper selector overlay
  - Sets `wallpaperSelector.selectionTarget = "main"`, `wallpaperSelector.targetMonitor`
  - Runs: `scripts/inir wallpaperSelector toggle`
- **Backdrop selection mode indicator** — shows when `multiMonitorPanel.backdropViewActive` is true
- **Deferred quick grid** (lines 451-650) — wallpaper thumbnail grid
  - Lazy-loaded (deferred in overlay mode)
  - Shows "Load quick grid" button when not loaded in overlay mode
  - Grid cells use `QuickWallpaperItem` delegate
  - Wallpaper selection logic handles: directories (navigate), backdrop view, colors-only mode, per-monitor wallpapers

#### SettingsGroup 2: Per-monitor wallpaper config (lines 656-1525)
1. **Per-monitor wallpapers** switch (line 657) — `ConfigSwitch`
   - Reads: `Config.options?.background?.multiMonitor?.enable ?? false`
   - Writes: `Config.setNestedValue("background.multiMonitor.enable", checked)` (line 662)
   - When disabled: applies global wallpaper via `Wallpapers.apply()`

2. **Multi-monitor panel** (lines 673-1525) — visual monitor layout
   - `selectedMonitor` property: defaults to primary screen, then focused, then first screen
   - `backdropViewActive` flag for backdrop wallpaper selection mode
   - Visual monitor cards with wallpaper previews + backdrop peek cards
   - Each monitor card supports: folder navigation, backdrop toggle, per-monitor wallpaper application, video/gif handling
   - `backdropPath` resolution: per-monitor backdrop > global backdrop > main wallpaper

### Sub-sections in SettingsGroup (lines ~1470+)
- **Backdrop configuration** (line ~1470) — `useBackdropForColors` switch
  - Reads: `Config.options?.appearance?.wallpaperTheming?.useBackdropForColors ?? false`
  - Writes: `Config.setNestedValue("appearance.wallpaperTheming.useBackdropForColors", checked)` (line 1492)

### Key Dependencies
- `Wallpapers` — wallpaper service (thumbnails, folders, video first frames)
- `WallpaperListener` — per-monitor wallpaper state, monitor name resolution
- `MaterialThemeLoader` — palette/theme variant application
- `ThemeService` — auto theme detection
- `GlobalStates` — `primaryScreen`, `settingsOverlayOpen`
- `Directories` — paths (scripts, wallpapers, config)
- `FileUtils` — file path manipulation
- `Appearance` — theme colors, fonts, animations, rounding
- `QuickWallpaperItem` — wallpaper thumbnail delegate component

### Overlay Mode Adaptations
- `isOverlayPage` property: `GlobalStates.settingsOverlayOpen ?? false`
- `quickGridLoaded` defaults to `!isOverlayPage` (grid loads immediately in standalone, deferred in overlay)
- Grid `Loader` uses `asynchronous: root.isOverlayPage` (line 515)
- Deferred content placeholder shows in overlay mode explaining "Quick wallpaper thumbnails are deferred in overlay mode"

### Config Paths Written
| Line | Config Path | Description |
|---|---|---|
| 240 | `appearance.palette.type` | Color scheme variant |
| 301 | `appearance.wallpaperTheming.colorStrength` | Wallpaper color strength (0.6-1.8) |
| 318 | `appearance.transparency.enable` | Transparency toggle |
| 330 | `appearance.wallpaperTheming.colorsOnlyMode` | Colors only mode |
| 332 | `appearance.wallpaperTheming.previewSourcePath` | Preview source path (cleared) |
| 362 | (read) `background.wallpaperPath` | Current wallpaper path (for folder nav) |
| 391 | `wallpaperSelector.selectionTarget` | Wallpaper selector target ("main") |
| 393 | `wallpaperSelector.targetMonitor` | Target monitor for selector |
| 625 | `background.backdrop.wallpaperPath` | Backdrop wallpaper path |
| 627 | `background.backdrop.useMainWallpaper` | Use main wallpaper for backdrop |
| 662 | `background.multiMonitor.enable` | Per-monitor wallpapers enable |
| 1492 | `appearance.wallpaperTheming.useBackdropForColors` | Use backdrop for colors |

---

## Pending Tasks

### Config Changes (`config/Config.qml`)
- [ ] Add `easyMode: false` to `settingsUi` block
- [ ] Add `overlayAppearance: { scrimDim: 0.5, backgroundOpacity: 0.9 }` to `settingsUi` block

### Section 0: Quick (QuickConfig.qml) — in progress
- [x] §1: Wallpaper & Colors — osu! button removed, Konachan button remains
- [ ] §2: Bar & screen (line 1504) — inspect and document
- [ ] §3: Game Mode (line 1633) — inspect and document
- [ ] §4: Quick Actions (line 1726) — inspect and document
