# VolumeOSD

## 1. Component Overview

VolumeOSD is an on-screen display component that shows volume changes for the Yemi QuickShell desktop. It displays a transient volume indicator when the user adjusts volume via keybinds or the mixer.

## 2. Project Structure and Dependencies

- **File**: `modules/osd/VolumeOSD.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `modules/osd/Wrapper.qml`
- **Depends on**: Audio service, VolumeMonitor service

## 3. Component Hierarchy and Role

VolumeOSD is an OSD component that renders volume change feedback. It is shown temporarily when volume is adjusted and fades out automatically.

## 4. Properties

VolumeOSD does not expose documented public properties in the source.

## 5. Signals

VolumeOSD does not define custom signals.

## 6. Methods

VolumeOSD does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Wrapper.qml**: Loads VolumeOSD for volume feedback
- **Audio service**: Reads volume level
- **VolumeMonitor service**: Monitors volume changes

## 8. Usage Example

VolumeOSD is triggered by volume changes and is not directly opened via IPC.
