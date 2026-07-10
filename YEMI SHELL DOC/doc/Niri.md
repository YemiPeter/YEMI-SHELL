# Niri

## 1. Component Overview

Niri is the Niri-specific backend implementation for the Compositor abstraction layer. It provides toplevel window management, workspace tracking, and monitor information specific to the Niri compositor.

## 2. Project Structure and Dependencies

- **File**: `compositor/Niri.qml`
- **Imports**: `Quickshell`, `Quickshell.Niri`
- **Instantiated by**: `Compositor.qml` as `niriImpl`
- **Depends on**: Quickshell Niri integration

## 3. Component Hierarchy and Role

Niri is a backend implementation that provides Niri-specific compositor functionality. It is enabled only when the detected compositor is Niri.

## 4. Properties

Niri does not expose documented public properties in the source.

## 5. Signals

Niri does not define custom signals.

## 6. Methods

Niri does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Compositor.qml**: Enabled when `runningCompositor === "niri"`; its properties and methods are forwarded through the Compositor interface

## 8. Usage Example

Niri is used internally through the Compositor abstraction. Direct usage is not recommended; use Compositor instead.
