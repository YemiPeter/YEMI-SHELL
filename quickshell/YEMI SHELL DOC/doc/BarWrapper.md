# BarWrapper

## 1. Component Overview

BarWrapper is a window wrapper that instantiates the Bar component for each screen. It creates a `PanelWindow` for each monitor and loads the Bar QML component into it, passing the screen and window references.

## 2. Project Structure and Dependencies

- **File**: `modules/bar/BarWrapper.qml`
- **Imports**: `Quickshell`, `QtQuick`, `modules/bar/Bar.qml`
- **Instantiated by**: `shell.qml` via `barLoader`
- **Depends on**: `Bar.qml`

## 3. Component Hierarchy and Role

BarWrapper is a `PanelWindow` that loads `Bar.qml` as its content. It is responsible for creating one bar window per screen and managing the window lifecycle.

## 4. Properties

BarWrapper does not expose documented public properties in the source.

## 5. Signals

BarWrapper does not define custom signals.

## 6. Methods

BarWrapper does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **shell.qml**: Loads BarWrapper via `barLoader`; receives the loaded item as `root.barWindow`
- **Bar.qml**: Child of BarWrapper; receives `screen` and `barWindow` properties

## 8. Usage Example

BarWrapper is loaded by shell.qml and is not directly reusable.
