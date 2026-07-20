# LinkBt

## 1. Component Overview

LinkBt is a pill surface that provides Bluetooth device management for the Yemi QuickShell desktop. It shows available Bluetooth devices, allows pairing and connecting, accessible from the pill when the linkBt surface is open.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/LinkBt.qml`
- **Imports**: `QtQuick`, `Quickshell`, `Quickshell.Networking`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: Bluetooth service, Networking Quickshell integration

## 3. Component Hierarchy and Role

LinkBt is a pill surface component that renders Bluetooth device management. It is shown when `Pill.surface === "bluetooth"` and is positioned and sized by the Pill's surface system.

## 4. Properties

LinkBt does not expose documented public properties in the source.

## 5. Signals

LinkBt does not define custom signals.

## 6. Methods

LinkBt does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains LinkBt as a child surface; shows/hides based on `surface` property
- **Bluetooth service**: Reads Bluetooth adapter and device state
- **PillState**: Opened via `PillState.toggleSurface(mon, "bluetooth")`

## 8. Usage Example

LinkBt is opened via the pill IPC:

```qml
// From terminal or keybind:
// qs ipc call pill bluetooth eDP-1
```
