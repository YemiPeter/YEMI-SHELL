# PillOverlay

## 1. Component Overview

PillOverlay manages the two-window architecture for the morphing pill surface on each monitor. It creates:

- A **reserve window** (`WlrLayer.Top`) that claims exclusive zone space at the pill's resting height so tiled windows sit below it and the bar does not compete for that strip
- An **overlay window** (`WlrLayer.Overlay`) that holds the actual pill, fullscreen detection, and input masking logic

The overlay window's mask dynamically switches between click-through (fullscreen), full capture (modal surface open), and pill-only (resting) states.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/PillOverlay.qml`
- **Imports**: `QtQuick`, `Quickshell`, `Quickshell.Io`, `Quickshell.Wayland`, `Quickshell.Hyprland`, `../../singletons`, `../../config`
- **Instantiated by**: `shell.qml` via `Variants` over `Quickshell.screens`
- **Depends on**: `Pill.qml`, `PillState` singleton, `Config` singleton, `Flags` singleton, `Metrics` singleton

## 3. Component Hierarchy and Role

PillOverlay is an `Item` that composes two `PanelWindow` objects:

- **reserve** — a transparent `WlrLayer.Top` window with zero-size input mask that reserves vertical space
- **overlay** — a full-screen `WlrLayer.Overlay` window that contains the `Pill` item and manages input masking based on fullscreen and surface state

It also contains background `Process` objects for fullscreen detection on both Hyprland and Niri.

## 4. Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| modelData | var | — | Yes | The Quickshell screen object for this overlay |
| barWindow | var | null | No | Reference to the bar window for alignment |
| s | real | derived | No | Read-only scale factor based on screen height and UI scale |
| restH | real | derived | No | Read-only resting height of the pill |
| barHeight | real | derived | No | Read-only bar height from config |
| topGap | real | derived | No | Read-only vertical gap between bar and pill |
| overlayTopOffset | real | derived | No | Read-only offset compensating for overlay window margin |
| surface | string | derived | No | Read-only; the currently open surface name for this monitor |
| surfaceOpen | bool | derived | No | Read-only; whether any surface is open on this monitor |
| monFullscreen | bool | false | No | Whether the monitor is in fullscreen mode |

## 5. Signals

PillOverlay does not define custom signals.

## 6. Methods

#### updateFullscreen() : void
Triggers a fullscreen state check for the current monitor. On Niri, it launches `niri msg -j windows` and parses the output to detect fullscreen. On Hyprland, it launches `hyprctl activeworkspace -j` and checks the `hasfullscreen` field. Sets `monFullscreen` accordingly.

## 7. Inter-Component Interactions

- **shell.qml**: Creates one PillOverlay per screen via `Variants`; passes `modelData` and `barWindow`
- **Pill.qml**: Child of the overlay window; receives `screenName`, `barWindow`, and `surface` bindings
- **PillState**: Read via `QsSingletons.PillState.openMon` and `openSurface` to determine which surface is open
- **Config**: Read for `config.bar.height`
- **Flags**: Read for `uiScale`
- **Metrics**: Read for `restHBase`
- **Hyprland backend**: Fullscreen detection via `hyprctl activeworkspace -j`
- **Niri backend**: Fullscreen detection via `niri msg -j windows`

## 8. Usage Example

PillOverlay is instantiated by shell.qml and is not directly reusable. Its two-window pattern is specific to the pill system architecture.
