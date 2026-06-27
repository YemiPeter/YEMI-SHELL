pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "Singletons"

/**
 * Workspace dots for one monitor. No numbers, no icons. Active one is a larger
 * filled vermillion dot; the rest are small and dim, brightening on hover.
 * Clicking a dot focuses that workspace via the Hyprland dispatcher. Active
 * marker tracks the monitor's live active workspace name from the Hyprland
 * model.
 *
 * The dot range comes from this monitor's workspace rules (Workspacerules),
 * so a rule-driven setup always shows every assigned dot. A setup with no rules
 * falls back to the workspaces Hyprland currently has on this monitor plus the
 * active one, so dots still appear and grow as new workspaces are visited.
 */
Item {
    id: workspaces

    property string screenName: ""
    property real s: 1
    property real stickW: 17 * s
    property real dotW: 5 * s
    property real gap: 4 * s

    readonly property var range: {
        var ruled = Workspacerules.byMonitor[screenName];
        if (ruled && ruled.length)
            return ruled;

        var out = [];
        var seen = ({});
        var wss = Hyprland.workspaces.values;
        for (var i = 0; i < wss.length; i++) {
            var w = wss[i];
            if (w.id >= 1 && w.monitor && w.monitor.name === screenName && !seen[w.id]) {
                seen[w.id] = true;
                out.push(w.id);
            }
        }
        var a = parseInt(activeName);
        if (a >= 1 && !seen[a])
            out.push(a);
        out.sort(function (x, y) { return x - y; });
        return out;
    }

    readonly property string activeName: {
        var mons = Hyprland.monitors.values;
        for (var i = 0; i < mons.length; i++)
            if (mons[i].name === screenName)
                return mons[i].activeWorkspace ? mons[i].activeWorkspace.name : "";
        return "";
    }

    readonly property int activeId: parseInt(activeName) || 0

    signal hoverIndexChanged(int index)

    implicitWidth: Math.max(1, range.length) * (dotW + gap) - gap
    implicitHeight: dotW

    Row {
        id: row
        anchors.centerIn: parent
        spacing: gap

        Repeater {
            model: workspaces.range

            delegate: Item {
                id: dot
                required property int index
                required property var modelData
                width: dotW
                height: dotW
                anchors.verticalCenter: parent.verticalCenter

                readonly property bool active: modelData === workspaces.activeId
                readonly property bool hovered: hoverArea.containsMouse

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: active ? Theme.verm : (hovered ? Theme.cream : Theme.iconDim)
                    opacity: active ? 1 : (hovered ? 0.8 : 0.4)
                    Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                    Behavior on color { ColorAnimation { duration: Motion.fast } }
                }

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    anchors.margins: -4 * workspaces.s
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Hyprland.dispatch("workspace", String(modelData));
                    }
                    onEntered: workspaces.hoverIndexChanged(modelData)
                }
            }
        }
    }
}
