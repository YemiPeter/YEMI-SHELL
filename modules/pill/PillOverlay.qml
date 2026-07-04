import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../singletons" as QsSingletons
import "../../config" as QsConfig

// ═══════════════════════════════════════════════════════════════════════════════
// PillOverlay — two-window architecture
//
//   reserve  (WlrLayer.Top)    — claims exclusive zone at resting height so the
//                                Bar doesn't fight for that top-strip space.
//                                Zero interactive content; purely a spacer.
//
//   overlay  (WlrLayer.Overlay) — full-screen window that holds the Pill, all
//                                 fullscreen detection, and mask logic.  This
//                                 window's mask already correctly controls
//                                 click-through during fullscreen AND during
//                                 normal morph states.
// ═══════════════════════════════════════════════════════════════════════════════

Item {
    id: root
    required property var modelData
    property var barWindow: null

    // ── Reserve window (WlrLayer.Top, exclusive zone) ────────────────────────
    PanelWindow {
        id: reserve
        screen: root.modelData

        // Claim the top strip so tiled windows sit below the pill's resting
        // position and the Bar doesn't compete for input routing there.
        anchors {
            top: true
            left: true
            right: true
        }
        height: reserve.restH + reserve.topGap

        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true

        // No interactive content — this window is purely a spacer.
        // A zero-size Region keeps the layer surface valid without capturing
        // any input.
        mask: Region { width: 0; height: 0 }

        readonly property real s: root.modelData ? (root.modelData.height / 1080) * QsSingletons.Flags.uiScale : 1
        readonly property real restH: QsSingletons.Metrics.restHBase * s
        readonly property var config: QsConfig.Config
        readonly property real barHeight: config.bar.height
        readonly property real topGap: (barHeight - restH) / 2
    }

    // ── Overlay window (WlrLayer.Overlay, full content) ──────────────────────
    PanelWindow {
        id: overlay
        screen: root.modelData
        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }
        margins.top: overlayTopOffset

        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: surfaceOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand
        exclusionMode: ExclusionMode.Ignore

        // Mask: click-through when fullscreen, full capture when modal,
        // pill-only when resting.
        mask: monFullscreen ? hiddenRegion : (surfaceOpen ? fullRegion : pillRegion)

        Region { id: hiddenRegion }

        Region {
            id: pillRegion
            readonly property real baseW: Math.max(pill.width, pill.targetW)
            x: pill.x + (pill.width - baseW) / 2
            y: pill.y - pill.inputPadTop
            width: baseW + pill.inputPadRight
            height: Math.max(pill.height, pill.targetH) + pill.inputPadTop
            onYChanged: console.log("[PILLREGION] y=", y, "h=", height, "ts=", Date.now())
            onHeightChanged: console.log("[PILLREGION] y=", y, "h=", height, "ts=", Date.now())
        }

        Region {
            id: fullRegion
            width: overlay.width
            height: overlay.height
        }

        // ── Helper properties ────────────────────────────────────────────────
        readonly property var config: QsConfig.Config
        readonly property real s: root.modelData ? (root.modelData.height / 1080) * QsSingletons.Flags.uiScale : 1
        readonly property real restH: QsSingletons.Metrics.restHBase * s
        readonly property real barHeight: config.bar.height
        // Overlay window has margins.top: 8*s (see overlayTopOffset below), which
        // shifts its ENTIRE coordinate system 8px lower than the Bar window (Bar has
        // no such margin). Without compensating here, the pill centers correctly
        // WITHIN the overlay, but sits 8px below the Bar's true centerline. This
        // subtracts that offset back out so absolute screen position lines up.
        readonly property real overlayTopOffset: 8 * s
        readonly property real topGap: (barHeight - restH) / 2 - overlayTopOffset
        readonly property string surface: QsSingletons.PillState.openMon === root.modelData.name ? QsSingletons.PillState.openSurface : ""
        readonly property bool surfaceOpen: surface.length > 0

        // ── Fullscreen state ─────────────────────────────────────────────────
        property bool monFullscreen: false

        function updateFullscreen(): void {
            var desktop = Quickshell.env("XDG_CURRENT_DESKTOP");
            if (desktop && desktop.toLowerCase().indexOf("niri") >= 0) {
                if (!niriFsProc.running) {
                    niriFsProc.output = "";
                    niriFsProc.running = true;
                }
                return;
            }

            // Hyprland: check workspace hasfullscreen flag
            var mons = Hyprland.monitors.values;
            for (var i = 0; i < mons.length; i++) {
                if (mons[i].name === root.modelData.name) {
                    var ws = mons[i].activeWorkspace;
                    monFullscreen = ws ? !!ws.hasfullscreen : false;
                    console.log("[FS-CHECK]", root.modelData.name, "monFullscreen=", monFullscreen);
                    return;
                }
            }
            monFullscreen = false;
        }

        // Niri fullscreen detection via niri msg -j windows IPC
        Process {
            id: niriFsProc
            property string output: ""
            command: ["niri", "msg", "-j", "windows"]
            running: false

            stdout: SplitParser {
                splitMarker: ""
                onRead: function(data) {
                    niriFsProc.output += data;
                }
            }

            onExited: code => {
                if (code === 0) {
                    try {
                        var windows = JSON.parse(niriFsProc.output.trim());
                        var isFullscreen = false;
                        for (var i = 0; i < windows.length; i++) {
                            if (windows[i].is_focused) {
                                var ts = windows[i].layout.tile_size;
                                if (ts && ts.length === 2) {
                                    var monW = root.modelData.width;
                                    var monH = root.modelData.height;
                                    if (ts[0] >= monW && ts[1] >= monH) {
                                        isFullscreen = true;
                                    }
                                }
                                break;
                            }
                        }
                        overlay.monFullscreen = isFullscreen;
                        console.log("[FS-CHECK]", root.modelData.name, "monFullscreen=", overlay.monFullscreen);
                    } catch (e) {
                        console.warn("[FS-CHECK] Failed to parse niri windows:", e);
                    }
                } else {
                    console.warn("[FS-CHECK] Failed to query niri windows");
                }
            }
        }

        // Poll fullscreen state every 500ms (Niri has no event-driven IPC for this)
        Timer {
            interval: 500
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: overlay.updateFullscreen()
        }

        Component.onCompleted: {
            updateFullscreen();
            console.log("[ALIGN-CHECK] barHeight=", barHeight, "restH=", restH, "topGap=", topGap, "s=", s);
            console.log("[MASK-CHECK] monFullscreen=", monFullscreen, "at rest, no window should be fullscreen");
        }

        // Re-check on Hyprland fullscreen events (no-op on Niri)
        Connections {
            target: Hyprland
            function onRawEvent(event) {
                var fsEvents = ["fullscreen", "fullscreen1", "fullscreen2", "openwindow", "closewindow", "movewindow", "workspace", "workspacev2"];
                if (fsEvents.indexOf(event.name) >= 0) {
                    Qt.callLater(overlay.updateFullscreen);
                }
            }
        }

        onMonFullscreenChanged: {
            console.log("[FS-CHECK] changed to", monFullscreen, "opacity should be", monFullscreen ? 0 : 1);
            console.log("[FULLSCREEN] onMonFullscreenChanged fired, value:", monFullscreen);
            console.log("[MASK-CHECK] monFullscreen=", monFullscreen, "at rest, no window should be fullscreen");
            if (monFullscreen) {
                QsSingletons.PillState.close();
            }
        }

        // Guard: if a surface is opened while fullscreen is already active
        // (e.g. via keybind IPC), immediately force-close it.
        // The `monFullscreen` transition case is already handled above;
        // this catches the "already fullscreen → keybind → toggleSurface" path.
        onSurfaceOpenChanged: {
            if (surfaceOpen && monFullscreen) {
                console.log("[FS-GUARD] surface opened during fullscreen — closing");
                Qt.callLater(QsSingletons.PillState.close);
            }
        }

        // ── Pill instance ────────────────────────────────────────────────────
        // ⚠️ QML SCOPE RULE: bindings inside a named component instance
        // (Pill { id: pill }, MouseArea { }, etc.) do NOT auto-climb into
        // the parent window's scope. Must qualify with the parent window's id.
        //   ✔  anchors.topMargin: overlay.topGap
        //   ✗  anchors.topMargin: topGap  (silent ReferenceError)
        // Same applies to `enabled: overlay.surfaceOpen` on the backdrop
        // MouseArea below and `y: overlay.monFullscreen ? …` in the Translate.
        Pill {
            id: pill
            anchors.top: parent.top
            anchors.topMargin: overlay.topGap
            anchors.horizontalCenter: parent.horizontalCenter
            s: overlay.s
            screenName: root.modelData.name
            surface: overlay.surface
            opacity: overlay.monFullscreen ? 0 : 1
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
            transform: Translate {
                y: overlay.monFullscreen ? -(pill.height + overlay.topGap) : 0
                Behavior on y {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
            }
            onRequestSurface: (name) => QsSingletons.PillState.toggleSurface(root.modelData.name, name)
            onRequestClose: QsSingletons.PillState.close()
        }

        // ── Backdrop close area ──────────────────────────────────────────────
        MouseArea {
            anchors.fill: parent
            z: -1
            enabled: overlay.surfaceOpen
            onClicked: (mouse) => {
                if (!pill.contains(mouse)) {
                    QsSingletons.PillState.close()
                }
            }
        }
    }
}
