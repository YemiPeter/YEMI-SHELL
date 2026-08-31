import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../../config" as QsConfig
import "../../../compositor" as QsCompositor

// Clean workspace container - no outer pill
Item {
    id: root
    
    property var screen
    
    readonly property string screenName: screen ? screen.name : ""
    readonly property var config: QsConfig.Config
    readonly property var compositor: QsCompositor.Compositor
    
    /**
     * Per-screen workspace state, recomputed from the Compositor singleton's
     * directly-tracked properties (workspaces / focusedWorkspace / monitors).
     *
     * The previous version called compositor.getOccupiedWorkspaces() inside a
     * binding — a JS function call whose internal reads don't reliably register
     * binding dependencies, so the occupied dots went stale when a window
     * closed. It also ignored the screen entirely, so on multi-monitor (and on
     * Niri, where each output carries its own workspace set) the bar showed
     * the wrong active/occupied set.
     *
     * This mirrors the pill's Workspaces.qml approach: read the tracked
     * properties directly (the `void` reads register the dependencies),
     * filter to THIS screen, and return a fresh object each pass so every
     * dependent slot re-evaluates.
     *
     * Shape: { activeId: int, occupied: { [workspaceId]: bool } }
     * On Niri, workspaceId is the per-output idx (what the dots render and
     * what dispatch() resolves); on Hyprland it is the global workspace id.
     */
    readonly property var wsState: {
        // Dependency forcing — recompute whenever any of these change.
        void compositor.workspaces;
        void compositor.focusedWorkspace;
        void compositor.monitors;
        void compositor.toplevels;
        void root.screenName;

        var occupied = {};
        var activeId = 1;
        var isNiri = compositor.isNiri;

        // Fast path: the focused workspace, when it belongs to this screen.
        var fw = compositor.focusedWorkspace;
        var fwMon = fw ? ((fw.monitor && fw.monitor.name) || fw.output || "") : "";
        if (fw && fwMon === root.screenName)
            activeId = isNiri ? (fw.idx ?? fw.id ?? 1) : (fw.id ?? 1);

        if (isNiri) {
            // Niri: the normalized workspaces carry no window count, so
            // occupancy is derived from the toplevels list (win.workspace.id
            // is the global workspace id). Iterate this screen's workspaces
            // and mark them occupied when a window sits on them.
            var winCount = {};
            var wins = compositor.toplevels;
            for (var t = 0; t < wins.length; t++) {
                var wws = wins[t] ? wins[t].workspace : null;
                if (wws && wws.id != null)
                    winCount[wws.id] = (winCount[wws.id] ?? 0) + 1;
            }
            var nwss = compositor.workspaces;
            for (var n = 0; n < nwss.length; n++) {
                var nw = nwss[n];
                if ((nw.output || "") !== root.screenName)
                    continue;
                var nid = nw.idx ?? nw.id;
                occupied[nid] = (winCount[nw.id] ?? 0) > 0;
                // isActive mirrors Niri's is_active — the per-output active
                // truth, correct even when keyboard focus is elsewhere.
                if (nw.isActive === true || nw.is_active === true)
                    activeId = nid;
            }
        } else {
            // Hyprland: workspaces carry lastIpcObject.windows directly.
            var wss = compositor.workspaces;
            for (var i = 0; i < wss.length; i++) {
                var w = wss[i];
                var wsMon = (w.monitor && w.monitor.name) || "";
                if (wsMon !== root.screenName)
                    continue;
                occupied[w.id] = ((w.lastIpcObject ? w.lastIpcObject.windows : 0) ?? 0) > 0;
            }

            // Slow path: focusedWorkspace's monitor field can be null for
            // special workspaces; fall back to this screen's monitor row.
            if (!(fw && fwMon === root.screenName)) {
                var mons = compositor.monitors;
                for (var m = 0; m < mons.length; m++) {
                    if (mons[m].name === root.screenName) {
                        var aw = mons[m].activeWorkspace;
                        if (aw && aw.id != null)
                            activeId = aw.id;
                        break;
                    }
                }
            }
        }

        return { activeId: activeId, occupied: occupied };
    }
    
    implicitWidth: layout.implicitWidth
    implicitHeight: config.bar.height - config.bar.padding * 2
    
    RowLayout {
        id: layout
        
        anchors.centerIn: parent
        spacing: root.config.bar.workspaces.spacing
        
        Repeater {
            id: workspaceRepeater
            model: root.config.bar.workspaces.count
            
            delegate: Loader {
                required property int index
                
                source: "Workspace.qml"
                asynchronous: false
                
                onLoaded: {
                    item.workspaceId = index + 1
                    item.isActive = Qt.binding(() => root.wsState.activeId === (index + 1))
                    item.isOccupied = Qt.binding(() => root.wsState.occupied[index + 1] ?? false)
                    item.clicked.connect(function() {
                        if (root.wsState.activeId !== item.workspaceId) {
                            root.compositor.dispatch(`workspace ${item.workspaceId}`)
                        }
                    })
                }
            }
        }
    }
}