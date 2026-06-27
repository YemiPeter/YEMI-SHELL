import QtQuick
import "Singletons"

/**
 * Scrolling text marquee for long track names and labels. Scrolls only when
 * the text overflows; pauses on hover.
 */
Item {
    id: root

    property real s: 1
    property string text: ""
    property color color: Theme.cream
    property real pixelSize: 13 * s
    property int speed: 40
    property bool paused: false

    implicitWidth: textItem.implicitWidth
    implicitHeight: textItem.implicitHeight

    Text {
        id: textItem
        text: root.text
        color: root.color
        font.family: Theme.font
        font.pixelSize: root.pixelSize
    }

    Timer {
        id: scrollTimer
        interval: 16
        running: textItem.implicitWidth > root.width && !root.paused
        repeat: true
        onTriggered: {
            textItem.x -= root.speed * root.s * 0.016;
            if (textItem.x < -textItem.implicitWidth)
                textItem.x = root.width;
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.paused = true
        onExited: root.paused = false
    }
}
