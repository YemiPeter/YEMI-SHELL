import QtQuick
import QtQuick.Controls
import Quickshell
import "Singletons"

/**
 * Calendar surface for the pill. Shows a month grid with today highlighted,
 * and a list of upcoming events from the Events singleton.
 */
PillSurface {
    id: root
    mTop: 15
    mLeft: 17
    mRight: 17
    mBottom: 14

    readonly property var now: new Date()
    readonly property int year: now.getFullYear()
    readonly property int month: now.getMonth()
    readonly property int today: now.getDate()

    implicitHeight: calGrid.implicitHeight + eventsList.implicitHeight + 40 * s
    implicitWidth: 282 * s

    Column {
        id: col
        anchors.fill: parent
        anchors.topMargin: 12 * root.s
        anchors.leftMargin: 16 * root.s
        anchors.rightMargin: 16 * root.s
        anchors.bottomMargin: 12 * root.s
        spacing: 12 * root.s

        // Month header
        Row {
            width: parent.width
            height: 24 * root.s

            Text {
            	width: parent.width
            	horizontalAlignment: Text.AlignHCenter
            	verticalAlignment: Text.AlignVCenter
            	text: Qt.formatDate(root.now, "MMMM yyyy")
            	color: Theme.cream
            	font.family: Theme.font
            	font.pixelSize: 14 * root.s
            	font.weight: Font.DemiBold
            }
        }

        // Day names
        Grid {
            id: dayNames
            width: parent.width
            height: 18 * root.s
            columns: 7
            columnSpacing: 2 * root.s
            rowSpacing: 2 * root.s

            Repeater {
                model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                delegate: Text {
                    text: modelData
                    color: Theme.faint
                    font.family: Theme.font
                    font.pixelSize: 9 * root.s
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    width: (parent.width - 6 * 2 * root.s) / 7
                }
            }
        }

        // Calendar grid
        Grid {
            id: calGrid
            width: parent.width
            columns: 7
            columnSpacing: 2 * root.s
            rowSpacing: 2 * root.s

            Repeater {
                model: 42
                delegate: Item {
                    id: dayCell
                    width: (parent.width - 6 * 2 * root.s) / 7
                    height: 28 * root.s

                    property int dayNum: modelData - 6
                    property bool inMonth: dayNum >= 1 && dayNum <= 31
                    property bool isToday: inMonth && dayNum === root.today

                    Rectangle {
                        anchors.fill: parent
                        radius: 6 * root.s
                        color: dayCell.isToday ? Qt.alpha(Theme.verm, 0.3) : "transparent"
                        border.width: dayCell.isToday ? 1 : 0
                        border.color: dayCell.isToday ? Qt.alpha(Theme.vermLit, 0.5) : "transparent"
                    }

                    Text {
                        anchors.centerIn: parent
                        text: dayCell.inMonth ? dayNum : ""
                        color: dayCell.isToday ? Theme.vermLit : (dayCell.inMonth ? Theme.cream : Theme.faint)
                        font.family: Theme.font
                        font.pixelSize: 11 * root.s
                        font.weight: dayCell.isToday ? Font.DemiBold : Font.Normal
                    }
                }
            }
        }

        // Upcoming events
        Text {
            text: "Upcoming"
            color: Theme.subtle
            font.family: Theme.font
            font.pixelSize: 11 * root.s
            font.weight: Font.Medium
        }

        ListView {
            id: eventsList
            width: parent.width
            height: 80 * root.s
            model: Events.events.slice(0, 4)
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            spacing: 3 * root.s

            delegate: Item {
                id: evRow
                required property var modelData
                required property int index
                width: parent.width
                height: 24 * root.s

                Rectangle {
                    anchors.fill: parent
                    radius: 6 * root.s
                    color: Qt.alpha(Theme.cream, 0.04)
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 8 * root.s

                    Text {
                        text: modelData.date || ""
                        color: Theme.verm
                        font.family: Theme.font
                        font.pixelSize: 10 * root.s
                    }

                    Text {
                        text: modelData.text || ""
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 11 * root.s
                        elide: Text.ElideRight
                        width: parent.width - 40 * root.s
                    }
                }
            }
        }
    }
}
