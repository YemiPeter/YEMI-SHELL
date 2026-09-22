# Theme

## 1. Component Overview

Theme is a singleton that provides the color palette and visual theme for the Yemi QuickShell desktop. It exposes theme colors derived from Matugen's wallpaper-based color generation, ensuring the shell's UI colors always match the current wallpaper.

## 2. Project Structure and Dependencies

- **File**: `singletons/Theme.qml`
- **Imports**: `QtQuick`
- **Instantiated by**: Any component that needs theme colors (e.g., `Bar.qml`, `Pill.qml`, `PillOverlay.qml`)
- **Depends on**: Matugen service for color generation

## 3. Component Hierarchy and Role

Theme is a `Singleton` extending `QtObject`. It exposes color properties that are updated when Matugen generates a new color scheme from the current wallpaper.

## 4. Properties

Theme does not expose documented public properties in the source.

## 5. Signals

Theme does not define custom signals.

## 6. Methods

Theme does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Matugen**: Updates theme colors when a new wallpaper is applied
- **Bar.qml**: Reads theme colors for pill backgrounds and borders
- **Pill.qml**: Reads theme colors for pill styling
- **PillOverlay.qml**: Reads theme colors for overlay styling
- **All UI components**: Consume theme colors for consistent visual appearance

## 8. Usage Example

```qml
import "../../singletons" as QsSingletons

Rectangle {
  color: QsSingletons.Theme.cardBot
  border.color: QsSingletons.Theme.cream
}
```
