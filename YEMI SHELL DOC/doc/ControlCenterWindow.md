# ControlCenterWindow Component

## Component Overview

ControlCenterWindow is a system control panel that provides quick access to common system functions including volume/brightness controls, network management, power controls, and system monitoring. It appears as a sliding panel on the right side of the screen and includes components for media playback, notifications, and system statistics. The component uses a Material Design 3 aesthetic with smooth animations and responsive layout.

## Project Structure and Dependencies

The ControlCenterWindow component is located at `/home/yemi/.config/quickshell/modules/controlcenter/ControlCenterWindow.qml`. It imports:

- **Qt Quick modules**: QtQuick 6.10, QtQuick.Layouts 6.10, QtQuick.Controls 6.10 for UI components
- **Quickshell framework**: Wayland integration, Io utilities, Bluetooth APIs
- **Project modules**: Services, config, effects, and control center components
- **Local components**: Various control center sub-components

The component extends PanelWindow to integrate properly with the Wayland compositor as a layer surface.

## Component Hierarchy and Role

ControlCenterWindow extends PanelWindow, making it a proper Wayland layer surface that respects compositor layer rules. It serves as the main container for the control center interface, managing the layout and interaction of various system controls including volume, brightness, network toggles, media controls, and system stats.

## Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| shouldShow | bool | false | No | Controls visibility of the control center panel |
| cSurface | color | pywal.background | No | Surface color token for the panel |
| cSurfaceContainer | color | Qt.lighter(pywal.background, 1.15) | No | Container color token |
| cSurfaceContainerHigh | color | Qt.lighter(pywal.background, 1.25) | No | High contrast container color |
| cBorder | color | Qt.rgba(pywal.foreground.r, ...) | No | Border color token |
| cPrimary | color | pywal.primary | No | Primary accent color |
| cSecondary | color | pywal.secondary | No | Secondary accent color |
| cOnSurface | color | pywal.foreground | No | Foreground text color |
| cOnSurfaceVariant | color | rgba(pywal.foreground with 0.7 alpha) | No | Variant text color |
| cOnSurfaceDim | color | rgba(pywal.foreground with 0.5 alpha) | No | Dimmed text color |
| logger | var | QsServices.Logger | No | Reference to logging service |
| config | var | QsConfig.Config | No | Reference to configuration |
| pywal | var | QsServices.Pywal | No | Reference to color theming service |
| network | var | QsServices.Network | No | Reference to network service |
| bluetooth | var | QsServices.Bluetooth | No | Reference to Bluetooth service |
| audio | var | QsServices.Audio | No | Reference to audio service |
| brightness | var | QsServices.Brightness | No | Reference to brightness service |
| mpris | var | QsServices.Players | No | Reference to media player service |
| notifs | var | QsServices.Notifs | No | Reference to notification service |
| systemUsage | var | QsServices.SystemUsage | No | Reference to system usage service |
| powerProfiles | var | QsServices.PowerProfiles | No | Reference to power profiles service |
| screenshot | var | QsServices.Screenshot | No | Reference to screenshot service |
| idleInhibitor | var | QsServices.IdleInhibitor | No | Reference to idle inhibition service |
| hyprsunset | var | QsServices.Hyprsunset | No | Reference to night light service |

## Signals

This component does not declare custom signals but uses various Qt Quick and Quickshell framework events.

## Methods

#### None declared
The component does not declare custom methods but uses inherited PanelWindow methods for window management.

## Inter-Component Interactions

The ControlCenterWindow component integrates with:

- **Services layer** to control system functions (audio, brightness, network, etc.)
- **Pywal theming** to maintain visual consistency with the overall color scheme
- **Process managers** to launch external tools (settings, lock screen, power menu)
- **Child components** (QuickToggle, VolumeSlider, BrightnessSlider, etc.) to implement specific controls
- **Notification system** to display and manage notifications
- **Media players** to control playback through MPRIS

The component uses the color properties from Pywal service extensively to maintain a consistent visual theme, though it references properties (warning, info, error, secondary) that may not exist in the actual Pywal implementation.

## Known Issues

According to the project audit, this component references color properties from Pywal service (warning, info, error, secondary) that do not exist in the actual Pywal implementation, which may cause visual inconsistencies.

## Usage Example

```qml
import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "components"

ControlCenterWindow {
    id: controlCenter
    
    // Toggle visibility
    function toggle() {
        shouldShow = !shouldShow;
    }
    
    // The component automatically connects to services and displays controls
    // based on the current system state and user configuration
}
```