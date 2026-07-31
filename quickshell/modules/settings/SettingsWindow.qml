import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.config
import qs.modules.common.widgets
import qs.modules.common.functions

/**
 * Standalone settings window.
 * Loaded on-demand via IPC: qs ipc call settings toggle
 * Provides a floating window with the same settings pages as the overlay.
 */
Scope {
    id: root

    property bool open: false
    property int currentPage: 0
    property string searchText: ""

    // Pages matching SettingsOverlay.qml overlayPages
    readonly property var pages: [
        {
            name: "Quick",
            shortName: "",
            icon: "instant_mix",
            desc: "Wallpaper & quick tweaks",
            essential: true,
            component: Quickshell.shellPath("modules/settings/QuickConfig.qml")
        },
        {
            name: "System",
            shortName: "",
            icon: "browse",
            desc: "Audio, battery, language, lock",
            essential: true,
            component: Quickshell.shellPath("modules/settings/GeneralConfig.qml")
        },
        {
            name: "Bar",
            shortName: "",
            icon: "toast",
            iconRotation: 180,
            desc: "Position, tray, modules",
            essential: true,
            component: Quickshell.shellPath("modules/settings/BarConfig.qml")
        },
        {
            name: "Background",
            shortName: "",
            icon: "texture",
            desc: "Parallax, effects, backdrop",
            essential: false,
            component: Quickshell.shellPath("modules/settings/BackgroundConfig.qml")
        },
        {
            name: "Themes",
            shortName: "",
            icon: "palette",
            desc: "Colors, fonts, styles",
            essential: true,
            component: Quickshell.shellPath("modules/settings/ThemesConfig.qml")
        },
        {
            name: "Interface",
            shortName: "",
            icon: "tune",
            desc: "Fonts, animations, rounding",
            essential: true,
            component: Quickshell.shellPath("modules/settings/InterfaceConfig.qml")
        },
        {
            name: "Services",
            shortName: "",
            icon: "account_tree",
            desc: "Mpris, notifications, tray",
            essential: false,
            component: Quickshell.shellPath("modules/settings/ServicesConfig.qml")
        },
        {
            name: "Tools",
            shortName: "",
            icon: "build",
            desc: "Scripts, commands, extras",
            essential: false,
            component: Quickshell.shellPath("modules/settings/ToolsConfig.qml")
        },
        {
            name: "Modules",
            shortName: "",
            icon: "grid_view",
            desc: "Module configuration",
            essential: false,
            component: Quickshell.shellPath("modules/settings/ModulesConfig.qml")
        },
        {
            name: "Advanced",
            shortName: "",
            icon: "shield",
            desc: "Expert settings",
            essential: false,
            component: Quickshell.shellPath("modules/settings/AdvancedConfig.qml")
        },
        {
            name: "Waffle",
            shortName: "",
            icon: "widgets",
            desc: "Waffle configuration",
            essential: false,
            component: Quickshell.shellPath("modules/settings/WaffleConfig.qml")
        },
        {
            name: "Niri",
            shortName: "",
            icon: "keyboard_arrow_right",
            desc: "Niri integration",
            essential: false,
            component: Quickshell.shellPath("modules/settings/NiriConfig.qml")
        },
        {
            name: "Desktop Widgets",
            shortName: "",
            icon: "dashboard",
            desc: "Widget configuration",
            essential: false,
            component: Quickshell.shellPath("modules/settings/DesktopWidgetsConfig.qml")
        },
        {
            name: "About",
            shortName: "",
            icon: "info",
            desc: "Version info, credits",
            essential: true,
            component: Quickshell.shellPath("modules/settings/About.qml")
        }
    ]

    function toggle(): void {
        root.open = !root.open
    }

    // Window
    Loader {
        id: windowLoader
        active: root.open

        sourceComponent: PanelWindow {
            id: settingsWindow

            visible: true
            WlrLayershell.namespace: "quickshell:settingsWindow"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            readonly property real maxCardWidth: Math.min(1100, Math.max(820, width * 0.7))
            readonly property real maxCardHeight: Math.min(840, Math.max(600, height * 0.82))

            anchors.centerIn: parent
            width: maxCardWidth
            height: maxCardHeight

            // Close on Escape
            Shortcut {
                sequences: ["Escape"]
                onActivated: root.open = false
            }

            // Scrim backdrop
            Rectangle {
                anchors.fill: parent
                color: Appearance.m3colors.m3scrim
                opacity: 0.5
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.open = false
                }
            }

            // Settings card
            Rectangle {
                id: settingsCard
                anchors.centerIn: parent
                width: parent.width * 0.9
                height: parent.height * 0.9
                radius: Appearance.rounding.windowRounding
                color: Appearance.auroraEverywhere ? "transparent"
                     : Appearance.inirEverywhere ? Appearance.inir.colLayer0
                     : Appearance.m3colors.m3background
                clip: true

                border.width: Appearance.angelEverywhere ? Appearance.angel.panelBorderWidth
                            : Appearance.inirEverywhere ? 1 : 0
                border.color: Appearance.angelEverywhere ? Appearance.angel.colPanelBorder
                            : Appearance.inirEverywhere ? Appearance.inir.colBorderMuted
                            : "transparent"

                GlassBackground {
                    anchors.fill: parent
                    z: -1
                    visible: Appearance.auroraEverywhere && !Appearance.inirEverywhere
                    screenX: settingsCard.x
                    screenY: settingsCard.y
                    screenWidth: settingsCard.width
                    screenHeight: settingsCard.height
                    fallbackColor: "transparent"
                    auroraTransparency: Appearance.angelEverywhere
                        ? Appearance.angel.panelTransparentize
                        : Appearance.aurora.overlayTransparentize
                    radius: parent.radius
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: mouse.accepted = true
                }

                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: 16
                    }
                    spacing: 0

                    // Title bar
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 12
                        spacing: 12

                        Item {
                            implicitWidth: 32
                            implicitHeight: 32

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface
                                     : Appearance.inirEverywhere ? Appearance.inir.colLayer1
                                     : Appearance.colors.colLayer1
                                border.width: 1
                                border.color: Appearance.colors.colPrimary
                            }

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "settings"
                                iconSize: 18
                                color: Appearance.colors.colPrimary
                            }
                        }

                        ColumnLayout {
                            spacing: 0
                            StyledText {
                                text: "Settings"
                                font {
                                    family: Appearance.font.family.title
                                    pixelSize: Appearance.font.pixelSize.title
                                    variableAxes: Appearance.font.variableAxes.title
                                }
                                color: Appearance.colors.colOnLayer0
                            }
                            StyledText {
                                text: SystemInfo.displayName || SystemInfo.username
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }

                        Item { Layout.fillWidth: true }

                        RippleButton {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            icon: "close"
                            iconSize: 18
                            onClicked: root.open = false
                        }
                    }

                    // Page content
                    Loader {
                        id: pageLoader
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        source: root.pages.length > 0 ? root.pages[root.currentPage].component : ""
                    }
                }
            }
        }
    }

    onOpenChanged: {
        if (!open) {
            windowLoader.active = false
        }
    }
}
