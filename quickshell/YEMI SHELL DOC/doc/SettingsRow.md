# SettingsRow

## 1. Component Overview

SettingsRow is a reusable pill component that provides a settings row layout for the Yemi QuickShell desktop. It is used in settings surfaces to display labeled settings controls in a consistent row format.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/SettingsRow.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: Settings, Appearance, and other settings surfaces
- **Depends on**: No external dependencies

## 3. Component Hierarchy and Role

SettingsRow is a reusable UI component that renders a settings row with label and control. It provides consistent layout and styling for settings controls across the shell.

## 4. Properties

SettingsRow does not expose documented public properties in the source.

## 5. Signals

SettingsRow does not define custom signals.

## 6. Methods

SettingsRow does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Settings.qml**: Uses SettingsRow for settings layout
- **Appearance.qml**: Uses SettingsRow for appearance settings
- **Other settings surfaces**: Use SettingsRow for consistent settings UI

## 8. Usage Example

SettingsRow is used as a child component within settings surfaces.
