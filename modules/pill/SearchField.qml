pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import "Singletons"

/**
 * Search input for the launcher surface. Styled to match the pill's washi
 * aesthetic with a kanji placeholder and a live character counter.
 */
Item {
    id: root

    property real s: 1
    property string kanji: "探"
    property string placeholder: "Search"
    property string counterText: ""
    property alias text: input.text
    signal moved(int delta)
    signal accepted()
    signal dismissed()

    implicitHeight: input.implicitHeight + 12 * s
    implicitWidth: input.implicitWidth + 16 * s

    TextField {
        id: input
        anchors.fill: parent
        anchors.margins: 6 * s
        placeholderText: root.kanji + " " + root.placeholder
        color: Theme.cream
        font.family: Theme.font
        font.pixelSize: 14 * root.s
        background: Rectangle {
            radius: 8 * root.s
            color: Qt.alpha(Theme.tileBg, 0.6)
            border.width: 1
            border.color: Qt.alpha(Theme.border, 0.5)
        }
        onAccepted: root.accepted()
    }

    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 10 * s
        text: root.counterText
        color: Theme.faint
        font.family: Theme.font
        font.pixelSize: 10 * s
    }
}
