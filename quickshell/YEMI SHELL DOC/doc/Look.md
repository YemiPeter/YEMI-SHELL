# Look

## 1. Component Overview

Look is a pill surface that provides visual appearance settings for the Yemi QuickShell desktop. It allows configuring the shell's visual style, decorations, and look-and-feel options, accessible from the pill when the look surface is open.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/Look.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: Theme singleton, appearance configuration

## 3. Component Hierarchy and Role

Look is a pill surface component that renders visual appearance settings controls. It is shown when `Pill.surface === "look"` and is positioned and sized by the Pill's surface system.

## 4. Properties

Look does not expose documented public properties in the source.

## 5. Signals

Look does not define custom signals.

## 6. Methods

Look does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains Look as a child surface; shows/hides based on `surface` property
- **Theme**: Reads and may update theme settings
- **PillState**: Opened via `PillState.toggleSurface(mon, "look")`

## 8. Usage Example

Look is opened via the pill IPC:

```qml
// From terminal or keybind:
// qs ipc call pill look eDP-1
```
