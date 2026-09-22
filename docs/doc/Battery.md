# Battery (Bar Component)

## 1. Component Overview

Battery is a bar component that displays battery status in the Yemi QuickShell desktop. It shows battery level, charging state, and time remaining in the right battery pill of the bar.

## 2. Project Structure and Dependencies

- **File**: `modules/bar/components/Battery.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Bar.qml` via battery loader
- **Depends on**: Quickshell power/battery integration

## 3. Component Hierarchy and Role

Battery is a bar component that renders battery indicators. It reads battery level, charging state, and power information from Quickshell's power backend.

## 4. Properties

Battery does not expose documented public properties in the source.

## 5. Signals

Battery does not define custom signals.

## 6. Methods

Battery does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Bar.qml**: Loads Battery into the right battery pill
- **Quickshell power backend**: Reads battery state

## 8. Usage Example

Battery is loaded by Bar and is not directly reusable.
