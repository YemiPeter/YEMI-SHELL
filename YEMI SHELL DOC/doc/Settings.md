# Settings

## 1. Component Overview

Settings is a pill surface that provides shell settings configuration for the Yemi QuickShell desktop. It allows configuring shell behavior, appearance, and features, accessible from the pill when the settings surface is open.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/Settings.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: Config singleton, various configuration objects

## 3. Component Hierarchy and Role

Settings is a pill surface component that renders settings controls. It is shown when `Pill.surface === "settings"` and is positioned and sized by the Pill's surface system.

## 4. Properties

Settings does not expose documented public properties in the source.

## 5. Signals

Settings does not define custom signals.

## 6. Methods

Settings does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains Settings as a child surface; shows/hides based on `surface` property
- **Config**: Reads configuration values
- **PillState**: Opened via `PillState.toggleSurface(mon, "settings")`

## 8. Usage Example

Settings is opened via the pill IPC:

```qml
// From terminal or keybind:
// qs ipc call pill settings eDP-1
```
