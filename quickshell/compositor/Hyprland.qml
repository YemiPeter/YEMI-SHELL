import Quickshell
import Quickshell.Hyprland
import QtQuick 6.10

Item {
    id: root
    
    property bool enabled: false
    
    // Forward raw Hyprland events so Compositor can re-emit them
    // without consumers needing to import Quickshell.Hyprland.
    signal rawEvent(var event)
    
    // Only activate when enabled
    readonly property var toplevels: enabled ? Hyprland.toplevels : []
    readonly property var workspaces: enabled ? Hyprland.workspaces : []
    readonly property var monitors: enabled ? Hyprland.monitors : []
    
    readonly property var activeToplevel: enabled ? Hyprland.activeToplevel : null
    readonly property var focusedWorkspace: enabled ? Hyprland.focusedWorkspace : null
    readonly property var focusedMonitor: enabled ? Hyprland.focusedMonitor : null
    readonly property int activeWsId: enabled ? (focusedWorkspace?.id ?? 1) : 1
    
    function dispatch(request: string): void {
        if (!enabled) return;

        if (Hyprland.usingLua) {
            request = translateDispatch(request);
        }

        Hyprland.dispatch(request);
    }

    function translateDispatch(request: string): string {
        if (request.startsWith("workspace ")) {
            return 'hl.dsp.focus({workspace = "' + request.slice(9) + '"})';
        }

        if (request.startsWith("focuswindow ")) {
            let addr = request.slice(12); // "address:0x..." or "0x..."
            return 'hl.dsp.focus({window = "' + addr + '"})';
        }

        if (request.startsWith("movetoworkspace ")) {
            var parts = request.slice(16).split(",");
            var ws = parts[0];
            var win = parts.length > 1 ? parts[1] : "";
            return 'hl.dsp.window.move({workspace = "' + ws + '", window = "' + win + '"})';
        }

        if (request === "quit") {
            return "hl.dsp.exit()";
        }

        return request;
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
            
            // Forward to Compositor layer
            root.rawEvent(event);
            
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