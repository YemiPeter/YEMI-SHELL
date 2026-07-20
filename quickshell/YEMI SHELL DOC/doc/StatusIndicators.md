# StatusIndicators

## 1. Component Overview

StatusIndicators is a bar component that displays system status indicators in the Yemi QuickShell desktop. It shows various system status icons (e.g., network, volume, battery) in the right status pill of the bar.

## 2. Project Structure and Dependencies

- **File**: `modules/bar/components/StatusIndicators.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Bar.qml` via status indicators loader
- **Depends on**: Various system services

## 3. Component Hierarchy and Role

StatusIndicators is a bar component that renders system status icons. It aggregates status from multiple services and displays compact indicators.

## 4. Properties

StatusIndicators does not expose documented public properties in the source.

## 5. Signals

StatusIndicators does not define custom signals.

## 6. Methods

StatusIndicators does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Bar.qml**: Loads StatusIndicators into the right status pill
- **System services**: Reads status from various services

## 8. Usage Example

StatusIndicators is loaded by Bar and is not directly reusable.
