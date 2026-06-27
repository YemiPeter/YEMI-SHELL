import QtQuick
import Quickshell
import Quickshell.Io
import "Singletons"

/**
 * Idle lock settings surface. Configures idle lock, screen off, and suspend
 * timers. Reads/writes Hyprland's hypridle.conf.
 */
PillSurface {
    id: root
    mTop: 15
    mLeft: 17
    mRight: 17
    mBottom: 14

    readonly property string confPath: Quickshell.env("HOME") + "/.config/hypr/hypridle.conf"
    readonly property string lockScript: Quickshell.env("HOME") + "/.config/hypr/scripts/lock.sh"

    implicitHeight: settingsCol.implicitHeight + 24 * s
    implicitWidth: 392 * s

    Column {
        id: settingsCol
        anchors.centerIn: parent
        spacing: 16 * root.s

        Text {
            text: "Idle & Lock"
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 16 * root.s
            font.weight: Font.DemiBold
        }

        // Lock timer
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
                        text: "Lock after"
                        color: Theme.subtle
                        font.family: Theme.font
                        font.pixelSize: 11 * root.s
                    }

                    Text {
                        text: Flags.idleLockMin + " minutes"
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 18 * root.s
                        font.weight: Font.DemiBold
                    }
                }
            }
        }

        // Screen off timer
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
                        text: "Screen off after"
                        color: Theme.subtle
                        font.family: Theme.font
                        font.pixelSize: 11 * root.s
                    }

                    Text {
                        text: Flags.idleScreenOffMin + " minutes"
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 18 * root.s
                        font.weight: Font.DemiBold
                    }
                }
            }
        }

        // Suspend timer
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
                        text: "Suspend after"
                        color: Theme.subtle
                        font.family: Theme.font
                        font.pixelSize: 11 * root.s
                    }

                    Text {
                        text: Flags.idleSuspendMin > 0 ? Flags.idleSuspendMin + " minutes" : "Never"
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 18 * root.s
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }
}
