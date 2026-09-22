# FontPicker

## 1. Component Overview

FontPicker is a pill surface that provides font selection and configuration for the Yemi QuickShell desktop. It allows choosing system fonts and adjusting font settings, accessible from the pill when the fontpicker surface is open.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/FontPicker.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: Font configuration, Qt font system

## 3. Component Hierarchy and Role

FontPicker is a pill surface component that renders font selection controls. It is shown when `Pill.surface === "fontpicker"` and is positioned and sized by the Pill's surface system.

## 4. Properties

FontPicker does not expose documented public properties in the source.

## 5. Signals

FontPicker does not define custom signals.

## 6. Methods

FontPicker does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains FontPicker as a child surface; shows/hides based on `surface` property
- **PillState**: Opened via `PillState.toggleSurface(mon, "fontpicker")`

## 8. Usage Example

FontPicker is opened via the pill IPC:

```qml
// From terminal or keybind:
// qs ipc call pill fontpicker eDP-1
```
