# Recorder

## 1. Component Overview

Recorder is a pill surface that provides screen recording controls for the Yemi QuickShell desktop. It shows recording status, timer, and controls for starting/stopping screen recordings, accessible from the pill when the recorder surface is open.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/Recorder.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: ScreenRec singleton, Quickshell screen recording integration

## 3. Component Hierarchy and Role

Recorder is a pill surface component that renders screen recording controls. It is shown when `Pill.surface === "recorder"` and is positioned and sized by the Pill's surface system.

## 4. Properties

Recorder does not expose documented public properties in the source.

## 5. Signals

Recorder does not define custom signals.

## 6. Methods

Recorder does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains Recorder as a child surface; shows/hides based on `surface` property
- **ScreenRec singleton**: Reads recording state and controls
- **PillState**: Opened via `PillState.toggleSurface(mon, "recorder")`

## 8. Usage Example

Recorder is opened via the pill IPC:

```qml
// From terminal or keybind:
// qs ipc call pill recorder eDP-1
```
