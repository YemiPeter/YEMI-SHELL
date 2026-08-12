pragma Singleton
import Quickshell
import QtQuick 6.10
import qs.compositor

Singleton {
    id: root

    // === Environment Detection ===
    readonly property bool isHyprland: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") !== ""
    readonly property bool isNiri: Quickshell.env("NIRI_SOCKET") !== ""

    // === Unified Niri-shaped API ===
    // windows: unified array of window objects (Niri-shaped)
    property list<var> windows: []
    // workspaces: object keyed by workspace id (Niri-shaped)
    property var workspaces: ({})
    // MRU window IDs for Alt-Tab (most recently used first, capped at 20)
    property var mruWindowIds: []
    // Current focused window (Niri-shaped)
    property var activeWindow: null

    // === Internal state ===
    property bool _dirty: false
    property string _lastActiveId: ""

    // 100ms throttle timer to batch updates and prevent UI lag
    Timer {
        id: throttleTimer
        interval: 100
        running: false
        repeat: false
        onTriggered: root._flushUpdates()
    }

    // Watch the underlying compositor for changes.
    // Hyprland models mutate in place, so also route raw events through
    // the throttle to catch updates that don't emit property-change signals.
    Connections {
        target: Compositor
        function onToplevelsChanged() { root._scheduleUpdate() }
        function onWorkspacesChanged() { root._scheduleUpdate() }
        function onActiveToplevelChanged() { root._scheduleUpdate() }
        function onRawEvent(event) { root._scheduleUpdate() }
    }

    function _scheduleUpdate() {
        _dirty = true
        if (!throttleTimer.running)
            throttleTimer.start()
    }

    function _flushUpdates() {
        if (!_dirty) return
        _dirty = false

        // Map toplevels to unified Niri-shaped windows
        var src = Compositor.toplevels
        var unified = []
        for (var i = 0; i < src.length; i++) {
            unified.push(_mapWindow(src[i]))
        }
        root.windows = unified

        // Map workspaces to Niri-shaped object keyed by id
        root.workspaces = _mapWorkspaces(Compositor.workspaces)

        // Active window
        var active = _mapWindow(Compositor.activeToplevel)
        root.activeWindow = active

        // MRU tracking — only when focus actually changes
        if (active && active.id && active.id !== _lastActiveId) {
            _lastActiveId = active.id
            _updateMru(active.id)
        }
    }

    // Map a backend window/toplevel to a unified Niri-shaped object
    function _mapWindow(w) {
        if (!w) return null
        var appId = w.appId ?? w.app_id ?? w.class ?? ""
        return {
            id: w.id ?? w.address ?? "",
            address: w.address ?? w.id ?? "",
            title: w.title ?? "",
            app_id: appId,
            icon: appId, // standard icon themes key icons by app_id
            isFocused: w.is_focused ?? (w === Compositor.activeToplevel),
            raw: w
        }
    }

    // Map backend workspaces to a Niri-shaped object keyed by id
    function _mapWorkspaces(ws) {
        var result = {}
        for (var i = 0; i < ws.length; i++) {
            var w = ws[i]
            result[w.id] = {
                id: w.id,
                name: w.name ?? ("Workspace " + w.id),
                isFocused: w === Compositor.focusedWorkspace,
                windows: w.windows ?? 0
            }
        }
        return result
    }

    // MRU tracker: push to front, remove duplicates, cap at 20
    function _updateMru(id) {
        var mru = root.mruWindowIds.slice()
        var idx = mru.indexOf(id)
        if (idx >= 0) mru.splice(idx, 1)
        mru.unshift(id)
        if (mru.length > 20) mru = mru.slice(0, 20)
        root.mruWindowIds = mru
    }

    // === Actions ===
    function focusWindow(id) {
        if (root.isHyprland) {
            Compositor.dispatch("focuswindow address:" + id)
        } else if (root.isNiri) {
            Compositor.dispatch("focus-window " + id)
        }
    }

    function closeWindow(id) {
        if (root.isHyprland) {
            Compositor.dispatch("closewindow address:" + id)
        } else if (root.isNiri) {
            Compositor.dispatch("close-window " + id)
        }
    }

    // Initial population after a short delay to let the backend settle
    Timer {
        id: initTimer
        interval: 200
        running: true
        repeat: false
        onTriggered: root._scheduleUpdate()
    }
}