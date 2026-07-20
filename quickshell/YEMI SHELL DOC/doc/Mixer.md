# Mixer

## 1. Component Overview

Mixer is a pill surface that provides audio volume control for the Yemi QuickShell desktop. It shows volume faders for individual audio sinks and applications, accessible from the pill when the mixer surface is open.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/Mixer.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: Audio service, VolumeMonitor service

## 3. Component Hierarchy and Role

Mixer is a pill surface component that renders audio volume faders. It is shown when `Pill.surface === "mixer"` and is positioned and sized by the Pill's surface system.

## 4. Properties

Mixer does not expose documented public properties in the source.

## 5. Signals

Mixer does not define custom signals.

## 6. Methods

Mixer does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains Mixer as a child surface; shows/hides based on `surface` property
- **Audio service**: Reads volume and sink state
- **VolumeMonitor service**: Monitors volume changes
- **PillState**: Opened via `PillState.toggleSurface(mon, "mixer")`

## 8. Usage Example

Mixer is opened via the pill IPC:

```qml
// From terminal or keybind:
// qs ipc call pill mixer eDP-1
```
