import QtQuick
import "Singletons"

/**
 * Single settings row: icon + label + value/control area.
 */
Item {
    id: root

    property real s: 1
    property string icon: ""
    property string label: ""
    property var control: null
    property bool active: false

    implicitHeight: Math.max(iconItem.height, labelText.height, control ? control.implicitHeight : 0) + 12 * s
    implicitWidth: Math.max(iconItem.width + labelText.width + 10 * s, control ? control.x + control.implicitWidth : 0) + 16 * s

    Rectangle {
        anchors.fill: parent
        radius: 8 * root.s
        color: root.active ? Qt.alpha(Theme.cream, 0.06) : "transparent"
        Behavior on color { ColorAnimation { duration: Motion.fast } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10 * root.s

        GlyphIcon {
            id: iconItem
            width: 18 * root.s
            height: 18 * root.s
            name: root.icon
            color: root.active ? Theme.cream : Theme.subtle
            stroke: 1.7
        }

        Text {
            id: labelText
            text: root.label
            color: root.active ? Theme.cream : Theme.dim
            font.family: Theme.font
            font.pixelSize: 13 * root.s
        }

        Item {
            id: controlSlot
            anchors.verticalCenter: parent.verticalCenter
            width: root.control ? root.control.implicitWidth : 0
            height: root.control ? root.control.implicitHeight : 0

            children: root.control
        }
    }
}
