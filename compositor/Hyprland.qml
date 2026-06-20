import Quickshell
import Quickshell.Hyprland
import QtQuick 6.10

Item {
    id: root
    
    property bool enabled: false
    
    // Only activate when enabled
    readonly property var toplevels: enabled ? Hyprland.toplevels : []
    readonly property var workspaces: enabled ? Hyprland.workspaces : []
    readonly property var monitors: enabled ? Hyprland.monitors : []
    
    readonly property var activeToplevel: enabled ? Hyprland.activeToplevel : null
    readonly property var focusedWorkspace: enabled ? Hyprland.focusedWorkspace : null
    readonly property var focusedMonitor: enabled ? Hyprland.focusedMonitor : null
    readonly property int activeWsId: enabled ? (focusedWorkspace?.id ?? 1) : 1
    
    function dispatch(request: string): void {
        if (enabled) {
            Hyprland.dispatch(request);
        }
    }
    
    function monitorFor(screen: var): var {
        if (enabled) {
            return Hyprland.monitorFor(screen);
        }
        return null;
    }
    
    // Get occupied workspaces (workspaces with windows)
    function getOccupiedWorkspaces(): var {
        if (!enabled) return {};
        
        const occupied = {};
        for (const ws of workspaces.values) {
            occupied[ws.id] = (ws.lastIpcObject?.windows ?? 0) > 0;
        }
        return occupied;
    }
    
    // Refresh timer to ensure updates when events are missed
    Timer {
        interval: 500
        running: enabled
        repeat: true
        onTriggered: {
            if (enabled) {
                Hyprland.refreshWorkspaces();
            }
        }
    }
    
    Connections {
        target: enabled ? Hyprland : null
        
        function onRawEvent(event: var): void {
            if (!enabled) return;
            
            const n = event.name;
            if (n.endsWith("v2"))
                return;
                
            // More aggressive refresh for workspace changes
            if (["workspace", "moveworkspace", "activespecial", "focusedmon", "activewindow"].includes(n)) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
            } else if (["openwindow", "closewindow", "movewindow"].includes(n)) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
            } else if (n.includes("workspace")) {
                Hyprland.refreshWorkspaces();
            } else if (n.includes("window")) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
            }
        }
    }
}