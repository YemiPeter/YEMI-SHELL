import QtQuick
import "Singletons"

/**
 * Label for display settings: icon + name + resolution.
 */
Item {
    id: root

    property real s: 1
    property string name: ""
    property string resolution: ""
    property bool active: false

    implicitHeight: 32 * s
    implicitWidth: Math.max(140 * s, nameText.implicitWidth + resText.implicitWidth + 20 * s)

    Rectangle {
        anchors.fill: parent
        radius: 8 * root.s
        color: root.active ? Qt.alpha(Theme.cream, 0.08) : "transparent"
        border.width: root.active ? 1 : 0
        border.color: root.active ? Qt.alpha(Theme.cream, 0.2) : "transparent"
    }

    Row {
        anchors.centerIn: parent
        spacing: 8 * root.s

        Text {
            text: root.name
            color: root.active ? Theme.cream : Theme.dim
            font.family: Theme.font
            font.pixelSize: 12 * root.s
            font.weight: root.active ? Font.DemiBold : Font.Normal
        }

        Text {
            text: root.resolution
            color: Theme.faint
            font.family: Theme.font
            font.pixelSize: 10 * root.s
        }
    }
}
