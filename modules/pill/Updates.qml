import QtQuick
import Quickshell.Io
import "Singletons"

/**
 * System updates surface. Shows pending package updates.
 * STUB: Full pacman/yad integration pending.
 */
PillSurface {
    id: root
    mTop: 15
    mLeft: 17
    mRight: 17
    mBottom: 14

    implicitHeight: contentCol.implicitHeight + 24 * s
    implicitWidth: 360 * s

    Column {
        id: contentCol
        anchors.centerIn: parent
        spacing: 12 * root.s

        Text {
            text: "Updates"
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 16 * root.s
            font.weight: Font.DemiBold
        }

        Text {
            text: "Checking for updates..."
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 12 * root.s
        }

        Text {
            text: "Run: sudo pacman -Syu"
            color: Theme.faint
            font.family: Theme.font
            font.pixelSize: 10 * root.s
        }
    }
}
