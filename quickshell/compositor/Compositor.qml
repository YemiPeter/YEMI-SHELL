pragma Singleton

import Quickshell
import QtQuick 6.10
import "." // Import the local compositor directory

Item {
    id: root
    
    // Detect which compositor is running
    readonly property string runningCompositor: detectCompositor()
    
    // Reference to the actual implementation based on detected compositor
    readonly property var impl: runningCompositor === "hyprland" ? hyprlandImpl : (runningCompositor === "niri" ? niriImpl : null)
    
    // Implementation instances
    Hyprland {
        id: hyprlandImpl
        enabled: runningCompositor === "hyprland"
    }
    
    Niri {
        id: niriImpl
        enabled: runningCompositor === "niri"
    }
    
    // Forward raw events from the active backend
    Connections {
        target: hyprlandImpl
        function onRawEvent(event) { root.rawEvent(event) }
    }
    
    /**
     * Normalize backend data to a plain array regardless of internal shape.
     *
     * Hyprland returns QML model objects (array-like, with a .values accessor).
     * Niri returns JS objects keyed by id/name.
     * Consumers should never need to know which one they're dealing with.
     */
    function _toArray(v: var): var {
        if (!v) return [];
        if (Array.isArray(v)) return v;
        // Hyprland model objects expose .values as a JS array
        if (v.values) return v.values;
        // Niri object keyed by id/name
        return Object.values(v);
    }
    
    // Interface properties — always plain arrays
    readonly property var toplevels: _toArray(impl?.toplevels)
    readonly property var workspaces: _toArray(impl?.workspaces)
    readonly property var monitors: _toArray(impl?.monitors)
    
    readonly property var activeToplevel: impl?.activeToplevel ?? null
    readonly property var focusedWorkspace: impl?.focusedWorkspace ?? null
    readonly property var focusedMonitor: impl?.focusedMonitor ?? null
    readonly property int activeWsId: impl?.activeWsId ?? 1
    
    // Forward raw compositor events so consumers (e.g. Workspacerules) can
    // react to specific event names without importing Quickshell.Hyprland.
    // Null/empty when the compositor backend doesn't emit raw events.
    signal rawEvent(var event)
    
    // Interface functions
    function dispatch(request: string): void {
        impl?.dispatch(request);
    }
    
    function monitorFor(screen: var): var {
        return impl?.monitorFor(screen);
    }
    
    function getOccupiedWorkspaces(): var {
        return impl?.getOccupiedWorkspaces() ?? {};
    }
    
    // Helper function to detect running compositor
    function detectCompositor(): string {
        // Check environment variables to determine which compositor is running
        var xdgCurrentDesktop = Quickshell.env("XDG_CURRENT_DESKTOP") || "";
        var desktopSession = Quickshell.env("DESKTOP_SESSION") || "";
        
        if (xdgCurrentDesktop.toLowerCase().includes("hyprland") || 
            desktopSession.toLowerCase().includes("hyprland")) {
            return "hyprland";
        }
        
        if (xdgCurrentDesktop.toLowerCase().includes("niri") || 
            desktopSession.toLowerCase().includes("niri")) {
            return "niri";
        }

        return null; // Unknown compositor
    }
}