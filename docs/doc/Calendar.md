# Calendar

## 1. Component Overview

Calendar is a pill surface that displays a calendar view in the Yemi QuickShell desktop. It shows the current date, month view, and upcoming events, accessible from the pill when the calendar surface is open.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/Calendar.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: Quickshell calendar integration

## 3. Component Hierarchy and Role

Calendar is a pill surface component that renders a calendar view. It is shown when `Pill.surface === "calendar"` and is positioned and sized by the Pill's surface system.

## 4. Properties

Calendar does not expose documented public properties in the source.

## 5. Signals

Calendar does not define custom signals.

## 6. Methods

Calendar does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains Calendar as a child surface; shows/hides based on `surface` property
- **PillState**: Opened via `PillState.toggleSurface(mon, "calendar")`

## 8. Usage Example

Calendar is opened via the pill IPC:

```qml
// From terminal or keybind:
// qs ipc call pill calendar eDP-1
```
