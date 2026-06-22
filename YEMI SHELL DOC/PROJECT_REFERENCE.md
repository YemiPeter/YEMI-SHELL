# Shell by Yemi — Project Reference

> Generated: 2026-06-22
> Scope: `~/.config/quickshell/`
> This document covers architecture, module structure, component API, and system design.
> For bugs and fixes see `BUG_REPORT.md`.

---

## Contents

1. [Project Overview](#1-project-overview)
2. [Directory Map](#2-directory-map)
3. [Architecture Patterns](#3-architecture-patterns)
4. [Module Reference — compositor/](#4-module-reference--compositor)
5. [Module Reference — config/](#5-module-reference--config)
6. [Module Reference — services/](#6-module-reference--services)
7. [Module Reference — modules/](#7-module-reference--modules)
8. [IPC Surface](#8-ipc-surface)
9. [Color System](#9-color-system)
10. [Keybind Reference](#10-keybind-reference)

---

## 1. Project Overview

Shell by Yemi is a custom QML desktop shell for Linux built on [Quickshell](https://quickshell.outfoxxed.me/). It targets Hyprland as the primary compositor with secondary Niri support in progress.

**Core capabilities:**
- Top bar with workspaces, clock, media, system status
- App launcher with usage-sorted search
- Wallpaper browser with thumbnail generation
- Music panel with GIF selector and MPRIS controls
- Control center with quick toggles, sliders, stats, notifications
- Volume and brightness OSD overlays
- Alt+Tab window switcher (in progress — parked)
- Dynamic theming from wallpaper via Pywal (Matugen migration in progress)

**Compositor support:**
- Hyprland — primary, fully integrated
- Niri — secondary, compositor layer exists, keybinds partially ported

---

## 2. Directory Map

```
~/.config/quickshell/
├── shell.qml                    # Entry point — ShellRoot
├── compositor/                  # module: qs.compositor
├── config/                      # module: qs.config
├── services/                    # module: qs.services
├── modules/                     # UI modules (bar, launcher, music, etc.)
├── components/effects/          # Shared animation constants
├── assets/gifs/                 # GIF assets for MusicPanel
├── scripts/                     # Shell utility scripts
├── state/                       # Runtime state files
├── dist/                        # Distributed configs for external tools
└── screenshots/
```

Full annotated tree:

```
~/.config/quickshell/
├── shell.qml
├── app_usage.json               # App launch frequency (root copy)
├── install.sh
├── reload-shell.sh
├── ARCHITECTURE.md
├── README.md
│
├── compositor/
│   ├── Compositor.qml           # Singleton — runtime detection, unified interface
│   ├── Hyprland.qml             # Hyprland backend
│   ├── Niri.qml                 # Niri backend (poll-based)
│   └── qmldir
│
├── config/
│   ├── Config.qml               # Top-level config singleton
│   ├── Appearance.qml           # Color tokens + iNiR compat aliases
│   ├── AppearanceConfig.qml
│   ├── BarConfig.qml
│   └── qmldir
│
├── services/
│   ├── Audio.qml                # PipeWire sink/source
│   ├── Bluetooth.qml            # bluetoothctl poller
│   ├── Brightness.qml           # sysfs read + brightnessctl write
│   ├── Hyprsunset.qml           # Night light (hyprsunset process)
│   ├── IdleInhibitor.qml        # Caffeine via systemd-inhibit
│   ├── Logger.qml               # Levelled console logger
│   ├── Matugen.qml              # Color pipeline stub (see §9)
│   ├── Network.qml              # nmcli WiFi
│   ├── Notifs.qml               # Notification store
│   ├── Players.qml              # MPRIS
│   ├── PowerProfiles.qml        # powerprofilesctl
│   ├── Pywal.qml                # Active color system (see §9)
│   ├── Screenshot.qml           # grim/slurp/wf-recorder
│   ├── SystemUsage.qml          # CPU/RAM/Disk/Net/GPU
│   ├── VolumeMonitor.qml        # wpctl poller
│   └── qmldir
│
├── modules/
│   ├── altswitcher/
│   │   ├── AltSwitcher.qml      # Alt+Tab switcher (parked — see BUG_REPORT.md)
│   │   └── CHECKLIST.md
│   ├── bar/
│   │   ├── Bar.qml
│   │   ├── BarWrapper.qml
│   │   ├── qmldir
│   │   └── components/
│   │       ├── Battery.qml
│   │       ├── Bluetooth.qml
│   │       ├── BluetoothPopupWindow.qml
│   │       ├── Brightness.qml
│   │       ├── BrightnessPopupWindow.qml
│   │       ├── Clock.qml
│   │       ├── ControlCenterToggle.qml
│   │       ├── MediaPlayer.qml
│   │       ├── Network.qml
│   │       ├── NetworkPopupWindow.qml
│   │       ├── NotificationPopups.qml
│   │       ├── StatusIndicators.qml
│   │       ├── SystemTray.qml
│   │       ├── Volume.qml
│   │       ├── VolumePopupWindow.qml
│   │       ├── Workspace.qml
│   │       └── Workspaces.qml
│   ├── controlcenter/
│   │   ├── ControlCenterWindow.qml
│   │   └── components/
│   │       ├── BrightnessSlider.qml
│   │       ├── MediaCard.qml
│   │       ├── NotificationList.qml
│   │       ├── QuickToggle.qml
│   │       ├── SystemStats.qml
│   │       ├── ThemeToggle.qml
│   │       ├── VolumeSlider.qml
│   │       └── qmldir
│   ├── launcher/
│   │   └── LauncherPanel.qml
│   ├── music/
│   │   └── MusicPanel.qml
│   ├── osd/
│   │   ├── BrightnessOSD.qml
│   │   ├── VolumeOSD.qml
│   │   ├── Wrapper.qml
│   │   └── qmldir
│   ├── settings/
│   │   ├── SettingsWindow.qml
│   │   └── components/          # empty
│   └── qmldir
│
├── components/
│   └── effects/
│       ├── Material3Anim.qml
│       └── qmldir
│
├── state/
│   ├── app_usage.json
│   ├── colormode               # "auto" | "dark" | "light"
│   └── gif-index
│
├── scripts/
│   ├── after-wall.sh           # Wallpaper hook → matugen → reload colors
│   ├── reset-app-usage.sh
│   └── toggle-colormode.sh
│
└── dist/
    ├── hypr/
    │   ├── hyprland.conf
    │   └── hyprland-layer-config.conf
    ├── niri/
    │   ├── config.kdl
    │   └── config.d/
    │       ├── 10-input-and-cursor.kdl
    │       ├── 20-layout-and-overview.kdl
    │       ├── 30-window-rules.kdl
    │       ├── 40-environment.kdl
    │       ├── 50-startup.kdl
    │       ├── 60-animations.kdl
    │       ├── 70-binds.kdl
    │       ├── 80-layer-rules.kdl
    │       └── 90-user-extra.kdl
    ├── matugen/config.toml
    ├── cava/, fastfetch/, rmpc/, scripts/
    ├── swaync/, templates/, wal/
    └── starship.toml
```

---

## 3. Architecture Patterns

### shell.qml is the state owner

`ShellRoot` in `shell.qml` owns all top-level state. Modules do not manage their own visibility — they read and mutate properties on `root`:

| State Property | Type | Purpose |
|---|---|---|
| `launcherVisible` | `bool` | Launcher panel open/closed |
| `activeTab` | `int` | Launcher tab (0 = Apps, 1 = Wallpapers) |
| `musicVisible` | `bool` | Music panel open/closed |
| `appList` | `var[]` | All discovered desktop apps |
| `appUsage` | `object` | Launch counts keyed by app name |
| `filteredApps` | `var[]` | Computed — sorted/filtered view of `appList` |
| `wallpaperList` | `var[]` | Discovered wallpaper files |
| `currentWallpaper` | `string` | Path to active wallpaper |
| `savedGifIndex` | `int` | Persisted GIF index for MusicPanel |
| `homePath` | `string` | `$HOME` |
| `configPath` | `string` | `$HOME/.config/quickshell` |
| `wallpaperPath` | `string` | `$HOME/wallpapers` |
| `statePath` | `string` | `configPath/state` |

### Services are singletons

All services under `services/` declare `pragma Singleton`. They are imported as:

```
import "../../services" as QsServices
```

Then accessed by name: `QsServices.Audio`, `QsServices.Pywal`, etc. New services must be added to `services/qmldir`.

### Compositor abstraction

`compositor/Compositor.qml` is a `Singleton` that detects the running compositor from `XDG_CURRENT_DESKTOP`/`DESKTOP_SESSION` and delegates to either `Hyprland.qml` or `Niri.qml`. Always use the abstraction:

| Use | Not |
|-----|-----|
| `Compositor.toplevels` | `Hyprland.toplevels` directly |
| `Compositor.workspaces` | `Hyprland.workspaces` directly |
| `Compositor.dispatch("...")` | `Hyprland.dispatch(...)` directly |
| `Compositor.activeWsId` | `Hyprland.focusedWorkspace.id` directly |

### Multi-screen pattern — `Scope` + `Variants`

`BarWrapper.qml` uses `Scope` as a container root (not a renderer) with `Variants { model: Quickshell.screens }` to create one `PanelWindow` per monitor. This is the correct pattern and should not be confused with BUG-001 where `Scope` is incorrectly used as the root of a component that needs to render visible content.

**Correct use of `Scope`:**
```qml
Scope {
    Variants { model: Quickshell.screens
        PanelWindow { ... }
    }
}
```

**Incorrect use of `Scope` (BUG-001):**
```qml
Scope {
    Rectangle { visible: true; width: 400; height: 300 }  // never renders
}
```

### IPC handlers

Declared as `IpcHandler { target: "name" }` blocks inside `shell.qml`. Called externally with:
```bash
qs ipc call <target> <function>
```

### Module loading

UI modules are loaded via `Loader { source: "..." }` in `shell.qml`. The settings window is created lazily via `Qt.createComponent` on first toggle to avoid startup cost.

---

## 4. Module Reference — compositor/

**QML module name:** `qs.compositor`
**Import:** `import qs.compositor` or `import "../../compositor" as QsCompositor`

### `Compositor.qml`

**Root type:** `Singleton` + `Item`

The unified compositor interface. Detects the running compositor at startup and delegates all calls to the appropriate backend.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `runningCompositor` | `string` (readonly) | `"hyprland"` or `"niri"` — detected from env vars |
| `toplevels` | `var` (readonly) | All open windows. Object keyed by id on Niri; list on Hyprland |
| `workspaces` | `var` (readonly) | All workspaces |
| `monitors` | `var` (readonly) | All monitors |
| `activeToplevel` | `var` (readonly) | Currently focused window |
| `focusedWorkspace` | `var` (readonly) | Currently active workspace |
| `focusedMonitor` | `var` (readonly) | Currently focused monitor |
| `activeWsId` | `int` (readonly) | Active workspace ID (defaults to 1) |

#### Methods

| Method | Description |
|--------|-------------|
| `dispatch(request: string)` | Send a compositor action (e.g. `"workspace 3"`, `"focus-window --id 42"`) |
| `monitorFor(screen: var)` | Return monitor info for a given screen object |
| `getOccupiedWorkspaces()` | Returns object mapping workspace ID → bool (has windows) |

---

### `Hyprland.qml`

**Root type:** `Item`
**Activated when:** `runningCompositor === "hyprland"`

Wraps `Quickshell.Hyprland` with an `enabled` guard. All properties and methods return safe defaults when `enabled = false`. Refreshes workspace/window state on Hyprland IPC events via a `Connections` block. Also runs a 500 ms polling timer as a fallback.

---

### `Niri.qml`

**Root type:** `Item`
**Activated when:** `runningCompositor === "niri"`

Poll-based (500 ms timer) because Niri does not expose a real-time event socket equivalent to Hyprland's. Spawns `niri msg --json workspaces` and `niri msg --json windows` on each tick and parses the JSON output.

---

## 5. Module Reference — config/

**QML module name:** `qs.config`

### `Config.qml`

**Root type:** `Singleton`

Top-level configuration. Composes `BarConfig` and `AppearanceConfig` and provides inline config objects for control center, notifications, and popups.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `bar` | `BarConfig` | Bar height, padding, workspace count/spacing |
| `appearance` | `AppearanceConfig` | Rounding, spacing, fonts, transparency |
| `controlCenter` | `object` | Width, maxHeight, padding, spacing, cornerRadius |
| `notifications` | `object` | popupWidth, maxVisible, timeout, spacing, margin |
| `popups` | `object` | width, minHeight, maxHeight, hoverDelay, margin |
| `dashboard` | `object` | Feature flags: showToggles, showMedia, showVolume, showSystem |

---

### `Appearance.qml`

**Root type:** `Singleton`

Wraps `AppearanceConfig` and exposes Pywal-derived semantic color tokens. Also contains an iNiR compatibility layer (aliases like `fontSize`, `fontFamily`, `effectsEnabled`, `colors.*`) for components ported from iNiR.

---

## 6. Module Reference — services/

**QML module name:** `qs.services`
**Import pattern:** `import "../../services" as QsServices` then `QsServices.Audio`, `QsServices.Pywal`, etc.

All services use `pragma Singleton` and `Singleton` as root type.

### `Audio.qml`

Wraps `Quickshell.Services.Pipewire`. Exposes the default audio sink and source with safe null-guards.

| Property | Type | Description |
|----------|------|-------------|
| `sink` | `PwNode` (readonly) | Default audio output device |
| `source` | `PwNode` (readonly) | Default audio input device |
| `sinkReady` | `bool` (readonly) | True when sink and sink.audio are non-null |
| `muted` | `bool` (readonly) | Output mute state |
| `volume` | `real` (readonly) | Output volume 0.0–1.5 |
| `percentage` | `int` (readonly) | `volume * 100` rounded |
| `sourceMuted` | `bool` (readonly) | Input mute state |
| `sourceVolume` | `real` (readonly) | Input volume |
| `sourcePercentage` | `int` (readonly) | `sourceVolume * 100` rounded |

| Method | Description |
|--------|-------------|
| `setVolume(newVolume)` | Set output volume, clamps 0.0–1.5, clears mute |
| `toggleMute()` | Toggle output mute |
| `increaseVolume()` | +5% |
| `decreaseVolume()` | -5% |
| `setSourceVolume(newVolume)` | Set input volume |
| `toggleSourceMute()` | Toggle input mute |

---

### `Bluetooth.qml`

Polls `bluetoothctl show` every 2 s to detect adapter power state, then `bluetoothctl info` to detect connection.

| Property | Type | Description |
|----------|------|-------------|
| `powered` | `bool` | Adapter power state |
| `connected` | `bool` | Whether a device is currently connected |
| `deviceName` | `string` | Connected device name, or `""` |

| Method | Description |
|--------|-------------|
| `togglePower()` | Run `bluetoothctl power on/off` |

---

### `Brightness.qml`

Reads `/sys/class/backlight/intel_backlight/brightness` and `/max_brightness` via `/bin/cat`. Writes via `brightnessctl set N%`.

| Property | Type | Description |
|----------|------|-------------|
| `brightness` | `real` | Current brightness 0.0–1.0 |
| `level` | `real` (readonly alias) | Same as `brightness` |
| `percentage` | `int` (readonly) | `brightness * 100` rounded |

| Method | Description |
|--------|-------------|
| `setBrightness(value)` | Set brightness, clamps 0.05–1.0 |
| `increaseBrightness()` | +5% |
| `decreaseBrightness()` | -5% |

---

### `Hyprsunset.qml`

Manages the `hyprsunset -t 4500` process for night light.

| Property | Type | Description |
|----------|------|-------------|
| `enabled` | `bool` (readonly) | Whether hyprsunset is currently running |
| `requested` | `bool` | Set to `true` to enable, `false` to disable |

---

### `IdleInhibitor.qml`

Caffeine mode via `systemd-inhibit --what=idle sleep infinity`.

| Property | Type | Description |
|----------|------|-------------|
| `inhibited` | `bool` | Set to `true` to prevent idle/sleep |
| `inhibitorPid` | `int` | PID of the running inhibitor process |

---

### `Logger.qml`

Levelled logger controlled by `QS_DEBUG=1` environment variable.

| Property | Type | Description |
|----------|------|-------------|
| `debugMode` | `bool` (readonly) | True when `QS_DEBUG` is `"1"` or `"true"` |
| `minLevel` | `int` | Minimum level to output (debug in debug mode, info otherwise) |

| Method | Description |
|--------|-------------|
| `trace(component, msg)` | Level 0 log |
| `debug(component, msg)` | Level 1 log |
| `info(component, msg)` | Level 2 log |
| `warn(component, msg)` | Level 3 log |
| `error(component, msg, details?)` | Level 4 log |
| `timeStart(label)` | Start a performance timer |
| `timeEnd(label)` | Stop timer and log elapsed ms |

---

### `Network.qml`

WiFi management via nmcli. Exposes a list of `AccessPoint` objects.

| Property | Type | Description |
|----------|------|-------------|
| `networks` | `list<AccessPoint>` (readonly) | All visible networks |
| `active` | `AccessPoint` (readonly) | Currently connected network or `null` |
| `wifiEnabled` | `bool` | WiFi radio state |
| `connected` | `bool` (readonly) | True when `active !== null` |
| `ssid` | `string` (readonly) | Active network SSID or `"Not Connected"` |
| `scanning` | `bool` (readonly) | True while a rescan is running |

**AccessPoint component properties:** `ssid`, `bssid`, `strength` (0–100), `frequency`, `active`, `security`, `isSecure`

| Method | Description |
|--------|-------------|
| `toggleWifi()` | Toggle WiFi radio |
| `rescanWifi()` | Force network list refresh |
| `connectToNetwork(ssid, password)` | Connect with password or saved credentials |
| `disconnectFromNetwork()` | Disconnect from active network |

---

### `Notifs.qml`

Notification store. Works alongside the `NotificationServer` declared in `shell.qml`.

| Property | Type | Description |
|----------|------|-------------|
| `notifications` | `list<Notif>` | All notifications (including closed, up to 24 h) |
| `activeNotifications` | `var` (readonly) | Filtered: not closed |
| `recentNotifications` | `var` (readonly) | Last 24 h, sorted newest first |
| `groupedNotifications` | `var` (readonly) | Active notifications grouped by `appName` |
| `dnd` | `bool` | Do Not Disturb mode |
| `count` | `int` (readonly alias) | `activeNotifications.length` |

| Method | Description |
|--------|-------------|
| `addNotification(notif)` | Add from `NotificationServer.onNotification`. Respects DND. |
| `toggleDnd()` | Toggle DND |
| `clearAll()` | Dismiss all active notifications |
| `clearApp(appName)` | Dismiss all from a specific app |
| `deleteNotification(notif)` | Permanently remove from history |

**Notif inline component properties:** `summary`, `body`, `appName`, `appIcon`, `image`, `urgency`, `actions`, `timestamp`, `closed`, `timeString`

---

### `Players.qml`

MPRIS player tracker via `Quickshell.Services.Mpris`.

| Property | Type | Description |
|----------|------|-------------|
| `list` | `var` (readonly) | All MPRIS players (`Mpris.players.values`) |
| `active` | `var` | Currently playing player, or first in list |
| `visible` | `bool` | Set to `false` to pause polling when UI is hidden |

| Method | Description |
|--------|-------------|
| `updateActivePlayer()` | Re-evaluate which player is active |
| `getIdentity(player)` | Returns `player.identity` or `"Unknown"` |

---

### `PowerProfiles.qml`

Wraps `powerprofilesctl`.

| Property | Type | Description |
|----------|------|-------------|
| `activeProfile` | `string` | `"performance"`, `"balanced"`, or `"power-saver"` |
| `availableProfiles` | `var` | `["performance", "balanced", "power-saver"]` |
| `isAvailable` | `bool` | Whether `powerprofilesctl` is installed |

| Method | Description |
|--------|-------------|
| `setProfile(profile)` | Switch to given profile |
| `getProfileIcon(profile)` | Returns Nerd Font icon string |
| `getProfileLabel(profile)` | Returns display name |

---

### `Pywal.qml`

**The active color system.** Watches `~/.cache/wal/colors.json` with `FileView`. Also watches `state/colormode` for light/dark mode.

| Property | Type | Description |
|----------|------|-------------|
| `background` | `color` | Base background |
| `foreground` | `color` | Base foreground/text |
| `color0`–`color15` | `color` | 16 pywal palette colors |
| `isLightMode` | `bool` | True when `state/colormode` is `"light"` |
| `primary` | `color` (readonly) | `color4` — primary accent |
| `surface` | `color` (readonly) | `background` |
| `surfaceBright` | `color` (readonly) | Lightened surface for elevation |
| `surfaceContainer` | `color` (readonly) | Container surface level |
| `outline` | `color` (readonly) | `color8` |
| `success` | `color` (readonly) | `color2` (green) |
| `warning` | `color` (readonly) | `color3` (orange) |
| `error` | `color` (readonly) | `color1` (red) |

| Method | Description |
|--------|-------------|
| `loadColors(text)` | Parse pywal JSON and update all color properties |
| `reload()` | Force reload from `~/.cache/wal/colors.json` |

> Note: `warning`, `error`, `success` exist in `Pywal.qml`. They are referenced but missing in `ControlCenterWindow.qml` which reads from a `pywal` property alias — see BUG-015 in `BUG_REPORT.md`.

---

### `SystemUsage.qml`

Multi-source system stats. All stats are updated on a 2 s timer with staggered sub-intervals.

| Property | Type | Description |
|----------|------|-------------|
| `cpuPerc` | `real` | CPU usage 0.0–1.0 |
| `cpuTemp` | `real` | CPU temperature °C |
| `memUsed` / `memTotal` | `real` | RAM bytes |
| `memPerc` | `real` (readonly) | `memUsed / memTotal` |
| `diskUsed` / `diskTotal` | `real` | Disk bytes |
| `diskPerc` | `real` (readonly) | Disk usage ratio |
| `downloadSpeed` / `uploadSpeed` | `real` | bytes/s |
| `gpuUsage` | `real` | GPU usage % |
| `gpuTemp` | `real` | GPU temp °C |
| `hasGpu` | `bool` | Whether a GPU was detected |
| `gpuType` | `string` | `"nvidia"`, `"amd"`, `"intel"`, or `"none"` |
| `topProcesses` | `var[]` | Top CPU processes: `{name, cpu, pid}` |
| `active` | `bool` | Set to `false` to pause all polling |

| Method | Description |
|--------|-------------|
| `ensureRunning()` | Set `active = true` and start timer |
| `stop()` | Set `active = false` |
| `kbToGbString(kb)` | Format KB value as human-readable GB/MB string |

---

### `VolumeMonitor.qml`

Lightweight wpctl-based volume poller (500 ms). Used by OSD overlays and the Volume bar component. Runs in parallel with `Audio.qml`.

| Property | Type | Description |
|----------|------|-------------|
| `percentage` | `int` | Volume 0–150 |
| `muted` | `bool` | Mute state |

---

## 7. Module Reference — modules/

### `shell.qml` — Entry Point

**Root type:** `ShellRoot`

Owns all top-level state and all `IpcHandler` blocks. Loads UI modules via `Loader`. See §3 for the state property table.

**Loaded components:**
- `Loader { source: "modules/bar/BarWrapper.qml" }` — bar
- `Loader { source: "modules/bar/components/NotificationPopups.qml" }` — notification popups
- `Wrapper { matugen: root.matugen }` — OSD overlays (from `modules/osd`)
- `Loader { source: "modules/music/MusicPanel.qml" }` — music panel
- AltSwitcher — currently disabled, see BUG-001/BUG-002

**Key processes in shell.qml:**

| Process | Purpose |
|---------|---------|
| `appListProc` | Parses all `.desktop` files into `appList` |
| `loadUsageProc` | Reads `app_usage.json` into `appUsage` |
| `wallpaperListProc` | `find ~/wallpapers` → `wallpaperList` |
| `thumbGenProc` | Generates thumbnails via vipsthumbnail/ImageMagick |
| `hashAllProc` | MD5-hashes wallpaper paths for cache lookup |
| `applyWallProc` | Runs `awww img` + `matugen image` |
| `randomWallProc` | Picks a random wallpaper |
| `initStateDir` | Creates state dirs, triggers app/wallpaper loading |

---

### `modules/bar/BarWrapper.qml`

**Root type:** `Scope` (correct — multi-screen container)

Creates one `PanelWindow` per monitor via `Variants { model: Quickshell.screens }`. Also hosts the `Loader`s for control center, launcher, and all popup windows. Binds popup references into `Bar.qml` via `barLoader.onStatusChanged`.

---

### `modules/bar/Bar.qml`

**Root type:** `Item`

Three-pill bar layout. Left: launcher button + workspaces. Center: clock. Right: connectivity pill (Network + Bluetooth), audio pill (Brightness + Volume), power pill (Battery + ControlCenterToggle + SystemTray). Also: media player module anchored between left and center.

All bar sub-components are loaded asynchronously via `Loader`.

---

### `modules/osd/Wrapper.qml`

**Root type:** `Scope` (correct — OSD container)

Hosts `VolumeOSD` and `BrightnessOSD`. Receives `matugen` as a `required property` and passes it down. Neither OSD actually uses the matugen value currently.

---

### `modules/osd/VolumeOSD.qml`

**Root type:** `PanelWindow`
**Trigger:** `VolumeMonitor.percentage` or `VolumeMonitor.muted` change
**Position:** Top-right, 20px from top, 12px from right
**Auto-hide:** 2 s after last change

---

### `modules/osd/BrightnessOSD.qml`

**Root type:** `PanelWindow`
**Trigger:** sysfs brightness value change (50 ms polling while visible, 200 ms otherwise)
**Position:** Top-right, 75px from top, 12px from right (below VolumeOSD)
**Auto-hide:** 2 s after last change

---

### `modules/controlcenter/ControlCenterWindow.qml`

**Root type:** `PanelWindow`
**Position:** Top-right, 12px margins
**Toggle:** `shouldShow` property

Scrollable panel with: quick toggles grid (WiFi, Bluetooth, DND, Theme, Caffeine, Screenshot, Night Light, Power Mode), volume/brightness sliders, system stats, media card, notification list.

Uses `FocusScope` with `HoverHandler` auto-close — closes ~400 ms after mouse leaves.

---

### `modules/launcher/LauncherPanel.qml`

**Root type:** `PanelWindow`
**Position:** Left edge, slides in/out via `margins.left` animation
**Visibility driven by:** `root.launcherVisible` (state in `shell.qml`)

Two tabs:
- **Apps** — `ListView` driven by `root.filteredApps`, keyboard navigable (↑↓ navigate, Enter launch, Esc close, Tab switch to wallpapers)
- **Wallpapers** — `GridView` (3 columns), thumbnail images from `~/.cache/wallpaper-thumbs/`, keyboard navigable

---

### `modules/music/MusicPanel.qml`

**Root type:** `PanelWindow`
**Position:** Top center, slides down via `margins.top` animation
**Visibility driven by:** `root.musicVisible` (state in `shell.qml`)

Uses `playerctl` CLI directly (not MPRIS service) for track info and playback control. Has a GIF selector — picks from `assets/gifs/`, copies selected GIF to `assets/gifs/current.gif` via shell.

---

### `modules/settings/SettingsWindow.qml`

**Root type:** `ApplicationWindow`
**Creation:** Lazy — `Qt.createComponent` on first `settings toggle` IPC call
**Status:** Placeholder stub — shows title text only

---

### `components/effects/Material3Anim.qml`

Shared animation timing constants following Material Design 3 motion spec.

| Property | Value | Description |
|----------|-------|-------------|
| `short2` | `100` ms | Fastest transitions |
| `short3` | `200` ms | |
| `short4` | `300` ms | Standard short |
| `medium1` | `250` ms | |
| `medium2` | `400` ms | |
| `medium4` | `500` ms | |
| `standard` | bezier curve | Standard easing |
| `emphasizedDecelerate` | bezier curve | Entrance easing |
| `emphasizedAccelerate` | bezier curve | Exit easing |

---

## 8. IPC Surface

Called externally with `qs ipc call <target> <function>`.

| Target | Function | Action |
|--------|----------|--------|
| `launcher` | `toggle` | Open/close launcher on Apps tab |
| `wallpaper` | `toggle` | Open/close launcher on Wallpapers tab |
| `wallpaper` | `random` | Apply a random wallpaper |
| `music` | `toggle` | Open/close music panel |
| `colors` | `reload` | Trigger `Matugen.reload()` (currently a no-op — see BUG-012) |
| `settings` | `toggle` | Open/close settings window |
| `altSwitcher` | `toggle` | Toggle window switcher (IPC handler exists; component disabled — BUG-002) |
| `altSwitcher` | `open` | Open switcher |
| `altSwitcher` | `close` | Close switcher |
| `altSwitcher` | `next` | Move to next window |
| `altSwitcher` | `previous` | Move to previous window |

---

## 9. Color System

### Active System: Pywal

`services/Pywal.qml` is the active theming system. It:
- Watches `~/.cache/wal/colors.json` with `FileView` (updates on file change)
- Watches `state/colormode` for light/dark mode
- Exposes `color0`–`color15`, `background`, `foreground`, and semantic aliases

Every component that references colors uses `QsServices.Pywal.*` or passes `pywal` as a property.

### In-Progress: Matugen

`services/Matugen.qml` is a stub for the planned Material You color pipeline via [matugen](https://github.com/InioX/matugen). The pipeline is not implemented:

- `applyWallpaper()` is broken (see BUG-007)
- `reload()` is a no-op (see BUG-012)
- `state/colors.qml` (the intended output file) does not exist

The `dist/matugen/config.toml` and templates exist. The `scripts/after-wall.sh` calls matugen. But the QML side of the pipeline is not wired up.

### Colormode

`state/colormode` contains `"auto"`, `"dark"`, or `"light"`. Written by `scripts/toggle-colormode.sh`. Read by `Pywal.qml` via `FileView`.

---

## 10. Keybind Reference

### Working Hyprland Keybinds

| Keybind | Action |
|---------|--------|
| `SUPER D` | `qs ipc call launcher toggle` — open app launcher |
| `SUPER W` | `qs ipc call wallpaper toggle` — open wallpaper browser |
| `SUPER M` | `qs ipc call music toggle` — open music panel |
| `SUPER N` | `swaync-client -t -sw` — notification center |
| `SUPER SHIFT N` | `swaync-client -C` — clear notifications |
| `SUPER X` | `hyprlock` — lock screen |
| `SUPER Return` | `kitty` — terminal |
| `SUPER E` | `thunar` — file manager |
| `SUPER SHIFT Q` | `killactive` — close window |
| `SUPER F` | `fullscreen` |
| Arrow keys | Focus/move/resize |
| `SUPER 1–5` | Switch workspace |
| `SUPER SHIFT 1–5` | Move window to workspace |
| `Print` | Screenshot with grim |

### Working Niri Keybinds

| Keybind | Action |
|---------|--------|
| `Mod+Tab` | Niri overview toggle |
| `Mod+Shift+E` | Quit Niri |
| `Mod+Escape` | Toggle keyboard shortcut inhibit |
| `Mod+Shift+O` | Power off monitors |
| `Super+E` | `nautilus` — file manager |
| `Mod+F` | Fullscreen window |
| `Mod+D` | Maximize column |
| `Mod+A` | Toggle floating |
| `Mod+R` | Cycle column widths |
| `Mod+C` | Center column |
| `Mod+H/J/K/L` | Vim-style focus navigation |
| `Mod+1–9` | Focus workspace |
| `Mod+Ctrl+1–9` | Move column to workspace |
| `Print` / `Ctrl+Print` / `Alt+Print` | Niri native screenshots |

### Keybinds That Need Fixing

See `BUG_REPORT.md` §6 for the full list of broken Niri binds (16 calling `inir` binary, 10+ phantom IPC targets).
