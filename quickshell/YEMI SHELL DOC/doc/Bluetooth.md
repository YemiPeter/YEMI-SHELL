# Bluetooth

## 1. Component Overview

Bluetooth is a service that manages Bluetooth device discovery, pairing, and connectivity for the Yemi QuickShell desktop. It provides the bar Bluetooth indicator and the pill link/Bluetooth surfaces with device list, connection state, and toggle control.

## 2. Project Structure and Dependencies

- **File**: `services/Bluetooth.qml`
- **Imports**: `Quickshell`, `Quickshell.Networking`
- **Instantiated by**: `shell.qml` as `QsServices.Bluetooth`
- **Depends on**: Quickshell Bluetooth/Networking integration

## 3. Component Hierarchy and Role

Bluetooth is a service object that wraps Quickshell's Bluetooth backend. It exposes adapter state, discovered devices, and connection methods for consumption by UI components.

## 4. Properties

Bluetooth does not expose documented public properties in the source.

## 5. Signals

Bluetooth does not define custom signals.

## 6. Methods

Bluetooth does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **shell.qml**: Initialized as a core service
- **Bluetooth.qml** (bar component): Reads Bluetooth state for the bar indicator
- **LinkBt.qml** (pill surface): Reads Bluetooth state for the device list surface

## 8. Usage Example

Bluetooth is consumed by bar and pill components. Direct usage depends on the Quickshell networking API.
