# Network (Bar Component)

## 1. Component Overview

Network is a bar component that displays network connectivity status in the Yemi QuickShell desktop. It shows Wi-Fi signal strength, network name, and connectivity state in the right connectivity pill of the bar.

## 2. Project Structure and Dependencies

- **File**: `modules/bar/components/Network.qml`
- **Imports**: `QtQuick`, `Quickshell`, `Quickshell.Networking`
- **Instantiated by**: `Bar.qml` via `networkLoader`
- **Depends on**: Network service, Networking Quickshell integration

## 3. Component Hierarchy and Role

Network is a bar component that renders network status indicators. It reads Wi-Fi state from the Networking service and displays signal strength and connection status.

## 4. Properties

Network does not expose documented public properties in the source.

## 5. Signals

Network does not define custom signals.

## 6. Methods

Network does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Bar.qml**: Loads Network into the right connectivity pill; passes `barWindow` and `screenName`
- **Network service**: Reads network and Wi-Fi state

## 8. Usage Example

Network is loaded by Bar and is not directly reusable.
