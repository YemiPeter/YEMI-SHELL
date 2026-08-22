# Bar

## 1. Component Overview

Bar is the per-screen status bar for the Yemi QuickShell desktop. It renders a floating, minimal-aesthetic bar at the top of each monitor containing workspace indicators, connectivity status (network and Bluetooth), volume control, battery status, and system tray icons. The bar uses a pill-shaped design language with subtle highlights and borders derived from the theme.

## 2. Project Structure and Dependencies

- **File**: `modules/bar/Bar.qml`
- **Imports**: `QtQuick 6.10`, `QtQuick.Layouts 6.10`, `QtQuick.Effects`, `Quickshell`, local `components/effects`, `../../config`, `../../services`, `../../singletons`
- **Instantiated by**: `BarWrapper.qml` (one Bar per screen)
- **Depends on**: `Workspaces.qml`, `Network.qml`, `Bluetooth.qml`, `Volume.qml`, `Battery.qml`, `StatusIndicators.qml`, `Tray.qml` (all in `modules/bar/components/`)

## 3. Component Hierarchy and Role

Bar is an `Item` that composes three horizontal sections:

- **Left module**: Workspace indicators in a pill-shaped container
- **Center spacer**: Empty space matching the pill's resting dimensions (the actual pill lives in PillOverlay)
- **Right pills**: Three separate pill containers for connectivity, volume/battery, and tray

Each section uses `Loader` to lazily load its child components and `Binding` to pass `barWindow` and `screenName` once the loader is ready.

## 4. Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| screen | var | — | Yes | The Quickshell screen object this bar is rendered on |
| barWindow | var | — | Yes | Reference to the parent BarWrapper window |
| screenName | string | derived | No | Read-only; screen.name or empty string |
| s | real | derived | No | Read-only scale factor based on screen height and UI scale flag |
| config | var | QsConfig.Config | No | Read-only reference to the configuration singleton |
| appearance | var | QsConfig.AppearanceConfig | No | Read-only reference to appearance configuration |
| pillBg | color | derived | No | Read-only pill background color with alpha |
| pillBorder | color | derived | No | Read-only pill border color with alpha |
| pillSeparator | color | derived | No | Read-only pill separator color with alpha |
| highlightTop | color | derived | No | Read-only top highlight color for pill gradient |

## 5. Signals

Bar does not define custom signals.

## 6. Methods

Bar does not define custom methods.

## 7. Inter-Component Interactions

- **BarWrapper.qml**: Creates one Bar per screen and passes `screen` and `barWindow`
- **Workspaces.qml**: Loaded into the left module; receives `screen` via Binding
- **Network.qml**: Loaded into the right connectivity pill; receives `barWindow` and `screenName`
- **Bluetooth.qml**: Loaded into the right connectivity pill; receives `barWindow` and `screenName`
- **Volume.qml**: Loaded into the right volume pill
- **Battery.qml**: Loaded into the right battery pill
- **StatusIndicators.qml**: Loaded into the right status pill
- **Tray.qml**: Loaded into the right tray pill
- **Config**: Read for `config.bar.height` and theme colors
- **Theme singleton**: Read for pill colors (`cardBot`, `cream`)
- **Flags singleton**: Read for `uiScale`

## 8. Usage Example

Bar is instantiated by BarWrapper and is not directly reusable by other components. Its structure is specific to the per-screen bar window.
