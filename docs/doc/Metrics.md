# Metrics

## 1. Component Overview

Metrics is a singleton that provides layout metrics and sizing constants for the Yemi QuickShell desktop. It centralizes dimension values used across the pill system and bar to ensure consistent sizing and spacing.

## 2. Project Structure and Dependencies

- **File**: `singletons/Metrics.qml`
- **Imports**: `QtQuick`
- **Instantiated by**: Components that need layout constants (e.g., `Pill.qml`, `PillOverlay.qml`)
- **Depends on**: No external dependencies

## 3. Component Hierarchy and Role

Metrics is a `Singleton` extending `QtObject`. It exposes numeric constants for resting height, padding, corner radius, and other layout dimensions used by the pill and bar systems.

## 4. Properties

Metrics does not expose documented public properties in the source.

## 5. Signals

Metrics does not define custom signals.

## 6. Methods

Metrics does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **Pill.qml**: Reads `Metrics.restHBase` for resting height calculation
- **PillOverlay.qml**: Reads `Metrics.restHBase` for reserve window height
- **Bar.qml**: May read metrics for consistent spacing

## 8. Usage Example

```qml
import "../../singletons" as QsSingletons

Item {
  height: QsSingletons.Metrics.restHBase * scaleFactor
}
```
