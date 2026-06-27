import QtQuick
import "Singletons"

/**
 * Decorative filament line for settings surfaces. A thin gradient line
 * separating sections.
 */
Item {
    id: root

    property real s: 1
    property color color: Theme.hair
    property real thickness: 1

    implicitHeight: thickness * s
    implicitWidth: parent ? parent.width : 200 * s

    Rectangle {
        anchors.fill: parent
        radius: thickness * root.s / 2
        color: root.color
    }
}
