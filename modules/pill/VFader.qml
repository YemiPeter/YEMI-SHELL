import QtQuick
import "Singletons"

/**
 * Vertical fader for the mixer. Drag up/down to adjust volume.
 */
Item {
    id: root

    property real s: 1
    property real value: 0.5
    property string label: ""
    property bool focused: false

    implicitHeight: 140 * s
    implicitWidth: 48 * s

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

        Item {
            width: 24 * root.s
            height: 100 * root.s

            Rectangle {
                anchors.centerIn: parent
                width: 4 * root.s
                height: parent.height
                radius: 2 * root.s
                color: Qt.alpha(Theme.cream, 0.15)
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: 4 * root.s
                height: parent.height * root.value
                radius: 2 * root.s
                color: Theme.flameGlow
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: (mouse) => {
                    root.value = 1 - Math.max(0, Math.min(1, mouse.y / height));
                    root.valueChanged(root.value);
                }
                onClicked: (mouse) => {
                    root.value = 1 - Math.max(0, Math.min(1, mouse.y / height));
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
