import QtQuick
import QtQuick.Controls
import "Singletons"

/**
 * Minimal skip-track transport button for Media.qml.
 * text: "<" or ">"
 * can: bool — controls enabled/disabled visual state
 * onActivated: fired on click when can is true
 */
Item {
    id: root
    property string text: ""
    property bool can: false
    signal activated

    width: 28 * s
    height: 28 * s

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.can ? Theme.tileBg : "transparent"
        border.width: 1
        border.color: root.can ? Theme.border : "transparent"
        opacity: root.can ? 1 : 0.35
        Behavior on opacity { NumberAnimation { duration: Motion.fast } }
    }

    Text {
        anchors.centerIn: parent
        text: root.text
        color: root.can ? Theme.cream : Theme.faint
        font.family: Theme.font
        font.pixelSize: 14 * s
        font.weight: Font.DemiBold
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.can
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
