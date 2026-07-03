import QtQuick 6.10

Rectangle {
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: 1 * scaleFactor
    height: parent.height / 2
    radius: parent.radius - 1
    gradient: Gradient {
        GradientStop { position: 0.0; color: topColor }
        GradientStop { position: 1.0; color: "transparent" }
    }
    property color topColor
    property real scaleFactor
}
