# Hyprland

## 1. Component Overview

Hyprland is the Hyprland-specific backend implementation for the Compositor abstraction layer. It provides toplevel window management, workspace tracking, and monitor information specific to the Hyprland compositor.

## 2. Project Structure and Dependencies

- **File**: `compositor/Hyprland.qml`
- **Imports**: `Quickshell`, `Quickshell.Hyprland`
- **Instantiated by**: `Compositor.qml` as `hyprlandImpl`
- **Depends on**: Quickshell Hyprland integration

## 3. Component Hierarchy and Role

Hyprland is a backend implementation that provides Hyprland-specific compositor functionality. It is enabled only when the detected compositor is Hyprland.

## 4. Properties

Hyprland does not expose documented public properties in the source.

## 5. Signals

Hyprland does not define custom signals.

## 6. Methods

Hyprland does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Compositor.qml**: Enabled when `runningCompositor === "hyprland"`; its properties and methods are forwarded through the Compositor interface

## 8. Usage Example

Hyprland is used internally through the Compositor abstraction. Direct usage is not recommended; use Compositor instead.
