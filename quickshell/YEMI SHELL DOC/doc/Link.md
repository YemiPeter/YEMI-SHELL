# Link

## 1. Component Overview

Link is a pill surface that provides network connectivity controls for the Yemi QuickShell desktop. It shows Wi-Fi networks, allows connecting to networks, and manages network settings, accessible from the pill when the link surface is open.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/Link.qml`
- **Imports**: `QtQuick`, `Quickshell`, `Quickshell.Networking`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: Network service, Networking Quickshell integration

## 3. Component Hierarchy and Role

Link is a pill surface component that renders network connectivity controls. It is shown when `Pill.surface === "link"` and is positioned and sized by the Pill's surface system.

## 4. Properties

Link does not expose documented public properties in the source.

## 5. Signals

Link does not define custom signals.

## 6. Methods

Link does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains Link as a child surface; shows/hides based on `surface` property
- **Network service**: Reads network and Wi-Fi state
- **PillState**: Opened via `PillState.toggleSurface(mon, "link")`

## 8. Usage Example

Link is opened via the pill IPC:

```qml
// From terminal or keybind:
// qs ipc call pill link eDP-1
```
