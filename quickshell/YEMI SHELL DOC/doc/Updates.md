# Updates

## 1. Component Overview

Updates is a pill surface that displays system update information for the Yemi QuickShell desktop. It shows available package updates and allows triggering system updates, accessible from the pill when the updates surface is open.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/Updates.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: System update checking integration

## 3. Component Hierarchy and Role

Updates is a pill surface component that renders system update information. It is shown when `Pill.surface === "updates"` and is positioned and sized by the Pill's surface system.

## 4. Properties

Updates does not expose documented public properties in the source.

## 5. Signals

Updates does not define custom signals.

## 6. Methods

Updates does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains Updates as a child surface; shows/hides based on `surface` property
- **PillState**: Opened via `PillState.toggleSurface(mon, "updates")`

## 8. Usage Example

Updates is opened via the pill IPC:

```qml
// From terminal or keybind:
// qs ipc call pill updates eDP-1
```
