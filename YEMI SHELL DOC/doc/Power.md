# Power

## 1. Component Overview

Power is a pill surface that provides power management controls for the Yemi QuickShell desktop. It shows power profile options, shutdown/restart/logout actions, accessible from the pill when the power surface is open.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/Power.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: PowerProfiles service, Quickshell power management

## 3. Component Hierarchy and Role

Power is a pill surface component that renders power management controls. It is shown when `Pill.surface === "power"` and is positioned and sized by the Pill's surface system.

## 4. Properties

Power does not expose documented public properties in the source.

## 5. Signals

Power does not define custom signals.

## 6. Methods

Power does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains Power as a child surface; shows/hides based on `surface` property
- **PowerProfiles service**: Reads and controls power profile state
- **PillState**: Opened via `PillState.toggleSurface(mon, "power")`

## 8. Usage Example

Power is opened via the pill IPC:

```qml
// From terminal or keybind:
// qs ipc call pill power eDP-1
```
