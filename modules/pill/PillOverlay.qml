import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../singletons" as QsSingletons
import "../../config" as QsConfig

PanelWindow {
    id: overlay
    required property var modelData
    property var barWindow: null

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
    exclusionMode: ExclusionMode.Ignore
    
    mask: surfaceOpen ? fullRegion : pillRegion
    Region { id: pillRegion
        readonly property real baseW: Math.max(pill.width, pill.targetW)
        x: pill.x + (pill.width - baseW) / 2
        y: pill.y
        width: baseW + pill.inputPadRight
        height: Math.max(pill.height, pill.targetH)
    }
    Region { id: fullRegion
        width: overlay.width
        height: overlay.height
    }
    
    // ---- Helper properties ----
    readonly property var config: QsConfig.Config
    readonly property real s: modelData ? (modelData.height / 1080) * QsSingletons.Flags.uiScale : 1

    // Pill's rest height (from Pill.qml, usually 38)
    readonly property real restH: 38 * s

    // topMargin to center the pill vertically within the bar's height
    // barWindow is a Scope, so we read config.bar.height directly
    readonly property real barHeight: config.bar.height
    readonly property real topGap: (barHeight - restH) / 2

    readonly property string surface: QsSingletons.PillState.openMon === modelData.name ? QsSingletons.PillState.openSurface : ""
    readonly property bool surfaceOpen: surface.length > 0

    // ---- Pill instance ----
    Pill {
        id: pill
        anchors.top: parent.top
        anchors.topMargin: topGap
        anchors.horizontalCenter: parent.horizontalCenter
        s: overlay.s
        screenName: modelData.name
        surface: overlay.surface
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