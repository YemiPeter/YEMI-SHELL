import QtQuick
import Quickshell
import Quickshell.Io
import "Singletons"
import "lib/monitors.js" as Mon

/**
 * Display settings surface. Monitor selection, resolution, refresh rate.
 */
PillSurface {
    id: root
    mTop: 15
    mLeft: 17
    mRight: 17
    mBottom: 14

    readonly property string monitorsPath: Quickshell.env("HOME") + "/.config/hypr/modules/monitors.lua"
    readonly property string helper: Quickshell.env("HOME") + "/.config/hypr/scripts/display-apply.sh"

    property string selectedMonitor: ""
    property int selectedMode: 0

    implicitHeight: contentCol.implicitHeight + 24 * s
    implicitWidth: 392 * s

    Column {
        id: contentCol
        anchors.centerIn: parent
        spacing: 12 * root.s

        Text {
            text: "Display"
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 16 * root.s
            font.weight: Font.DemiBold
        }

        Text {
            text: root.selectedMonitor || "Primary Display"
            color: Theme.subtle
            font.family: Theme.font
            font.pixelSize: 12 * root.s
        }

        Text {
            text: "Resolution: " + (root.selectedMode > 0 ? "Custom" : "Auto")
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 11 * root.s
        }

        Rectangle {
            width: parent.width
            height: 40 * root.s
            radius: 8 * root.s
            color: Theme.tileBg
            border.width: 1
            border.color: Theme.border

            Text {
                anchors.centerIn: parent
                text: "Apply changes via monitors.lua"
                color: Theme.faint
                font.family: Theme.font
                font.pixelSize: 11 * root.s
            }
        }
    }
}
