# Volume (Bar Component)

## 1. Component Overview

Volume is a bar component that displays audio volume status in the Yemi QuickShell desktop. It shows volume level, mute state, and provides a clickable indicator for volume control in the right volume pill of the bar.

## 2. Project Structure and Dependencies

- **File**: `modules/bar/components/Volume.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Bar.qml` via volume loader
- **Depends on**: Audio service, VolumeMonitor service

## 3. Component Hierarchy and Role

Volume is a bar component that renders volume indicators. It reads volume level and mute state from the Audio service and displays them.

## 4. Properties

Volume does not expose documented public properties in the source.

## 5. Signals

Volume does not define custom signals.

## 6. Methods

Volume does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Bar.qml**: Loads Volume into the right volume pill
- **Audio service**: Reads volume and mute state
- **VolumeMonitor service**: Monitors volume changes

## 8. Usage Example

Volume is loaded by Bar and is not directly reusable.
