import QtQuick
import Quickshell
import Quickshell.Io
import "Singletons"
import "lib/setDeco.js" as SetDeco

/**
 * Look settings surface. Window rounding, gaps, borders.
 */
PillSurface {
    id: root
    mTop: 15
    mLeft: 17
    mRight: 17
    mBottom: 14

    readonly property string decoPath: Quickshell.env("HOME") + "/.config/hypr/modules/decoration.lua"

    implicitHeight: settingsCol.implicitHeight + 24 * s
    implicitWidth: 392 * s

    Column {
        id: settingsCol
        anchors.centerIn: parent
        spacing: 16 * root.s

        Text {
            text: "Look"
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 16 * root.s
            font.weight: Font.DemiBold
        }

        // Rounding
        Item {
            width: parent.width
            height: 50 * root.s
            Rectangle {
                anchors.fill: parent
                radius: 10 * root.s
                color: Theme.tileBg
                border.width: 1
                border.color: Theme.border

                Column {
                    anchors.centerIn: parent
                    spacing: 4 * root.s

                    Text {
                        text: "Window Rounding"
                        color: Theme.subtle
                        font.family: Theme.font
                        font.pixelSize: 11 * root.s
                    }

                    Text {
                        text: SetDeco.getRounding() + "px"
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 14 * root.s
                    }
                }
            }
        }

        Text {
            text: "Edit decoration.lua for full customization"
            color: Theme.faint
            font.family: Theme.font
            font.pixelSize: 10 * root.s
        }
    }
}
