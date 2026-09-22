# OsdWrapper

## 1. Component Overview

OsdWrapper is a module that manages on-screen display components for the Yemi QuickShell desktop. It loads and manages VolumeOSD and BrightnessOSD, providing a unified interface for OSD display.

## 2. Project Structure and Dependencies

- **File**: `modules/osd/Wrapper.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `shell.qml` or other components that need OSD
- **Depends on**: VolumeOSD, BrightnessOSD

## 3. Component Hierarchy and Role

OsdWrapper is a module that composes OSD components. It manages the lifecycle and display of on-screen notifications for volume and brightness changes.

## 4. Properties

OsdWrapper does not expose documented public properties in the source.

## 5. Signals

OsdWrapper does not define custom signals.

## 6. Methods

OsdWrapper does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **shell.qml**: May load OsdWrapper for OSD management
- **VolumeOSD**: Managed by OsdWrapper
- **BrightnessOSD**: Managed by OsdWrapper

## 8. Usage Example

OsdWrapper is used internally for OSD management.
