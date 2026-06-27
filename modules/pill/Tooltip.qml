import QtQuick
import QtQuick.Effects
import "Singletons"

/**
 * Hover tooltip for pill icons. Appears above the target with a small arrow.
 */
Item {
    id: root

    property real s: 1
    property string text: ""
    property Item target: null
    property bool visible: false

    implicitWidth: bg.implicitWidth
    implicitHeight: bg.implicitHeight

    Rectangle {
        id: bg
        anchors.centerIn: parent
        radius: 6 * root.s
        color: Qt.alpha(Theme.cardTop, 0.95)
        border.width: 1
        border.color: Theme.border

        Text {
            anchors.centerIn: parent
            anchors.margins: 8 * root.s
            text: root.text
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 11 * root.s
        }
    }

    Behavior on opacity { NumberAnimation { duration: Motion.fast } }
    opacity: root.visible ? 1 : 0
}
