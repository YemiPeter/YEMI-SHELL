# Workspaces

## 1. Component Overview

Workspaces is a bar component that displays workspace indicators for the Yemi QuickShell desktop. It shows the current workspace state and allows switching between workspaces, typically rendered as a row of dots or numbered indicators in the left pill of the bar.

## 2. Project Structure and Dependencies

- **File**: `modules/bar/components/Workspaces.qml`
- **Imports**: `QtQuick`, `Quickshell`, `Quickshell.Hyprland` or `Quickshell.Niri`
- **Instantiated by**: `Bar.qml` via `workspacesLoader`
- **Depends on**: Compositor backend for workspace state

## 3. Component Hierarchy and Role

Workspaces is a bar component that renders workspace indicators. It reads workspace state from the compositor backend and displays active, occupied, and empty workspaces.

## 4. Properties

Workspaces does not expose documented public properties in the source.

## 5. Signals

Workspaces does not define custom signals.

## 6. Methods

Workspaces does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Bar.qml**: Loads Workspaces into the left module; passes `screen` via Binding
- **Compositor**: Reads workspace state from the active backend

## 8. Usage Example

Workspaces is loaded by Bar and is not directly reusable.
