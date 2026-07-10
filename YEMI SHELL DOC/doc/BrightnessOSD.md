# BrightnessOSD

## 1. Component Overview

BrightnessOSD is an on-screen display component that shows brightness changes for the Yemi QuickShell desktop. It displays a transient brightness indicator when the user adjusts brightness via keybinds or the display surface.

## 2. Project Structure and Dependencies

- **File**: `modules/osd/BrightnessOSD.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: `modules/osd/Wrapper.qml`
- **Depends on**: Brightness service

## 3. Component Hierarchy and Role

BrightnessOSD is an OSD component that renders brightness change feedback. It is shown temporarily when brightness is adjusted and fades out automatically.

## 4. Properties

BrightnessOSD does not expose documented public properties in the source.

## 5. Signals

BrightnessOSD does not define custom signals.

## 6. Methods

BrightnessOSD does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Wrapper.qml**: Loads BrightnessOSD for brightness feedback
- **Brightness service**: Reads brightness level

## 8. Usage Example

BrightnessOSD is triggered by brightness changes and is not directly opened via IPC.
