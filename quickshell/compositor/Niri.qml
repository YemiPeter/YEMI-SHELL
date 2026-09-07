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
        id: monitorProc
        property string output: ""
        command: ["niri", "msg", "--json", "outputs"]
        running: false

        stdout: SplitParser {
            splitMarker: ""
            onRead: function(data) {
                monitorProc.output += data;
            }
        }

        onExited: code => {
            if (code === 0)
                root.parseMonitors(output);
            else
                console.warn("Failed to query niri monitors");
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
            // niri's `focus-workspace <REFERENCE>` is scoped to the *focused*
            // monitor, so focusing an index while keyboard focus is elsewhere hits
            // the wrong monitor. Resolve the index to its output and focus that
            // monitor first. Harmless on single-monitor (focuses the only output).
            // Note: niri 26.04 has no `focus-workspace --id`; it only takes an
            // index/name, so we dispatch by idx (position), which is what the
            // pill's dots are ordered by.
            var idx = parts[1];
            var output = null;
            var wss = _niriState.workspaces;
            for (var id in wss) {
                if (String(wss[id].idx) === idx) {
                    output = wss[id].output;
                    break;
                }
            }
            if (output) {
                dispatchProc.command = ["sh", "-c",
                    "niri msg action focus-monitor '" + output + "' && niri msg action focus-workspace " + idx];
            } else {
                dispatchProc.command = ["niri", "msg", "action", "focus-workspace", idx];
            }
        } else {
            dispatchProc.command = ["niri", "msg", "action"].concat(parts);
        }
        dispatchProc.running = true;
    }
    
    function monitorFor(screen: var): var {
        if (enabled) {
            // Match by screen name
            for (var monitorId in _niriState.monitors) {
                var monitor = _niriState.monitors[monitorId];
                if (monitor.output === screen.name) {
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
        
        // Update monitors
        updateMonitors();
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

    function updateMonitors(): void {
        if (!enabled || monitorProc.running) return;

        monitorProc.output = "";
        monitorProc.running = true;
    }

    function parseWorkspaces(output: string): void {
        try {
            var workspaceData = JSON.parse(output.trim());

            // Convert array to object keyed by workspace ID for easier lookup.
            // Normalize each row so consumers never depend on Niri's raw shape:
            //  - name is null by default (user-set), so fall back to a label so
            //    the OSD flash / dot label never see null.
            //  - keep both id (stable, global) and idx (position on its monitor)
            //    since niri only lets you focus a workspace by index/name, not id.
            //  - isActive mirrors Niri's is_active (visible on its output) which is
            //    the per-monitor truth the pill dot must track; is_focused is global.
            var newWorkspaces = {};
            var newFocusedWorkspace = null;

            for (var i = 0; i < workspaceData.length; i++) {
                var src = workspaceData[i];
                var ws = {
                    id: src.id,
                    idx: src.idx,
                    name: src.name != null ? src.name : ("WS " + src.idx),
                    output: src.output,
                    isActive: src.is_active === true,
                    is_focused: src.is_focused === true
                };
                newWorkspaces[ws.id] = ws;

                // Identify the globally focused workspace (used by fast path / fallback)
                if (ws.is_focused) {
                    newFocusedWorkspace = ws;
                }
            }

            _niriState.workspaces = newWorkspaces;
            _niriState.focusedWorkspace = newFocusedWorkspace;

            // Re-link activeWorkspace onto the monitor rows and reassign the
            // monitors map, so consumers that read monitors (parallax, OSD,
            // bar/pill workspaces) refresh in the same poll cycle as the
            // switch instead of waiting for the next monitors parse.
            root.linkWorkspacesToMonitors();
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

    function parseMonitors(output: string): void {
        try {
            var monitorData = JSON.parse(output.trim());

            // niri msg --json outputs returns an object keyed by output name
            // e.g. {"eDP-1": { name: "eDP-1", make: "...", ... }}
            // Transform into a shape compatible with Hyprland.monitors entries:
            // { output, name, width, height, refresh, scale, x, y, availableModes, activeWorkspace }
            var newMonitors = {};
            var newFocusedMonitor = null;

            for (var outputName in monitorData) {
                var src = monitorData[outputName];
                var logical = src.logical || {};

                // Build the available modes list in Hyprland format
                var modes = (src.modes || []).map(function(m, idx) {
                    return {
                        w: m.width,
                        h: m.height,
                        hz: m.refresh_rate / 1000,
                        raw: m.width + "x" + m.height + "@" + (m.refresh_rate / 1000).toFixed(2) + "Hz"
                    };
                });

                var monitor = {
                    output: src.name,
                    name: src.name,
                    width: logical.width || 0,
                    height: logical.height || 0,
                    refresh: (src.modes && src.modes.length > 0) ? src.modes[src.current_mode || 0].refresh_rate / 1000 : 60,
                    scale: logical.scale || 1,
                    x: logical.x || 0,
                    y: logical.y || 0,
                    availableModes: modes,
                    modes: modes,
                    // activeWorkspace is not provided by niri outputs directly;
                    // we'll populate it from workspace data when we parse workspaces
                    activeWorkspace: null
                };

                newMonitors[outputName] = monitor;

                // Determine focused monitor (first one with x=0,y=0 is primary)
                if (!newFocusedMonitor || (monitor.x === 0 && monitor.y === 0)) {
                    newFocusedMonitor = monitor;
                }
            }

            _niriState.monitors = newMonitors;
            _niriState.focusedMonitor = newFocusedMonitor;

            // Link workspaces to monitors: after monitors update, assign activeWorkspace
            // by matching workspace output to monitor name
            root.linkWorkspacesToMonitors();
        } catch (e) {
            console.warn("Failed to parse monitor data:", e);
        }
    }

    /**
     * After monitors and/or workspaces have been parsed, link each output's
     * active workspace into its monitor row so consumers that expect
     * Hyprland-like monitor.activeWorkspace work.
     *
     * Niri's is_active means "this workspace is currently shown on its output"
     * — exactly one per monitor — so every monitor gets its own activeWorkspace.
     * is_focused is global (one across all outputs), kept only as a fallback.
     *
     * IMPORTANT: this rebuilds and REASSIGNS the monitors map rather than
     * mutating activeWorkspace on the existing plain JS objects. A field write
     * on a plain JS object emits no change signal, so QML bindings could not
     * see it — a workspace switch only reached the parallax / OSD / workspace
     * pills when the NEXT monitors poll happened (~0.5-1s later). Reassigning
     * the property var fires the change notification, and because bindings
     * re-evaluate only after the synchronous call stack completes, consumers
     * always observe the fully linked map.
     */
    function linkWorkspacesToMonitors(): void {
        var ws = _niriState.workspaces;
        var mons = _niriState.monitors;
        var linked = {};
        for (var output in mons) {
            // Shallow-copy each monitor row so the new map is a distinct
            // object; the copy starts with no active workspace.
            var mon = mons[output];
            var copy = {};
            for (var k in mon)
                copy[k] = mon[k];
            copy.activeWorkspace = null;
            linked[output] = copy;
        }
        for (var wsId in ws) {
            var w = ws[wsId];
            if (w.output && linked[w.output] && (w.isActive || w.is_focused)) {
                linked[w.output].activeWorkspace = w;
            }
        }
        _niriState.monitors = linked;
    }
    
    // Connections to listen for Niri events if available
    // Note: Niri may not have real-time event notifications, so polling approach is used
}