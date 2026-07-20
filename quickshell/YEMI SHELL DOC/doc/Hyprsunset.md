# Hyprsunset

## 1. Component Overview

Hyprsunset is a Hyprland-specific service that manages the Hyprland sunset/blue-light filter feature. It provides temperature and brightness adjustment for the screen, typically consumed by the pill display surface or automatic day/night scheduling.

## 2. Project Structure and Dependencies

- **File**: `services/Hyprsunset.qml`
- **Imports**: `Quickshell`, `Quickshell.Hyprland`
- **Instantiated by**: `shell.qml` as `QsServices.Hyprsunset`
- **Depends on**: Hyprland's hyprsunset protocol

## 3. Component Hierarchy and Role

Hyprsunset is a service object that wraps Hyprland's sunset/blue-light filter. It exposes temperature and brightness adjustment methods for consumption by UI components.

## 4. Properties

Hyprsunset does not expose documented public properties in the source.

## 5. Signals

Hyprsunset does not define custom signals.

## 6. Methods

Hyprsunset does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **shell.qml**: Initialized as a core service (Hyprland-only)
- **Display.qml** (pill surface): May read and control Hyprsunset state

## 8. Usage Example

Hyprsunset is consumed by the pill display surface on Hyprland. Direct usage depends on the Quickshell Hyprland API.
