# Input

## 1. Component Overview

Input is a pill surface that provides input device settings for the Yemi QuickShell desktop. It allows configuring keyboard, mouse, and touchpad settings, accessible from the pill when the input surface is open.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/Input.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: Input device configuration

## 3. Component Hierarchy and Role

Input is a pill surface component that renders input device settings controls. It is shown when `Pill.surface === "input"` and is positioned and sized by the Pill's surface system.

## 4. Properties

Input does not expose documented public properties in the source.

## 5. Signals

Input does not define custom signals.

## 6. Methods

Input does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains Input as a child surface; shows/hides based on `surface` property
- **PillState**: Opened via `PillState.toggleSurface(mon, "input")`

## 8. Usage Example

Input is opened via the pill IPC:

```qml
// From terminal or keybind:
// qs ipc call pill input eDP-1
```
