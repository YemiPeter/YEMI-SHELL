# Compositor

## 1. Component Overview

Compositor is a singleton abstraction layer that detects and wraps the active Wayland compositor (Hyprland or Niri). It provides a unified interface to the rest of the shell so that compositor-specific code does not need to be scattered across components. Instead of importing `Quickshell.Hyprland` or `Quickshell.Niri` directly, components read from `Compositor` and get the correct backend automatically.

## 2. Project Structure and Dependencies

- **File**: `compositor/Compositor.qml`
- **Imports**: `Quickshell`, `QtQuick 6.10`, local `.` (compositor directory)
- **Instantiated by**: Any component that imports `qs.compositor` (e.g., `shell.qml`, `PillOverlay.qml`)
- **Depends on**: `Hyprland.qml`, `Niri.qml` (both in `compositor/`)

## 3. Component Hierarchy and Role

Compositor is a `Singleton` that composes two backend implementations:

- `Hyprland` — Hyprland-specific toplevel, workspace, and monitor handling
- `Niri` — Niri-specific toplevel, workspace, and monitor handling

Only the backend matching the detected compositor is enabled; the other remains disabled. Compositor forwards properties and methods from the active backend through a unified interface.

## 4. Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| runningCompositor | string | detectCompositor() | No | Name of the detected compositor: "hyprland" or "niri" |
| impl | var | hyprlandImpl or niriImpl | No | Read-only reference to the active backend implementation |
| toplevels | list | [] | No | Active toplevel windows from the compositor |
| workspaces | list | [] | No | Workspaces from the compositor |
| monitors | list | [] | No | Monitors from the compositor |
| activeToplevel | var | null | No | Currently active toplevel window |
| focusedWorkspace | var | null | No | Currently focused workspace |
| focusedMonitor | var | null | No | Currently focused monitor |
| activeWsId | int | 1 | No | ID of the currently active workspace |

## 5. Signals

#### rawEvent(var event)
Forwarded from the active Hyprland backend. Emitted when a raw compositor event occurs. Consumers (e.g., Workspacerules) can react to specific event names without importing Quickshell.Hyprland directly.

## 6. Methods

#### dispatch(request: string) : void
Sends a raw dispatch request to the active compositor backend (e.g., Hyprland dispatch commands).

#### monitorFor(screen: var) : var
Returns the compositor monitor object corresponding to the given Quickshell screen.

#### getOccupiedWorkspaces() : var
Returns a map of occupied workspaces from the active backend.

#### detectCompositor() : string
Reads `XDG_CURRENT_DESKTOP` and `DESKTOP_SESSION` environment variables to determine whether Hyprland or Niri is running. Falls back to "hyprland" if detection fails.

## 7. Inter-Component Interactions

- **shell.qml**: Reads `compositor.focusedMonitor` for IPC handlers that need the active monitor name
- **PillOverlay.qml**: Uses compositor indirectly through `Quickshell.screens` and monitor data
- **Hyprland.qml**: Backend implementation enabled when `runningCompositor === "hyprland"`
- **Niri.qml**: Backend implementation enabled when `runningCompositor === "niri"`

## 8. Usage Example

```qml
import qs.compositor as QsCompositor

Text {
  text: "Compositor: " + QsCompositor.Compositor.runningCompositor
  text: "Focused monitor: " + QsCompositor.Compositor.focusedMonitor.name
}
```
