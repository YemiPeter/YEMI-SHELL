pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "Singletons"
import qs.services as QsServices

/**
 * First-run welcome dialog. Surfaced by FirstRunExperience.welcomeQmlPath on a
 * fresh install. Greets the user and offers a shortcut into Settings.
 */
PanelWindow {
    id: dialog

    property real s: 1

    visible: false
    color: "transparent"
    screen: Quickshell.screens[0]

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "welcome"

    function open() { dialog.visible = true }
    function close() { dialog.visible = false }

    Keys.onEscapePressed: dialog.close()

    MouseArea {
        anchors.fill: parent
        onClicked: dialog.close()
    }

    Rectangle {
        anchors.centerIn: parent
        width: 380 * dialog.s
        radius: 16 * dialog.s
        clip: true

        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.cardTop }
            GradientStop { position: 1.0; color: Theme.cardBot }
        }
        border.width: 1
        border.color: Theme.border

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadow
            shadowBlur: 0.9
            shadowVerticalOffset: 4 * dialog.s
        }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22 * dialog.s
            spacing: 12 * dialog.s

            Text {
                text: "✺  Welcome"
                color: Theme.cream
                font.family: Theme.font
                font.weight: Font.Bold
                font.pixelSize: 22 * dialog.s
            }

            Text {
                Layout.fillWidth: true
                text: QsServices.FirstRunExperience.firstRunNotifBody
                color: Theme.subtle
                font.family: Theme.font
                font.pixelSize: 12 * dialog.s
                wrapMode: Text.WordWrap
            }

            Item { Layout.fillHeight: true }

            Rectangle {
                id: openBtn
                Layout.fillWidth: true
                Layout.preferredHeight: 34 * dialog.s
                radius: 9 * dialog.s
                color: openArea.containsMouse ? Theme.vermLit : Theme.verm

                Text {
                    anchors.centerIn: parent
                    text: "Open Settings"
                    color: Theme.cream
                    font.family: Theme.font
                    font.weight: Font.Bold
                    font.pixelSize: 12 * dialog.s
                }

                MouseArea {
                    id: openArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["qs", "ipc", "call", "settings", "toggle"])
                        dialog.close()
                    }
                }
            }
        }
    }
}
