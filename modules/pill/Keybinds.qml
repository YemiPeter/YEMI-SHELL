import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "Singletons"
import "lib/binds.js" as Binds
import "lib/keychord.js" as Chord

/**
 * Keybind editor surface. Shows a list of current keybinds with edit/delete.
 * Supports chord capture for multi-key sequences.
 */
PillSurface {
    id: root
    mTop: 15
    mLeft: 17
    mRight: 17
    mBottom: 14

    property var binds: []
    property int focusedIdx: 0
    property bool formOpen: false
    property bool listening: false

    readonly property string bindsPath: Quickshell.env("HOME") + "/.config/hypr/modules/binds.lua"

    implicitHeight: bindList.implicitHeight + 24 * s
    implicitWidth: 460 * s

    function move(dir) {
        focusedIdx = Math.max(0, Math.min(binds.length - 1, focusedIdx + dir));
    }

    function activate() {
        if (focusedIdx >= 0 && focusedIdx < binds.length) {
            formOpen = true;
            editBind = binds[focusedIdx];
        }
    }

    function closeForm() {
        formOpen = false;
        editBind = null;
    }

    function startListening() {
        listening = true;
        chord.start();
    }

    function stopListening() {
        listening = false;
        chord.stop();
    }

    property var editBind: null
    property var chord: new Chord.KeyChord()

    FileView {
        id: bindsFile
        path: root.bindsPath
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: root.binds = Binds.parse(bindsFile.text())
        onFileChanged: reload()
    }

    Component.onCompleted: {
        try {
            root.binds = Binds.parse(bindsFile.text());
        } catch (e) { root.binds = []; }
    }

    Column {
        anchors.fill: parent
        anchors.topMargin: 12 * root.s
        anchors.leftMargin: 16 * root.s
        anchors.rightMargin: 16 * root.s
        anchors.bottomMargin: 12 * root.s
        spacing: 8 * root.s

        Text {
            text: "Keybinds"
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 14 * root.s
            font.weight: Font.DemiBold
        }

        ListView {
            id: bindList
            width: parent.width
            height: Math.min(240 * root.s, model * 40 * root.s)
            model: root.binds
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            spacing: 2 * root.s

            delegate: Item {
                id: bindRow
                required property var modelData
                required property int index
                width: parent.width
                height: 40 * root.s

                Rectangle {
                    anchors.fill: parent
                    radius: 8 * root.s
                    color: index === root.focusedIdx ? Qt.alpha(Theme.cream, 0.06) : "transparent"
                    Behavior on color { ColorAnimation { duration: Motion.fast } }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 10 * root.s

                    Text {
                        text: modelData.mods || ""
                        color: Theme.subtle
                        font.family: Theme.font
                        font.pixelSize: 11 * root.s
                    }

                    Text {
                        text: modelData.key || ""
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 12 * root.s
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: modelData.description || ""
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 11 * root.s
                        elide: Text.ElideRight
                        width: parent.width - 100 * root.s
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.focusedIdx = index
                }
            }
        }
    }
}
