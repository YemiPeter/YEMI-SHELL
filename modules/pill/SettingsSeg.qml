import QtQuick
import "Singletons"

/**
 * Segmented control for settings: a row of toggle buttons where one is active.
 */
Item {
    id: root

    property real s: 1
    property var options: []
    property int selected: 0
    property color activeColor: Theme.verm
    property color inactiveColor: Theme.tileBg
    property color textActive: Theme.cream
    property color textInactive: Theme.dim

    implicitHeight: segRow.implicitHeight + 4 * s
    implicitWidth: segRow.implicitWidth + 8 * s

    Row {
        id: segRow
        anchors.centerIn: parent
        spacing: 3 * root.s

        Repeater {
            model: root.options

            delegate: Rectangle {
                id: seg
                required property var modelData
                required property int index
                width: Math.max(40 * root.s, modelData.label ? modelData.label.length * 7 * root.s : 30 * root.s)
                height: 28 * root.s
                radius: 6 * root.s
                color: root.selected === index ? root.activeColor : root.inactiveColor
                border.width: 1
                border.color: root.selected === index ? Qt.alpha(Theme.vermLit, 0.5) : Qt.alpha(Theme.border, 0.5)

                Behavior on color { ColorAnimation { duration: Motion.fast } }

                Text {
                    anchors.centerIn: parent
                    anchors.margins: 8 * root.s
                    text: modelData.label || ""
                    color: root.selected === index ? root.textActive : root.textInactive
                    font.family: Theme.font
                    font.pixelSize: 11 * root.s
                    font.weight: root.selected === index ? Font.DemiBold : Font.Normal
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
