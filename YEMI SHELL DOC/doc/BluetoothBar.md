# Bluetooth (Bar Component)

## 1. Component Overview

Bluetooth is a bar component that displays Bluetooth connectivity status in the Yemi QuickShell desktop. It shows Bluetooth adapter state and connection status in the right connectivity pill of the bar.

## 2. Project Structure and Dependencies

- **File**: `modules/bar/components/Bluetooth.qml`
- **Imports**: `QtQuick`, `Quickshell`, `Quickshell.Networking`
- **Instantiated by**: `Bar.qml` via `bluetoothLoader`
- **Depends on**: Bluetooth service, Networking Quickshell integration

## 3. Component Hierarchy and Role

Bluetooth is a bar component that renders Bluetooth status indicators. It reads adapter state from the Bluetooth service and displays connection status.

## 4. Properties

Bluetooth does not expose documented public properties in the source.

## 5. Signals

Bluetooth does not define custom signals.

## 6. Methods

Bluetooth does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Bar.qml**: Loads Bluetooth into the right connectivity pill; passes `barWindow` and `screenName`
- **Bluetooth service**: Reads Bluetooth adapter and device state

## 8. Usage Example

Bluetooth is loaded by Bar and is not directly reusable.
