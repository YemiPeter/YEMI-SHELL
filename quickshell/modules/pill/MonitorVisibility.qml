pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.settings
import "Singletons"

/**
 * MONITOR VISIBILITY sub-surface (Pill face). The logic is the shared
 * MonitorVisibilityCore; this file is only the Pill skin. It mirrors the Waffle
 * Monitors page: a Shell-visibility card (intro, primary-monitor picker,
 * connected outputs) and a Shared-popups card (per-surface output toggles).
 *
 * The Waffle-only Taskbar card is intentionally omitted here — Pill has no
 * taskbar, and the two families must never borrow each other's panels.
 *
 * Reached from the settings index; morphs back on the header strip.
 */
SettingsSurface {
    id: root

    backSurface: "settings"
    implicitHeight: content.implicitHeight
    rows: []

    MonitorVisibilityCore { id: core }

    function pillIconFor(path) {
        if (path.indexOf("notifications") >= 0) return "inbox";
        if (path.indexOf("osd") >= 0) return "speaker";
        if (path.indexOf("widgets") >= 0) return "sparkles";
        return "monitor";
    }

    component PillBtn: Rectangle {
        property string label: ""
        property bool active: false
        signal activate()
        radius: 9 * root.s
        height: 28 * root.s
        implicitWidth: btnLabel.implicitWidth + 18 * root.s
        color: active ? Theme.verm : (btnArea.containsMouse ? Theme.frameBg : Theme.tileBg)
        border.width: 1
        border.color: active ? Theme.vermLit : Theme.hairSoft
        Behavior on color { ColorAnimation { duration: Motion.fast } }
        Behavior on border.color { ColorAnimation { duration: Motion.fast } }
        Text {
            id: btnLabel
            anchors.centerIn: parent
            text: label
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 10.5 * root.s
            font.weight: Font.DemiBold
        }
        MouseArea {
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.activate()
        }
    }

    component InfoBanner: Rectangle {
        property string iconName: "monitor"
        property string message: ""
        width: parent.width
        radius: Motion.rTile * root.s
        color: Theme.cardTop
        border.width: 1
        border.color: Theme.hairSoft
        implicitHeight: ibRow.implicitHeight + 18 * root.s
        Row {
            id: ibRow
            anchors.fill: parent
            anchors.margins: 11 * root.s
            spacing: 10 * root.s
            Rectangle {
                width: 26 * root.s
                height: 26 * root.s
                radius: 7 * root.s
                color: Qt.alpha(Theme.vermLit, 0.12)
                GlyphIcon {
                    anchors.centerIn: parent
                    width: 14 * root.s
                    height: 14 * root.s
                    name: iconName
                    color: Theme.vermLit
                    stroke: 1.8
                }
            }
            Text {
                width: parent.width - 36 * root.s
                text: message
                color: Theme.faint
                font.family: Theme.font
                font.pixelSize: 10.5 * root.s
                wrapMode: Text.WordWrap
                lineHeight: 1.25
            }
        }
    }

    component MonitorInfoRow: Rectangle {
        required property var monitor
        required property int index
        readonly property string screenName: monitor?.name ?? ""
        readonly property bool primary: screenName === core.primaryScreenName()
        width: parent.width
        radius: Motion.rTile * root.s
        color: primary ? Qt.alpha(Theme.vermLit, 0.14) : Theme.cardTop
        border.width: 1
        border.color: primary ? Theme.vermLit : Theme.hairSoft
        implicitHeight: miRow.implicitHeight + 16 * root.s
        Row {
            id: miRow
            anchors.fill: parent
            anchors.margins: 9 * root.s
            spacing: 10 * root.s
            Rectangle {
                width: 28 * root.s
                height: 28 * root.s
                radius: 7 * root.s
                color: primary ? Theme.vermLit : Theme.tileBg
                GlyphIcon {
                    anchors.centerIn: parent
                    width: 15 * root.s
                    height: 15 * root.s
                    name: "monitor"
                    color: primary ? Theme.cream : Theme.subtle
                    stroke: 1.8
                }
            }
            Column {
                width: parent.width - 28 * root.s - 10 * root.s - 70 * root.s
                spacing: 1 * root.s
                Text {
                    width: parent.width
                    text: screenName || ("Monitor " + (index + 1))
                    color: Theme.cream
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: core.monitorResolution(monitor)
                    color: Theme.subtle
                    font.family: Theme.font
                    font.pixelSize: 10 * root.s
                    elide: Text.ElideRight
                }
            }
            Item {
                width: 64 * root.s
                height: 28 * root.s
                Text {
                    visible: primary
                    anchors.centerIn: parent
                    text: "Primary"
                    color: Theme.vermLit
                    font.family: Theme.font
                    font.pixelSize: 10 * root.s
                    font.weight: Font.Bold
                }
                PillBtn {
                    visible: !primary
                    label: "Use"
                    onActivate: Config.setNestedValue("display.primaryMonitor", screenName)
                }
            }
        }
    }

    component SurfaceBlock: Rectangle {
        required property var surface
        readonly property bool allOutputs: core.allScreensEnabled(surface.path)
        width: parent.width
        radius: Motion.rTile * root.s
        color: Theme.cardTop
        border.width: 1
        border.color: allOutputs ? Theme.hairSoft : Theme.vermLit
        implicitHeight: blockCol.implicitHeight + 20 * root.s
        Column {
            id: blockCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 11 * root.s
            spacing: 8 * root.s
            Row {
                width: parent.width
                spacing: 8 * root.s
                Rectangle {
                    width: 30 * root.s
                    height: 30 * root.s
                    radius: 8 * root.s
                    color: allOutputs ? Theme.tileBg : Theme.vermLit
                    GlyphIcon {
                        anchors.centerIn: parent
                        width: 16 * root.s
                        height: 16 * root.s
                        name: root.pillIconFor(surface.path)
                        color: allOutputs ? Theme.subtle : Theme.cream
                        stroke: 1.8
                    }
                }
                Column {
                    width: parent.width - 30 * root.s - 8 * root.s
                    spacing: 3 * root.s
                    Row {
                        width: parent.width
                        spacing: 8 * root.s
                        Text {
                            width: parent.width - sumChip.implicitWidth - 8 * root.s
                            text: surface.title
                            color: Theme.cream
                            font.family: Theme.font
                            font.pixelSize: 12 * root.s
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        Rectangle {
                            id: sumChip
                            implicitWidth: sumT.implicitWidth + 16 * root.s
                            implicitHeight: sumT.implicitHeight + 8 * root.s
                            radius: 14 * root.s
                            color: allOutputs ? Theme.tileBg : Theme.vermLit
                            Text {
                                id: sumT
                                anchors.centerIn: parent
                                text: core.visibilitySummary(surface.path)
                                color: allOutputs ? Theme.faint : Theme.cream
                                font.family: Theme.font
                                font.pixelSize: 9.5 * root.s
                                font.weight: Font.Bold
                            }
                        }
                    }
                    Text {
                        width: parent.width
                        text: surface.description
                        color: Theme.subtle
                        font.family: Theme.font
                        font.pixelSize: 10 * root.s
                        wrapMode: Text.WordWrap
                        lineHeight: 1.2
                    }
                }
            }
            Text {
                width: parent.width
                text: "VISIBLE ON"
                color: Theme.subtle
                font.family: Theme.font
                font.pixelSize: 9.5 * root.s
                font.weight: Font.Bold
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1.2 * root.s
            }
            Flow {
                width: parent.width
                spacing: 5 * root.s
                PillBtn {
                    label: "All outputs"
                    active: allOutputs
                    onActivate: core.setSurfaceAll(surface.path)
                }
                Repeater {
                    model: core.connectedScreenNames()
                    PillBtn {
                        required property var modelData
                        readonly property string sn: String(modelData ?? "")
                        label: sn
                        active: core.surfaceEnabled(surface.path, sn)
                        onActivate: core.setSurfaceScreen(surface.path, sn, !active)
                    }
                }
            }
        }
    }

    Column {
        id: content
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        SettingsHeader {
            s: root.s
            title: "MONITORS"
            showBack: true
        }

        Item { width: 1; height: 12 * root.s }

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12 * root.s
            anchors.rightMargin: 12 * root.s
            spacing: 12 * root.s

            Rectangle {
                width: parent.width
                radius: Motion.rTile * root.s
                color: Theme.cardTop
                border.width: 1
                border.color: Theme.hairSoft
                implicitHeight: cv1.implicitHeight + 22 * root.s
                Column {
                    id: cv1
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 13 * root.s
                    anchors.rightMargin: 13 * root.s
                    anchors.topMargin: 11 * root.s
                    spacing: 9 * root.s

                    InfoBanner {
                        iconName: "monitor"
                        message: "This page controls where Yemishell surfaces appear. It does not change monitor resolution, scale, rotation, or physical output layout."
                    }

                    Row {
                        width: parent.width
                        spacing: 12 * root.s
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 110 * root.s
                            text: "Primary monitor"
                            color: Theme.cream
                            font.family: Theme.font
                            font.pixelSize: 12 * root.s
                            font.weight: Font.DemiBold
                        }
                        SettingsSeg {
                            anchors.verticalCenter: parent.verticalCenter
                            s: root.s
                            options: core.monitorOptions().map(function (o) { return { label: o.displayName, value: o.value }; })
                            value: Config.options?.display?.primaryMonitor ?? ""
                            onPicked: function (v) { Config.setNestedValue("display.primaryMonitor", v); }
                        }
                    }

                    Text {
                        width: parent.width
                        text: "CONNECTED OUTPUTS"
                        color: Theme.subtle
                        font.family: Theme.font
                        font.pixelSize: 9.5 * root.s
                        font.weight: Font.Bold
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1.2 * root.s
                    }

                    Repeater {
                        model: Quickshell.screens
                        MonitorInfoRow {
                            required property var modelData
                            monitor: modelData
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                radius: Motion.rTile * root.s
                color: Theme.cardTop
                border.width: 1
                border.color: Theme.hairSoft
                implicitHeight: cv2.implicitHeight + 22 * root.s
                Column {
                    id: cv2
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 13 * root.s
                    anchors.rightMargin: 13 * root.s
                    anchors.topMargin: 11 * root.s
                    spacing: 10 * root.s

                    InfoBanner {
                        iconName: "sparkles"
                        message: "These surfaces are shared by both families, so the same monitor choices apply in Material and Waffle."
                    }

                    Row {
                        width: parent.width
                        spacing: 8 * root.s
                        PillBtn {
                            width: (parent.width - 8 * root.s) / 2
                            label: "Primary only"
                            onActivate: core.setPathsToPrimary(core.surfacePaths(core.sharedSurfaces))
                        }
                        PillBtn {
                            width: (parent.width - 8 * root.s) / 2
                            label: "Show everywhere"
                            onActivate: core.setPathsToAll(core.surfacePaths(core.sharedSurfaces))
                        }
                    }

                    Repeater {
                        model: core.sharedSurfaces
                        SurfaceBlock {
                            required property var modelData
                            surface: modelData
                        }
                    }
                }
            }

            Item { width: 1; height: 4 * root.s }
        }
    }
}
