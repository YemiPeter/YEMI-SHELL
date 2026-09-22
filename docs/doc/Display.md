# Display

## 1. Component Overview

Display is a pill surface that provides display settings for the Yemi QuickShell desktop. It allows configuring monitor settings, brightness, and display-related options, accessible from the pill when the display surface is open.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/Display.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: Brightness service, Hyprsunset service, display configuration

## 3. Component Hierarchy and Role

Display is a pill surface component that renders display settings controls. It is shown when `Pill.surface === "display"` and is positioned and sized by the Pill's surface system.

## 4. Properties

Display does not expose documented public properties in the source.

## 5. Signals

Display does not define custom signals.

## 6. Methods

Display does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains Display as a child surface; shows/hides based on `surface` property
- **Brightness service**: Reads and controls brightness
- **Hyprsunset service**: Reads and controls blue-light filter
- **PillState**: Opened via `PillState.toggleSurface(mon, "display")`

## 8. Usage Example

Display is opened via the pill IPC:

```qml
// From terminal or keybind:
// qs ipc call pill display eDP-1
```
