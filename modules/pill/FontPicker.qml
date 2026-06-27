import QtQuick
import QtQuick.Controls
import "Singletons"

/**
 * Font picker surface. Shows a list of available system fonts with a preview.
 */
PillSurface {
    id: root
    mTop: 15
    mLeft: 17
    mRight: 17
    mBottom: 14

    property string selectedFont: Flags.uiFont || Theme.font

    implicitHeight: fontList.implicitHeight + 24 * s
    implicitWidth: 360 * s

    ListView {
        id: fontList
        anchors.fill: parent
        anchors.topMargin: 12 * root.s
        anchors.leftMargin: 16 * root.s
        anchors.rightMargin: 16 * root.s
        anchors.bottomMargin: 12 * root.s
        model: Theme.fontFamilies
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        spacing: 2 * root.s

        delegate: Item {
            id: fontRow
            required property var modelData
            required property int index
            width: parent.width
            height: 36 * root.s

            Rectangle {
                anchors.fill: parent
                radius: 8 * root.s
                color: fontArea.containsMouse ? Qt.alpha(Theme.cream, 0.06) : "transparent"
                Behavior on color { ColorAnimation { duration: Motion.fast } }
            }

            Row {
                anchors.centerIn: parent
                spacing: 10 * root.s

                Text {
                    text: fontRow.modelData
                    color: root.selectedFont === fontRow.modelData ? Theme.cream : Theme.dim
                    font.family: fontRow.modelData
                    font.pixelSize: 13 * root.s
                    font.weight: root.selectedFont === fontRow.modelData ? Font.DemiBold : Font.Normal
                }

                Text {
                    visible: root.selectedFont === fontRow.modelData
                    text: "✓"
                    color: Theme.verm
                    font.pixelSize: 14 * root.s
                }
            }

            MouseArea {
                id: fontArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.selectedFont = fontRow.modelData;
                    // In full impl: write to Flags.uiFont
                }
            }
        }
    }
}
