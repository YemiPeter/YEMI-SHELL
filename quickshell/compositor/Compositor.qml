pragma Singleton

import Quickshell
import QtQuick 6.10
import "." // Import the local compositor directory

Item {
    id: root
    
    // Detect which compositor is running
    readonly property string runningCompositor: detectCompositor()

    // Convenience boolean flags (used by the wallpaper/backdrop path so we
    // never have to string-compare runningCompositor in every binding).
    readonly property bool isNiri: runningCompositor === "niri"
    readonly property bool isHyprland: runningCompositor === "hyprland"

    /**
     * True when the compositor applies its own blur to quickshell's layer
     * surfaces (Hyprland: `layerrule = blur on, match:namespace quickshell|pill`).
     *
     * QML-side drop shadows must be suppressed when this is set: the layer
     * blur is drawn behind EVERY translucent pixel of the layer surface, so
     * a shadow painted outside a card's border reads as a frosted halo of
     * blurred wallpaper instead of a shadow. On such compositors the
     * compositor blur itself lifts the card. Niri has no layer blur yet, so
     * QML shadows render there as designed.
     */
    readonly property bool hasLayerBlur: isHyprland
    
    // Reference to the actual implementation based on detected compositor.
    // Backend instances are Loader-gated below: only the backend matching the
    // running compositor is ever instantiated (no Niri objects on Hyprland,
    // no Hyprland objects on Niri). `impl` is null until the matching loader's
    // item exists; every consumer below guards with `impl?.` / `??`.
    readonly property var impl: runningCompositor === "hyprland" ? hyprlandLoader.item
                              : (runningCompositor === "niri" ? niriLoader.item : null)

    // Implementation instances (Loader-gated)
    Loader {
        id: hyprlandLoader
        active: runningCompositor === "hyprland"
        sourceComponent: Hyprland {
            id: hyprlandImpl
            enabled: runningCompositor === "hyprland"
        }
    }

    Loader {
        id: niriLoader
        active: runningCompositor === "niri"
        sourceComponent: Niri {
            id: niriImpl
            enabled: runningCompositor === "niri"
        }
    }

    // Forward raw events from the active backend
    Connections {
        target: hyprlandLoader.item
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