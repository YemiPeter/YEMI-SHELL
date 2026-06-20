import Quickshell
import Quickshell.Io
import QtQuick 6.10

Item {
    id: root
    
    property bool enabled: false
    
    // Properties that will be updated via Niri IPC
    readonly property var toplevels: enabled ? _niriState.toplevels : []
    readonly property var workspaces: enabled ? _niriState.workspaces : []
    readonly property var monitors: enabled ? _niriState.monitors : []
    
    readonly property var activeToplevel: enabled ? _niriState.activeToplevel : null
    readonly property var focusedWorkspace: enabled ? _niriState.focusedWorkspace : null
    readonly property var focusedMonitor: enabled ? _niriState.focusedMonitor : null
    readonly property int activeWsId: enabled ? (_niriState.focusedWorkspace?.id ?? 1) : 1
    
    // Internal state object to hold Niri data
    QtObject {
        id: _niriState
        
        property var toplevels: ({})
        property var workspaces: ({})
        property var monitors: ({})
        property var activeToplevel: null
        property var focusedWorkspace: null
        property var focusedMonitor: null
        
        // These will be populated by calling niri msg commands
    }
    
    // Temporary processes for workspace and window updates
    Process {
        id: workspaceProc
        property string output: ""
        command: ["niri", "msg", "--json", "workspaces"]
        running: false

        stdout: SplitParser {
            splitMarker: ""
            onRead: function(data) {
                workspaceProc.output += data;
            }
        }

        onExited: code => {
            if (code === 0)
                root.parseWorkspaces(output);
            else
                console.warn("Failed to query niri workspaces");
        }
    }
    
    Process {
        id: windowProc
        property string output: ""
        command: ["niri", "msg", "--json", "windows"]
        running: false

        stdout: SplitParser {
            splitMarker: ""
            onRead: function(data) {
                windowProc.output += data;
            }
        }

        onExited: code => {
            if (code === 0)
                root.parseWindows(output);
            else
                console.warn("Failed to query niri windows");
        }
    }

    Process {
        id: dispatchProc
        running: false
    }
    
    function dispatch(request: string): void {
        if (!enabled || dispatchProc.running)
            return;

        var parts = request.trim().split(/\s+/);
        if (parts[0] === "workspace" && parts.length > 1) {
            dispatchProc.command = ["niri", "msg", "action", "focus-workspace", parts[1]];
        } else {
            dispatchProc.command = ["niri", "msg", "action"].concat(parts);
        }
        dispatchProc.running = true;
    }
    
    function monitorFor(screen: var): var {
        if (enabled) {
            // Find monitor based on screen information
            for (var monitorId in _niriState.monitors) {
                var monitor = _niriState.monitors[monitorId];
                // This would need proper implementation based on screen dimensions/position
                if (monitor.output === screen) {
                    return monitor;
                }
            }
        }
        return null;
    }
    
    function getOccupiedWorkspaces(): var {
        if (!enabled) return {};
        
        const occupied = {};
        for (var wsId in _niriState.workspaces) {
            var ws = _niriState.workspaces[wsId];
            occupied[wsId] = (ws.windows ?? 0) > 0;
        }
        return occupied;
    }
    
    // Timer to periodically update state from Niri
    Timer {
        interval: 500
        running: enabled
        repeat: true
        triggeredOnStart: true
        onTriggered: updateNiriState()
    }
    
    function updateNiriState(): void {
        if (!enabled) return;
        
        // Update workspaces
        updateWorkspaces();
        
        // Update windows (toplevels)
        updateWindows();
    }
    
    function updateWorkspaces(): void {
        if (!enabled || workspaceProc.running) return;

        workspaceProc.output = "";
        workspaceProc.running = true;
    }
    
    function updateWindows(): void {
        if (!enabled || windowProc.running) return;

        windowProc.output = "";
        windowProc.running = true;
    }

    function parseWorkspaces(output: string): void {
        try {
            var workspaceData = JSON.parse(output.trim());

            // Convert array to object keyed by workspace ID for easier lookup
            var newWorkspaces = {};
            var newFocusedWorkspace = null;

            for (var i = 0; i < workspaceData.length; i++) {
                var ws = workspaceData[i];
                newWorkspaces[ws.id] = ws;

                // Identify the focused workspace
                if (ws.is_focused) {
                    newFocusedWorkspace = ws;
                }
            }

            _niriState.workspaces = newWorkspaces;
            _niriState.focusedWorkspace = newFocusedWorkspace;
        } catch (e) {
            console.warn("Failed to parse workspace data:", e);
        }
    }

    function parseWindows(output: string): void {
        try {
            var windowData = JSON.parse(output.trim());

            // Convert array to object keyed by window ID for easier lookup
            var newToplevels = {};
            var newActiveToplevel = null;

            for (var i = 0; i < windowData.length; i++) {
                var win = windowData[i];
                newToplevels[win.id] = win;

                // Identify the active/focused window
                if (win.is_focused) {
                    newActiveToplevel = win;
                }
            }

            _niriState.toplevels = newToplevels;
            _niriState.activeToplevel = newActiveToplevel;
        } catch (e) {
            console.warn("Failed to parse window data:", e);
        }
    }
    
    // Connections to listen for Niri events if available
    // Note: Niri may not have real-time event notifications, so polling approach is used
}
