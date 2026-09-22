# LinkToggle

## 1. Component Overview

LinkToggle is a reusable pill component that provides a toggle switch for network connectivity in the Yemi QuickShell desktop. It is used in the link surface to toggle Wi-Fi and other network connections.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/LinkToggle.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: Link.qml
- **Depends on**: Network service, Networking Quickshell integration

## 3. Component Hierarchy and Role

LinkToggle is a reusable UI component that renders a network toggle switch. It provides Wi-Fi and network enable/disable control.

## 4. Properties

LinkToggle does not expose documented public properties in the source.

## 5. Signals

LinkToggle does not define custom signals.

## 6. Methods

LinkToggle does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Link.qml**: Uses LinkToggle for network toggle control
- **Network service**: Reads and controls network state

## 8. Usage Example

LinkToggle is used as a child component within the link surface.
