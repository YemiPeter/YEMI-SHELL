# Network

## 1. Component Overview

Network is a service that manages network connectivity and Wi-Fi for the Yemi QuickShell desktop. It provides network device state, available Wi-Fi networks, connection status, and toggle control for the bar network indicator and the pill link surface.

## 2. Project Structure and Dependencies

- **File**: `services/Network.qml`
- **Imports**: `Quickshell`, `Quickshell.Networking`
- **Instantiated by**: `shell.qml` as `QsServices.Network`
- **Depends on**: Quickshell Networking service

## 3. Component Hierarchy and Role

Network is a service object that wraps Quickshell's Networking backend. It exposes Wi-Fi enabled state, active network, available networks, and device information for consumption by UI components.

## 4. Properties

Network does not expose documented public properties in the source.

## 5. Signals

Network does not define custom signals.

## 6. Methods

Network does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **shell.qml**: Initialized as a core service
- **Network.qml** (bar component): Reads network state for the bar indicator
- **Link.qml** (pill surface): Reads network state for the Wi-Fi list surface
- **Pill.qml**: Reads `Networking.devices` and Wi-Fi state directly

## 8. Usage Example

Network is consumed by bar and pill components. Direct usage depends on the Quickshell networking API.
