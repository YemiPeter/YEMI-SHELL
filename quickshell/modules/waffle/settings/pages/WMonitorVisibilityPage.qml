pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.settings
import qs.modules.waffle.looks
import qs.modules.waffle.settings

WSettingsPage {
    id: root
    settingsPageIndex: 11
    pageTitle: Translation.tr("Monitors")
    pageIcon: "desktop"
    pageDescription: Translation.tr("Choose which outputs show Waffle and shared shell surfaces")

    readonly property var waffleSurfaces: [
        { title: Translation.tr("Taskbar"), description: Translation.tr("Windows 11 taskbar and its hit target"), icon: "desktop", path: "waffles.bar.screenList" }
    ]
    MonitorVisibilityCore { id: core }



    component InfoBanner: Rectangle {
        property string iconName: "info"
        property string message: ""

        Layout.fillWidth: true
        Layout.leftMargin: Looks.dp(14)
        Layout.rightMargin: Looks.dp(14)
        Layout.topMargin: Looks.dp(6)
        Layout.bottomMargin: Looks.dp(6)
        implicitHeight: bannerRow.implicitHeight + Looks.dp(18)
        radius: Looks.radius.large
        color: Looks.colors.bg2Base
        border.width: 1
        border.color: Looks.colors.bg2Border

        RowLayout {
            id: bannerRow
            anchors.fill: parent
            anchors.margins: Looks.dp(9)
            spacing: Looks.dp(10)

            Rectangle {
                implicitWidth: Looks.dp(28)
                implicitHeight: Looks.dp(28)
                radius: Looks.radius.medium
                color: Qt.alpha(Looks.colors.accent, 0.12)
                Layout.alignment: Qt.AlignTop

                FluentIcon {
                    anchors.centerIn: parent
                    icon: iconName
                    implicitSize: Looks.dp(15)
                    color: Looks.colors.accent
                }
            }

            WText {
                Layout.fillWidth: true
                text: message
                font.pixelSize: Looks.font.pixelSize.small
                color: Looks.colors.fg1
                wrapMode: Text.WordWrap
                lineHeight: 1.25
            }
        }
    }

    component PresetActions: RowLayout {
        required property var paths
        Layout.fillWidth: true
        Layout.leftMargin: Looks.dp(14)
        Layout.rightMargin: Looks.dp(14)
        Layout.topMargin: Looks.dp(4)
        Layout.bottomMargin: Looks.dp(8)
        spacing: Looks.dp(8)

        WButton {
            Layout.fillWidth: true
            text: Translation.tr("Primary only")
            icon.name: "eye-off"
            onClicked: core.setPathsToPrimary(paths)
        }

        WButton {
            Layout.fillWidth: true
            text: Translation.tr("Show everywhere")
            icon.name: "eye"
            onClicked: core.setPathsToAll(paths)
        }
    }

    component SectionLabel: WText {
        Layout.fillWidth: true
        Layout.leftMargin: Looks.dp(14)
        Layout.rightMargin: Looks.dp(14)
        Layout.topMargin: Looks.dp(4)
        text: ""
        font.pixelSize: Looks.font.pixelSize.small
        font.weight: Looks.font.weight.strong
        color: Looks.colors.subfg
    }

    component MonitorInfoRow: Rectangle {
        required property var monitor
        required property int index
        readonly property string screenName: monitor?.name ?? ""
        readonly property bool primary: screenName === core.primaryScreenName()

        Layout.fillWidth: true
        Layout.leftMargin: Looks.dp(14)
        Layout.rightMargin: Looks.dp(14)
        Layout.topMargin: Looks.dp(3)
        implicitHeight: monitorRow.implicitHeight + Looks.dp(18)
        radius: Looks.radius.medium
        color: primary ? Qt.alpha(Looks.colors.accent, 0.14) : Looks.colors.bg2Base
        border.width: 1
        border.color: primary ? Looks.colors.accent : Looks.colors.bg2Border

        RowLayout {
            id: monitorRow
            anchors.fill: parent
            anchors.margins: Looks.dp(9)
            spacing: Looks.dp(10)

            Rectangle {
                implicitWidth: Looks.dp(30)
                implicitHeight: Looks.dp(30)
                radius: Looks.radius.medium
                color: primary ? Looks.colors.accent : Looks.colors.bg1
                Layout.alignment: Qt.AlignVCenter

                FluentIcon {
                    anchors.centerIn: parent
                    icon: "desktop"
                    implicitSize: Looks.dp(16)
                    color: primary ? Looks.colors.accentFg : Looks.colors.subfg
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Looks.dp(1)

                WText {
                    Layout.fillWidth: true
                    text: screenName || (Translation.tr("Monitor ") + (index + 1))
                    font.pixelSize: Looks.font.pixelSize.normal
                    font.weight: Looks.font.weight.strong
                    color: Looks.colors.fg
                    elide: Text.ElideRight
                }

                WText {
                    Layout.fillWidth: true
                    text: core.monitorResolution(monitor)
                    font.pixelSize: Looks.font.pixelSize.small
                    color: Looks.colors.subfg
                    elide: Text.ElideRight
                }
            }

            WText {
                visible: primary
                text: Translation.tr("Primary")
                font.pixelSize: Looks.font.pixelSize.small
                font.weight: Looks.font.weight.strong
                color: Looks.colors.accent
                Layout.alignment: Qt.AlignVCenter
            }

            WButton {
                visible: !primary
                text: Translation.tr("Use")
                icon.name: "checkmark"
                onClicked: if (screenName.length > 0) Config.setNestedValue("display.primaryMonitor", screenName)
            }
        }
    }

    component SurfaceVisibilityBlock: Rectangle {
        required property var surface
        readonly property bool allOutputs: core.allScreensEnabled(surface.path)
        readonly property int leadingWidth: Looks.dp(34)

        Layout.fillWidth: true
        Layout.leftMargin: Looks.dp(14)
        Layout.rightMargin: Looks.dp(14)
        Layout.topMargin: Looks.dp(5)
        implicitHeight: surfaceColumn.implicitHeight + Looks.dp(20)
        radius: Looks.radius.large
        color: Looks.colors.bg2Base
        border.width: 1
        border.color: allOutputs ? Looks.colors.bg2Border : Looks.colors.accent

        ColumnLayout {
            id: surfaceColumn
            anchors.fill: parent
            anchors.margins: Looks.dp(10)
            spacing: Looks.dp(8)

            RowLayout {
                Layout.fillWidth: true
                spacing: Looks.dp(10)

                Rectangle {
                    implicitWidth: leadingWidth
                    implicitHeight: leadingWidth
                    radius: Looks.radius.medium
                    color: allOutputs ? Looks.colors.bg1 : Looks.colors.accent
                    Layout.alignment: Qt.AlignTop

                    FluentIcon {
                        anchors.centerIn: parent
                        icon: surface.icon
                        implicitSize: Looks.dp(17)
                        color: allOutputs ? Looks.colors.subfg : Looks.colors.accentFg
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Looks.dp(2)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Looks.dp(8)

                        WText {
                            Layout.fillWidth: true
                            text: surface.title
                            font.pixelSize: Looks.font.pixelSize.normal
                            font.weight: Looks.font.weight.strong
                            color: Looks.colors.fg
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            implicitWidth: summaryText.implicitWidth + Looks.dp(16)
                            implicitHeight: summaryText.implicitHeight + Looks.dp(8)
                            radius: Looks.radius.xLarge
                            color: allOutputs ? Looks.colors.bg1 : Looks.colors.accent
                            Layout.alignment: Qt.AlignVCenter

                            WText {
                                id: summaryText
                                anchors.centerIn: parent
                                text: core.visibilitySummary(surface.path)
                                font.pixelSize: Looks.font.pixelSize.small
                                font.weight: Looks.font.weight.strong
                                color: allOutputs ? Looks.colors.fg1 : Looks.colors.accentFg
                            }
                        }
                    }

                    WText {
                        Layout.fillWidth: true
                        text: surface.description
                        font.pixelSize: Looks.font.pixelSize.small
                        color: Looks.colors.subfg
                        wrapMode: Text.WordWrap
                        lineHeight: 1.2
                    }
                }
            }

            WText {
                Layout.fillWidth: true
                Layout.leftMargin: leadingWidth + Looks.dp(10)
                text: Translation.tr("Visible on")
                font.pixelSize: Looks.font.pixelSize.small
                font.weight: Looks.font.weight.strong
                color: Looks.colors.subfg
            }

            Flow {
                Layout.fillWidth: true
                Layout.leftMargin: leadingWidth + Looks.dp(10)
                spacing: Looks.dp(5)

                WButton {
                    text: Translation.tr("All outputs")
                    icon.name: "checkmark"
                    checked: allOutputs
                    checkable: false
                    font.pixelSize: Looks.font.pixelSize.small
                    horizontalPadding: Looks.dp(10)
                    verticalPadding: Looks.dp(5)
                    onClicked: core.setSurfaceAll(surface.path)
                }

                Repeater {
                    model: core.connectedScreenNames()

                    WButton {
                        required property var modelData
                        readonly property string screenName: String(modelData ?? "")
                        text: screenName
                        icon.name: "desktop"
                        checked: core.surfaceEnabled(surface.path, screenName)
                        checkable: false
                        font.pixelSize: Looks.font.pixelSize.small
                        horizontalPadding: Looks.dp(10)
                        verticalPadding: Looks.dp(5)
                        onClicked: core.setSurfaceScreen(surface.path, screenName, !checked)
                    }
                }
            }
        }
    }

    WSettingsCard {
        title: Translation.tr("Shell visibility")
        icon: "desktop"

        InfoBanner {
            iconName: "info"
            message: Translation.tr("This page controls where Yemishell surfaces appear. It does not change monitor resolution, scale, rotation, or physical output layout.")
        }

        WSettingsDropdown {
            label: Translation.tr("Primary monitor")
            icon: "desktop"
            description: Translation.tr("Fallback output for popups when the focused monitor is unknown")
            currentValue: Config.options?.display?.primaryMonitor ?? ""
            options: core.monitorOptions()
            onSelected: newValue => Config.setNestedValue("display.primaryMonitor", newValue)
        }

        SectionLabel {
            text: Translation.tr("Connected outputs")
        }

        Repeater {
            model: Quickshell.screens
            MonitorInfoRow {
                required property var modelData
                monitor: modelData
            }
        }
    }

    WSettingsCard {
        title: Translation.tr("Waffle shell surfaces")
        icon: "desktop"

        InfoBanner {
            iconName: "apps"
            message: Translation.tr("These controls only affect the Waffle family: the Windows 11 taskbar and its activation area.")
        }

        PresetActions {
            paths: core.surfacePaths(root.waffleSurfaces)
        }

        Repeater {
            model: root.waffleSurfaces
            SurfaceVisibilityBlock {
                required property var modelData
                surface: modelData
            }
        }
    }

    WSettingsCard {
        title: Translation.tr("Shared popups and widgets")
        icon: "alert"

        InfoBanner {
            iconName: "info"
            message: Translation.tr("These surfaces are shared by both families, so the same monitor choices apply in Material and Waffle.")
        }

        PresetActions {
            paths: core.surfacePaths(core.sharedSurfaces)
        }

        Repeater {
            model: core.sharedSurfaces
            SurfaceVisibilityBlock {
                required property var modelData
                surface: modelData
            }
        }
    }
}
