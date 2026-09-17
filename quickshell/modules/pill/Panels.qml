pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.compositor
import "../common"
import "../../config" as QsConfig
import "Singletons"

/**
 * PANELS sub-surface: master switches for the big overlay panels the pill
 * owns. Values persist through Flags (flags.json) so they survive a restart.
 * Reached from the settings index; morphs back on the back chevron.
 */
SettingsSurface {
    id: root

    backSurface: "settings"
    property real maxSurfaceH: 0
    implicitHeight: Math.min(settingsHeader.implicitHeight + innerColumn.implicitHeight, maxSurfaceH)
    rows: []

    component Group: Rectangle {
        id: g
        property string title: ""
        property bool collapsed: false
        default property alias content: bodyColumn.data

        width: parent ? parent.width : 0
        implicitHeight: cardBody.implicitHeight
        radius: Motion.rTile * root.s
        color: Theme.cardTop
        border.width: 1
        border.color: Theme.hairSoft
        clip: true

        Glass {
            anchors.fill: parent
            radius: parent.radius
            tintScale: 1.0
        }

        readonly property real pad: 4 * root.s

        Column {
            id: cardBody
            width: parent.width - pad * 2
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: pad
            bottomPadding: pad
            spacing: 0

            Item {
                id: header
                width: cardBody.width
                height: 30 * root.s

                Row {
                    id: headerRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6 * root.s

                    GlyphIcon {
                        width: 14 * root.s
                        height: 14 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        name: "chevron-down"
                        rotation: g.collapsed ? -90 : 0
                        color: Theme.faint
                        stroke: 2.2

                        Behavior on rotation { NumberAnimation { duration: 150 } }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: g.title
                        color: Theme.faint
                        font.family: Theme.font
                        font.pixelSize: 8.5 * root.s
                        font.weight: Font.Bold
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1.2 * root.s
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: g.collapsed = !g.collapsed
                }
            }

            Column {
                id: bodyColumn
                width: cardBody.width
                clip: true
                enabled: !g.collapsed
                opacity: g.collapsed ? 0 : 1
                height: g.collapsed ? 0 : implicitHeight

                Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 160 } }
            }
        }
    }

    component FieldRow: Item {
        id: frow
        property string label: ""
        property string caption: ""
        default property alias control: ctrl.data

        width: parent ? parent.width : 0
        height: 34 * root.s

        Column {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1 * root.s
            width: Math.max(0, parent.width - ctrl.width - 12 * root.s)

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: frow.label
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 12.5 * root.s
                font.weight: Font.Medium
            }

            Text {
                width: parent.width
                visible: frow.caption.length > 0
                elide: Text.ElideRight
                text: frow.caption
                color: Theme.faint
                font.family: Theme.font
                font.pixelSize: 9 * root.s
                font.weight: Font.Medium
            }
        }

        Item {
            id: ctrl
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: childrenRect.width
            height: childrenRect.height
        }
    }

    Column {
        id: content
        z: 100
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0
        height: root.height + root.mBottom * root.s
        clip: true

        SettingsHeader {
            id: settingsHeader
            s: root.s
            title: "PANELS"
            showBack: true
        }

        Flickable {
            id: scroller
            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.max(0, root.height - settingsHeader.height)
            contentHeight: innerColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: innerColumn
                width: parent.width
                spacing: 10 * root.s
                bottomPadding: 12 * root.s

            Group {
                id: switcherGroup
                title: "Window switcher"
                collapsed: false

                FieldRow {
                    label: "Overview (Alt+Tab)"
                    caption: "Show the window picker on Alt+Tab"
                    LinkToggle {
                        s: root.s
                        on: Flags.altSwitcherEnabled
                        onToggled: Flags.altSwitcherEnabled = !Flags.altSwitcherEnabled
                    }
                }
            }

            }

            WheelScroller { flick: scroller }
        }
    }
}
