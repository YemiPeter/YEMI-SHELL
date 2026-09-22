# Ame

## 1. Component Overview

Ame is a reusable pill component that provides transition animations for the Yemi QuickShell desktop. It manages morphing transitions between pill states (rest, hover, and various surfaces) with smooth easing and cross-fade effects.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/Ame.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `Pill.qml` as the transition controller
- **Depends on**: No external dependencies

## 3. Component Hierarchy and Role

Ame is a reusable UI component that renders transition animations. It is used by Pill to morph between different states and surfaces with smooth animations.

## 4. Properties

Ame does not expose documented public properties in the source.

## 5. Signals

Ame does not define custom signals.

## 6. Methods

Ame does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Uses Ame for state morphing transitions

## 8. Usage Example

Ame is used internally by Pill and is not directly reusable.
