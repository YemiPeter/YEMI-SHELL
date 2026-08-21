pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks
import qs.modules.waffle.settings

WSettingsPage {
    id: root
    settingsPageIndex: 10
    pageTitle: Translation.tr("About")
    pageIcon: "info"
    pageDescription: Translation.tr("Project information and links")

    readonly property string repoDir: Quickshell.env("HOME") + "/YEMI-SHELL"
    property string version: ""

    Process {
        id: verProc
        command: ["sh", "-c", "git -C \"" + root.repoDir + "\" describe --tags --always 2>/dev/null || git -C \"" + root.repoDir + "\" log -1 --format='%h %cs' 2>/dev/null || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: root.version = (text ?? "").trim()
        }
    }

    Component.onCompleted: verProc.running = true

    // Hero card — project identity
    WSettingsCard {
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            Layout.topMargin: 8
            Layout.bottomMargin: 4
            spacing: 18
            
            Rectangle {
                implicitWidth: 72
                implicitHeight: 72
                radius: Looks.radius.xLarge
                color: Looks.colors.accent
                
                WText {
                    anchors.centerIn: parent
                    text: "YS"
                    font.pixelSize: 30
                    font.weight: Font.Bold
                    color: Looks.colors.accentFg
                }
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                WText {
                    text: "YemiShell"
                    font.pixelSize: Looks.font.pixelSize.xlarger * 1.4
                    font.weight: Looks.font.weight.stronger
                }
                
                WText {
                    text: Translation.tr("Yemishell desktop environment")
                    font.pixelSize: Looks.font.pixelSize.normal
                    color: Looks.colors.subfg
                }
                
                RowLayout {
                    spacing: 8
                    Layout.topMargin: 4
                    
                    // Version badge
                    Rectangle {
                        implicitWidth: versionLabel.implicitWidth + 16
                        implicitHeight: 24
                        radius: Looks.radius.small
                        color: Looks.colors.accent
                        
                        WText {
                            id: versionLabel
                            anchors.centerIn: parent
                            text: root.version.length ? (root.version[0] === "v" || root.version[0] === "V" ? root.version : "v" + root.version.replace(" ", " · ")) : "?"
                            font.pixelSize: Looks.font.pixelSize.small
                            font.weight: Looks.font.weight.strong
                            color: Looks.colors.accentFg
                        }
                    }
                    
                    // Compositor badge
                    Rectangle {
                        implicitWidth: compLabel.implicitWidth + 16
                        implicitHeight: 24
                        radius: Looks.radius.small
                        color: Looks.colors.bg2
                        
                        WText {
                            id: compLabel
                            anchors.centerIn: parent
                            text: "Niri · Hyprland"
                            font.pixelSize: Looks.font.pixelSize.small
                            color: Looks.colors.subfg
                        }
                    }
                    
                    // Framework badge
                    Rectangle {
                        implicitWidth: fwLabel.implicitWidth + 16
                        implicitHeight: 24
                        radius: Looks.radius.small
                        color: Looks.colors.bg2
                        
                        WText {
                            id: fwLabel
                            anchors.centerIn: parent
                            text: "Qt 6"
                            font.pixelSize: Looks.font.pixelSize.small
                            color: Looks.colors.subfg
                        }
                    }
                }
            }
        }
    }
    
    // Links
    WSettingsCard {
        title: Translation.tr("Links")
        icon: "open"
        
        WSettingsButton {
            label: Translation.tr("GitHub Repository")
            description: "github.com/YemiPeter/YEMI-SHELL"
            icon: "globe-search"
            buttonText: Translation.tr("Open")
            onButtonClicked: Qt.openUrlExternally("https://github.com/YemiPeter/YEMI-SHELL")
        }

        WSettingsButton {
            label: Translation.tr("Documentation")
            description: "github.com/YemiPeter/YEMI-SHELL"
            icon: "library"
            buttonText: Translation.tr("Open")
            onButtonClicked: Qt.openUrlExternally("https://github.com/YemiPeter/YEMI-SHELL")
        }
        
        WSettingsButton {
            label: Translation.tr("Quickshell Documentation")
            description: "quickshell.outfoxxed.me"
            icon: "globe-search"
            buttonText: Translation.tr("Open")
            onButtonClicked: Qt.openUrlExternally("https://quickshell.outfoxxed.me")
        }
    }
    
    // Credits
    WSettingsCard {
        title: Translation.tr("Credits")
        icon: "people"
        
        WSettingsButton {
            label: Translation.tr("Ricelin")
            description: "github.com/Gakuseei/Ricelin"
            icon: "open"
            buttonText: Translation.tr("Open")
            onButtonClicked: Qt.openUrlExternally("https://github.com/Gakuseei/Ricelin")
        }
        WSettingsButton {
            label: Translation.tr("iNiR (Yemi's Niri rice)")
            description: "github.com/YemiPeter/iNiR"
            icon: "open"
            buttonText: Translation.tr("Open")
            onButtonClicked: Qt.openUrlExternally("https://github.com/YemiPeter/iNiR")
        }
        WSettingsButton {
            label: Translation.tr("qylock")
            description: "github.com/Darkkal44/qylock"
            icon: "open"
            buttonText: Translation.tr("Open")
            onButtonClicked: Qt.openUrlExternally("https://github.com/Darkkal44/qylock")
        }
        WSettingsButton {
            label: Translation.tr("skwd-wall")
            description: "github.com/liixini/skwd-wall"
            icon: "open"
            buttonText: Translation.tr("Open")
            onButtonClicked: Qt.openUrlExternally("https://github.com/liixini/skwd-wall")
        }
        WSettingsButton {
            label: Translation.tr("quickshell (YemiPeter)")
            description: "github.com/YemiPeter/quickshell"
            icon: "open"
            buttonText: Translation.tr("Open")
            onButtonClicked: Qt.openUrlExternally("https://github.com/YemiPeter/quickshell")
        }
        WSettingsButton {
            label: Translation.tr("quickshell (tripathiji)")
            description: "github.com/tripathiji1312/quickshell"
            icon: "open"
            buttonText: Translation.tr("Open")
            onButtonClicked: Qt.openUrlExternally("https://github.com/tripathiji1312/quickshell")
        }
    }
    
    // System Info
    WSettingsCard {
        title: Translation.tr("System Info")
        icon: "info"
        
        WSettingsRow {
            label: Translation.tr("Config path")
            description: FileUtils.trimFileProtocol(Directories.config)
            icon: "folder"
        }
        
        WSettingsRow {
            label: Translation.tr("Shell path")
            description: FileUtils.trimFileProtocol(root.repoDir)
            icon: "folder"
        }
        
        WSettingsRow {
            label: Translation.tr("Panel family")
            description: Config.options?.panelFamily === "waffle" ? "Waffle (Windows 11)" : "Pill (impulse)"
            icon: "app-generic"
        }
    }
}
