pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import "Singletons"

/**
 * ABOUT sub-surface (Pill face). Mirrors the Waffle About: a YemiShell identity
 * hero, source links, full credits to the projects it was copied from, and system
 * info. Styled like the Pill Appearance/Looks sections — hairline dividers
 * between rows, NO solid section cards (the monitor page's card look was dropped
 * per the settings convention). Reached from the settings index; morphs back on
 * the header strip.
 */
SettingsSurface {
    id: root

    backSurface: "settings"
    clip: true
    rows: []

    readonly property string repoDir: Quickshell.env("HOME") + "/YEMI-SHELL"
    property string version: ""

    Process {
        id: verProc
        command: ["sh", "-c",
            "git -C \"" + root.repoDir + "\" describe --tags --always 2>/dev/null" +
            " || git -C \"" + root.repoDir + "\" log -1 --format='%h' 2>/dev/null" +
            " || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: root.version = (text ?? "").trim()
        }
    }

    Component.onCompleted: verProc.running = true

    function openUrl(u) { Qt.openUrlExternally(u) }

    readonly property string versionLabel: root.version.length > 0
        ? (root.version[0] === "v" || root.version[0] === "V" ? root.version : "v" + root.version)
        : "?"

    component Badge: Rectangle {
        property string text: ""
        property bool accent: false
        height: 20 * root.s
        radius: 6 * root.s
        color: accent ? Theme.vermLit : Theme.tileBg
        border.width: accent ? 0 : 1
        border.color: Theme.hairSoft
        implicitWidth: bTxt.implicitWidth + 12 * root.s
        Text {
            id: bTxt
            anchors.centerIn: parent
            text: parent.text
            color: accent ? Theme.cream : Theme.subtle
            font.family: Theme.font
            font.pixelSize: 9.5 * root.s
            font.weight: Font.DemiBold
        }
    }

    component GroupLabel: Text {
        color: Theme.faint
        font.family: Theme.font
        font.pixelSize: 8.5 * root.s
        font.weight: Font.Bold
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1.2 * root.s
        anchors.left: parent.left
        anchors.leftMargin: 12 * root.s
        topPadding: 14 * root.s
        bottomPadding: 6 * root.s
    }

    component Divider: Rectangle {
        width: parent.width - 24 * root.s
        height: 1
        anchors.horizontalCenter: parent.horizontalCenter
        color: Theme.hairSoft
    }

    component LinkRow: Item {
        property string icon: ""
        property string name: ""
        property string sub: ""
        property string url: ""
        width: parent.width
        height: lrInner.implicitHeight + 14 * root.s

        Rectangle {
            anchors.fill: parent
            anchors.margins: -2 * root.s
            radius: 9 * root.s
            color: lrArea.containsMouse ? Theme.frameBg : "transparent"
            Behavior on color { ColorAnimation { duration: Motion.fast } }
        }

        Row {
            id: lrInner
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 12 * root.s
            anchors.rightMargin: 12 * root.s
            spacing: 11 * root.s

            GlyphIcon {
                width: 16 * root.s
                height: 16 * root.s
                name: icon
                color: lrArea.containsMouse ? Theme.cream : Theme.subtle
                stroke: 1.8
                anchors.verticalCenter: parent.verticalCenter
            }
            Column {
                width: parent.width - 16 * root.s - 11 * root.s - 16 * root.s
                spacing: 1 * root.s
                Text {
                    text: name
                    color: Theme.cream
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                    font.weight: Font.DemiBold
                }
                Text {
                    width: parent.width
                    text: sub
                    color: Theme.faint
                    font.family: Theme.font
                    font.pixelSize: 10 * root.s
                    elide: Text.ElideRight
                }
            }
            GlyphIcon {
                width: 15 * root.s
                height: 15 * root.s
                name: "chevron-right"
                color: Theme.iconDim
                stroke: 2
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: lrArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openUrl(url)
        }
    }

    component InfoRow: Item {
        property string name: ""
        property string value: ""
        property bool last: false
        width: parent.width
        height: irCol.implicitHeight + 12 * root.s

        Column {
            id: irCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 12 * root.s
            anchors.rightMargin: 12 * root.s
            spacing: 1 * root.s
            Text {
                text: name
                color: Theme.subtle
                font.family: Theme.font
                font.pixelSize: 11 * root.s
                font.weight: Font.DemiBold
            }
            Text {
                width: parent.width
                text: value
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 10.5 * root.s
                elide: Text.ElideMiddle
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Theme.hairSoft
            visible: !last
        }
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true

        Column {
            id: content
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0

            SettingsHeader {
                s: root.s
                title: "ABOUT"
                showBack: true
            }

            Item { width: 1; height: 14 * root.s }

            // Hero — YemiShell identity (no solid card)
            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 12 * root.s
                anchors.rightMargin: 12 * root.s
                spacing: 12 * root.s

                Rectangle {
                    width: 50 * root.s
                    height: 50 * root.s
                    radius: 14 * root.s
                    color: Theme.vermLit
                    Text {
                        anchors.centerIn: parent
                        text: "Y"
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 26 * root.s
                        font.weight: Font.Bold
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3 * root.s
                    Text {
                        text: "YemiShell"
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 16 * root.s
                        font.weight: Font.Bold
                    }
                    Text {
                        text: "Yemishell desktop environment"
                        color: Theme.subtle
                        font.family: Theme.font
                        font.pixelSize: 10.5 * root.s
                    }
                    Row {
                        spacing: 6 * root.s
                        Badge { text: root.versionLabel; accent: true }
                        Badge { text: "Niri · Hyprland" }
                        Badge { text: "Qt 6" }
                    }
                }
            }

            Item { width: 1; height: 12 * root.s }
            Divider { }
            Item { width: 1; height: 4 * root.s }

            GroupLabel { text: "LINKS" }

            LinkRow {
                icon: "app-window"
                name: "GitHub Repository"
                sub: "github.com/YemiPeter/YEMI-SHELL"
                url: "https://github.com/YemiPeter/YEMI-SHELL"
            }
            LinkRow {
                icon: "language"
                name: "Documentation"
                sub: "github.com/YemiPeter/YEMI-SHELL"
                url: "https://github.com/YemiPeter/YEMI-SHELL"
            }
            LinkRow {
                icon: "download"
                name: "Quickshell Documentation"
                sub: "quickshell.outfoxxed.me"
                url: "https://quickshell.outfoxxed.me"
            }

            Divider { }
            Item { width: 1; height: 4 * root.s }

            GroupLabel { text: "CREDITS" }

            LinkRow {
                icon: "sparkles"
                name: "Ricelin"
                sub: "github.com/Gakuseei/Ricelin"
                url: "https://github.com/Gakuseei/Ricelin"
            }
            LinkRow {
                icon: "monitor"
                name: "iNiR (Yemi's Niri rice)"
                sub: "github.com/YemiPeter/iNiR"
                url: "https://github.com/YemiPeter/iNiR"
            }
            LinkRow {
                icon: "lock"
                name: "qylock"
                sub: "github.com/Darkkal44/qylock"
                url: "https://github.com/Darkkal44/qylock"
            }
            LinkRow {
                icon: "app-window"
                name: "skwd-wall"
                sub: "github.com/liixini/skwd-wall"
                url: "https://github.com/liixini/skwd-wall"
            }
            LinkRow {
                icon: "download"
                name: "quickshell (YemiPeter)"
                sub: "github.com/YemiPeter/quickshell"
                url: "https://github.com/YemiPeter/quickshell"
            }
            LinkRow {
                icon: "download"
                name: "quickshell (tripathiji)"
                sub: "github.com/tripathiji1312/quickshell"
                url: "https://github.com/tripathiji1312/quickshell"
            }

            Divider { }
            Item { width: 1; height: 4 * root.s }

            GroupLabel { text: "SYSTEM" }

            InfoRow {
                name: "Config path"
                value: FileUtils.trimFileProtocol(Directories.config)
            }
            InfoRow {
                name: "Shell path"
                value: FileUtils.trimFileProtocol(root.repoDir)
            }
            InfoRow {
                name: "Panel family"
                value: Config.options?.panelFamily === "waffle" ? "Waffle (Windows 11)" : "Pill (impulse)"
                last: true
            }

            Item { width: 1; height: 8 * root.s }
        }
    }
}
