# Bar Migration — Shell by Yemi → Ricelin

> Goal: Copy the Shell by Yemi bar into the Ricelin project at `.Ricelin/configs/quickshell/`
> Source: `~/.config/quickshell/modules/bar/`
> Target: `~/.config/quickshell/.Ricelin/configs/quickshell/`

---

## Contents

1. [What You're Moving](#1-what-youre-moving)
2. [What Ricelin Already Has](#2-what-ricelin-already-has)
3. [Dependency Differences](#3-dependency-differences)
4. [File-by-File Migration Plan](#4-file-by-file-migration-plan)
5. [Theme Bridging](#5-theme-bridging)
6. [Service Bridging](#6-service-bridging)
7. [Shell Wiring](#7-shell-wiring)
8. [Known Bugs to Fix Before Migrating](#8-known-bugs-to-fix-before-migrating)
9. [Migration Checklist](#9-migration-checklist)

---

## 1. What You're Moving

The full bar system from Shell by Yemi consists of these files:

**Core**

| File | Role |
|------|------|
| `modules/bar/BarWrapper.qml` | Multi-screen `Scope` + `Variants { PanelWindow }` entry point |
| `modules/bar/Bar.qml` | Three-pill bar layout (left / center / right) |

**Bar components** (`modules/bar/components/`)

| File | Role |
|------|------|
| `Battery.qml` | UPower battery with plug-in liquid animation |
| `Bluetooth.qml` | Bluetooth status indicator |
| `BluetoothPopupWindow.qml` | Bluetooth device manager popup |
| `Brightness.qml` | Brightness % with scroll-wheel control |
| `BrightnessPopupWindow.qml` | Brightness slider popup |
| `Clock.qml` | 1 s clock, Pywal colored |
| `ControlCenterToggle.qml` | Gear icon toggle for control center |
| `MediaPlayer.qml` | Compact MPRIS player (vinyl, marquee title, controls) |
| `Network.qml` | WiFi signal indicator |
| `NetworkPopupWindow.qml` | Network list + password dialog popup |
| `NotificationPopups.qml` | Floating notification cards with swipe gestures |
| `StatusIndicators.qml` | Caffeine + DND pill |
| `SystemTray.qml` | Quickshell SystemTray repeater |
| `Volume.qml` | Volume % with scroll-wheel control |
| `VolumePopupWindow.qml` | Volume/input sliders popup |
| `Workspace.qml` | Single animated workspace dot |
| `Workspaces.qml` | Repeater of dots, driven by `Compositor` |

**Shared effects** (also needed)

| File | Role |
|------|------|
| `components/effects/Material3Anim.qml` | M3 animation timing constants used throughout |
| `components/effects/qmldir` | Exports `Material3Anim` |

---

## 2. What Ricelin Already Has

Ricelin's quickshell structure lives under `.Ricelin/configs/quickshell/` and is split into standalone mini-shells, each with its own `shell.qml`:

| Directory | Purpose |
|-----------|---------|
| `topbar/` | Ricelin's existing top bar (separate from what you're adding) |
| `pill/` | The main pill-style panel — the primary Ricelin shell |
| `sidebar/` | Sidebar panel |
| `launcher/` | App launcher |
| `lock/` | Lock screen |

**Ricelin's `topbar/`** is a self-contained bar with:
- `Bar.qml` — rounded card, left (torii icon + workspaces), center (clock + calendar), right (Mpris + tray + sidebar button + power)
- `Workspaces.qml` — Hyprland-specific, hardcoded per monitor (`DP-1` → workspaces 1-5, `HDMI-A-1` → 6-10), shows app icons inside slots
- `Clock.qml` — uses `SystemClock`, German locale date, opens `Calendar` popup on click
- `Singletons/Theme.qml` — **hardcoded warm terracotta palette** (not dynamic)

**Key difference:** Ricelin uses a static `Theme` singleton with fixed colors. Shell by Yemi uses `Pywal` for dynamic wallpaper-driven colors. You will need to decide which color system drives the migrated bar.

---

## 3. Dependency Differences

This is the most important section. The Shell by Yemi bar pulls in several singleton services and a compositor abstraction that do not exist in Ricelin's project.

### Services (from `services/`)

The bar components use these singletons — all must either be ported or bridged:

| Singleton | Used By | What It Does |
|-----------|---------|-------------|
| `QsServices.Pywal` | `Bar.qml`, `Clock.qml`, `MediaPlayer.qml`, all popups | Dynamic colors from `~/.cache/wal/colors.json` |
| `QsServices.Audio` | `VolumePopupWindow.qml`, `Volume.qml` | PipeWire sink/source volume and mute |
| `QsServices.VolumeMonitor` | `Volume.qml`, `VolumeOSD` | wpctl-based volume percentage + mute |
| `QsServices.Brightness` | `Brightness.qml`, `BrightnessPopupWindow.qml` | sysfs brightness read + brightnessctl write |
| `QsServices.Network` | `Network.qml`, `NetworkPopupWindow.qml` | nmcli WiFi list and connection management |
| `QsServices.Notifs` | `NotificationPopups.qml`, `StatusIndicators.qml` | Notification store + DND state |
| `QsServices.Logger` | `NotificationPopups.qml` | Debug logger |
| `QsServices.Players` | `MediaPlayer.qml` | MPRIS active player |
| `QsServices.PowerProfiles` | (via control center toggle — not in bar directly) | powerprofilesctl |
| `QsServices.IdleInhibitor` | `StatusIndicators.qml` | Caffeine inhibited state |

### Compositor abstraction (from `compositor/`)

| Used By | What It Needs |
|---------|-------------|
| `Workspaces.qml` | `QsCompositor.Compositor.activeWsId`, `Compositor.getOccupiedWorkspaces()`, `Compositor.dispatch("workspace N")` |

Ricelin's `Workspaces.qml` calls `Hyprland.*` directly. The Shell by Yemi version goes through the `Compositor` abstraction for Niri compatibility.

### Config (from `config/`)

| Used By | What It Needs |
|---------|-------------|
| `Bar.qml` | `QsConfig.Config.bar.height`, `QsConfig.AppearanceConfig` |
| `Workspaces.qml` | `QsConfig.Config.bar.workspaces.count`, `Config.bar.workspaces.spacing`, `Config.bar.height`, `Config.bar.padding` |
| `NotificationPopups.qml` | `QsConfig.Config.notifications.*` (popupWidth, maxVisible, timeout, spacing, margin) |

### Import path structure

Shell by Yemi uses relative imports like:
```qml
import "../../../services" as QsServices
import "../../../config" as QsConfig
import "../../../compositor" as QsCompositor
import "../../../components/effects"
```

In Ricelin's flat per-feature structure, these relative paths won't work as-is. You'll need to either:
- Copy the entire dependency tree (services, config, compositor, components) into Ricelin's quickshell root, or
- Rewrite imports to match where you place things in Ricelin

---

## 4. File-by-File Migration Plan

### Recommended target layout

```
.Ricelin/configs/quickshell/
├── yemi-bar/
│   ├── BarWrapper.qml           # renamed/adapted entry point
│   ├── Bar.qml
│   ├── components/
│   │   └── [all bar components]
│   └── shell.qml                # new entry point for this bar
│
├── services/                    # ported service singletons
│   ├── qmldir
│   ├── Pywal.qml
│   ├── Audio.qml
│   ├── VolumeMonitor.qml
│   ├── Brightness.qml
│   ├── Network.qml
│   ├── Notifs.qml
│   ├── Logger.qml
│   ├── Players.qml
│   ├── IdleInhibitor.qml
│   └── ...
│
├── compositor/                  # ported compositor abstraction
│   ├── qmldir
│   ├── Compositor.qml
│   ├── Hyprland.qml
│   └── Niri.qml
│
├── config/                      # ported config singletons
│   ├── qmldir
│   ├── Config.qml
│   ├── BarConfig.qml
│   └── AppearanceConfig.qml
│
└── components/
    └── effects/
        ├── Material3Anim.qml
        └── qmldir
```

### Alternative: minimal approach

If you only want the bar and nothing else, you can inline all service reads into the bar components and replace singleton references with local `Process` + timer reads. This is more work upfront but keeps Ricelin's structure clean.

---

## 5. Theme Bridging

The bar uses `QsServices.Pywal` for all colors. Ricelin uses `Singletons/Theme.qml` with hardcoded values.

**Option A — Keep Pywal dynamic (recommended)**
Copy `services/Pywal.qml` into Ricelin's services folder. The bar will automatically update colors when the wallpaper changes via `after-wall.sh`.

**Option B — Map Pywal tokens to Ricelin's Theme**
Replace all `pywal.*` references in bar components with equivalent `Theme.*` values:

| Pywal token used in bar | Ricelin Theme equivalent |
|------------------------|--------------------------|
| `pywal.background` | `Theme.cardTop` / `Theme.cardBot` |
| `pywal.foreground` | `Theme.cream` |
| `pywal.primary` | `Theme.vermLit` |
| `pywal.color5` | `Theme.dim` (approximate) |
| `pywal.color8` | `Theme.dim` |
| `pywal.warning` | no equivalent — hardcode `"#f59e0b"` |
| `pywal.error` | no equivalent — hardcode `"#ef4444"` |

**Option C — Hybrid**
Keep `Pywal.qml` for the bar but also keep `Theme.qml` for Ricelin's existing components. Both can coexist as singletons under different names.

---

## 6. Service Bridging

### Minimum required services for the bar

If you want the full bar working, you need these services ported to Ricelin:

| Priority | Service | Why |
|----------|---------|-----|
| Required | `Pywal.qml` | All colors |
| Required | `Audio.qml` | Volume popup slider |
| Required | `VolumeMonitor.qml` | Volume indicator + OSD trigger |
| Required | `Brightness.qml` | Brightness indicator |
| Required | `Network.qml` | WiFi indicator + popup |
| Required | `Players.qml` | Media player widget |
| Required | `Notifs.qml` | Notification popups |
| Required | `IdleInhibitor.qml` | StatusIndicators pill |
| Required | `Logger.qml` | Used by NotificationPopups |
| Optional | `PowerProfiles.qml` | Not used directly in bar |
| Optional | `Hyprsunset.qml` | Not used in bar |
| Optional | `Screenshot.qml` | Not used in bar |
| Optional | `SystemUsage.qml` | Not used in bar |

Ricelin already has `sidebar/Audio.qml`, `sidebar/Bluetooth.qml`, `sidebar/Network.qml`. Check if these are singletons — if so they may conflict with the ported ones unless you rename or merge.

### Checking for conflicts
<br>

Ricelin's sidebar services to check:

| Ricelin file | Potential conflict |
|---|---|
| `sidebar/Audio.qml` | May duplicate `services/Audio.qml` — check if it's a singleton |
| `sidebar/Network.qml` | May duplicate `services/Network.qml` |
| `sidebar/Bluetooth.qml` | May duplicate `services/Bluetooth.qml` |

---

## 7. Shell Wiring

### What `BarWrapper.qml` needs from `shell.qml`

`BarWrapper.qml` reads properties from the `ShellRoot` via `root.*` bindings passed into `Bar.qml`:

| Property passed | Source in shell.qml | Purpose |
|---|---|---|
| `toggleLauncher` | `function toggleLauncher()` on ShellRoot | Launcher pill click handler |
| `launcherVisible` | `property bool launcherVisible` | Launcher button active state |

The popup windows (ControlCenter, Launcher, Bluetooth, Network, Volume, Brightness) are loaded as `Loader`s inside `BarWrapper.qml` and referenced by `Bar.qml` via bindings set in `barLoader.onStatusChanged`.

### Creating a standalone shell.qml for Ricelin

Ricelin's structure has a separate `shell.qml` per feature. For the bar you need:

```qml
// .Ricelin/configs/quickshell/yemi-bar/shell.qml
import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
    id: root

    // Minimal state the bar needs
    property bool launcherVisible: false
    function toggleLauncher() { launcherVisible = !launcherVisible }

    BarWrapper {}
}
```

If you're merging into Ricelin's existing `pill/shell.qml` instead, add the `BarWrapper {}` instantiation and the required state properties there.

---

## 8. Known Bugs to Fix Before Migrating

Before copying the bar into Ricelin, fix these bugs from `BUG_REPORT.md` that affect bar components:

| Bug | File | Impact on Migration |
|-----|------|---------------------|
| **BUG-015** | `ControlCenterWindow.qml` | `pywal.warning`, `pywal.info`, `pywal.error`, `pywal.secondary` are undefined — 4 toggle colors invisible. Fix in source before copying or fix in Ricelin after. |
| **BUG-014** | `MediaPlayer.qml` | `import "../../../components"` is dangling. After migration the path will change anyway — rewrite to `import "../components/effects"` (or wherever you put `Material3Anim`). |
| **BUG-013** | `LauncherPanel.qml` | Dead `Qt5Compat.GraphicalEffects` import. Not directly in the bar but if you copy the launcher too, remove it. |

The other critical bugs (BUG-001 through BUG-012) are in `AltSwitcher`, `Matugen`, and `Screenshot` — none of these are in the bar module, so they don't affect this migration.

---

## 9. Migration Checklist

```
[ ] Decide on directory layout in Ricelin (§4)
[ ] Decide on color system — Pywal dynamic or Theme static (§5, Option A/B/C)
[ ] Check Ricelin sidebar services for singleton conflicts (§6)

[ ] Copy modules/bar/ → .Ricelin/configs/quickshell/yemi-bar/
[ ] Copy components/effects/ → .Ricelin/configs/quickshell/components/effects/
[ ] Copy services/qmldir + required services (§6 table) → .Ricelin/configs/quickshell/services/
[ ] Copy compositor/ → .Ricelin/configs/quickshell/compositor/
[ ] Copy config/ → .Ricelin/configs/quickshell/config/

[ ] Fix all import paths in copied bar components (relative paths will break)
[ ] Fix BUG-015: replace undefined pywal.warning/info/error/secondary
[ ] Fix BUG-014: update dangling "components" import in MediaPlayer.qml
[ ] Fix BUG-016: remove duplicate Bluetooth polling from Network.qml (optional cleanup)

[ ] Create yemi-bar/shell.qml with ShellRoot + BarWrapper (§7)
[ ] Add required state properties to ShellRoot (launcherVisible, toggleLauncher)
[ ] Verify Workspaces.qml compositor abstraction works (dispatches to Hyprland or Niri)

[ ] Test: bar renders on all screens
[ ] Test: workspace dots update on focus change
[ ] Test: volume/brightness indicators respond to changes
[ ] Test: popup windows open and close correctly
[ ] Test: notification popups appear and can be dismissed
[ ] Test: media player shows current track
```
