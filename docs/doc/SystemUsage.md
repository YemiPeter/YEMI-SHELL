# SystemUsage

## 1. Component Overview

SystemUsage is a service that monitors system resource usage (CPU, memory, disk) for the Yemi QuickShell desktop. It provides real-time usage metrics consumed by the bar status indicators and the pill system monitor surface.

## 2. Project Structure and Dependencies

- **File**: `services/SystemUsage.qml`
- **Imports**: `Quickshell`
- **Instantiated by**: `shell.qml` as `QsServices.SystemUsage`
- **Depends on**: Quickshell system monitoring integration

## 3. Component Hierarchy and Role

SystemUsage is a service object that wraps Quickshell's system monitoring backend. It exposes CPU, memory, and disk usage metrics for consumption by UI components.

## 4. Properties

SystemUsage does not expose documented public properties in the source.

## 5. Signals

SystemUsage does not define custom signals.

## 6. Methods

SystemUsage does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **shell.qml**: Initialized as a core service
- **StatusIndicators.qml** (bar component): Reads system usage for status display
- **SysmonSurface.qml** (pill surface): Reads system usage for the system monitor surface

## 8. Usage Example

SystemUsage is consumed by bar and pill components. Direct usage depends on the Quickshell system monitoring API.
