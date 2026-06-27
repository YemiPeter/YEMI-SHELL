import QtQuick
import "Singletons"

/**
 * Horizontal fader for the mixer. Drag left/right to adjust volume.
 */
Item {
    id: root

    property real s: 1
    property real value: 0.5
    property string label: ""
    property bool focused: false

    implicitHeight: 48 * s
    implicitWidth: 180 * s

    Rectangle {
        anchors.fill: parent
        radius: 8 * root.s
        color: root.focused ? Qt.alpha(Theme.cream, 0.05) : "transparent"
        Behavior on color { ColorAnimation { duration: Motion.fast } }
    }

    Column {
        anchors.centerIn: parent
        spacing: 4 * root.s

        Text {
            text: root.label
            color: Theme.subtle
            font.family: Theme.font
            font.pixelSize: 10 * root.s
        }

        Row {
            spacing: 8 * root.s

            Rectangle {
                width: 120 * root.s
                height: 4 * root.s
                radius: 2 * root.s
                color: Qt.alpha(Theme.cream, 0.15)

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    width: parent.width * root.value
                    radius: parent.radius
                    color: Theme.flameGlow
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPositionChanged: (mouse) => {
                        root.value = Math.max(0, Math.min(1, mouse.x / width));
                        root.valueChanged(root.value);
                    }
                    onClicked: (mouse) => {
                        root.value = Math.max(0, Math.min(1, mouse.x / width));
                        root.valueChanged(root.value);
                    }
                }
            }

            Text {
                text: Math.round(root.value * 100) + "%"
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 11 * root.s
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
            }
        }
    }
}
