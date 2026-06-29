pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import "Singletons"

/**
 * Minimized-window tray for the hover glance. Shows icons for windows that are
 * minimized but still alive in Hyprland's toplevel list. Clicking a thumbnail
 * restores the window.
 */
Item {
    id: root

    property real s: 1
    property string screenName: ""

    readonly property var minimized: {
        var out = [];
        var toplevels = Hyprland.toplevels.values;
        for (var i = 0; i < toplevels.length; i++) {
            var t = toplevels[i];
            if (t.minimized && t.monitor && t.monitor.name === root.screenName)
                out.push(t);
        }
        return out;
    }
    readonly property int count: minimized.length

    implicitWidth: Math.max(0, count) * (17 * s + 3 * s) - 3 * s
    implicitHeight: 17 * s

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 3 * s

        Repeater {
            model: root.minimized

            delegate: Item {
                id: thumb
                required property var modelData
                width: 17 * s
                height: 17 * s
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent
                    radius: 4 * s
                    color: Theme.tileBg
                    border.width: 1
                    border.color: Theme.border
                }

                Image {
                    anchors.fill: parent
                    anchors.margins: 2 * s
                    source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Hyprland.dispatch("movetoworkspace", "name:" + modelData.workspace?.name || "current", modelData.address);
                    }
                }
            }
        }
    }
}
