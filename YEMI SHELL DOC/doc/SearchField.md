# SearchField

## 1. Component Overview

SearchField is a reusable pill component that provides a search input field for the Yemi QuickShell desktop. It is used in surfaces that require search functionality, such as the launcher and keybinds surfaces.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/SearchField.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: Launcher, Keybinds, and other searchable surfaces
- **Depends on**: No external dependencies

## 3. Component Hierarchy and Role

SearchField is a reusable UI component that renders a search input with styling consistent with the pill design language. It provides text input with focus handling and search icon.

## 4. Properties

SearchField does not expose documented public properties in the source.

## 5. Signals

SearchField does not define custom signals.

## 6. Methods

SearchField does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Launcher.qml**: Uses SearchField for application search
- **Keybinds.qml**: Uses SearchField for keybind search
- **Other searchable surfaces**: May use SearchField for consistent search UI

## 8. Usage Example

SearchField is used as a child component within searchable surfaces.
