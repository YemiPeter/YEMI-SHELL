# Clipboard

## 1. Component Overview

Clipboard is a pill surface that displays clipboard history for the Yemi QuickShell desktop. It shows recent clipboard entries and allows copying them again, accessible from the pill when the clipboard surface is open.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/Clipboard.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: Quickshell clipboard integration

## 3. Component Hierarchy and Role

Clipboard is a pill surface component that renders clipboard history. It is shown when `Pill.surface === "clipboard"` and is positioned and sized by the Pill's surface system.

## 4. Properties

Clipboard does not expose documented public properties in the source.

## 5. Signals

Clipboard does not define custom signals.

## 6. Methods

Clipboard does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains Clipboard as a child surface; shows/hides based on `surface` property
- **PillState**: Opened via `PillState.toggleSurface(mon, "clipboard")`

## 8. Usage Example

Clipboard is opened via the pill IPC:

```qml
// From terminal or keybind:
// qs ipc call pill clipboard eDP-1
```
