# MusicPanel

## 1. Component Overview

MusicPanel is a module that displays music playback controls and information for the Yemi QuickShell desktop. It shows the current track, playback controls, and volume for active media players.

## 2. Project Structure and Dependencies

- **File**: `modules/music/MusicPanel.qml`
- **Imports**: `QtQuick`, `Quickshell`, `Quickshell.Services.Mpris`
- **Instantiated by**: `shell.qml` via `musicPanelLoader`
- **Depends on**: Players service, MPRIS integration

## 3. Component Hierarchy and Role

MusicPanel is a standalone module that renders music playback controls. It is loaded by shell.qml and its visibility is controlled by `musicVisible`.

## 4. Properties

MusicPanel does not expose documented public properties in the source.

## 5. Signals

MusicPanel does not define custom signals.

## 6. Methods

MusicPanel does not define documented custom methods in the source.

## 7. Inter-Component Interactions

- **shell.qml**: Loads MusicPanel via `musicPanelLoader`; visibility controlled by `musicVisible`
- **Players service**: Reads active players and track metadata
- **MPRIS**: Reads playback state and controls

## 8. Usage Example

MusicPanel is loaded by shell.qml and toggled via IPC:

```qml
// From terminal or keybind:
// qs ipc call music toggle
```
