# Media

## 1. Component Overview

Media is a pill surface that displays media playback controls for the Yemi QuickShell desktop. It shows the current track, playback controls, and volume for active media players, accessible from the pill when the media surface is open.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/Media.qml`
- **Imports**: `QtQuick`, `Quickshell`, `Quickshell.Services.Mpris`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: Players service, MPRIS integration

## 3. Component Hierarchy and Role

Media is a pill surface component that renders media playback controls. It is shown when `Pill.surface === "media"` and is positioned and sized by the Pill's surface system.

## 4. Properties

Media does not expose documented public properties in the source.

## 5. Signals

Media does not define custom signals.

## 6. Methods

Media does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains Media as a child surface; shows/hides based on `surface` property
- **Players service**: Reads active players and track metadata
- **MPRIS**: Reads playback state and controls
- **PillState**: Opened via `PillState.toggleSurface(mon, "media")`

## 8. Usage Example

Media is opened via the pill IPC:

```qml
// From terminal or keybind:
// qs ipc call pill media eDP-1
```
