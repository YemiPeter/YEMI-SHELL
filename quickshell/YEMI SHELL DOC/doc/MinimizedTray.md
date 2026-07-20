# MinimizedTray

## 1. Component Overview

MinimizedTray is a pill surface that displays minimized application windows for the Yemi QuickShell desktop. It shows a list of minimized windows and allows restoring them, accessible from the pill when the minimized tray surface is open.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/MinimizedTray.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: Compositor backend for minimized window state

## 3. Component Hierarchy and Role

MinimizedTray is a pill surface component that renders minimized window list. It is shown when `Pill.surface === "minimized"` and is positioned and sized by the Pill's surface system.

## 4. Properties

MinimizedTray does not expose documented public properties in the source.

## 5. Signals

MinimizedTray does not define custom signals.

## 6. Methods

MinimizedTray does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains MinimizedTray as a child surface; shows/hides based on `surface` property
- **Compositor**: Reads minimized window state
- **PillState**: Opened via `PillState.toggleSurface(mon, "minimized")`

## 8. Usage Example

MinimizedTray is opened via the pill IPC:

```qml
// From terminal or keybind:
// qs ipc call pill minimized eDP-1
```
