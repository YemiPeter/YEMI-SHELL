import QtQuick
import "Singletons"

/**
 * Display mode picker: resolution + refresh rate selector.
 */
Item {
    id: root

    property real s: 1
    property var modes: []
    property int selected: 0

    implicitHeight: modeList.implicitHeight + 8 * s
    implicitWidth: 180 * s

    Column {
        id: modeList
        anchors.centerIn: parent
        spacing: 3 * root.s

        Repeater {
            model: root.modes

            delegate: Rectangle {
                id: modeItem
                required property var modelData
                required property int index
                width: parent.width
                height: 32 * root.s
                radius: 6 * root.s
                color: root.selected === index ? Qt.alpha(Theme.cream, 0.1) : "transparent"
                border.width: root.selected === index ? 1 : 0
                border.color: root.selected === index ? Qt.alpha(Theme.cream, 0.2) : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: modelData.label || ""
                    color: root.selected === index ? Theme.cream : Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selected = index;
                        root.selectedChanged(index);
                    }
                }
            }
        }
    }
}
