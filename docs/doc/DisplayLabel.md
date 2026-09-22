# DisplayLabel

## 1. Component Overview

DisplayLabel is a reusable pill component that provides a display label for the Yemi QuickShell desktop. It is used in the display settings surface to show monitor names and display information.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/DisplayLabel.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: Display.qml, DisplayPicker.qml
- **Depends on**: No external dependencies

## 3. Component Hierarchy and Role

DisplayLabel is a reusable UI component that renders a display label. It provides consistent styling for monitor names and display information in the display settings surface.

## 4. Properties

DisplayLabel does not expose documented public properties in the source.

## 5. Signals

DisplayLabel does not define custom signals.

## 6. Methods

DisplayLabel does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Display.qml**: Uses DisplayLabel for monitor labels
- **DisplayPicker.qml**: Uses DisplayLabel for monitor labels

## 8. Usage Example

DisplayLabel is used as a child component within display-related surfaces.
