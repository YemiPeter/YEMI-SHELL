# Compositor Component

## Component Overview

Compositor is a singleton component that provides a unified abstraction layer for different Wayland compositors (currently Hyprland and Niri). It automatically detects which compositor is running and delegates to the appropriate backend implementation. This component allows the rest of the QuickShell application to interact with compositor-specific APIs through a consistent interface, simplifying support for multiple compositors without changing the higher-level code.

## Project Structure and Dependencies

The Compositor component is located at `/home/yemi/.config/quickshell/compositor/Compositor.qml` and is marked as a singleton with `pragma Singleton`. It imports:

- **Quickshell framework**: For environment variable access
- **Qt Quick 6.10**: For basic QML functionality
- **Local compositor implementations**: Imports from "." for Hyprland and Niri backends

The component is imported as a singleton throughout the application using `import qs.compositor` and provides a consistent interface to compositor-specific functionality.

## Component Hierarchy and Role

Compositor extends the `Item` type and acts as a facade pattern implementation. It encapsulates both Hyprland and Niri backend implementations and routes requests to the appropriate backend based on runtime detection. This provides a unified API regardless of which compositor is actually running.

## Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| runningCompositor | string | detectCompositor() | No | Name of the currently running compositor ("hyprland", "niri", or fallback) |
| impl | var | appropriate backend | No | Reference to the active backend implementation |
| toplevels | var | impl?.toplevels ?? [] | No | List of top-level windows from the active compositor |
| workspaces | var | impl?.workspaces ?? [] | No | List of workspaces from the active compositor |
| monitors | var | impl?.monitors ?? [] | No | List of monitors from the active compositor |
| activeToplevel | var | impl?.activeToplevel ?? null | No | Currently active/focused window |
| focusedWorkspace | var | impl?.focusedWorkspace ?? null | No | Currently focused workspace |
| focusedMonitor | var | impl?.focusedMonitor ?? null | No | Currently focused monitor |
| activeWsId | int | impl?.activeWsId ?? 1 | No | ID of the currently active workspace |

## Signals

This component does not declare custom signals but forwards events from the active backend implementation.

## Methods

#### dispatch(request: string) : void
Dispatches a command to the active compositor backend. Parameters: `request` (command string to dispatch).

#### monitorFor(screen: var) : var
Retrieves monitor information for a given screen. Parameters: `screen` (screen identifier).

#### getOccupiedWorkspaces() : var
Retrieves a mapping of workspace IDs to occupancy status. Returns: object mapping workspace IDs to boolean values indicating if they have windows.

#### detectCompositor() : string
Detects which compositor is currently running by checking environment variables. Returns: string identifying the compositor ("hyprland", "niri", or "hyprland" as fallback).

## Inter-Component Interactions

The Compositor component is used throughout the application to:

- **Window management**: Retrieve lists of windows and control focus
- **Workspace operations**: Navigate between workspaces and retrieve workspace information
- **Monitor handling**: Access monitor properties and assign windows to monitors
- **Action dispatching**: Send commands to the compositor (workspace switching, window management)

Higher-level components interact with the compositor through this unified interface without needing to know which specific compositor implementation is active.

## Usage Example

```qml
import qs.compositor

Item {
    // Access compositor information through the unified interface
    readonly property var compositor: Compositor
    readonly property var activeWindow: compositor.activeToplevel
    readonly property var workspaces: compositor.workspaces
    
    // Dispatch actions to the active compositor
    function switchToWorkspace(id) {
        compositor.dispatch(`workspace ${id}`);
    }
}
```