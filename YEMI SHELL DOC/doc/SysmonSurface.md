# SysmonSurface

## 1. Component Overview

SysmonSurface is a pill surface that displays system monitoring information for the Yemi QuickShell desktop. It shows CPU, memory, disk usage, and other system metrics, accessible from the pill when the sysmon surface is open.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/SysmonSurface.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: SystemUsage service

## 3. Component Hierarchy and Role

SysmonSurface is a pill surface component that renders system monitoring information. It is shown when `Pill.surface === "sysmon"` and is positioned and sized by the Pill's surface system.

## 4. Properties

SysmonSurface does not expose documented public properties in the source.

## 5. Signals

SysmonSurface does not define custom signals.

## 6. Methods

SysmonSurface does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains SysmonSurface as a child surface; shows/hides based on `surface` property
- **SystemUsage service**: Reads CPU, memory, and disk metrics
- **PillState**: Opened via `PillState.toggleSurface(mon, "sysmon")`

## 8. Usage Example

SysmonSurface is opened via the pill IPC:

```qml
// From terminal or keybind:
// qs ipc call pill sysmon eDP-1
```
