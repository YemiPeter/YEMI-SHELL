import QtQuick
import Quickshell.Io
import "Singletons"

/**
 * Appearance settings surface. Theme mode, accent hue, saturation, pill opacity.
 */
PillSurface {
    id: root
    mTop: 15
    mLeft: 17
    mRight: 17
    mBottom: 14

    implicitHeight: settingsCol.implicitHeight + 24 * s
    implicitWidth: 392 * s

    Column {
        id: settingsCol
        anchors.centerIn: parent
        spacing: 16 * root.s

        Text {
            text: "Appearance"
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 16 * root.s
            font.weight: Font.DemiBold
        }

        // Palette mode
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
                        text: "Palette Mode"
                        color: Theme.subtle
                        font.family: Theme.font
                        font.pixelSize: 11 * root.s
                    }

                    Text {
                        text: Flags.paletteMode === "static" ? "Static" : "Dynamic (Wallpaper)"
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 14 * root.s
                    }
                }
            }
        }

        // Pill opacity
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
                        text: "Pill Opacity"
                        color: Theme.subtle
                        font.family: Theme.font
                        font.pixelSize: 11 * root.s
                    }

                    Text {
                        text: Math.round(Flags.pillOpacity * 100) + "%"
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 14 * root.s
                    }
                }
            }
        }

        // Hue
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
                        text: "Accent Hue"
                        color: Theme.subtle
                        font.family: Theme.font
                        font.pixelSize: 11 * root.s
                    }

                    Text {
                        text: Flags.manualHue + "°"
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 14 * root.s
                    }
                }
            }
        }
    }
}
