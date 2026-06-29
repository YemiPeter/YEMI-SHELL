import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Notifications
import "Singletons"

/**
 * Link surface: inbox glance + network/BT quick settings. Two sub-views:
 * "main" shows inbox + quick toggles, "wifi" shows the network list.
 */
PillSurface {
    id: root
    mTop: 15
    mLeft: 17
    mRight: 17
    mBottom: 14

    property string initialView: "main"
    property string currentView: "main"

    implicitHeight: Math.max(280 * s, viewStack.implicitHeight + 24 * s)
    implicitWidth: 360 * s
    readonly property real desiredW: 360 * s

    onActiveChanged: {
        if (active) root.currentView = root.initialView;
    }

    function back() {
        if (root.currentView === "wifi") {
            root.currentView = "main";
            return true;
        }
        return false;
    }

    Item {
        id: viewStack
        anchors.fill: parent
        anchors.topMargin: 12 * root.s
        anchors.leftMargin: 16 * root.s
        anchors.rightMargin: 16 * root.s
        anchors.bottomMargin: 12 * root.s

        // Main view
        Item {
            id: mainView
            anchors.fill: parent
            opacity: root.currentView === "main" ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: Motion.standard } }

            Column {
                anchors.fill: parent
                spacing: 12 * root.s

                Text {
                    text: "Quick Links"
                    color: Theme.cream
                    font.family: Theme.font
                    font.pixelSize: 14 * root.s
                    font.weight: Font.DemiBold
                }

                // WiFi toggle
                LinkToggle {
                    width: parent.width
                    s: root.s
                    label: "Wi-Fi"
                    checked: pill.wifiOn
                    onToggled: {
                        // In full impl: toggle WiFi via Networking
                    }
                }

                // Bluetooth toggle
                LinkToggle {
                    width: parent.width
                    s: root.s
                    label: "Bluetooth"
                    checked: true
                    onToggled: {
                        // In full impl: toggle Bluetooth
                    }
                }

                // Inbox shortcut
                Rectangle {
                    width: parent.width
                    height: 44 * root.s
                    radius: 10 * root.s
                    color: inboxArea.containsMouse ? Qt.alpha(Theme.cream, 0.06) : Theme.tileBg
                    border.width: 1
                    border.color: Theme.border

                    Row {
                        anchors.centerIn: parent
                        spacing: 10 * root.s

                        GlyphIcon {
                            width: 18 * root.s
                            height: 18 * root.s
                            name: "inbox"
                            color: Theme.cream
                            stroke: 1.7
                        }

                        Text {
                            text: "Notifications"
                            color: Theme.cream
                            font.family: Theme.font
                            font.pixelSize: 13 * root.s
                        }

                        Text {
                            visible: Notifs.unread > 0
                            text: Notifs.unread + " unread"
                            color: Theme.flameGlow
                            font.family: Theme.font
                            font.pixelSize: 11 * root.s
                        }
                    }

                    MouseArea {
                        id: inboxArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            pill.linkInitialView = "main";
                            pill.requestClose();
                        }
                    }
                }
            }
        }

        // WiFi view
        Item {
            id: wifiView
            anchors.fill: parent
            opacity: root.currentView === "wifi" ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: Motion.standard } }

            Column {
                anchors.fill: parent
                spacing: 8 * root.s

                Row {
                    width: parent.width
                    height: 24 * root.s

                    GlyphIcon {
                        width: 16 * root.s
                        height: 16 * root.s
                        name: "chevron-left"
                        color: Theme.subtle
                        stroke: 2

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4 * root.s
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentView = "main"
                        }
                    }

                    Text {
                        text: "Wi-Fi Networks"
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 14 * root.s
                        font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                ListView {
                    width: parent.width
                    height: parent.height - 32 * root.s
                    model: pill.wifiNets.slice(0, 10)
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    spacing: 2 * root.s

                    delegate: Item {
                        id: netRow
                        required property var modelData
                        required property int index
                        width: parent.width
                        height: 40 * root.s

                        Rectangle {
                            anchors.fill: parent
                            radius: 8 * root.s
                            color: netArea.containsMouse ? Qt.alpha(Theme.cream, 0.06) : "transparent"
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 10 * root.s

                            WifiGlyph {
                                width: 16 * root.s
                                height: 16 * root.s
                                level: modelData.signalStrength || 0
                                on: true
                            }

                            Text {
                                text: modelData.ssid || "Hidden"
                                color: modelData.connected ? Theme.cream : Theme.dim
                                font.family: Theme.font
                                font.pixelSize: 13 * root.s
                            }

                            Text {
                                visible: modelData.connected
                                text: "Connected"
                                color: Theme.flameGlow
                                font.family: Theme.font
                                font.pixelSize: 10 * root.s
                            }
                        }

                        MouseArea {
                            id: netArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // In full impl: connect to network
                            }
                        }
                    }
                }
            }
        }
    }
}
