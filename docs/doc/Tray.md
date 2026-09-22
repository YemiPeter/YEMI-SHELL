# Tray

## 1. Component Overview

Tray is a bar component that displays system tray icons in the Yemi QuickShell desktop. It shows application tray icons in the rightmost section of the bar, providing access to background applications.

## 2. Project Structure and Dependencies

- **File**: `modules/bar/components/Tray.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Bar.qml` via tray loader
- **Depends on**: Quickshell system tray integration

## 3. Component Hierarchy and Role

Tray is a bar component that renders system tray icons. It reads tray icon state from Quickshell's system tray backend and displays them.

## 4. Properties

Tray does not expose documented public properties in the source.

## 5. Signals

Tray does not define custom signals.

## 6. Methods

Tray does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Bar.qml**: Loads Tray into the right tray pill
- **Quickshell system tray**: Reads tray icon state

## 8. Usage Example

Tray is loaded by Bar and is not directly reusable.
