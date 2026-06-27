import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "Singletons"

/**
 * Wallpaper picker surface. Shows a horizontal strip of wallpaper thumbnails
 * with search. Click to apply, right-click for options.
 */
PillSurface {
    id: root
    mTop: 15
    mLeft: 17
    mRight: 17
    mBottom: 14

    property int focusedIdx: 0
    property bool searching: false
    property string searchQuery: ""

    readonly property string searchScript: Quickshell.env("HOME") + "/.config/quickshell/scripts/wallpaper-search.sh"

    implicitHeight: strip.implicitHeight + 20 * s
    implicitWidth: 720 * s

    function move(dir) {
        focusedIdx = Math.max(0, Math.min(Walls.count - 1, focusedIdx + dir));
    }

    function activate() {
        if (Walls.count > 0 && focusedIdx >= 0 && focusedIdx < Walls.count)
            Walls.apply(Walls.entries[focusedIdx].path);
    }

    function startSearch(ch) {
        searching = true;
        searchQuery = ch;
    }

    Row {
        id: strip
        anchors.centerIn: parent
        spacing: 8 * root.s

        Repeater {
            model: Walls.entries.slice(0, 10)

            delegate: Item {
                id: thumb
                required property var modelData
                required property int index
                width: 100 * root.s
                height: 100 * root.s

                Rectangle {
                    anchors.fill: parent
                    radius: 8 * root.s
                    color: root.focusedIdx === index ? Qt.alpha(Theme.verm, 0.2) : Theme.tileBg
                    border.width: root.focusedIdx === index ? 2 : 1
                    border.color: root.focusedIdx === index ? Theme.verm : Theme.border
                    Behavior on color { ColorAnimation { duration: Motion.fast } }
                }

                Image {
                    anchors.fill: parent
                    anchors.margins: 4 * root.s
                    source: modelData.thumb
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.focusedIdx = index;
                        root.activate();
                    }
                }
            }
        }
    }
}
