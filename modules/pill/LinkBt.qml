import QtQuick
import Quickshell.Io
import Quickshell.Bluetooth
import "Singletons"

/**
 * Bluetooth device row for the link surface. Shows device name, connection
 * state, and a connect/disconnect toggle.
 */
Item {
    id: root

    property real s: 1
    property var device: null

    implicitHeight: 44 * s
    implicitWidth: parent ? parent.width : 300 * s

    Rectangle {
        anchors.fill: parent
        radius: 8 * root.s
        color: rowArea.containsMouse ? Qt.alpha(Theme.cream, 0.06) : "transparent"
        Behavior on color { ColorAnimation { duration: Motion.fast } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10 * root.s

        GlyphIcon {
            width: 18 * root.s
            height: 18 * root.s
            name: "bluetooth"
            color: root.device && root.device.connected ? Theme.flameGlow : Theme.iconDim
            stroke: 1.7
        }

        Text {
            text: root.device ? root.device.name : "Unknown"
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 13 * root.s
        }

        Item {
            width: 60 * root.s
            height: 24 * root.s

            Rectangle {
                anchors.centerIn: parent
                width: 44 * root.s
                height: 22 * root.s
                radius: 11 * root.s
                color: root.device && root.device.connected ? Qt.alpha(Theme.verm, 0.3) : Qt.alpha(Theme.tileBg, 0.5)
                border.width: 1
                border.color: root.device && root.device.connected ? Qt.alpha(Theme.verm, 0.5) : Theme.border

                Behavior on color { ColorAnimation { duration: Motion.fast } }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 16 * root.s
                height: 16 * root.s
                radius: 8 * root.s
                color: root.device && root.device.connected ? Theme.verm : Theme.iconDim
                Behavior on x { NumberAnimation { duration: Motion.fast } }
                x: root.device && root.device.connected ? parent.width - width - 3 * root.s : 3 * root.s
            }
        }
    }

    MouseArea {
        id: rowArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.device) {
                if (root.device.connected)
                    root.device.disconnect();
                else
                    root.device.connect();
            }
        }
    }
}
