# BatterySurface

## 1. Component Overview

BatterySurface is a pill surface that displays detailed battery information for the Yemi QuickShell desktop. It shows battery level, charging status, and power settings, accessible from the pill when the battery surface is open.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/BatterySurface.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: Quickshell power/battery integration

## 3. Component Hierarchy and Role

BatterySurface is a pill surface component that renders detailed battery information. It is shown when `Pill.surface === "battery"` and is positioned and sized by the Pill's surface system.

## 4. Properties

BatterySurface does not expose documented public properties in the source.

## 5. Signals

BatterySurface does not define custom signals.

## 6. Methods

BatterySurface does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains BatterySurface as a child surface; shows/hides based on `surface` property
- **Quickshell power backend**: Reads battery state
- **PillState**: Opened via `PillState.toggleSurface(mon, "battery")`

## 8. Usage Example

BatterySurface is opened via the pill IPC:

```qml
// From terminal or keybind:
// qs ipc call pill battery eDP-1
```
