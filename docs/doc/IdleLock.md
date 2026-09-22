# IdleLock

## 1. Component Overview

IdleLock is a pill surface that provides idle and lock screen settings for the Yemi QuickShell desktop. It allows configuring idle inhibition, lock screen behavior, and related options, accessible from the pill when the idlelock surface is open.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/IdleLock.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: IdleInhibitor service, lock screen configuration

## 3. Component Hierarchy and Role

IdleLock is a pill surface component that renders idle and lock screen settings controls. It is shown when `Pill.surface === "idlelock"` and is positioned and sized by the Pill's surface system.

## 4. Properties

IdleLock does not expose documented public properties in the source.

## 5. Signals

IdleLock does not define custom signals.

## 6. Methods

IdleLock does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains IdleLock as a child surface; shows/hides based on `surface` property
- **IdleInhibitor service**: Reads and controls idle inhibition
- **PillState**: Opened via `PillState.toggleSurface(mon, "idlelock")`

## 8. Usage Example

IdleLock is opened via the pill IPC:

```qml
// From terminal or keybind:
// qs ipc call pill idlelock eDP-1
```
