# Brightness

## 1. Component Overview

Brightness is a service that manages display brightness control for the Yemi QuickShell desktop. It provides brightness adjustment capabilities consumed by the bar brightness indicator and the pill display surface.

## 2. Project Structure and Dependencies

- **File**: `services/Brightness.qml`
- **Imports**: `Quickshell`
- **Instantiated by**: `shell.qml` as `QsServices.Brightness`
- **Depends on**: Quickshell display/backlight integration

## 3. Component Hierarchy and Role

Brightness is a service object that wraps Quickshell's display brightness backend. It exposes current brightness level and adjustment methods for consumption by UI components.

## 4. Properties

Brightness does not expose documented public properties in the source.

## 5. Signals

Brightness does not define custom signals.

## 6. Methods

Brightness does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **shell.qml**: Initialized as a core service
- **Brightness.qml** (bar component): Reads brightness state for the bar indicator
- **Display.qml** (pill surface): Reads brightness state for the display settings surface

## 8. Usage Example

Brightness is consumed by bar and pill components. Direct usage depends on the Quickshell display API.
