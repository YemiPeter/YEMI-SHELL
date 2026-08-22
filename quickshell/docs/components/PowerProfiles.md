# PowerProfiles

## 1. Component Overview

PowerProfiles is a service that manages power profile switching for the Yemi QuickShell desktop. It provides access to available power profiles (performance, balanced, power-saver) and allows switching between them, typically consumed by the pill power surface.

## 2. Project Structure and Dependencies

- **File**: `services/PowerProfiles.qml`
- **Imports**: `Quickshell`
- **Instantiated by**: `shell.qml` as `QsServices.PowerProfiles`
- **Depends on**: Quickshell power management integration

## 3. Component Hierarchy and Role

PowerProfiles is a service object that wraps Quickshell's power profile backend. It exposes available profiles, the current profile, and switching methods for consumption by UI components.

## 4. Properties

PowerProfiles does not expose documented public properties in the source.

## 5. Signals

PowerProfiles does not define custom signals.

## 6. Methods

PowerProfiles does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **shell.qml**: Initialized as a core service
- **Power.qml** (pill surface): Reads and controls power profile state

## 8. Usage Example

PowerProfiles is consumed by the pill power surface. Direct usage depends on the Quickshell power management API.
