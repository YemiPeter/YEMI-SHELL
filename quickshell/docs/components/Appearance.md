# Appearance

## 1. Component Overview

Appearance is a pill surface that provides appearance and theme settings for the Yemi QuickShell desktop. It allows configuring visual styles, fonts, and theme options, accessible from the pill when the appearance surface is open.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/Appearance.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: Config singleton, AppearanceConfig, Theme singleton

## 3. Component Hierarchy and Role

Appearance is a pill surface component that renders appearance settings controls. It is shown when `Pill.surface === "appearance"` and is positioned and sized by the Pill's surface system.

## 4. Properties

Appearance does not expose documented public properties in the source.

## 5. Signals

Appearance does not define custom signals.

## 6. Methods

Appearance does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains Appearance as a child surface; shows/hides based on `surface` property
- **Config**: Reads appearance configuration
- **Theme**: Reads and may update theme settings
- **PillState**: Opened via `PillState.toggleSurface(mon, "appearance")`

## 8. Usage Example

Appearance is opened via the pill IPC:

```qml
// From terminal or keybind:
// qs ipc call pill appearance eDP-1
```
