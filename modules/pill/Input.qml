import QtQuick
import Quickshell
import Quickshell.Io
import "Singletons"
import "lib/setInput.js" as SetInput

/**
 * Input settings surface. Keyboard layout, touchpad toggle.
 */
PillSurface {
    id: root
    mTop: 15
    mLeft: 17
    mRight: 17
    mBottom: 14

    readonly property string inputPath: Quickshell.env("HOME") + "/.config/hypr/modules/input.lua"
    readonly property string envPath: Quickshell.env("HOME") + "/.config/hypr/modules/env.lua"
    readonly property string autostartPath: Quickshell.env("HOME") + "/.config/hypr/modules/autostart.lua"

    implicitHeight: settingsCol.implicitHeight + 24 * s
    implicitWidth: 392 * s

    Column {
        id: settingsCol
        anchors.centerIn: parent
        spacing: 16 * root.s

        Text {
            text: "Input"
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 16 * root.s
            font.weight: Font.DemiBold
        }

        // Keyboard layout
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
                        text: "Keyboard Layout"
                        color: Theme.subtle
                        font.family: Theme.font
                        font.pixelSize: 11 * root.s
                    }

                    Text {
                        text: SetInput.getKeyboardLayout().toUpperCase()
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 14 * root.s
                    }
                }
            }
        }

        // Touchpad
        Item {
            width: parent.width
            height: 50 * root.s
            Rectangle {
                anchors.fill: parent
                radius: 10 * root.s
                color: Theme.tileBg
                border.width: 1
                border.color: Theme.border

                Row {
                    anchors.centerIn: parent
                    spacing: 12 * root.s

                    Text {
                        text: "Touchpad"
                        color: Theme.subtle
                        font.family: Theme.font
                        font.pixelSize: 12 * root.s
                    }

                    Text {
                        text: SetInput.getTouchpadEnabled() ? "Enabled" : "Disabled"
                        color: SetInput.getTouchpadEnabled() ? Theme.flameGlow : Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 12 * root.s
                    }
                }
            }
        }
    }
}
