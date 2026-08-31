import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell
import "../../components/effects"
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../singletons" as QsSingletons
import qs.compositor

Item {
    id: root
    property var screen
    property var barWindow

    // Screen name for PillState toggle calls
    readonly property string screenName: root.screen ? root.screen.name : ""

    // Scale factor matching PillOverlay so bar spacing and center spacer align.
    readonly property real s: screen ? (screen.height / 1080) * QsSingletons.Flags.uiScale : 1

    readonly property var config: QsConfig.Config
    readonly property var appearance: QsConfig.AppearanceConfig
    /**
     * Side-pill alpha — read from the canonical single source (Theme.pillAlpha,
     * defined in Appearance.qml) so bar and pill can never drift: Niri always
     * solid, Hyprland via the Look → Pill opacity stepper. pillBg uses
     * Theme.pillSurface (cardBotBase @ pillAlpha, alpha applied exactly once).
     */
    readonly property real pillAlpha: QsSingletons.Theme.pillAlpha
    readonly property color pillBg: QsSingletons.Theme.pillSurface
    readonly property color pillBorder: Qt.rgba(QsSingletons.Theme.cream.r, QsSingletons.Theme.cream.g, QsSingletons.Theme.cream.b, 0.10)
    readonly property color pillSeparator: Qt.rgba(QsSingletons.Theme.cream.r, QsSingletons.Theme.cream.g, QsSingletons.Theme.cream.b, 0.15)

    readonly property color highlightTop: Qt.rgba(1, 1, 1, 0.04)
    // ═══════════════════════════════════════════════════════════════════════
    // MINIMAL AESTHETIC BAR
    // Clean, professional, beautiful - inspired by modern Linux rice
    // ═══════════════════════════════════════════════════════════════════════

    // Main bar container with floating effect
    Item {
        id: barContainer
        anchors.fill: parent
        anchors.topMargin: 1 * root.s
        anchors.leftMargin: 9 * root.s
        anchors.rightMargin: 9 * root.s
        anchors.bottomMargin: 1 * root.s

        // ═══════════════════════════════════════════════════════════════
        // LEFT MODULE - Workspaces
        // ═══════════════════════════════════════════════════════════════
        Row {
            id: leftPills
            // Side-pill toggle (Flags.barLeftVisible): lets the user collapse
            // the left cluster for a single-pill layout. Opacity + width clip
            // so the bar strip itself stays put.
            visible: QsSingletons.Flags.barLeftVisible
            opacity: QsSingletons.Flags.barLeftVisible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8 * root.s

            // Workspaces pill
            Rectangle {
                id: leftModule
                height: 28 * root.s
                width: leftContent.implicitWidth + 16 * root.s
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
                    anchors.margins: 1 * root.s
                    height: parent.height / 2
                    radius: parent.radius - 1
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: highlightTop }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                RowLayout {
                    id: leftContent
                    anchors.centerIn: parent
                    spacing: 10 * root.s

                    Loader {
                        id: workspacesLoader
                        Layout.alignment: Qt.AlignVCenter
                        asynchronous: false
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
        // CENTER MODULE - Spacer (pill now lives in PillOverlay.qml)
        // ═══════════════════════════════════════════════════════════════
        Item {
            id: centerContainer
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            // Scaled spacer matching the pill's rest dimensions in PillOverlay
            width: 160 * root.s
            height: 38 * root.s
        }

        // ═══════════════════════════════════════════════════════════════
        // RIGHT SIDE - Three Separate Pills
        // ═══════════════════════════════════════════════════════════════
        Row {
            id: rightPills
            // Side-pill toggle (Flags.barRightVisible) — mirrors leftPills.
            visible: QsSingletons.Flags.barRightVisible
            opacity: QsSingletons.Flags.barRightVisible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6 * root.s

            // ═══ PILL 1: Network + Bluetooth (Connectivity) ═══
            Rectangle {
                id: connectivityPill
                height: 28 * root.s
                width: connectivityContent.implicitWidth + 16 * root.s
                radius: 14 * root.s
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
                    anchors.margins: 1 * root.s
                    height: parent.height / 2
                    radius: parent.radius - 1
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: highlightTop }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                Row {
                    id: connectivityContent
                    anchors.centerIn: parent
                    spacing: 4 * root.s

                    Loader {
                        id: networkLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: false
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
                            property: "screenName"
                            value: root.screenName
                            when: networkLoader.status === Loader.Ready
                            restoreMode: Binding.RestoreBinding
                        }
                    }

                    // Separator
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 12 * root.s
                        radius: 0.5 * root.s
                        color: pillSeparator
                    }

                    Loader {
                        id: bluetoothLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: false
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
                            property: "screenName"
                            value: root.screenName
                            when: bluetoothLoader.status === Loader.Ready
                            restoreMode: Binding.RestoreBinding
                        }
                    }
                }
            }

            // ═══ PILL 2: Brightness + Volume (Audio/Display) ═══
            Rectangle {
                id: audioPill
                height: 28 * root.s
                width: audioContent.implicitWidth + 16 * root.s
                radius: 14 * root.s
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
                    anchors.margins: 1 * root.s
                    height: parent.height / 2
                    radius: parent.radius - 1
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: highlightTop }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                Row {
                    id: audioContent
                    anchors.centerIn: parent
                    spacing: 6 * root.s

                    Loader {
                        id: brightnessLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: false
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
                            property: "screenName"
                            value: root.screenName
                            when: brightnessLoader.status === Loader.Ready
                            restoreMode: Binding.RestoreBinding
                        }
                    }

                    // Separator
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 12 * root.s
                        radius: 0.5 * root.s
                        color: pillSeparator
                    }

                    Loader {
                        id: volumeLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: false
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
                            property: "screenName"
                            value: root.screenName
                            when: volumeLoader.status === Loader.Ready
                            restoreMode: Binding.RestoreBinding
                        }
                    }
                }
            }

            // ═══ PILL 3: Battery + Tray ═══
            Rectangle {
                id: powerPill
                height: 28 * root.s
                width: powerContent.implicitWidth + 16 * root.s
                radius: 14 * root.s
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
                    anchors.margins: 1 * root.s
                    height: parent.height / 2
                    radius: parent.radius - 1
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: highlightTop }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                Row {
                    id: powerContent
                    anchors.centerIn: parent
                    spacing: 6 * root.s

                    // Status Indicators (Caffeine, DND)
                    Loader {
                        id: statusIndicatorsLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: false
                        source: "components/StatusIndicators.qml"
                        visible: item ? item.hasActiveIndicators : false
                    }

                    // Separator (only if status indicators visible)
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 12 * root.s
                        radius: 0.5 * root.s
                        color: pillSeparator
                        visible: statusIndicatorsLoader.item ? statusIndicatorsLoader.item.hasActiveIndicators : false
                    }

                    // Battery
                    Loader {
                        id: batteryLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: false
                        source: "components/Battery.qml"
                        Binding {
                            target: batteryLoader.item
                            property: "screenName"
                            value: root.screenName
                            when: batteryLoader.status === Loader.Ready
                            restoreMode: Binding.RestoreBinding
                        }
                    }

                    // System Tray (only if has items)
                    Loader {
                        id: systemTrayLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: false
                        // source: "components/SystemTray.qml"
                        visible: item ? item.hasItems : false
                    }
                }
            }
        }
    }
}