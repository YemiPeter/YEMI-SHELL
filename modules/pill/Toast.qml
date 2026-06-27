pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "Singletons"

/**
 * Toast content for the morphing pill body: icon tile, app eyebrow, summary
 * with critical ember dot, optional body text and action pills, dismiss glyph
 * on the right. Draws no background of its own; the pill body behind it
 * provides the washi material. Clicking the body emits openCenter(); dismiss
 * and action pills consume their clicks. Auto-expires via Notifs.expireAt
 * unless the notification is critical.
 */
Item {
    id: root

    property real s: 1
    property bool live: true
    required property var notif

    signal openCenter()

    readonly property bool critical: notif.urgency === NotificationUrgency.Critical
    readonly property var acts: notif.actions.filter(function(a) { return a.text.length > 0; })

    implicitHeight: Math.max(iconTile.height, col.implicitHeight)

    /**
     * Deadline is snapshotted once: binding the interval to Notifs.expireAt
     * restarts the timer (and drifts the lifetime) every time an unrelated
     * notification replaces the map.
     */
    property double deadline: 0
    Component.onCompleted: deadline = Notifs.expireAt[notif.id] || (Date.now() + 6000)

    Timer {
        interval: Math.max(300, root.deadline - Date.now())
        running: root.deadline > 0 && root.live && root.notif.urgency !== NotificationUrgency.Critical
        onTriggered: Notifs.removePopup(root.notif)
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.openCenter()
    }

    Rectangle {
        id: iconTile
        anchors.left: parent.left
        anchors.top: parent.top
        width: 28 * root.s
        height: 28 * root.s
        radius: 9 * root.s
        color: Theme.tileBg
        border.width: 1
        border.color: Theme.border

        Image {
            id: toastImg
            anchors.fill: parent
            anchors.margins: root.notif.image ? 0 : 6 * root.s
            source: Notifs.iconFor(root.notif)
            sourceSize.width: 56
            sourceSize.height: 56
            fillMode: Image.PreserveAspectCrop
            smooth: true
            visible: source.toString().length > 0
        }

        Rectangle {
            anchors.centerIn: parent
            visible: !toastImg.visible
            width: 7 * root.s
            height: 7 * root.s
            radius: 2 * root.s
            rotation: 45
            color: root.critical ? Theme.vermLit : Theme.verm
        }
    }

    Column {
        id: col
        anchors.left: iconTile.right
        anchors.leftMargin: 10 * root.s
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2 * root.s

        Text {
            text: root.notif.appName || "App"
            color: Theme.subtle
            font.family: Theme.font
            font.pixelSize: 9 * root.s
            font.weight: Font.Medium
            font.capitalization: Font.AllUppercase
        }

        Text {
            text: root.notif.summary || ""
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 12 * root.s
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            width: parent.width - 20 * root.s
        }

        Text {
            visible: root.notif.body && root.notif.body.length > 0
            text: root.notif.body
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 10 * root.s
            elide: Text.ElideRight
            width: parent.width - 20 * root.s
        }

        Row {
            visible: root.acts.length > 0
            spacing: 6 * root.s

            Repeater {
                model: root.acts

                Rectangle {
                    id: actBtn
                    required property var modelData
                    height: 22 * root.s
                    radius: 6 * root.s
                    color: actArea.containsMouse ? Qt.alpha(Theme.vermLit, 0.2) : Qt.alpha(Theme.cream, 0.08)
                    border.width: 1
                    border.color: actArea.containsMouse ? Qt.alpha(Theme.vermLit, 0.4) : Qt.alpha(Theme.cream, 0.15)

                    Text {
                        anchors.centerIn: parent
                        anchors.margins: 8 * root.s
                        text: modelData.text
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 10 * root.s
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        id: actArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            modelData.invoke();
                            Notifs.removePopup(root.notif);
                        }
                    }
                }
            }
        }
    }

    // Dismiss glyph
    GlyphIcon {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 4 * root.s
        width: 12 * root.s
        height: 12 * root.s
        name: "x"
        color: Theme.faint
        stroke: 2

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4 * root.s
            cursorShape: Qt.PointingHandCursor
            onClicked: Notifs.removePopup(root.notif)
        }
    }

    // Critical ember dot
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        width: 6 * root.s
        height: 6 * root.s
        radius: width / 2
        color: Theme.verm
        visible: root.critical
    }
}
