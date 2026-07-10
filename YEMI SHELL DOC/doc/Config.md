# Config

## 1. Component Overview

Config is a singleton configuration aggregator for the Yemi QuickShell desktop environment. It provides centralized access to bar settings, appearance configuration, notification defaults, popup sizing, and dashboard visibility toggles. Other components import Config to read shared defaults rather than hardcoding values.

## 2. Project Structure and Dependencies

- **File**: `config/Config.qml`
- **Imports**: `Quickshell`
- **Instantiated by**: Any QML component that imports `config` (e.g., `Bar.qml`, `PillOverlay.qml`)
- **Depends on**: `BarConfig`, `AppearanceConfig` (both in the same `config/` directory)

## 3. Component Hierarchy and Role

Config is a `Singleton` (Quickshell singleton pattern) that composes two dedicated configuration objects:

- `BarConfig` — bar height, position, and display settings
- `AppearanceConfig` — theme, font, and visual style settings

It also exposes inline configuration objects for notifications, popups, and dashboard features.

## 4. Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| bar | BarConfig | BarConfig {} | No | Bar layout and sizing configuration |
| appearance | AppearanceConfig | AppearanceConfig {} | No | Theme, font, and visual style configuration |
| notifications | var | { popupWidth: 340, maxVisible: 5, timeout: 7000, spacing: 8, margin: 8 } | No | Notification popup defaults |
| popups | var | { width: 280, minHeight: 100, maxHeight: 400, hoverDelay: 300, margin: 6 } | No | Generic popup sizing and interaction defaults |
| dashboard | var | { enable: false, showToggles: true, showMedia: true, showVolume: true, showWeather: false, showSystem: true } | No | Dashboard feature toggles for overview compatibility |

## 5. Signals

Config does not define custom signals.

## 6. Methods

Config does not define custom methods. All access is through properties.

## 7. Inter-Component Interactions

- **Bar.qml**: Reads `config.bar.height` and `config.bar` for bar sizing
- **PillOverlay.qml**: Reads `config.bar.height` for reserve window calculations
- **AppearanceConfig**: Composed into `config.appearance` for theme access
- **BarConfig**: Composed into `config.bar` for bar layout

## 8. Usage Example

```qml
import "config" as QsConfig

Text {
  text: "Bar height: " + QsConfig.Config.bar.height
  color: QsConfig.Config.appearance.fontColor
}
```
