import QtQuick
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Io
import "Singletons"

/**
 * On-screen display for the pill: volume, brightness, workspace switch, and
 * media track changes. Flashes the pill open briefly to show the change, then
 * collapses. Suppressed while a surface is open so the OSD never fights a
 * morphing surface for space.
 *
 * STUB: Full Pipewire/Mpris integration requires those services. This version
 * uses safe null-guards so the pill compiles without them.
 */
Item {
    id: root

    property real s: 1
    property string screenName: ""
    property bool suppressed: false
    property bool flashing: false
    property string kind: "volume"
    property bool armed: false
    property string shownTrackLine: ""
    property bool shownPlaying: false
    property string shownArtUrl: ""
    property string lastTrackLine: ""
    property bool lastPlaying: false
    property real brightness: 0
    property int lastBrightness: -1
    property bool recordStarted: false
    property var wsIndicator: null
   
    // STUB: Pipewire not yet available — null-guarded
    readonly property var sink: null
    readonly property bool muted: false
    readonly property real volume: 0

    // STUB: Mpris not yet available — null-guarded
    readonly property var player: null
    readonly property bool playing: false
    readonly property string trackLine: ""

    readonly property real desiredW: kind === "workspace" ? Math.max(120 * s, (wsIndicator ? wsIndicator.implicitWidth : 0) + 40 * s)
        : (kind === "track" ? 332 * s : (kind === "record" ? 256 * s : 248 * s))
    readonly property real desiredH: kind === "track" ? 56 * s : 44 * s

    readonly property string activeWsName: {
        var mons = Hyprland.monitors.values;
        for (var i = 0; i < mons.length; i++)
            if (mons[i].name === screenName)
                return mons[i].activeWorkspace ? mons[i].activeWorkspace.name : "";
        return "";
    }
    onActiveWsNameChanged: if (activeWsName.length > 0) flash("workspace")

    function trackEvent() {
        // STUB: would flash media track OSD
    }

    function flash(newKind) {
        if (suppressed) return;
        kind = newKind;
        flashing = true;
        flashTimer.restart();
    }

    function setBrightness(val) {
        brightness = val;
        if (lastBrightness !== val) {
            lastBrightness = val;
            flash("brightness");
        }
    }

    Timer {
        id: flashTimer
        interval: 1200
        running: flashing
        repeat: false
        onTriggered: flashing = false
    }

    // --- Visual ---

    Rectangle {
        anchors.fill: parent
        radius: 12 * s
        color: Qt.alpha(Theme.cardTop, 0.92)
        border.width: 1
        border.color: Theme.border

        Row {
            id: content
            anchors.centerIn: parent
            spacing: 10 * s

            // Volume icon
            GlyphIcon {
                visible: root.kind === "volume"
                width: 20 * s
                height: 20 * s
                name: root.muted ? "speaker-off" : "speaker"
                color: Theme.cream
                stroke: 1.7
            }

            // Brightness icon
            GlyphIcon {
                visible: root.kind === "brightness"
                width: 20 * s
                height: 20 * s
                name: "sun"
                color: Theme.cream
                stroke: 1.7
            }

            // Workspace indicator
            Text {
                visible: root.kind === "workspace"
                text: root.activeWsName
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 14 * s
                font.weight: Font.DemiBold
            }

            // Volume bar
            Rectangle {
                visible: root.kind === "volume"
                width: 80 * s
                height: 4 * s
                radius: 2 * s
                color: Qt.alpha(Theme.cream, 0.2)

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    width: parent.width * root.volume
                    radius: parent.radius
                    color: root.muted ? Theme.verm : Theme.flameGlow
                }
            }

            // Brightness bar
            Rectangle {
                visible: root.kind === "brightness"
                width: 80 * s
                height: 4 * s
                radius: 2 * s
                color: Qt.alpha(Theme.cream, 0.2)

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    width: parent.width * (root.brightness / 100)
                    radius: parent.radius
                    color: Theme.flameGlow
                }
            }

            // Muted indicator
            Text {
                visible: root.kind === "volume" && root.muted
                text: "MUTED"
                color: Theme.verm
                font.family: Theme.font
                font.pixelSize: 10 * s
                font.weight: Font.Bold
                font.capitalization: Font.AllUppercase
            }
        }
    }
}
