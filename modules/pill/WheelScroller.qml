import QtQuick

/**
 * Scroll wheel handler that forwards wheel events to a target Flickable.
 * Used by the wallpaper strip and quick-record monitor picker.
 */
Item {
    id: root

    property Item flick
    property real s: 1

    anchors.fill: parent

    onFlickChanged: {
        if (flick && flick.contentX !== undefined) {
            // Connected
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: (wheel) => {
            if (root.flick) {
                root.flick.contentX -= wheel.angleDelta.y * 0.5 * root.s;
                wheel.accepted = true;
            }
        }
    }
}
