# Bar System Audit — Shell by Yemi

> Scope: `modules/bar/`, `components/effects/`
> Standards applied: qt-qml-docs, qt-deprecated-cl, qt-cpp-doc
> Generated: 2026-06-22

---

## Contents

1. [Module Overview](#1-module-overview)
2. [File Inventory](#2-file-inventory)
3. [Component Reference](#3-component-reference)
   - [BarWrapper.qml](#barwrapper)
   - [Bar.qml](#bar)
   - [Material3Anim.qml](#material3anim)
   - [Workspace.qml](#workspace)
   - [Workspaces.qml](#workspaces)
   - [Clock.qml](#clock)
   - [MediaPlayer.qml](#mediaplayer)
   - [Volume.qml](#volume)
   - [Brightness.qml](#brightness)
   - [Battery.qml](#battery)
   - [Network.qml](#network)
   - [Bluetooth.qml](#bluetooth)
   - [StatusIndicators.qml](#statusindicators)
   - [ControlCenterToggle.qml](#controlcentertoggle)
   - [SystemTray.qml](#systemtray)
   - [NotificationPopups.qml](#notificationpopups)
   - [VolumePopupWindow.qml](#volumepopupwindow)
   - [BrightnessPopupWindow.qml](#brightnesspopupwindow)
   - [NetworkPopupWindow.qml](#networkpopupwindow)
   - [BluetoothPopupWindow.qml](#bluetoothpopupwindow)
4. [Deprecated API Usage](#4-deprecated-api-usage)
5. [Bug Findings](#5-bug-findings)
6. [Index of All Properties](#6-index-of-all-properties)

---

## 1. Module Overview

The bar system is the primary visible surface of Shell by Yemi. It renders a floating pill-based top bar across every connected monitor, hosts all system status indicators, and acts as the entry point for the launcher, control center, and all popup windows.

The module is structured as a two-level hierarchy:

- `BarWrapper.qml` — multi-screen entry point. Creates one `PanelWindow` per monitor using `Variants`. Owns all popup `Loader`s and wires them into the bar.
- `Bar.qml` — single-screen bar content. Three-pill layout: left (launcher + workspaces), center (clock), right (connectivity + audio/display + power). Also renders the media player module.

All bar sub-components are loaded asynchronously via `Loader` inside `Bar.qml` or directly instantiated inside `BarWrapper.qml`.

**Color system:** Every component reads from `QsServices.Pywal` — the active wallpaper-driven color singleton. No hardcoded palette colors are used except fallbacks in OSD overlays.

**Animation system:** All transitions use `Material3Anim` constants from `components/effects/Material3Anim.qml`, following Material Design 3 motion spec.

---

## 2. File Inventory

| File | Root Type | Role |
|------|-----------|------|
| `BarWrapper.qml` | `Scope` | Multi-screen wrapper, popup loader host |
| `Bar.qml` | `Item` | Per-screen three-pill bar layout |
| `components/Battery.qml` | `Item` | UPower battery display |
| `components/Bluetooth.qml` | `Item` | Bluetooth status indicator |
| `components/BluetoothPopupWindow.qml` | `PanelWindow` | Bluetooth device manager popup |
| `components/Brightness.qml` | `Item` | Brightness % with scroll control |
| `components/BrightnessPopupWindow.qml` | `PanelWindow` | Brightness slider popup |
| `components/Clock.qml` | `Item` | 1-second clock |
| `components/ControlCenterToggle.qml` | `Item` | Gear icon toggle for control center |
| `components/MediaPlayer.qml` | `Item` | Compact MPRIS player widget |
| `components/Network.qml` | `Item` | WiFi signal indicator |
| `components/NetworkPopupWindow.qml` | `PanelWindow` | Network list + password dialog |
| `components/NotificationPopups.qml` | `PanelWindow` | Floating notification cards |
| `components/StatusIndicators.qml` | `Item` | Caffeine + DND pill |
| `components/SystemTray.qml` | `RowLayout` | System tray icon repeater |
| `components/Volume.qml` | `Item` | Volume % with scroll control |
| `components/VolumePopupWindow.qml` | `PanelWindow` | Volume/input sliders popup |
| `components/Workspace.qml` | `Rectangle` | Single animated workspace dot |
| `components/Workspaces.qml` | `Item` | Repeater of workspace dots |
| `components/effects/Material3Anim.qml` | `QtObject` (Singleton) | M3 motion timing constants |

---

## 3. Component Reference

---

### BarWrapper

**File:** `modules/bar/BarWrapper.qml`
**Root type:** `Scope`
**Instantiated by:** `shell.qml` via `Loader { source: "modules/bar/BarWrapper.qml" }`

#### Component Overview

`BarWrapper` is the multi-screen entry point for the entire bar system. It uses `Scope` correctly as a non-rendering container that hosts a `Variants { model: Quickshell.screens }` block, producing one `PanelWindow` per connected monitor. It also owns the `Loader`s for all popup windows and the control center, then injects those references into each `Bar.qml` instance via property bindings in `barLoader.onStatusChanged`.

This is one of two correct uses of `Scope` in the project (`modules/osd/Wrapper.qml` is the other). `Scope` is appropriate here because the goal is to host multiple top-level windows — not to render visual content directly.

#### Project Structure and Dependencies

Imported by `shell.qml`. Imports `../../config as QsConfig` for `Config.bar.height`.

Loads these components as async `Loader`s:
- `components/BluetoothPopupWindow.qml`
- `components/NetworkPopupWindow.qml`
- `components/VolumePopupWindow.qml`
- `components/BrightnessPopupWindow.qml`
- `../controlcenter/ControlCenterWindow.qml`
- `../launcher/LauncherPanel.qml`

For each monitor screen, creates a `PanelWindow` containing `Bar.qml` loaded via an inner `Loader`.

#### Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `config` | `var` (readonly) | `QsConfig.Config` | No | Reference to the global Config singleton for bar height |

#### Inter-Component Interactions

- Reads `QsConfig.Config.bar.height` to set `implicitHeight` on each `PanelWindow`.
- Binds six popup references into each `Bar.qml` instance once `barLoader.status === Loader.Ready`:
  - `bluetoothPopup`, `networkPopup`, `volumePopup`, `brightnessPopup`, `controlCenter`, `launcher`
- Binds `toggleLauncher` and `launcherVisible` from the `ShellRoot` (`root.*`) into each `Bar.qml`.

#### Usage Example

```qml
// In shell.qml
Loader {
    id: barLoader
    source: "modules/bar/BarWrapper.qml"
}
```

---

### Bar

**File:** `modules/bar/Bar.qml`
**Root type:** `Item`
**Instantiated by:** `BarWrapper.qml` via inner `Loader` (one per monitor)

#### Component Overview

The per-screen bar layout. Renders a floating container with three pill groups: left (launcher button + workspace dots), center (clock), and right (connectivity, audio/display, power). Also renders the media player pill anchored left of center. All sub-components are loaded asynchronously.

#### Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `screen` | `var` | — | Yes | The `Quickshell.screens` model item for this monitor |
| `barWindow` | `var` | — | Yes | The enclosing `PanelWindow` — passed down to sub-components for popup positioning |
| `mediaPopup` | `var` | — | No | Media popup reference. Currently unused — no media popup window exists. Wired but always `undefined`. |
| `bluetoothPopup` | `var` | — | No | Reference to `BluetoothPopupWindow` — injected by `BarWrapper` |
| `networkPopup` | `var` | — | No | Reference to `NetworkPopupWindow` — injected by `BarWrapper` |
| `volumePopup` | `var` | — | No | Reference to `VolumePopupWindow` — injected by `BarWrapper` |
| `brightnessPopup` | `var` | — | No | Reference to `BrightnessPopupWindow` — injected by `BarWrapper` |
| `controlCenter` | `var` | — | No | Reference to `ControlCenterWindow` — injected by `BarWrapper` |
| `launcher` | `var` | — | No | Reference to `LauncherPanel` — injected by `BarWrapper` |
| `toggleLauncher` | `var` | `null` | No | Function reference from `ShellRoot.toggleLauncher` |
| `launcherVisible` | `bool` | `false` | No | Bound to `ShellRoot.launcherVisible` — drives launcher button active state |
| `config` | `var` (readonly) | `QsConfig.Config` | No | Bar config |
| `appearance` | `var` (readonly) | `QsConfig.AppearanceConfig` | No | Appearance config |
| `pywal` | `var` (readonly) | `QsServices.Pywal` | No | Active color system |

#### Inter-Component Interactions

- Reads `QsServices.Pywal` for all pill background and border colors.
- Loads all sub-components as async `Loader` instances, then injects `barWindow`, `networkPopup`, `bluetoothPopup`, `volumePopup`, `brightnessPopup`, `controlCenter`, `mediaPopup`, `screen` via `Binding` objects.
- Launcher button `MouseArea.onClicked` calls `toggleLauncher()`.
- `Workspaces` loader receives `screen` binding for per-monitor workspace filtering.

---

### Material3Anim

**File:** `components/effects/Material3Anim.qml`
**Root type:** `QtObject` (pragma Singleton)
**Module:** `effects` — `singleton Material3Anim 1.0 Material3Anim.qml`

#### Component Overview

A singleton providing all animation timing constants and easing curves for the shell, following the Material Design 3 motion specification. Every animated component in the bar imports this via `import "../../../components/effects"` and references `Material3Anim.*`.

No visual content. Pure data object.

#### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `short1`–`short4` | `int` (readonly) | 50, 100, 150, 200 ms | Fastest transition durations |
| `medium1`–`medium4` | `int` (readonly) | 250, 300, 350, 400 ms | Standard transition durations |
| `long1`–`long4` | `int` (readonly) | 450–600 ms | Longer transition durations |
| `extraLong1`–`extraLong4` | `int` (readonly) | 700–1000 ms | Complex transitions |
| `emphasized` | `var` (readonly) | `[0.2, 0.0, 0, 1.0]` | Cubic bezier — important state changes |
| `emphasizedDecelerate` | `var` (readonly) | `[0.05, 0.7, 0.1, 1.0]` | Entrance easing (elements entering screen) |
| `emphasizedAccelerate` | `var` (readonly) | `[0.3, 0.0, 0.8, 0.15]` | Exit easing (elements leaving screen) |
| `standard` | `var` (readonly) | `[0.2, 0.0, 0, 1.0]` | Normal UI transitions |
| `springBounce` | `var` (readonly) | `[0.34, 1.56, 0.64, 1.0]` | Overshoot spring — toggles and buttons |
| `springGentle` | `var` (readonly) | `[0.22, 1.0, 0.36, 1.0]` | Gentle spring — subtle interactions |
| `hoverOpacity` | `real` (readonly) | `0.08` | State layer opacity for hover |
| `focusOpacity` | `real` (readonly) | `0.12` | State layer opacity for focus |
| `pressedOpacity` | `real` (readonly) | `0.12` | State layer opacity for pressed |
| `pressedScale` | `real` (readonly) | `0.96` | Scale for press micro-interaction |
| `hoverScale` | `real` (readonly) | `1.02` | Scale for hover micro-interaction |
| `bouncePeakScale` | `real` (readonly) | `1.08` | Peak scale for bounce effects |

---

### Workspace

**File:** `modules/bar/components/Workspace.qml`
**Root type:** `Rectangle`

#### Component Overview

A single animated workspace indicator dot. Changes size and color based on state: active (expanded pill, primary color), occupied (medium dot, foreground at 50% opacity), or empty (small dot, foreground at 20% opacity). All size and color transitions are driven by `Material3Anim` curves.

#### Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `workspaceId` | `int` | `1` | No | The workspace number this dot represents |
| `isActive` | `bool` | `false` | No | Whether this workspace is currently focused |
| `isOccupied` | `bool` | `false` | No | Whether this workspace has any open windows |

#### Signals

#### clicked()
Emitted when the user clicks the dot. `Workspaces.qml` connects this to `Compositor.dispatch("workspace N")`.

#### Inter-Component Interactions

- Reads `QsServices.Pywal.primary` and `QsServices.Pywal.foreground` for colors.
- Reads `QsConfig.Config` (imported but not actively used for sizing — sizing is hardcoded).
- Emits `clicked()` consumed by `Workspaces.qml` to trigger workspace focus via `Compositor.dispatch`.
- All animation timings use `Material3Anim` constants.

#### Usage Example

```qml
Workspace {
    workspaceId: 3
    isActive: compositor.activeWsId === 3
    isOccupied: compositor.getOccupiedWorkspaces()[3] ?? false
    onClicked: compositor.dispatch("workspace 3")
}
```

---

### Workspaces

**File:** `modules/bar/components/Workspaces.qml`
**Root type:** `Item`

#### Component Overview

Renders a `RowLayout` of `Workspace` dots, one per configured workspace count. Uses `Compositor` for active workspace ID and occupied workspace map. Per-monitor workspace display is not implemented — all monitors show the same workspace set.

#### Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `screen` | `var` | — | No | The monitor screen object — accepted but not used to filter workspaces per monitor |

#### Inter-Component Interactions

- Reads `QsConfig.Config.bar.workspaces.count` for repeater model count.
- Reads `QsConfig.Config.bar.workspaces.spacing` for dot spacing.
- Reads `QsConfig.Config.bar.height` and `QsConfig.Config.bar.padding` for implicit height.
- Reads `QsCompositor.Compositor.activeWsId` to set `isActive` on each dot.
- Reads `QsCompositor.Compositor.getOccupiedWorkspaces()` to set `isOccupied` on each dot.
- Calls `compositor.dispatch("workspace N")` when a dot is clicked.

---

### Clock

**File:** `modules/bar/components/Clock.qml`
**Root type:** `Item`

#### Component Overview

Displays the current time formatted as `hh:mm AP` (12-hour with AM/PM). Updates every second via a `Timer`. Color driven by `Pywal.color5`.

#### Properties

No declared properties. Implicitly sized from the label's implicit width plus 16 px padding.

#### Inter-Component Interactions

- Reads `QsServices.Pywal.color5` for text color.
- Uses a `Timer { interval: 1000 }` to call `Qt.formatDateTime(new Date(), "hh:mm AP")` each second.

**Note:** The clock uses `Qt.formatDateTime(new Date(), ...)` on a 1-second timer rather than Quickshell's `SystemClock` type. This is functionally equivalent but slightly less efficient. No bug — just a style difference from Ricelin's clock.

---

### MediaPlayer

**File:** `modules/bar/components/MediaPlayer.qml`
**Root type:** `Item`

#### Component Overview

A compact MPRIS media player widget. Shows a spinning vinyl record, scrolling track title (marquee when text overflows), and prev/play/pause/next controls with a progress bar. When no player is active, shows a "No media" placeholder. Width adapts between a fixed 70 px (no player) and the content row's implicit width (player active).

#### Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `barWindow` | `var` | — | No | Enclosing bar window — accepted but unused in this component |
| `mediaPopup` | `var` | — | No | Media popup reference — accepted but unused |
| `isHovered` | `bool` | derived | No | True when content mouse area or no-media mouse area is hovered |

Derived readonly bindings (not declared as properties):
- `player` — `Players.active`
- `hasPlayer` — `player !== null`
- `isPlaying` — `player?.isPlaying ?? false`
- `progressPercent` — `position / duration` ratio for progress bar

#### Inter-Component Interactions

- Imports `qs.services` directly and reads `Players.active` by singleton name.
- Reads `Pywal.foreground`, `Pywal.primary`, `Pywal.color2` for colors.
- Calls `player.previous()`, `player.togglePlaying()`, `player.next()` on button click — checks `canGoPrevious`, `canTogglePlaying`, `canGoNext` guards.

**Bug — dangling import:** `import "../../../components"` resolves to a directory with no `qmldir` and no QML files at the top level. Only `components/effects/` exists. The import should be `import "../../../components/effects"`. This does not crash if `Material3Anim` is not referenced from this file — but it is an unresolved import that will produce a warning.

---

### Volume

**File:** `modules/bar/components/Volume.qml`
**Root type:** `Item`

#### Component Overview

Displays current volume percentage with a matching icon. Supports scroll-wheel volume adjustment (±2% per tick via `wpctl`) and click-to-mute. Pulses the icon on volume change.

#### Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `barWindow` | `var` | — | No | Accepted for API compatibility — not used |
| `volumePopup` | `var` | — | No | Accepted for API compatibility — not used (popup handled by `VolumePopupWindow`) |

#### Inter-Component Interactions

- Reads `QsServices.VolumeMonitor.percentage` and `QsServices.VolumeMonitor.muted` for display.
- Reads `QsServices.Pywal.foreground` and `Pywal.primary` for colors.
- Scroll-wheel: spawns `wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 2%+/-`.
- Click: spawns `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle`.
- Listens to `VolumeMonitor.onPercentageChanged` to trigger a pulse animation on the icon.

---

### Brightness

**File:** `modules/bar/components/Brightness.qml`
**Root type:** `Item`

#### Component Overview

Displays current brightness percentage with a matching icon. Supports scroll-wheel brightness adjustment via `QsServices.Brightness.increaseBrightness()` / `decreaseBrightness()`. Pulses the icon on change.

#### Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `barWindow` | `var` | — | No | Accepted for API compatibility — not used |
| `brightnessPopup` | `var` | — | No | Accepted for API compatibility — not used |

#### Inter-Component Interactions

- Reads `QsServices.Brightness.percentage` for display value.
- Reads `QsServices.Pywal.foreground`, `Pywal.primary`, `Pywal.warning` for colors.
- **Note:** `Pywal.warning` does not exist in `Pywal.qml` (BUG-015). The high-brightness icon color will be `undefined`. No crash but icon color will be invisible at ≥75% brightness.
- Calls `QsServices.Brightness.increaseBrightness()` / `decreaseBrightness()` on scroll.
- Listens to `QsServices.Brightness.onBrightnessChanged` to trigger pulse animation.

---

### Battery

**File:** `modules/bar/components/Battery.qml`
**Root type:** `Item`

#### Component Overview

Displays battery level with a custom drawn battery icon. Has three visual states: normal/compact (icon + percentage text), charging compact (shimmer animation on fill), and expanded pill (Samsung-style liquid fill animation triggered on plug-in). The expanded state automatically collapses after 4 seconds.

#### Properties

No declared public properties. All state is derived from `UPower.displayDevice`.

Key internal derived properties (not externally settable):
- `percentage` — `battery?.percentage ?? 0` (0.0–1.0)
- `batteryLevel` — `Math.round(percentage * 100)`
- `isCharging` — `battery?.state === UPowerDevice.Charging`
- `isFullyCharged` — `battery?.state === UPowerDevice.FullyCharged`
- `isLow` — level ≤ 25 and not plugged in
- `isCritical` — level ≤ 15 and not plugged in

#### Inter-Component Interactions

- Reads `Quickshell.Services.UPower.displayDevice` for all battery state.
- Reads `QsServices.PowerProfiles` (imported but not directly used in the visual — reference only).
- Reads `QsServices.Pywal.foreground` for normal color.
- Critical state triggers an opacity pulse animation.
- Plug-in event triggers the liquid fill expansion animation and auto-collapse `Timer`.
- All animations use `Material3Anim` constants.

---

### Network

**File:** `modules/bar/components/Network.qml`
**Root type:** `Item`

#### Component Overview

Displays WiFi connection status with a signal-strength icon and SSID label. Clicking opens the `NetworkPopupWindow` positioned just below the bar.

#### Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `barWindow` | `var` | — | No | The enclosing `PanelWindow` — used to calculate popup position relative to screen width |
| `networkPopup` | `var` | — | No | Reference to `NetworkPopupWindow` — injected by `BarWrapper` |

#### Inter-Component Interactions

- Reads `QsServices.Network.active`, `Network.wifiEnabled`, `Network.active.strength`, `Network.active.ssid`.
- Reads `QsServices.Pywal.foreground` and `Pywal.primary` for colors.
- On click: calculates `rightEdge` position by mapping to `barWindow.contentItem`, then sets `networkPopup.margins.right` and `networkPopup.margins.top`, toggles `networkPopup.shouldShow`.

---

### Bluetooth

**File:** `modules/bar/components/Bluetooth.qml`
**Root type:** `Item`

#### Component Overview

Displays Bluetooth adapter state and connected device name. Uses `Quickshell.Bluetooth` directly (not `QsServices.Bluetooth`). Clicking opens the `BluetoothPopupWindow` positioned below the bar.

#### Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `barWindow` | `var` | — | No | Used for popup positioning |
| `bluetoothPopup` | `var` | — | No | Reference to `BluetoothPopupWindow` — injected by `BarWrapper` |

#### Inter-Component Interactions

- Reads `Quickshell.Bluetooth.defaultAdapter` for `enabled` state.
- Reads `Quickshell.Bluetooth.devices.values` filtered to `connected` devices.
- Reads `QsServices.Pywal.foreground` and `Pywal.primary` for colors.
- On click: calculates popup position from `barWindow`, toggles `bluetoothPopup.shouldShow`.

**Note:** This component uses `Quickshell.Bluetooth` (the Quickshell built-in) directly, not `QsServices.Bluetooth` (the project's bluetoothctl poller). This is the correct approach for device listing and adapter control. `QsServices.Bluetooth` is a simpler poller used by `ControlCenterWindow`.

---

### StatusIndicators

**File:** `modules/bar/components/StatusIndicators.qml`
**Root type:** `Item`

#### Component Overview

A self-hiding pill that shows active system status indicators in the bar. Currently tracks two states: Caffeine mode (idle inhibitor active) and Do Not Disturb. Each indicator is a small circular icon that can be clicked to disable the state. The entire component collapses to zero width when no indicators are active, using an animated width transition.

#### Properties

No declared public properties. Visibility is entirely driven by service state.

Key derived readonly properties:
- `caffeineActive` — `QsServices.IdleInhibitor.inhibited`
- `dndActive` — `QsServices.Notifs.dnd`
- `hasActiveIndicators` — `caffeineActive || dndActive`

#### Inter-Component Interactions

- Reads `QsServices.IdleInhibitor.inhibited` to show/hide caffeine indicator.
- Reads `QsServices.Notifs.dnd` to show/hide DND indicator.
- Reads `QsServices.Pywal.primary` for caffeine indicator color.
- Caffeine indicator click: sets `idleInhibitor.inhibited = false`.
- DND indicator click: sets `notifs.dnd = false`.
- Both indicators show `ToolTip` on hover with a 300 ms delay.
- `Bar.qml` shows/hides this component via `visible: item?.hasActiveIndicators ?? false` on the `Loader`.

---

### ControlCenterToggle

**File:** `modules/bar/components/ControlCenterToggle.qml`
**Root type:** `Item`

#### Component Overview

A settings gear icon (󰒓) that toggles the control center panel. Rotates 90° when the panel is open, scales on hover/press, and shows an animated glow ring while active. All transitions use `Material3Anim` constants.

#### Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `controlCenter` | `var` | — | No | Reference to `ControlCenterWindow` — injected by `BarWrapper` via `Bar.qml` |

#### Inter-Component Interactions

- Reads `controlCenter.shouldShow` to drive `isActive` state.
- On click: toggles `controlCenter.shouldShow`.
- Reads `QsServices.Pywal.foreground` and `Pywal.primary` for icon color.
- Uses `Material3Anim.short3`, `Material3Anim.short2`, `Material3Anim.medium4` for transition durations.

---

### SystemTray

**File:** `modules/bar/components/SystemTray.qml`
**Root type:** `RowLayout`

#### Component Overview

A horizontal row of system tray icons, one per `SystemTray.items` entry. Each icon is a 24×24 transparent rectangle with a 16×16 image. Left-click activates the item, right-click opens its context menu. Hidden in `Bar.qml` when `item?.hasItems` is false.

#### Properties

No declared public properties. The model is driven entirely by `Quickshell.Services.SystemTray.items`.

#### Inter-Component Interactions

- Reads `Quickshell.Services.SystemTray.items` as the repeater model.
- Left-click: calls `modelData.activate(0, 0)`.
- Right-click: calls `modelData.menu.open(0, 0)`.

---

### NotificationPopups

**File:** `modules/bar/components/NotificationPopups.qml`
**Root type:** `PanelWindow`
**Instantiated by:** `shell.qml` via `Loader { source: "modules/bar/components/NotificationPopups.qml" }`

#### Component Overview

A top-right `PanelWindow` that renders floating notification cards from `QsServices.Notifs.activeNotifications`. Shows at most `Config.notifications.maxVisible` cards at once. Each card supports:
- Swipe left/right to dismiss (with trackpad two-finger scroll also supported)
- Middle-click to dismiss
- Single-click to invoke the sole action (if only one action exists)
- Auto-dismiss after `Config.notifications.timeout` ms via a progress bar
- Material 3 expressive entrance animation (scale + slide + fade)

#### Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `pywal` | `var` (readonly) | `QsServices.Pywal` | No | Color source |
| `notifs` | `var` (readonly) | `QsServices.Notifs` | No | Notification store |
| `logger` | `var` (readonly) | `QsServices.Logger` | No | Debug logger |
| `config` | `var` (readonly) | `QsConfig.Config` | No | Configuration for width, margin, maxVisible, timeout, spacing |
| `swipeThreshold` | `real` (readonly) | `0.35` | No | Fraction of popup width required to trigger swipe-dismiss |
| `activePopups` | `var` (readonly) | derived | No | `notifs.activeNotifications.slice(0, config.notifications.maxVisible)` |

#### Inter-Component Interactions

- Reads `QsServices.Notifs.activeNotifications` as the card model.
- Reads `QsConfig.Config.notifications.*` for all sizing and timing.
- Reads `QsServices.Pywal.*` for all colors.
- Calls `modelData.close()` when a notification is dismissed.
- Calls `modelData.actions[0].invoke()` on single-action click.
- Window visible when `activePopups.length > 0`.
- Anchors top-right with `Config.notifications.margin` offset.

---

### VolumePopupWindow

**File:** `modules/bar/components/VolumePopupWindow.qml`
**Root type:** `PanelWindow`

#### Component Overview

A top-right popup with separate output and input volume sliders, mute toggles, and percentage readouts. Uses Material 3 expressive entrance animation (scale + opacity). Auto-closes when mouse leaves via a `MouseArea` covering the background.

#### Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `shouldShow` | `bool` | `false` | No | Controls popup visibility and triggers entrance/exit animation |
| `isHovered` | `bool` | `false` | No | Set by internal `MouseArea` on background — drives the exit-on-leave behavior |

#### Inter-Component Interactions

- Reads `QsServices.Pywal.background`, `Pywal.foreground`, `Pywal.color4`, `Pywal.color2`, `Pywal.color3`, `Pywal.color1` for colors.
- Reads `QsServices.Audio.percentage`, `Audio.muted`, `Audio.sourcePercentage`, `Audio.sourceMuted`.
- Output slider `onMoved`: calls `audio.setVolume(value / 100)`.
- Input slider `onMoved`: calls `audio.setSourceVolume(value / 100)`.
- Output mute toggle: calls `audio.toggleMute()`.
- Input mute toggle: calls `audio.toggleSourceMute()`.
- `shouldShow` is toggled by `Network.qml` click handler (wrong — that's `networkPopup`). Actually toggled by `Volume.qml`'s `volumePopup` reference... but `Volume.qml` does not use `volumePopup` at all. `shouldShow` is only toggled by the `Bluetooth`/`Network` bar components for their respective popups — see the note below.

**Note:** `Volume.qml` accepts `volumePopup` as a property but never uses it. The volume popup is therefore never opened from the bar. `VolumePopupWindow` can only be opened externally (e.g. via direct IPC or future wiring). This is a silent dead-wire: the popup window exists and is loaded, but has no trigger.

---

### BrightnessPopupWindow

**File:** `modules/bar/components/BrightnessPopupWindow.qml`
**Root type:** `PanelWindow`

#### Component Overview

Top-right popup with a brightness slider, percentage readout, and four quick preset buttons (25%, 50%, 75%, 100%). Same animation pattern as `VolumePopupWindow`. Auto-closes when mouse leaves.

#### Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `shouldShow` | `bool` | `false` | No | Controls visibility and animation |
| `isHovered` | `bool` | `false` | No | Set by background `MouseArea` |

#### Inter-Component Interactions

- Reads `QsServices.Brightness.percentage` and calls `setBrightness(value / 100)` on slider move.
- Reads `QsServices.Pywal.*` for colors.
- Same dead-wire issue as `VolumePopupWindow`: `Brightness.qml` accepts `brightnessPopup` but never calls `shouldShow` on it.

---

### NetworkPopupWindow

**File:** `modules/bar/components/NetworkPopupWindow.qml`
**Root type:** `PanelWindow`

#### Component Overview

A top-right popup showing the WiFi network list with signal strength, connection status, scan button, and a WiFi toggle. Includes an inline password dialog overlay for connecting to secured networks. Uses `FocusScope` with `HoverHandler` auto-close (400 ms delay after mouse leaves). Handles keyboard `Escape` to close.

#### Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `shouldShow` | `bool` | `false` | No | Controls visibility and animation |
| `sortedNetworks` | `var` (readonly) | derived | No | `network.networks` sorted: connected first, then by signal strength |

#### Inter-Component Interactions

- Reads `QsServices.Network.networks`, `Network.wifiEnabled`, `Network.scanning`, `Network.active`.
- Calls `network.toggleWifi()`, `network.rescanWifi()`, `network.connectToNetwork(ssid, password)`, `network.disconnectFromNetwork()`.
- Reads `network.savedNetworks` to determine if a network needs a password.
- Password dialog: `WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand` when `shouldShow`.
- Launches `nm-connection-editor` via `Process` for settings button.

---

### BluetoothPopupWindow

**File:** `modules/bar/components/BluetoothPopupWindow.qml`
**Root type:** `PanelWindow`

#### Component Overview

A top-right popup showing paired/discovered Bluetooth devices with connect/disconnect actions, a scan toggle, and an adapter power switch. Uses `FocusScope` with `HoverHandler` auto-close. Handles `Escape` key. Device list is sorted: connected first, then paired, then alphabetical.

#### Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| `shouldShow` | `bool` | `false` | No | Controls visibility and animation |
| `devices` | `var` (readonly) | derived | No | `Bluetooth.devices.values` sorted by connected → paired → name |
| `adapter` | `var` (readonly) | `Bluetooth.defaultAdapter` | No | Reference to the default BT adapter |

#### Inter-Component Interactions

- Reads `Quickshell.Bluetooth.defaultAdapter` for power/discover state.
- Reads `Quickshell.Bluetooth.devices.values` for device list.
- Adapter power toggle: `adapter.enabled = !adapter.enabled`.
- Scan toggle: `adapter.discovering = !adapter.discovering`.
- Device connect/disconnect: `modelData.connected = true/false`.
- Launches `blueman-manager` via `Process` for settings button.
- `WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand` when `shouldShow`.

---

## 4. Deprecated API Usage

Checked against the `qt-deprecated-cl` reference list. All findings are QML-level equivalents of the listed patterns.

| File | Pattern Found | Rule | Recommendation |
|------|--------------|------|----------------|
| `Clock.qml` | `Qt.formatDateTime(new Date(), ...)` on a 1 s `Timer` | Not deprecated — but uses JS `Date` object instead of Quickshell's `SystemClock`. `SystemClock` is more efficient (no JS object creation per tick). | Replace with `SystemClock { precision: SystemClock.Minutes }` as Ricelin's `Clock.qml` does |
| `Bar.qml` | `property var mediaPopup` — accepted but never set or used | Dead property, wasted binding slot | Remove |
| `Volume.qml` | `property var volumePopup` — accepted but never used | Same | Remove or wire up |
| `Brightness.qml` | `property var brightnessPopup` — accepted but never used | Same | Remove or wire up |
| `VolumePopupWindow.qml` | `screen: Quickshell.screens[0]` | Hardcodes the primary screen. On multi-monitor setups, the popup always appears on screen 0 regardless of which bar triggered it. | Pass `screen` as a `required property` from `BarWrapper` |
| `BrightnessPopupWindow.qml` | `screen: Quickshell.screens[0]` | Same issue | Same fix |
| `NetworkPopupWindow.qml` | `screen: Quickshell.screens[0]` | Same issue | Same fix |
| `BluetoothPopupWindow.qml` | `screen: Quickshell.screens[0]` | Same issue | Same fix |
| `NotificationPopups.qml` | `screen: Quickshell.screens[0]` | Same issue | Same fix |
| Multiple files | `import QtQuick 6.10`, `import QtQuick.Layouts 6.10` — versioned imports | Qt 6 imports should be unversioned. Versioned imports are deprecated style. | Drop version numbers: `import QtQuick`, `import QtQuick.Layouts` |

---

## 5. Bug Findings

All bugs specific to the bar system. Cross-references BUG_REPORT.md numbering where applicable.

| ID | File | Severity | Description | Fix |
|----|------|----------|-------------|-----|
| BUG-014 | `MediaPlayer.qml` | High | `import "../../../components"` — dangling path, no `qmldir` at `components/` top level | Change to `import "../../../components/effects"` |
| BUG-015 (partial) | `Brightness.qml` | Medium | References `pywal.warning` for high-brightness icon color — property does not exist in `Pywal.qml`. Icon color is `undefined` at ≥75% brightness. | Replace with `pywal.color3` |
| BAR-001 | `Volume.qml` | Medium | `volumePopup` property accepted but never used. Volume popup has no open trigger from the bar. | Either call `volumePopup.shouldShow = !volumePopup.shouldShow` on click, or remove the property |
| BAR-002 | `Brightness.qml` | Medium | `brightnessPopup` property accepted but never used. Same dead-wire as BAR-001. | Same fix as BAR-001 |
| BAR-003 | All popup windows | Medium | `screen: Quickshell.screens[0]` — all five popup `PanelWindow`s hardcode screen index 0. On multi-monitor setups, popups always appear on the primary monitor regardless of which bar triggered them. | Add `required property var screen` to each popup and pass the triggering bar's screen from `BarWrapper` |
| BAR-004 | `Clock.qml` | Low | Uses JS `new Date()` + `Timer { interval: 1000 }` instead of Quickshell's `SystemClock`. Slightly less efficient — creates a new JS Date object every second. | Replace with `SystemClock { precision: SystemClock.Minutes }` |
| BAR-005 | `Bar.qml` | Low | `mediaPopup` property declared and wired in `BarWrapper.onStatusChanged` but no media popup window exists. Always `undefined`. | Remove the property and wiring |
| BAR-006 | Multiple | Low | Versioned Qt 6 imports (`import QtQuick 6.10` etc.) — deprecated style in Qt 6. | Drop version numbers |
| BAR-007 | `Workspaces.qml` | Low | `screen` property accepted but never used to filter workspaces per monitor. All monitors show the same workspace set. | Implement per-monitor workspace ranges if multi-monitor support is needed |

---

## 6. Index of All Properties

Quick reference — every declared property across all bar components, grouped by file.

### BarWrapper.qml
`config` (readonly var)

### Bar.qml
`screen` (var, required) · `barWindow` (var) · `mediaPopup` (var) · `bluetoothPopup` (var) · `networkPopup` (var) · `volumePopup` (var) · `brightnessPopup` (var) · `controlCenter` (var) · `launcher` (var) · `toggleLauncher` (var, default null) · `launcherVisible` (bool, default false) · `config` (readonly var) · `appearance` (readonly var) · `pywal` (readonly var)

### Material3Anim.qml
`short1–4` (int) · `medium1–4` (int) · `long1–4` (int) · `extraLong1–4` (int) · `emphasized` (var) · `emphasizedDecelerate` (var) · `emphasizedAccelerate` (var) · `standard` (var) · `standardDecelerate` (var) · `standardAccelerate` (var) · `expressiveDecelerate` (var) · `expressiveAccelerate` (var) · `expressiveSpatial` (var) · `springBounce` (var) · `springGentle` (var) · `hoverOpacity` (real) · `focusOpacity` (real) · `pressedOpacity` (real) · `draggedOpacity` (real) · `disabledOpacity` (real) · `disabledContainerOpacity` (real) · `pressedScale` (real) · `hoverScale` (real) · `bouncePeakScale` (real)

### Workspace.qml
`workspaceId` (int, default 1) · `isActive` (bool, default false) · `isOccupied` (bool, default false) · `config` (readonly var) · `pywal` (readonly var)

### Workspaces.qml
`screen` (var)

### Battery.qml
_(no declared public properties — all derived from UPower)_

### Bluetooth.qml
`barWindow` (var) · `bluetoothPopup` (var)

### Brightness.qml
`barWindow` (var) · `brightnessPopup` (var) · `pywal` (readonly var) · `brightness` (readonly var) · `isHovered` (readonly bool) · `percentage` (readonly int)

### Clock.qml
_(no declared properties)_

### ControlCenterToggle.qml
`controlCenter` (var) · `pywal` (readonly var) · `isActive` (readonly bool) · `isHovered` (readonly bool)

### MediaPlayer.qml
`barWindow` (var) · `mediaPopup` (var) · `isHovered` (bool)

### Network.qml
`barWindow` (var) · `networkPopup` (var) · `pywal` (readonly var) · `network` (readonly var) · `isHovered` (readonly bool) · `isConnected` (readonly bool) · `isEnabled` (readonly bool) · `signalStrength` (readonly int) · `networkName` (readonly string)

### NotificationPopups.qml
`pywal` (readonly var) · `notifs` (readonly var) · `logger` (readonly var) · `config` (readonly var) · `swipeThreshold` (readonly real) · `activePopups` (readonly var)

### StatusIndicators.qml
`pywal` (readonly var) · `idleInhibitor` (readonly var) · `notifs` (readonly var) · `caffeineActive` (readonly bool) · `dndActive` (readonly bool) · `hasActiveIndicators` (readonly bool)

### SystemTray.qml
_(no declared properties — model from Quickshell.Services.SystemTray.items)_

### Volume.qml
`barWindow` (var) · `volumePopup` (var) · `pywal` (readonly var) · `audio` (readonly var) · `volumeMonitor` (readonly var) · `isHovered` (readonly bool) · `isMuted` (readonly bool) · `percentage` (readonly int)

### VolumePopupWindow.qml
`shouldShow` (bool) · `isHovered` (bool) · `pywal` (readonly var) · `audio` (readonly var)

### BrightnessPopupWindow.qml
`shouldShow` (bool) · `isHovered` (bool) · `pywal` (readonly var) · `brightness` (readonly var)

### NetworkPopupWindow.qml
`shouldShow` (bool) · `pywal` (readonly var) · `network` (readonly var) · `sortedNetworks` (readonly var)

### BluetoothPopupWindow.qml
`shouldShow` (bool) · `adapter` (readonly var) · `pywal` (readonly var) · `devices` (readonly var)
