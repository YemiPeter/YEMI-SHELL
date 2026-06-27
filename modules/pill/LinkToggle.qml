import QtQuick
import "Singletons"

/**
 * Toggle switch for link surface (WiFi, Bluetooth).
 */
Item {
    id: root

    property real s: 1
    property bool checked: false
    property string label: ""

    signal toggled(bool checked)

    implicitHeight: 28 * s
    implicitWidth: Math.max(50 * s, labelText.implicitWidth + 40 * s)

    Rectangle {
        anchors.fill: parent
        radius: 14 * root.s
        color: root.checked ? Qt.alpha(Theme.verm, 0.3) : Qt.alpha(Theme.tileBg, 0.5)
        border.width: 1
        border.color: root.checked ? Qt.alpha(Theme.verm, 0.5) : Theme.border

        Behavior on color { ColorAnimation { duration: Motion.fast } }
        Behavior on border.color { ColorAnimation { duration: Motion.fast } }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 3 * root.s
        width: 20 * root.s
        height: 20 * root.s
        radius: 10 * root.s
        color: root.checked ? Theme.verm : Theme.iconDim
        Behavior on x { NumberAnimation { duration: Motion.fast; easing.type: Motion.easeStandard } }
        Behavior on color { ColorAnimation { duration: Motion.fast } }
        x: root.checked ? parent.width - width - 3 * root.s : 3 * root.s
    }

    Text {
        id: labelText
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 12 * root.s
        anchors.right: parent.right
        anchors.rightMargin: 8 * root.s
        text: root.label
        color: root.checked ? Theme.cream : Theme.dim
        font.family: Theme.font
        font.pixelSize: 12 * root.s
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.checked = !root.checked;
            root.toggled(root.checked);
        }
    }
}
