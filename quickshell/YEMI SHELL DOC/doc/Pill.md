# Pill

## 1. Component Overview

Pill is the morphing pill body that serves as the central interactive surface for the Yemi QuickShell desktop. It is a single element that carries every state (rest, hover, pinned, and all open surfaces) with width and height driven by the current `surface` string. Surfaces are stacked absolutely and cross-fade using Ame transitions. Hover comes from a passive `HoverHandler` and pin from a passive `TapHandler`, so neither swallows pointer events from surfaces stacked above (workspace dots, clock, tray icons, mixer faders).

## 2. Project Structure and Dependencies

- **File**: `modules/pill/Pill.qml`
- **Imports**: `QtQuick`, `QtQuick.Effects`, `QtQuick.Shapes`, `Quickshell`, `Quickshell.Services.Mpris`, `Quickshell.Networking`, `Singletons` (local), `../../singletons`
- **Instantiated by**: `PillOverlay.qml` as a child of the overlay window
- **Depends on**: `PillState` singleton, `Theme` singleton, `Flags` singleton, `Metrics` singleton, `Notifs` service, `ScreenRec` singleton, `Networking` Quickshell service

## 3. Component Hierarchy and Role

Pill is an `Item` that uses `pragma ComponentBehavior: Bound` to ensure bindings are properly managed. It composes:

- A `HoverHandler` and `TapHandler` for hover and pin interactions
- An `Ame` transition controller for morphing between states
- Multiple surface items stacked absolutely (calendar, launcher, clipboard, wallpaper, power, media, mixer, settings, etc.)
- A `WheelHandler` for scrolling through surfaces
- Various helper items for input padding, background, border, and shadow

## 4. Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| s | real | 1 | No | Scale factor for responsive sizing |
| screenName | string | "" | No | The monitor name this pill is on |
| barWindow | var | — | Yes | Reference to the bar window |
| surface | string | "" | No | Currently open surface name (empty = resting) |
| hovered | bool | false | No | Whether the mouse is hovering over the pill |
| pinned | bool | false | No | Whether the pill is pinned open |
| forcePinned | bool | false | No | Whether the pill is force-pinned (e.g., by keybind) |
| held | bool | derived | No | Read-only; true if pinned or forcePinned |
| mixerOpen | bool | derived | No | Read-only; true if surface is "mixer" |
| calendarOpen | bool | derived | No | Read-only; true if surface is "calendar" |
| launcherOpen | bool | derived | No | Read-only; true if surface is "launcher" |
| clipboardOpen | bool | derived | No | Read-only; true if surface is "clipboard" |
| wallpaperOpen | bool | derived | No | Read-only; true if surface is "wallpaper" |
| powerOpen | bool | derived | No | Read-only; true if surface is "power" |
| mediaOpen | bool | derived | No | Read-only; true if surface is "media" |
| linkOpen | bool | derived | No | Read-only; true if surface is "link" |
| linkBtOpen | bool | derived | No | Read-only; true if surface is "bluetooth" |
| batteryOpen | bool | derived | No | Read-only; true if surface is "battery" |
| settingsOpen | bool | derived | No | Read-only; true if surface is "settings" |
| keybindsOpen | bool | derived | No | Read-only; true if surface is "keybinds" |
| recorderOpen | bool | derived | No | Read-only; true if surface is "recorder" |
| sysmonOpen | bool | derived | No | Read-only; true if surface is "sysmon" |
| appearanceOpen | bool | derived | No | Read-only; true if surface is "appearance" |
| updatesOpen | bool | derived | No | Read-only; true if surface is "updates" |
| displayOpen | bool | derived | No | Read-only; true if surface is "display" |
| inputOpen | bool | derived | No | Read-only; true if surface is "input" |
| lookOpen | bool | derived | No | Read-only; true if surface is "look" |
| idlelockOpen | bool | derived | No | Read-only; true if surface is "idlelock" |
| fontpickerOpen | bool | derived | No | Read-only; true if surface is "fontpicker" |
| settingsLike | bool | derived | No | Read-only; true if any settings-like surface is open |
| hasMedia | bool | derived | No | Read-only; true if Mpris has active players |
| linkInitialView | string | "main" | No | Initial subview for the link surface |
| linkBtInitialView | string | "bt" | No | Initial subview for the bluetooth surface |
| netDevices | list | derived | No | Read-only; network devices from Networking service |
| wifiDev | var | derived | No | Read-only; Wi-Fi device if available |
| wifiOn | bool | derived | No | Read-only; whether Wi-Fi is enabled |
| wifiNets | list | derived | No | Read-only; available Wi-Fi networks |
| wifiActive | var | derived | No | Read-only; currently connected Wi-Fi network |
| wifiLevel | real | derived | No | Read-only; Wi-Fi signal strength |
| surfaceOpen | bool | derived | No | Read-only; whether any surface is open |
| hoverLatch | bool | false | No | Whether hover is latched (keeps pill open) |
| expanded | bool | derived | No | Read-only; true if surface is open, held, or hover latched |
| toastActive | bool | derived | No | Read-only; whether notification toasts are active |
| osdActive | bool | derived | No | Read-only; whether OSD is flashing |
| quickHere | bool | derived | No | Read-only; whether quick-record is on this monitor |
| quickChoosing | bool | derived | No | Read-only; whether quick-record chooser is active |
| quickCounting | bool | derived | No | Read-only; whether quick-record countdown is active |
| restW | real | derived | No | Read-only; resting width |
| restH | real | derived | No | Read-only; resting height |
| hoverPad | real | derived | No | Read-only; hover padding |
| hoverW | real | derived | No | Read-only; hover width |
| hoverH | real | derived | No | Read-only; hover height |
| mixerW | real | derived | No | Read-only; mixer surface width |
| mixerH | real | derived | No | Read-only; mixer surface height |
| calendarW | real | derived | No | Read-only; calendar surface width |
| calendarH | real | derived | No | Read-only; calendar surface height |
| launcherW | real | derived | No | Read-only; launcher surface width |
| launcherH | real | derived | No | Read-only; launcher surface height |
| clipboardW | real | derived | No | Read-only; clipboard surface width |
| clipboardH | real | derived | No | Read-only; clipboard surface height |
| wallpaperW | real | derived | No | Read-only; wallpaper surface width |
| wallpaperH | real | derived | No | Read-only; wallpaper surface height |
| powerW | real | derived | No | Read-only; power surface width |
| powerH | real | derived | No | Read-only; power surface height |
| mediaW | real | derived | No | Read-only; media surface width |
| mediaH | real | derived | No | Read-only; media surface height |
| batteryW | real | derived | No | Read-only; battery surface width |
| settingsW | real | derived | No | Read-only; settings surface width |
| keybindsW | real | derived | No | Read-only; keybinds surface width |
| recorderW | real | derived | No | Read-only; recorder surface width |
| sysmonW | real | derived | No | Read-only; sysmon surface width |
| appearanceW | real | derived | No | Read-only; appearance surface width |
| updatesW | real | derived | No | Read-only; updates surface width |
| displayW | real | derived | No | Read-only; display surface width |
| inputW | real | derived | No | Read-only; input surface width |
| lookW | real | derived | No | Read-only; look surface width |
| idlelockW | real | derived | No | Read-only; idle lock surface width |
| fontpickerW | real | derived | No | Read-only; font picker surface width |
| toastW | real | derived | No | Read-only; toast width |
| quickChooseW | real | derived | No | Read-only; quick-record chooser width |
| quickChooseH | real | derived | No | Read-only; quick-record chooser height |
| quickCountW | real | derived | No | Read-only; quick-record countdown width |
| quickCountH | real | derived | No | Read-only; quick-record countdown height |
| restCorner | real | derived | No | Read-only; resting corner radius |
| openCorner | real | derived | No | Read-only; open corner radius |
| surfaces | var | derived | No | Read-only; map of surface names to size and anchor info |

## 5. Signals

Pill does not define custom signals.

## 6. Methods

Pill does not define custom methods. State changes are driven by property bindings and the Ame transition system.

## 7. Inter-Component Interactions

- **PillOverlay.qml**: Parent window; passes `screenName`, `barWindow`, and `surface` bindings
- **PillState**: Read via `QsSingletons.PillState.openMon` and `openSurface` to determine which surface to show
- **Notifs**: Read via `Notifs.popups.length` for toast state
- **ScreenRec**: Read via `ScreenRec.quickMon`, `quickChoosing`, `counting` for quick-record state
- **Mpris**: Read via `Mpris.players.values` for media presence
- **Networking**: Read for Wi-Fi and network device state
- **Theme**: Read for pill colors and styling
- **Flags**: Read for `uiScale`
- **Metrics**: Read for `restHBase`
- **Surface components**: Calendar, Launcher, Clipboard, Wallpaper, Power, Media, Mixer, Settings, Keybinds, Recorder, Sysmon, Appearance, Updates, Display, Input, Look, IdleLock, FontPicker, Battery, Link, LinkBt, Osd, Toast — all stacked as children and shown/hidden based on `surface`

## 8. Usage Example

Pill is instantiated by PillOverlay and is not directly reusable by other components. Its surface system is specific to the pill architecture.
