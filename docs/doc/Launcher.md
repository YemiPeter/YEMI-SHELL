# Launcher

## 1. Component Overview

Launcher is a pill surface that provides an application launcher for the Yemi QuickShell desktop. It allows searching and launching applications, accessible from the pill when the launcher surface is open.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/Launcher.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: Quickshell application launcher integration

## 3. Component Hierarchy and Role

Launcher is a pill surface component that renders an application launcher with search. It is shown when `Pill.surface === "launcher"` and is positioned and sized by the Pill's surface system.

## 4. Properties

Launcher does not expose documented public properties in the source.

## 5. Signals

Launcher does not define custom signals.

## 6. Methods

Launcher does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains Launcher as a child surface; shows/hides based on `surface` property
- **PillState**: Opened via `PillState.toggleSurface(mon, "launcher")`

## 8. Usage Example

Launcher is opened via the pill IPC:

```qml
// From terminal or keybind:
// qs ipc call pill launcher eDP-1
```
