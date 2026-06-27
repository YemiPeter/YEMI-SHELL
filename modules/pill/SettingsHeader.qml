import QtQuick
import "Singletons"

/**
 * Section header for settings surfaces. Title + optional subtitle.
 */
Item {
    id: root

    property real s: 1
    property string title: ""
    property string subtitle: ""

    implicitHeight: col.implicitHeight + 8 * s
    implicitWidth: col.implicitWidth

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2 * root.s

        Text {
            text: root.title
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 15 * root.s
            font.weight: Font.DemiBold
        }

        Text {
            visible: root.subtitle.length > 0
            text: root.subtitle
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 11 * root.s
        }
    }
}
