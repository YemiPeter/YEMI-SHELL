# Tooltip

## 1. Component Overview

Tooltip is a pill surface that displays tooltip information for the Yemi QuickShell desktop. It shows hover tooltips for pill elements and bar components, accessible from the pill when tooltip display is needed.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/Tooltip.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Pill.qml` as a child surface
- **Depends on**: No external dependencies

## 3. Component Hierarchy and Role

Tooltip is a pill surface component that renders tooltip information. It is shown on hover over pill elements and is positioned and sized by the Pill's surface system.

## 4. Properties

Tooltip does not expose documented public properties in the source.

## 5. Signals

Tooltip does not define custom signals.

## 6. Methods

Tooltip does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Contains Tooltip as a child surface; shows/hides on hover
- **Bar components**: May trigger tooltips on hover

## 8. Usage Example

Tooltip is shown on hover and is not directly opened via IPC.
