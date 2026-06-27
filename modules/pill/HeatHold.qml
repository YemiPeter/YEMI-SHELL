import QtQuick
import "Singletons"

/**
 * Hold-to-confirm button for destructive actions (shutdown, reboot). Fills
 * a progress bar as the user holds; releases early cancel.
 */
Item {
    id: root

    property real s: 1
    property real progress: 0
    property string label: "Hold to confirm"
    property bool armed: false

    implicitHeight: 36 * s
    implicitWidth: Math.max(120 * s, labelText.implicitWidth + 24 * s)

    signal triggered()
    signal cancelled()

    Rectangle {
        anchors.fill: parent
        radius: 10 * root.s
        color: root.armed ? Qt.alpha(Theme.verm, 0.15) : Qt.alpha(Theme.tileBg, 0.5)
        border.width: 1
        border.color: root.armed ? Qt.alpha(Theme.verm, 0.4) : Theme.border

        Behavior on color { ColorAnimation { duration: Motion.fast } }
        Behavior on border.color { ColorAnimation { duration: Motion.fast } }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * Math.min(1, root.progress)
        radius: parent.radius
        color: root.armed ? Qt.alpha(Theme.verm, 0.3) : "transparent"
        Behavior on width { NumberAnimation { duration: 50 } }
    }

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        color: root.armed ? Theme.verm : Theme.dim
        font.family: Theme.font
        font.pixelSize: 12 * root.s
        font.weight: Font.DemiBold
    }
}
