# Screenshot

## 1. Component Overview

Screenshot is a service that handles screenshot capture for the Yemi QuickShell desktop. It provides methods to capture the full screen, selected regions, or active window, typically triggered by keybinds.

## 2. Project Structure and Dependencies

- **File**: `services/Screenshot.qml`
- **Imports**: `Quickshell`, `Quickshell.Io`
- **Instantiated by**: `shell.qml` as `QsServices.Screenshot`
- **Depends on**: External screenshot tools (e.g., grim, slurp)

## 3. Component Hierarchy and Role

Screenshot is a service object that wraps screenshot capture functionality. It exposes methods to capture different types of screenshots and save them to disk.

## 4. Properties

Screenshot does not expose documented public properties in the source.

## 5. Signals

Screenshot does not define custom signals.

## 6. Methods

Screenshot does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **shell.qml**: Initialized as a core service
- **Keybinds**: Trigger screenshot capture via IPC or direct method calls

## 8. Usage Example

Screenshot is triggered by keybinds. Direct usage depends on the Quickshell screenshot API and external tools.
