import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import "Singletons"

/**
 * WiFi network list for the link surface. Shows SSID, signal strength, and
 * a lock icon for secured networks. Click to connect.
 */
Item {
    id: root

    property real s: 1
    property var networks: []
    property var activeNetwork: null
    property bool scanning: false

    signal networkSelected(var network)

    implicitHeight: Math.min(280 * s, networkList.contentHeight + 20 * s)
    implicitWidth: 320 * s

    Column {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 8 * s
        anchors.leftMargin: 12 * s
        anchors.rightMargin: 12 * s
        spacing: 6 * root.s

        Text {
            text: "Wi-Fi"
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 16 * root.s
            font.weight: Font.DemiBold
        }

        Text {
            text: root.scanning ? "Scanning..." : (root.networks.length + " networks")
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 11 * root.s
        }
    }

    ListView {
        id: networkList
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 8 * root.s
        anchors.bottomMargin: 8 * root.s
        anchors.leftMargin: 8 * root.s
        anchors.rightMargin: 8 * root.s
        model: root.networks
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        spacing: 2 * root.s

        delegate: Item {
            id: netRow
            required property var modelData
            required property int index
            width: parent.width
            height: 40 * root.s

            Rectangle {
                anchors.fill: parent
                radius: 8 * root.s
                color: netArea.containsMouse ? Qt.alpha(Theme.cream, 0.06) : "transparent"
                Behavior on color { ColorAnimation { duration: Motion.fast } }
            }

            Row {
                anchors.centerIn: parent
                spacing: 10 * root.s

                WifiGlyph {
                    width: 16 * root.s
                    height: 16 * root.s
                    level: modelData.signalStrength || 0
                    on: true
                }

                Text {
                    text: modelData.ssid || "Hidden Network"
                    color: modelData.connected ? Theme.cream : Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 13 * root.s
                    font.weight: modelData.connected ? Font.DemiBold : Font.Normal
                }

                Text {
                    visible: modelData.secured
                    text: "🔒"
                    font.pixelSize: 12 * root.s
                    color: Theme.faint
                }

                Text {
                    visible: modelData.connected
                    text: "Connected"
                    color: Theme.flameGlow
                    font.family: Theme.font
                    font.pixelSize: 10 * root.s
                }
            }

            MouseArea {
                id: netArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.networkSelected(modelData)
            }
        }
    }
}
