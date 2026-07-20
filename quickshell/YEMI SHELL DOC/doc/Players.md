# Players

## 1. Component Overview

Players is a service that integrates with MPRIS media players to provide media playback information and control for the Yemi QuickShell desktop. It exposes active players, playback state, track metadata, and control methods for the bar media indicator and the pill media surface.

## 2. Project Structure and Dependencies

- **File**: `services/Players.qml`
- **Imports**: `Quickshell`, `Quickshell.Services.Mpris`
- **Instantiated by**: `shell.qml` as `QsServices.Players`
- **Depends on**: Quickshell MPRIS service

## 3. Component Hierarchy and Role

Players is a service object that wraps Quickshell's MPRIS backend. It exposes active media players, current track information, and playback control for consumption by UI components.

## 4. Properties

Players does not expose documented public properties in the source.

## 5. Signals

Players does not define custom signals.

## 6. Methods

Players does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **shell.qml**: Initialized as a core service
- **Media.qml** (pill surface): Reads player state for the media controls surface
- **Pill.qml**: Reads `Mpris.players.values` for media presence detection

## 8. Usage Example

Players is consumed by the pill media surface. Direct usage depends on the Quickshell MPRIS API.
