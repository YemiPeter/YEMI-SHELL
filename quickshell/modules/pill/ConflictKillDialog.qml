pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "Singletons"
import qs.services as QsServices

/**
 * Conflict kill dialog. Surfaced by ConflictKiller.killDialogQmlPath when
 * duplicate keybinds or shared-surface (tray / notifications) claims clash.
 * Lists every active conflict and offers a quick action per type.
 */
PanelWindow {
    id: dialog

    property real s: 1

    visible: false
    color: "transparent"
    screen: Quickshell.screens[0]

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "conflict-kill"

    function open() { dialog.visible = true }
    function close() { dialog.visible = false }

    Keys.onEscapePressed: dialog.close()

    MouseArea {
        anchors.fill: parent
        onClicked: dialog.close()
    }

    Rectangle {
        anchors.centerIn: parent
        width: 360 * dialog.s
        radius: 14 * dialog.s
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
            anchors.margins: 14 * dialog.s
            spacing: 10 * dialog.s

            Text {
                text: "Conflicts"
                color: Theme.cream
                font.family: Theme.font
                font.weight: Font.DemiBold
                font.pixelSize: 15 * dialog.s
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1.4 * dialog.s
            }

            Repeater {
                model: QsServices.ConflictKiller.conflicts

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 54 * dialog.s
                    radius: 9 * dialog.s
                    color: Theme.tileBg
                    border.width: 1
                    border.color: Theme.border

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12 * dialog.s
                        anchors.rightMargin: 12 * dialog.s
                        spacing: 2 * dialog.s

                        Text {
                            text: (modelData.type === "keybind" ? "Keybind · " : "") + modelData.detail
                            color: Theme.cream
                            font.family: Theme.font
                            font.pixelSize: 11.5 * dialog.s
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: modelData.type === "keybind"
                                ? "Open Keybinds to resolve"
                                : "Disable one owner (" + (modelData.owners || []).join(", ") + ")"
                            color: Theme.subtle
                            font.family: Theme.font
                            font.pixelSize: 9.5 * dialog.s
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }
}
