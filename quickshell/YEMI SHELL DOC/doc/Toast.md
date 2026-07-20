# Toast

## 1. Component Overview

Toast is a pill surface that displays toast notifications for the Yemi QuickShell desktop. It shows transient notification popups within the pill area, accessible from the pill when notifications need to be displayed.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/Toast.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: Notifs service

## 3. Component Hierarchy and Role

Toast is a pill surface component that renders toast notifications. It is shown when `Pill.toastActive` is true and is positioned and sized by the Pill's surface system.

## 4. Properties

Toast does not expose documented public properties in the source.

## 5. Signals

Toast does not define custom signals.

## 6. Methods

Toast does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains Toast as a child surface; shows/hides based on `toastActive`
- **Notifs service**: Reads notification popups for toast content

## 8. Usage Example

Toast is triggered by incoming notifications and is not directly opened via IPC.
