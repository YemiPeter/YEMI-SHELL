# Flags

## 1. Component Overview

Flags is a singleton that holds feature flags and global UI settings for the Yemi QuickShell desktop. It provides a single source of truth for configuration values that affect multiple components, such as UI scale factor and feature toggles.

## 2. Project Structure and Dependencies

- **File**: `singletons/Flags.qml`
- **Imports**: `QtQuick`
- **Instantiated by**: Any component that needs global flags (e.g., `Bar.qml`, `Pill.qml`, `PillOverlay.qml`)
- **Depends on**: No external dependencies

## 3. Component Hierarchy and Role

Flags is a `Singleton` extending `QtObject`. It exposes boolean and numeric properties that control feature availability and UI scaling across the shell.

## 4. Properties

Flags does not expose documented public properties in the source.

## 5. Signals

Flags does not define custom signals.

## 6. Methods

Flags does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Bar.qml**: Reads `Flags.uiScale` for responsive sizing
- **Pill.qml**: Reads `Flags.uiScale` for responsive sizing
- **PillOverlay.qml**: Reads `Flags.uiScale` for responsive sizing
- **All UI components**: Consume flags for consistent behavior

## 8. Usage Example

```qml
import "../../singletons" as QsSingletons

Item {
  width: 100 * QsSingletons.Flags.uiScale
  height: 50 * QsSingletons.Flags.uiScale
}
```
