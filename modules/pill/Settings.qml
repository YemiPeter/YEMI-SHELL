import QtQuick
import "Singletons"

/**
 * Settings index surface. Grid of setting category tiles.
 */
PillSurface {
    id: root
    mTop: 15
    mLeft: 17
    mRight: 17
    mBottom: 14

    readonly property var categories: [
        { key: "appearance", icon: "palette", label: "Appearance" },
        { key: "display", icon: "monitor", label: "Display" },
        { key: "input", icon: "keyboard", label: "Input" },
        { key: "look", icon: "sparkles", label: "Look" },
        { key: "idlelock", icon: "lock", label: "Idle & Lock" },
        { key: "updates", icon: "download", label: "Updates" },
        { key: "fontpicker", icon: "type", label: "Fonts" }
    ]

    implicitHeight: catGrid.implicitHeight + 24 * s
    implicitWidth: 392 * s

    Grid {
        id: catGrid
        anchors.centerIn: parent
        columns: 2
        columnSpacing: 10 * root.s
        rowSpacing: 8 * root.s

        Repeater {
            model: root.categories

            delegate: Item {
                id: catTile
                required property var modelData
                required property int index
                width: 170 * root.s
                height: 60 * root.s

                Rectangle {
                    anchors.fill: parent
                    radius: 12 * root.s
                    color: catArea.containsMouse ? Qt.alpha(Theme.cream, 0.06) : Theme.tileBg
                    border.width: 1
                    border.color: catArea.containsMouse ? Qt.alpha(Theme.cream, 0.15) : Theme.border
                    Behavior on color { ColorAnimation { duration: Motion.fast } }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 10 * root.s

                    GlyphIcon {
                        width: 20 * root.s
                        height: 20 * root.s
                        name: modelData.icon
                        color: Theme.cream
                        stroke: 1.7
                    }

                    Text {
                        text: modelData.label
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 13 * root.s
                    }
                }

                MouseArea {
                    id: catArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.requestSurface(modelData.key)
                }
            }
        }
    }
}
