import QtQuick
import "Singletons"

/**
 * Base surface for settings-family surfaces (Settings, Appearance, Updates,
 * Display, Input, Look, IdleLock, FontPicker). Provides the header bar with
 * back button and title, and a scrollable content area.
 */
Item {
    id: root

    property real s: 1
    property string title: ""
    property var contentItem: null
    property bool backEnabled: true

    signal requestBack()

    implicitHeight: contentArea.implicitHeight + header.height + 12 * s
    implicitWidth: 392 * s

    Rectangle {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40 * root.s
        radius: 10 * root.s
        color: Qt.alpha(Theme.tileBg, 0.5)

        Row {
            anchors.centerIn: parent
            spacing: 8 * root.s

            GlyphIcon {
                visible: root.backEnabled
                width: 16 * root.s
                height: 16 * root.s
                name: "chevron-left"
                color: Theme.subtle
                stroke: 2

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4 * root.s
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.requestBack()
                }
            }

            Text {
                text: root.title
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 14 * root.s
                font.weight: Font.DemiBold
            }
        }
    }

    Item {
        id: contentArea
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 8 * root.s
        anchors.bottomMargin: 8 * root.s

        children: root.contentItem
    }
}
