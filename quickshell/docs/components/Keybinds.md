# Keybinds

## 1. Component Overview

Keybinds is a pill surface that displays keyboard shortcuts and keybindings for the Yemi QuickShell desktop. It shows a searchable list of keybinds and their actions, accessible from the pill when the keybinds surface is open.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/Keybinds.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: Keybind configuration

## 3. Component Hierarchy and Role

Keybinds is a pill surface component that renders keyboard shortcut documentation. It is shown when `Pill.surface === "keybinds"` and is positioned and sized by the Pill's surface system.

## 4. Properties

Keybinds does not expose documented public properties in the source.

## 5. Signals

Keybinds does not define custom signals.

## 6. Methods

Keybinds does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains Keybinds as a child surface; shows/hides based on `surface` property
- **PillState**: Opened via `PillState.toggleSurface(mon, "keybinds")`

## 8. Usage Example

Keybinds is opened via the pill IPC:

```qml
// From terminal or keybind:
// qs ipc call pill keybinds eDP-1
```
