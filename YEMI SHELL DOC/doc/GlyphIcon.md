# GlyphIcon

## 1. Component Overview

GlyphIcon is a reusable pill component that displays icon glyphs for the Yemi QuickShell desktop. It provides a consistent way to render icons across the pill surfaces and bar components.

## 2. Project Structure and Dependencies

- **File**: `modules/pill/GlyphIcon.qml`
- **Imports**: `QtQuick`, `Quickshell`
- **Instantiated by**: Various pill and bar components
- **Depends on**: Theme singleton for icon colors

## 3. Component Hierarchy and Role

GlyphIcon is a reusable UI component that renders icon glyphs. It is used throughout the pill and bar systems for consistent icon display.

## 4. Properties

GlyphIcon does not expose documented public properties in the source.

## 5. Signals

GlyphIcon does not define custom signals.

## 6. Methods

GlyphIcon does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Various pill surfaces**: Use GlyphIcon for icon display
- **Bar components**: Use GlyphIcon for icon display
- **Theme**: Reads icon colors from theme

## 8. Usage Example

GlyphIcon is used as a child component within various surfaces and bar components.
