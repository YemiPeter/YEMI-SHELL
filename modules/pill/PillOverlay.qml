import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../singletons" as QsSingletons
import "../../config" as QsConfig

PanelWindow {
    id: overlay
    required property var modelData
    property var barWindow: null

    // ---- Fullscreen state ----
    property bool monFullscreen: false

    // ---- Window geometry ----
    screen: modelData
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: surfaceOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore

    // Mask: click-through when fullscreen, full capture when modal, pill-only when rest
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

    // ---- Helper properties ----
    readonly property var config: QsConfig.Config
    readonly property real s: modelData ? (modelData.height / 1080) * QsSingletons.Flags.uiScale : 1
    readonly property real restH: 38 * s
    readonly property real barHeight: config.bar.height
    readonly property real topGap: (barHeight - restH) / 2
    readonly property string surface: QsSingletons.PillState.openMon === modelData.name ? QsSingletons.PillState.openSurface : ""
    readonly property bool surfaceOpen: surface.length > 0

    // ---- Fullscreen detection ----
    function updateFullscreen(): void {
        var desktop = Quickshell.env("XDG_CURRENT_DESKTOP");
        if (desktop && desktop.toLowerCase().indexOf("niri") >= 0) {
            // Niri: shell out to niri msg -j windows
            if (!niriFsProc.running) {
                niriFsProc.output = "";
                niriFsProc.running = true;
            }
            return;
        }

        // Hyprland: check workspace hasfullscreen flag
        var mons = Hyprland.monitors.values;
        for (var i = 0; i < mons.length; i++) {
            if (mons[i].name === modelData.name) {
                var ws = mons[i].activeWorkspace;
                monFullscreen = ws ? !!ws.hasfullscreen : false;
                console.log("[FS-CHECK]", modelData.name, "monFullscreen=", monFullscreen);
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
                                var monW = overlay.modelData.width;
                                var monH = overlay.modelData.height;
                                if (ts[0] >= monW && ts[1] >= monH) {
                                    isFullscreen = true;
                                }
                            }
                            break;
                        }
                    }
                    overlay.monFullscreen = isFullscreen;
                    console.log("[FS-CHECK]", overlay.modelData.name, "monFullscreen=", overlay.monFullscreen);
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
        onTriggered: updateFullscreen()
    }

    Component.onCompleted: {
        updateFullscreen();
        console.log("[MASK-CHECK] monFullscreen=", monFullscreen, "at rest, no window should be fullscreen");
    }

    // Re-check on Hyprland fullscreen events (no-op on Niri)
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            var fsEvents = ["fullscreen", "fullscreen1", "fullscreen2", "openwindow", "closewindow", "movewindow", "workspace", "workspacev2"];
            if (fsEvents.indexOf(event.name) >= 0) {
                Qt.callLater(updateFullscreen);
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

    // ---- Pill instance ----
    Pill {
        id: pill
        anchors.top: parent.top
        anchors.topMargin: topGap
        anchors.horizontalCenter: parent.horizontalCenter
        s: overlay.s
        screenName: modelData.name
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
        onRequestSurface: (name) => QsSingletons.PillState.toggleSurface(modelData.name, name)
        onRequestClose: QsSingletons.PillState.close()
    }

    // ---- Backdrop close area ----
    MouseArea {
        anchors.fill: parent
        z: -1
        enabled: surfaceOpen
        onClicked: (mouse) => {
            if (!pill.contains(mouse)) {
                QsSingletons.PillState.close()
            }
        }
    }
}
