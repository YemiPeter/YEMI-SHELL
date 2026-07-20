# Osd

## 1. Component Overview

Osd is a pill surface that displays on-screen display notifications for the Yemi QuickShell desktop. It shows transient feedback for volume, brightness, and other system actions, accessible from the pill when OSD feedback is needed.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/Osd.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: Audio service, Brightness service

## 3. Component Hierarchy and Role

Osd is a pill surface component that renders on-screen display notifications. It is shown when OSD feedback is triggered and is positioned and sized by the Pill's surface system.

## 4. Properties

Osd does not expose documented public properties in the source.

## 5. Signals

Osd does not define custom signals.

## 6. Methods

Osd does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains Osd as a child surface; shows/hides based on OSD state
- **Audio service**: Triggers volume OSD
- **Brightness service**: Triggers brightness OSD

## 8. Usage Example

Osd is triggered by system actions (volume change, brightness change) and is not directly opened via IPC.
