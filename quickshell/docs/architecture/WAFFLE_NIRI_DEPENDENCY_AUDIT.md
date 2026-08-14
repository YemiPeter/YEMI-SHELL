# Waffle → Niri Dependency Audit

> **READ-ONLY** audit of `/home/yemi/iNiR` for porting the iNiR waffle panel family into Yemi-Shell.
> Generated: 2026-08-14.

---

## Waffle Panels (95 QML files)

| Panel dir | File count |
|---|---|
| looks | 41 |
| bar | 27 |
| actionCenter | 24 |
| settings | 28 |
| notificationCenter | 13 |
| startMenu | 11 |
| onScreenDisplay | 6 |
| notificationPopup | 4 |
| altSwitcher | 4 |
| sessionScreen | 4 |
| clipboard | 3 |
| polkit | 2 |
| lock | 2 |
| widgets | 2 |
| background | 2 |
| regionSelector | 1 |
| backdrop | 1 |

Import roots: `import qs.modules.waffle.*` for panel-level modules; `import qs.services` and `import qs.services.deferred` for service access. `lock/` additionally imports `qs.modules.lock`.

---

## Waffle Service Matrix

| Service | Panels that consume it |
|---|---|
| Audio | actionCenter, bar, lock, looks, onScreenDisplay, settings |
| Network | actionCenter, bar, lock, looks, settings |
| Battery | actionCenter, bar, lock, looks, settings |
| Notifications | actionCenter, bar, lock, looks, notificationCenter, notificationPopup, settings |
| MprisController | actionCenter, lock, looks, notificationCenter, notificationPopup, onScreenDisplay |
| TaskbarApps | bar, looks |
| WindowPreviewService | taskview |
| AppSearch | startMenu, settings |
| AppCatalog | startMenu |
| TrayService | bar |
| NiriService | lock, onScreenDisplay, taskview |
| CompositorService | taskview, altSwitcher, lock, notificationPopup, settings |
| DateTime | bar, lock, looks |
| SystemInfo | looks |
| ResourceUsage | looks |
| Brightness | bar, actionCenter |

---

## Waffle Config Keys (top 40 by usage)

```
50  waffles?.bar
40  waffles?.widgetsPanel
26  waffles?.background
21  appearance?.wallpaperTheming
18  waffles?.altSwitcher
15  lock?.notifications
14  background?.wallpaperPath
12  screenRecord?.discordCompress
 9  panelFamily
 8  lock?.widgets
 8  lock?.blur
 7  lock?.dim
 6  waffles?.theming
 6  waffles?.behavior
 6  lock?.clock
 5  bar?.weather
 4  waffles?.tweaks
 4  waffles?.taskView
 3  calendar?.externalSync
 3  battery?.chargeLimit
 3  background?.multiMonitor
```

### Config Schema (`.waffles`)

```
.waffles
  ├── actionCenter
  ├── altSwitcher
  ├── background
  ├── bar
  ├── behavior
  ├── calendar
  ├── modules
  ├── notifications
  ├── settings
  ├── startMenu
  ├── taskView
  ├── theming          → { useMaterialColors, font: { family, scale } }
  ├── tweaks
  ├── widgetsPanel
  └── workspaceNames
```

External config keys referenced: `appearance`, `lock`, `background`, `compositor`, `gameMode`, `bar`, `screenRecord`, `osd`, `calendar`, `battery`, `keyboardIndicators`, `enabledPanels`.

---

## Niri Services Ranked (by line count)

| # | Service | Lines | What it does |
|---|---|---|---|
| 1 | `services/NiriService.qml` | 1545 | Core Niri integration — parses `niri msg -e -j` event stream (`handleNiriEvent` l.89), queries outputs (l.105) and keyboard layouts (l.127), owns authoritative Niri window list (l.1225), fullscreen detection (l.125), single-window width logic (l.173), screenshot temp path `/tmp/qs-niri-preview-` (l.759). |
| 2 | `services/GameMode.qml` | 434 | GameMode daemon bridge — calls `CompositorService.isNiri` (l.70) to suppress/restore Niri animations via `setNiriAnimations()`; config keys `gameMode?.disableNiriAnimations`, `niriWindowListUpdateIntervalMs*` (l.39-40). |
| 3 | `services/CompositorService.qml` | 407 | Abstraction layer — `isNiri` flag (245 hits) + unified API (`windows`, `workspaces`, `currentWorkspace`, `toggleOverview`, `windowPreview`, `sendWindowToWorkspace`, `screenshot`, `closeWindow`, etc.); `isHyprland` branch (51 hits). |
| 4 | `services/deferred/NiriKeybinds.qml` | 401 | Deferred service — parses user keybind config via `scripts/parse_niri_keybinds.py`, drives `niri msg` calls ("niri"×6, "niri msg"×5). |
| 5 | `services/WindowPreviewService.qml` | 347 | Niri-specific preview focus handling (l.159-173) + Niri screenshot path (l.759); gated by `!CompositorService.isNiri`. |
| 6 | `services/TaskbarApps.qml` | 71 | Window-list delegate model for taskbar; compositor-agnostic, uses CompositorService. |
| 7 | `services/MinimizedWindows.qml` | 164 | Minimized window state tracking; compositor-agnostic. |

---

## Compositor API Surface (top 15)

```
CompositorService.isNiri            245
CompositorService.isHyprland         51
CompositorService.wm                 43
CompositorService.activity           40
CompositorService.workspaces         38
CompositorService.windows            37
CompositorService.currentWorkspace   22
CompositorService.windowPreview      18
CompositorService.sendWindowToWorkspace  11
CompositorService.toggleOverview      9
CompositorService.toggleWindowPreview   8
CompositorService.moveWindowToWorkspace 7
CompositorService.windowPreviewEnabled  6
CompositorService.screenshot          5
CompositorService.windowExists        4
CompositorService.closeWindow         3
CompositorService.centerWindow        3
```

---

## Niri KDL Assets

| Path | Notes |
|---|---|
| `defaults/niri/config.d/10-input-and-cursor.kdl` | Input/cursor config |
| `defaults/niri/config.d/20-layout-and-overview.kdl` | Layout + overview behavior |
| `defaults/niri/config.d/30-window-rules.kdl` | Window rules |
| `defaults/niri/config.d/40-environment.kdl` | Environment vars |
| `defaults/niri/config.d/50-startup.kdl` | Startup apps |
| `defaults/niri/config.d/60-animations.kdl` | Animation settings |
| `defaults/niri/config.d/70-binds.kdl` | Keybinds (consumed by NiriKeybinds.qml) |
| `defaults/niri/config.d/80-layer-rules.kdl` | Layer rules |
| `defaults/niri/config.d/90-user-extra.kdl` | User override slot |
| `defaults/niri/config.kdl` | Entry point (sources `include "config.d/*.kdl"`) |
| `dots/.config/niri/config.kdl` | Active user dotfile |

---

## Verdict: Must-Port vs. Optional (Niri)

### Must-port

| Service | Lines | Rationale |
|---|---|---|
| **NiriService.qml** | 1545 | Sole implementor of the Niri event loop, window list, output/keyboard queries, and preview screenshot logic. No substitute. |
| **CompositorService.qml** | 407 | `isNiri` branch + the full compositor API surface (`windows`, `workspaces`, `toggleOverview`, `windowPreview`, `sendWindowToWorkspace`, …) consumed by taskview, altSwitcher, lock, notificationPopup, settings. |
| **NiriKeybinds.qml** | 401 | Bridges user config keybinds → `niri msg workspace/output/window` calls via `parse_niri_keybinds.py`. Without it, keyboard integration is lost. |

### Recommended

| Service | Lines | Rationale |
|---|---|---|
| **WindowPreviewService.qml** | 347 | Niri-specific focus + screenshot temp-path logic already wired into taskview. Loss without it: degraded window-preview UX on Niri. |
| **GameMode.qml** | 434 | Niri animation suppression only works through this. If Yemi-Shell has its own game-mode integration, port only the `setNiriAnimations` branch; otherwise port wholesale. |

### Reusable from existing Yemi-Hyprland work

| Service | Lines | Notes |
|---|---|---|
| TaskbarApps.qml | 71 | Compositor-agnostic; goes through CompositorService. |
| MinimizedWindows.qml | 164 | Compositor-agnostic; no Niri-specific code. |

---

*Source: `grep` evidence from /home/yemi/iNiR/services/ and /home/yemi/iNiR/modules/waffle/. No files were modified.*