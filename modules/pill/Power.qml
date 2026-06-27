import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import "Singletons"

/**
 * Power management surface. Lock, logout, reboot, shutdown, suspend tiles.
 */
PillSurface {
    id: root
    mTop: 15
    mLeft: 17
    mRight: 17
    mBottom: 14

    property int focusedIdx: 0
    property real holdProgress: 0
    property bool holding: false

    readonly property var tiles: [
        { key: "lock", glyph: "lock", label: "Lock", confirm: false, dispatch: "", argv: [Quickshell.env("HOME") + "/.config/hypr/scripts/lock.sh"] },
        { key: "logout", glyph: "logout", label: "Logout", confirm: true, dispatch: "exit", argv: [] },
        { key: "reboot", glyph: "reboot", label: "Reboot", confirm: true, dispatch: "reboot", argv: [] },
        { key: "shutdown", glyph: "shutdown", label: "Shutdown", confirm: true, dispatch: "shutdown", argv: [] },
        { key: "suspend", glyph: "suspend", label: "Suspend", confirm: false, dispatch: "suspend", argv: [] }
    ]

    implicitHeight: tileGrid.implicitHeight + 24 * s
    implicitWidth: 330 * s

    function pressFocused() {
        if (focusedIdx < 0 || focusedIdx >= tiles.length) return false;
        var tile = tiles[focusedIdx];
        if (tile.confirm) {
            holding = true;
            holdProgress = 0;
            holdAnim.restart();
            return true;
        }
        fireTile(tile);
        return true;
    }

    function releaseFocused() {
        holding = false;
        holdProgress = 0;
        holdAnim.stop();
    }

    function fireTile(tile) {
        if (tile.dispatch.length > 0)
            Hyprland.dispatch(tile.dispatch);
        if (tile.argv.length > 0)
            Quickshell.execDetached(tile.argv);
    }

    SequentialAnimation {
        id: holdAnim
        NumberAnimation { target: root; property: "holdProgress"; to: 1; duration: 800; easing.type: Easing.OutCubic }
        onStopped: {
            if (root.holding && root.holdProgress >= 1) {
                var tile = tiles[root.focusedIdx];
                if (tile) fireTile(tile);
            }
            root.holding = false;
            root.holdProgress = 0;
        }
    }

    Grid {
        id: tileGrid
        anchors.centerIn: parent
        columns: 3
        columnSpacing: 10 * root.s
        rowSpacing: 10 * root.s

        Repeater {
            model: root.tiles

            delegate: Item {
                id: tile
                required property var modelData
                required property int index
                width: 90 * root.s
                height: 70 * root.s

                readonly property bool focused: index === root.focusedIdx
                readonly property bool held: focused && root.holding

                Rectangle {
                    anchors.fill: parent
                    radius: 12 * root.s
                    color: tile.focused ? Qt.alpha(Theme.cream, 0.08) : Theme.tileBg
                    border.width: tile.focused ? 1 : 0
                    border.color: tile.focused ? Qt.alpha(Theme.cream, 0.2) : Theme.border

                    Behavior on color { ColorAnimation { duration: Motion.fast } }
                }

                // Hold progress fill
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Qt.alpha(Theme.verm, 0.2)
                    visible: tile.held
                    width: parent.width * (root.holdProgress || 0)
                    clip: true
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 4 * root.s

                    GlyphIcon {
                        width: 22 * root.s
                        height: 22 * root.s
                        name: modelData.glyph
                        color: tile.focused ? Theme.cream : Theme.subtle
                        stroke: 1.7
                    }

                    Text {
                        text: modelData.label
                        color: tile.focused ? Theme.cream : Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 11 * root.s
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.focusedIdx = index;
                        root.pressFocused();
                    }
                    onPressAndHold: {
                        root.focusedIdx = index;
                        root.pressFocused();
                    }
                    onReleased: root.releaseFocused()
                }
            }
        }
    }
}
