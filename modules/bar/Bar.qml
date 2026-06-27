import Quickshell
import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
// import "components" as BarComponents // dead import — components loaded via Loader, never referenced
import "../../components/effects"
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../singletons" as QsSingletons
import "../pill" as Pill

Item {
    id: root
    property var screen
    property var barWindow
    property var bluetoothPopup
    property var networkPopup
    property var volumePopup
    property var brightnessPopup

    readonly property var config: QsConfig.Config
    readonly property var appearance: QsConfig.AppearanceConfig
    readonly property color pillBg: Qt.rgba(QsSingletons.Theme.cardBot.r, QsSingletons.Theme.cardBot.g, QsSingletons.Theme.cardBot.b, 0.7)
    readonly property color pillBorder: Qt.rgba(QsSingletons.Theme.cream.r, QsSingletons.Theme.cream.g, QsSingletons.Theme.cream.b, 0.10)
    readonly property color pillSeparator: Qt.rgba(QsSingletons.Theme.cream.r, QsSingletons.Theme.cream.g, QsSingletons.Theme.cream.b, 0.15)

    // ═══════════════════════════════════════════════════════════════════════
    // MINIMAL AESTHETIC BAR
    // Clean, professional, beautiful - inspired by modern Linux rice
    // ═══════════════════════════════════════════════════════════════════════

    // Main bar container with floating effect
    Item {
        id: barContainer
        anchors.fill: parent
        anchors.topMargin: 1
        anchors.leftMargin: 9
        anchors.rightMargin: 9
        anchors.bottomMargin: 1

        // ═══════════════════════════════════════════════════════════════
        // LEFT MODULE - Workspaces
        // ═══════════════════════════════════════════════════════════════
        Row {
            id: leftPills
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Workspaces pill
            Rectangle {
                id: leftModule
                height: 28
                width: leftContent.implicitWidth + 16
                radius: 14
                color: pillBg
                border.width: 1
                border.color: pillBorder

                Behavior on width {
                    NumberAnimation {
                        duration: 350;
                        easing.bezierCurve: [0.34, 1.56, 0.64, 1]
                    }
                }

                // Top highlight
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 1
                    height: parent.height / 2
                    radius: parent.radius - 1
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.04) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                RowLayout {
                    id: leftContent
                    anchors.centerIn: parent
                    spacing: 10

                    Loader {
                        id: workspacesLoader
                        Layout.alignment: Qt.AlignVCenter
                        asynchronous: true
                        source: "components/Workspaces.qml"
                        Binding {
                            target: workspacesLoader.item
                            property: "screen"
                            value: root.screen
                            when: workspacesLoader.status === Loader.Ready && root.screen !== undefined
                            restoreMode: Binding.RestoreBinding
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════
        // CENTER MODULE - Pill (Morphing Launcher)
        // ═══════════════════════════════════════════════════════════════
        Item {
            id: centerContainer
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: pill ? pill.implicitWidth : 0
            height: pill ? pill.implicitHeight : 0
        
            // Hover detection for the pill
            HoverHandler {
                id: pillHover
                onHoveredChanged: {
                    if (pill && pill.hovered !== hovered)
                        pill.hovered = hovered;
                }
            }
        
            Pill.Pill {
                id: pill
                screenName: root.screen?.name || ""
                barWindow: root.barWindow
                surface: ""
                s: 1
                anchors.centerIn: parent
            }
        }

        // ═══════════════════════════════════════════════════════════════
        // RIGHT SIDE - Three Separate Pills
        // ═══════════════════════════════════════════════════════════════
        Row {
            id: rightPills
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // ═══ PILL 1: Network + Bluetooth (Connectivity) ═══
            Rectangle {
                id: connectivityPill
                height: 28
                width: connectivityContent.implicitWidth + 16
                radius: 14
                color: pillBg
                border.width: 1
                border.color: pillBorder

                Behavior on width {
                    NumberAnimation {
                        duration: 250;
                        easing.type: Easing.OutCubic
                    }
                }

                // Highlight
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 1
                    height: parent.height / 2
                    radius: parent.radius - 1
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.04) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                Row {
                    id: connectivityContent
                    anchors.centerIn: parent
                    spacing: 4

                    Loader {
                        id: networkLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Network.qml"
                        Binding {
                            target: networkLoader.item
                            property: "barWindow"
                            value: root.barWindow
                            when: networkLoader.status === Loader.Ready && root.barWindow !== undefined
                            restoreMode: Binding.RestoreBinding
                        }
                        Binding {
                            target: networkLoader.item
                            property: "networkPopup"
                            value: root.networkPopup
                            when: networkLoader.status === Loader.Ready && root.networkPopup !== undefined
                            restoreMode: Binding.RestoreBinding
                        }
                    }

                    // Separator
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 12
                        radius: 0.5
                        color: pillSeparator
                    }

                    Loader {
                        id: bluetoothLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Bluetooth.qml"
                        Binding {
                            target: bluetoothLoader.item
                            property: "barWindow"
                            value: root.barWindow
                            when: bluetoothLoader.status === Loader.Ready && root.barWindow !== undefined
                            restoreMode: Binding.RestoreBinding
                        }
                        Binding {
                            target: bluetoothLoader.item
                            property: "bluetoothPopup"
                            value: root.bluetoothPopup
                            when: bluetoothLoader.status === Loader.Ready && root.bluetoothPopup !== undefined
                            restoreMode: Binding.RestoreBinding
                        }
                    }
                }
            }

            // ═══ PILL 2: Brightness + Volume (Audio/Display) ═══
            Rectangle {
                id: audioPill
                height: 28
                width: audioContent.implicitWidth + 16
                radius: 14
                color: pillBg
                border.width: 1
                border.color: pillBorder

                Behavior on width {
                    NumberAnimation {
                        duration: 250;
                        easing.type: Easing.OutCubic
                    }
                }

                // Highlight
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 1
                    height: parent.height / 2
                    radius: parent.radius - 1
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.04) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                Row {
                    id: audioContent
                    anchors.centerIn: parent
                    spacing: 6

                    Loader {
                        id: brightnessLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Brightness.qml"
                        Binding {
                            target: brightnessLoader.item
                            property: "barWindow"
                            value: root.barWindow
                            when: brightnessLoader.status === Loader.Ready && root.barWindow !== undefined
                            restoreMode: Binding.RestoreBinding
                        }
                        Binding {
                            target: brightnessLoader.item
                            property: "brightnessPopup"
                            value: root.brightnessPopup
                            when: brightnessLoader.status === Loader.Ready && root.brightnessPopup !== undefined
                            restoreMode: Binding.RestoreBinding
                        }
                    }

                    // Separator
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 12
                        radius: 0.5
                        color: pillSeparator
                    }

                    Loader {
                        id: volumeLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Volume.qml"
                        Binding {
                            target: volumeLoader.item
                            property: "barWindow"
                            value: root.barWindow
                            when: volumeLoader.status === Loader.Ready && root.barWindow !== undefined
                            restoreMode: Binding.RestoreBinding
                        }
                        Binding {
                            target: volumeLoader.item
                            property: "volumePopup"
                            value: root.volumePopup
                            when: volumeLoader.status === Loader.Ready && root.volumePopup !== undefined
                            restoreMode: Binding.RestoreBinding
                        }
                    }
                }
            }

            // ═══ PILL 3: Battery + Tray ═══
            Rectangle {
                id: powerPill
                height: 28
                width: powerContent.implicitWidth + 16
                radius: 14
                color: pillBg
                border.width: 1
                border.color: pillBorder

                Behavior on width {
                    NumberAnimation {
                        duration: 250;
                        easing.type: Easing.OutCubic
                    }
                }

                // Highlight
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 1
                    height: parent.height / 2
                    radius: parent.radius - 1
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.04) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                Row {
                    id: powerContent
                    anchors.centerIn: parent
                    spacing: 6

                    // Status Indicators (Caffeine, DND)
                    Loader {
                        id: statusIndicatorsLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/StatusIndicators.qml"
                        visible: item?.hasActiveIndicators ?? false
                    }

                    // Separator (only if status indicators visible)
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 12
                        radius: 0.5
                        color: pillSeparator
                        visible: statusIndicatorsLoader.item?.hasActiveIndicators ?? false
                    }

                    // Battery
                    Loader {
                        id: batteryLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Battery.qml"
                    }

                    // Separator
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 12
                        radius: 0.5
                        color: pillSeparator
                    }

                    // System Tray (only if has items)
                    Loader {
                        id: systemTrayLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/SystemTray.qml"
                        visible: item?.hasItems ?? false
                    }
                }
            }
        }
    }
}
