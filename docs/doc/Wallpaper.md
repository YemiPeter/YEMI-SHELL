# Wallpaper

## 1. Component Overview

Wallpaper is a pill surface that displays wallpaper selection and management for the Yemi QuickShell desktop. It shows available wallpapers, previews, and allows applying new wallpapers, accessible from the pill when the wallpaper surface is open.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/Wallpaper.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: ShellRoot wallpaper pipeline, Matugen service

## 3. Component Hierarchy and Role

Wallpaper is a pill surface component that renders wallpaper selection UI. It is shown when `Pill.surface === "wallpaper"` and is positioned and sized by the Pill's surface system.

## 4. Properties

Wallpaper does not expose documented public properties in the source.

## 5. Signals

Wallpaper does not define custom signals.

## 6. Methods

Wallpaper does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains Wallpaper as a child surface; shows/hides based on `surface` property
- **ShellRoot**: Reads wallpaper list, current wallpaper, and apply functions
- **Matugen**: Triggers color reload after wallpaper change
- **PillState**: Opened via `PillState.toggleSurface(mon, "wallpaper")`

## 8. Usage Example

Wallpaper is opened via the pill IPC:

```qml
// From terminal or keybind:
// qs ipc call pill wallpaper eDP-1
```
