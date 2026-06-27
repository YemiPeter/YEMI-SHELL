import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "Singletons"

/**
 * Media player surface. Shows current track info and playback controls.
 * STUB: Mpris service not yet available — shows placeholder UI.
 */
PillSurface {
    id: root
    mTop: 15
    mLeft: 17
    mRight: 17
    mBottom: 14

    readonly property var player: null

    implicitHeight: contentCol.implicitHeight + 24 * s
    implicitWidth: 390 * s

    Column {
        id: contentCol
        anchors.centerIn: parent
        spacing: 12 * root.s

        Text {
            text: "Media"
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 16 * root.s
            font.weight: Font.DemiBold
        }

        Text {
            text: "No media playing"
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 12 * root.s
        }

        Text {
            text: "MPRIS integration pending"
            color: Theme.faint
            font.family: Theme.font
            font.pixelSize: 10 * root.s
        }
    }
}
