import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../singletons" as QsSingletons
import "../../config" as QsConfig
import qs.compositor

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

    // ── Shadow window (Hyprland) ─────────────────────────────────────────────
    // QML drop shadows are Niri-only (Compositor.qmlShadows): on Hyprland the
    // pill overlay's layerrule blur composites blurred wallpaper behind every
    // translucent pixel of the surface, so a QML shadow painted there reads
    // as a frosted halo outside the pill's border. This separate surface
    // carries ONLY the shadow, under its own namespace ("shell-shadow" —
    // deliberately matches none of the blur layerrules, and avoids the
    // substring "pill" since match:namespace is regex-based), so the shadow
    // darkens the live wallpaper exactly like a normal drop shadow.
    //
    // Layer Top: always below the Overlay-layer pill surface, above tiled
    // windows (a drop shadow cast over windows is expected). Zero mask keeps
    // it click-through.
    //
    // The shadow is an SDF rounded-box shader (shaders/shadow.*.qsb) rather
    // than MultiEffect: MultiEffect always draws its source silhouette, and
    // an opaque silhouette here would show through the translucent pill
    // above. The shader emits shadow-only alpha: zero inside the pill frame
    // so it never tints the pill's own frost. Tuning mirrors the Niri QML
    // shadow (0.45 alpha, vertical offset 4) so the compositors look alike.
    PanelWindow {
        id: shadowWin
        screen: root.modelData

        visible: Compositor.isHyprland && QsSingletons.Flags.barShadow
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "shell-shadow"
        exclusionMode: ExclusionMode.Ignore

        // Purely decorative — never take input.
        mask: Region { width: 0; height: 0 }

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        readonly property real s: overlay.s
        readonly property real fadePx: 34 * s                 // falloff distance
        readonly property real offY: 4 * s                    // cast downward
        readonly property real strength: 0.45
        readonly property real marginPx: fadePx + Math.abs(offY) + 8

        // Pill frame in this window's scene coords. The window is unmargined,
        // so these mirror the overlay's anchors.topMargin + horizontalCenter
        // and track the pill morph through plain bindings.
        readonly property real frameX: (width - pill.width) / 2
        readonly property real frameY: overlay.overlayTopOffset + overlay.topGap

        ShaderEffect {
            x: shadowWin.frameX - shadowWin.marginPx
            y: shadowWin.frameY - shadowWin.marginPx
            width: pill.width + shadowWin.marginPx * 2
            height: pill.height + shadowWin.marginPx * 2

            // Fades out with the pill when a monitor goes fullscreen.
            opacity: overlay.monFullscreen ? 0 : 1
            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            property vector4d uGeom: Qt.vector4d(width, height, pill.width, pill.height)
            property vector4d uParams: Qt.vector4d(pill.morphRadius, shadowWin.fadePx, 0, shadowWin.offY)
            property color uColor: Qt.rgba(0, 0, 0, shadowWin.strength)

            vertexShader: "shaders/shadow.vert.qsb"
            fragmentShader: "shaders/shadow.frag.qsb"
        }
    }

    // ── Overlay window (WlrLayer.Overlay, full content) ──────────────────────

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
                // niriFsProc is Loader-gated (Niri-only); null when inactive.
                var proc = niriFsLoader.item
                if (proc && !proc.running) {
                    proc.output = "";
                    proc.running = true;
                }
                return;
            }

            // Hyprland: query hyprctl activeworkspace -j for live fullscreen state
            // hyprFsProc is Loader-gated (Hyprland-only); null when inactive.

            var proc = hyprFsLoader.item

            if (proc && !proc.running) {
              proc.output = "";
              proc.running = true;
            }
        }

        // Niri fullscreen detection via niri msg -j windows IPC.
        // Loader-gated: the Process is never constructed off-Niri; callers
        // null-check niriFsLoader.item.
        Loader {
            id: niriFsLoader
            active: Compositor.isNiri
            sourceComponent: Process {
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
                    } catch (e) {
                    }
                } else {
                }
            }
          }
        }

          // Hyprland fullscreen detection via hyprctl activeworkspace -j.


          // Loader-gated:the Process is never constructed off-Hyprland; callers
          // null-check hyprFsLoader.item.(Mirror of niriFsLoader.)
          Loader {
            id: hyprFsLoader
            active: Compositor.isHyprland
            sourceComponent: Process {
            id: hyprFsProc
            property string output: ""
            command: ["hyprctl", "activeworkspace", "-j"]
            running: false
          
            stdout: SplitParser {
              splitMarker: ""
              onRead: function(data) {
                hyprFsProc.output += data;
              }
            }
          
            onExited: code => {
              if (code === 0) {
                try {
                  var ws = JSON.parse(hyprFsProc.output.trim());
                  var isFullscreen = !!(ws && ws.hasfullscreen);
                  overlay.monFullscreen = isFullscreen;
                } catch (e) {
                }
              } else {
              }
            }
          }
        }
          
          // Poll fullscreen state every 500ms (Niri has no event-driven IPC for this)
        Timer {
            interval: 500
            running: Compositor.runningCompositor === "niri"
            repeat: true
            triggeredOnStart: true
            onTriggered: overlay.updateFullscreen()
        }

        Component.onCompleted: {
            updateFullscreen();
        }

        // Re-check on compositor raw events (Hyprland events forwarded via Compositor)
        Connections {
            target: Compositor
            function onRawEvent(event) {
                var fsEvents = ["fullscreen", "fullscreen1", "fullscreen2", "openwindow", "closewindow", "movewindow", "workspace", "workspacev2"];
                if (fsEvents.indexOf(event.name) >= 0) {
                    Qt.callLater(overlay.updateFullscreen);
                }
            }
        }

        onMonFullscreenChanged: {
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
            forcePinned: QsSingletons.PillState.peekMon === root.modelData.name
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
