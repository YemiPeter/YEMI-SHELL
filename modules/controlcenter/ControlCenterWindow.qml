import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Bluetooth
import "../../services" as QsServices
import "../../singletons" as QsSingletons
import "../../config" as QsConfig
import "../../components/effects"
import "components"

PanelWindow {
    id: root
    
    // Services
    readonly property var logger: QsServices.Logger
    readonly property var config: QsConfig.Config
    readonly property var network: QsServices.Network
    readonly property var bluetooth: QsServices.Bluetooth
    readonly property var audio: QsServices.Audio
    readonly property var brightness: QsServices.Brightness
    readonly property var mpris: QsServices.Players
    readonly property var notifs: QsServices.Notifs
    readonly property var systemUsage: QsServices.SystemUsage
    readonly property var powerProfiles: QsServices.PowerProfiles
    readonly property var screenshot: QsServices.Screenshot
    readonly property var idleInhibitor: QsServices.IdleInhibitor
    readonly property var hyprsunset: QsServices.Hyprsunset

    // Process launchers for header buttons
    Process {
        id: settingsProcess
        command: ["nm-connection-editor"]
        onStarted: root.shouldShow = false
    }

    Process {
        id: lockProcess
        command: ["loginctl", "lock-session"]
        onStarted: root.shouldShow = false
    }

    Process {
        id: powerProcess
        command: ["wlogout"]
        onStarted: root.shouldShow = false
    }
    
    // Solid UI Color Tokens - Professional dark theme
    readonly property color cSurface: QsSingletons.Theme.cardBot
    readonly property color cSurfaceContainer: QsSingletons.Theme.cardTop
    readonly property color cSurfaceContainerHigh: Qt.lighter(QsSingletons.Theme.cardBot, 1.25)
    readonly property color cBorder: Qt.rgba(QsSingletons.Theme.cream.r, QsSingletons.Theme.cream.g, QsSingletons.Theme.cream.b, 0.08)
    readonly property color cPrimary: QsSingletons.Theme.onGlow
    readonly property color cSecondary: QsSingletons.Theme.verm
    readonly property color cOnSurface: QsSingletons.Theme.cream
    readonly property color cOnSurfaceVariant: Qt.rgba(QsSingletons.Theme.cream.r, QsSingletons.Theme.cream.g, QsSingletons.Theme.cream.b, 0.7)
    readonly property color cOnSurfaceDim: Qt.rgba(QsSingletons.Theme.cream.r, QsSingletons.Theme.cream.g, QsSingletons.Theme.cream.b, 0.5)
    
    screen: Quickshell.screens[0]
    
    anchors {
        top: true
        right: true
    }
    
    margins {
        right: 12
        top: 12
    }
    
    implicitWidth: 420
    implicitHeight: Math.min(860, screen.height - 40)
    color: "transparent"
    visible: shouldShow || panelContent.opacity > 0
    
    property bool shouldShow: false
    
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    
    // Main Panel Container
    FocusScope {
        id: panelContent
        anchors.fill: parent
        
        transformOrigin: Item.TopRight
        scale: 0.94
        opacity: 0
        
        focus: true
        
        Keys.onEscapePressed: root.shouldShow = false
        
        // Track if mouse has entered at least once
        property bool mouseHasEntered: false
        property bool mouseInside: hoverHandler.hovered
        
        // Reset when panel opens/closes
        Connections {
            target: root
            function onShouldShowChanged() {
                if (root.shouldShow) {
                    panelContent.mouseHasEntered = false
                    closeTimer.stop()
                }
            }
        }
        
        // Timer to delay close
        Timer {
            id: closeTimer
            interval: 400
            onTriggered: {
                if (!panelContent.mouseInside && panelContent.mouseHasEntered && root.shouldShow) {
                    root.shouldShow = false
                }
            }
        }
        
        // HoverHandler works regardless of child item stacking
        HoverHandler {
            id: hoverHandler
            onHoveredChanged: {
                if (hovered) {
                    panelContent.mouseHasEntered = true
                    closeTimer.stop()
                } else if (panelContent.mouseHasEntered && root.shouldShow) {
                    closeTimer.restart()
                }
            }
        }
        
        onVisibleChanged: {
            if (visible) forceActiveFocus()
        }
        
        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: root.shouldShow = false
        }
        
        // Show Animation - Material 3 emphasized decelerate
        SequentialAnimation {
            running: root.shouldShow
            ParallelAnimation {
                NumberAnimation { 
                    target: panelContent
                    property: "scale"
                    from: 0.94
                    to: 1.0
                    duration: Material3Anim.medium2
                    easing.bezierCurve: Material3Anim.emphasizedDecelerate
                }
                NumberAnimation { 
                    target: panelContent
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Material3Anim.medium1
                    easing.bezierCurve: Material3Anim.standard
                }
            }
        }
        
        // Hide Animation - Material 3 emphasized accelerate
        ParallelAnimation {
            running: !root.shouldShow && panelContent.opacity > 0
            NumberAnimation { 
                target: panelContent
                property: "scale"
                to: 0.94
                duration: Material3Anim.short4
                easing.bezierCurve: Material3Anim.emphasizedAccelerate
            }
            NumberAnimation { 
                target: panelContent
                property: "opacity"
                to: 0
                duration: Material3Anim.short4
                easing.bezierCurve: Material3Anim.standard
            }
        }
        
        // Main Panel Background
        Rectangle {
            id: panel
            anchors.fill: parent
            color: Qt.rgba(root.cSurface.r, root.cSurface.g, root.cSurface.b, 0.55)
            radius: 24
            border.color: root.cBorder
            border.width: 1
            clip: true
            
            Behavior on color {
                ColorAnimation {
                    duration: Material3Anim.medium2
                    easing.bezierCurve: Material3Anim.standard
                }
            }
            
            // Block clicks from passing through
            MouseArea {
                anchors.fill: parent
                onClicked: (mouse) => { mouse.accepted = true }
            }
            
            // Content Layout
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16
                
                // Header Section
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    spacing: 12
                    
                    // Time & Date
                    ColumnLayout {
                        spacing: 2
                        
                        Text {
                            id: timeText
                            text: Qt.formatTime(new Date(), "hh:mm")
                            font.family: "Inter"
                            font.pixelSize: 32
                            font.weight: Font.Bold
                            color: root.cOnSurface
                        }
                        
                        Text {
                            text: Qt.formatDate(new Date(), "dddd, MMMM d")
                            font.family: "Inter"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: root.cOnSurfaceVariant
                        }
                        
                        Timer {
                            interval: 1000
                            running: true
                            repeat: true
                            onTriggered: timeText.text = Qt.formatTime(new Date(), "hh:mm")
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    // Header Actions
                    RowLayout {
                        spacing: 6
                        
                        HeaderButton {
                            icon: "󰒓"
                            tooltip: "Settings"
                            onClicked: settingsProcess.running = true
                        }
                        HeaderButton {
                            icon: "󰐥"
                            tooltip: "Power Menu"
                            onClicked: powerProcess.running = true
                        }
                    }
                }
                
                // Scrollable Content
                Flickable {
                    id: contentFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    contentHeight: contentColumn.height
                    clip: true
                    boundsBehavior: Flickable.DragAndOvershootBounds
                    flickDeceleration: 1200
                    maximumFlickVelocity: 2500
                    pressDelay: 50
                    
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width: 4
                        
                        contentItem: Rectangle {
                            radius: 2
                            color: Qt.rgba(root.cOnSurface.r, root.cOnSurface.g, root.cOnSurface.b, 0.2)
                        }
                    }
                    
                    ColumnLayout {
                        id: contentColumn
                        width: contentFlick.width
                        spacing: 14
                        
                        // Quick Toggles
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: 10
                            rowSpacing: 10
                            
                            QuickToggle {
                                Layout.fillWidth: true
                                icon: "󰖩"
                                label: "Wi-Fi"
                                subLabel: root.network.connected ? root.network.ssid : "Disconnected"
                                active: root.network.wifiEnabled
                                activeColor: root.cPrimary
                                surfaceColor: Qt.rgba(root.cSurfaceContainerHigh.r, root.cSurfaceContainerHigh.g, root.cSurfaceContainerHigh.b, 0.75)
                                textColor: root.cOnSurface
                                onClicked: root.network.toggleWifi()
                            }

                            QuickToggle {
                                Layout.fillWidth: true
                                icon: (Bluetooth.defaultAdapter?.enabled ?? false) ? "󰂯" : "󰂲"
                                label: "Bluetooth"
                                subLabel: (Bluetooth.defaultAdapter?.enabled ?? false) ? "On" : "Off"
                                active: Bluetooth.defaultAdapter?.enabled ?? false
                                activeColor: root.cPrimary
                                surfaceColor: Qt.rgba(root.cSurfaceContainerHigh.r, root.cSurfaceContainerHigh.g, root.cSurfaceContainerHigh.b, 0.75)
                                textColor: root.cOnSurface
                                onClicked: {
                                    if (Bluetooth.defaultAdapter) {
                                        Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                                    }
                                }
                            }

                            QuickToggle {
                                Layout.fillWidth: true
                                icon: "󰔎"
                                label: "Do Not Disturb"
                                subLabel: root.notifs.dnd ? "On" : "Off"
                                active: root.notifs.dnd
                                activeColor: QsSingletons.Theme.verm
                                surfaceColor: Qt.rgba(root.cSurfaceContainerHigh.r, root.cSurfaceContainerHigh.g, root.cSurfaceContainerHigh.b, 0.75)
                                textColor: root.cOnSurface
                                onClicked: root.notifs.toggleDnd()
                            }

                            ThemeToggle {
                                activeColor: root.cPrimary
                                surfaceColor: Qt.rgba(root.cSurfaceContainerHigh.r, root.cSurfaceContainerHigh.g, root.cSurfaceContainerHigh.b, 0.75)
                                textColor: root.cOnSurface
                            }

                            QuickToggle {
                                Layout.fillWidth: true
                                icon: "󰅶"
                                label: "Caffeine"
                                subLabel: root.idleInhibitor.inhibited ? "Active" : "Off"
                                active: root.idleInhibitor.inhibited
                                activeColor: QsSingletons.Theme.onGlow
                                surfaceColor: Qt.rgba(root.cSurfaceContainerHigh.r, root.cSurfaceContainerHigh.g, root.cSurfaceContainerHigh.b, 0.75)
                                textColor: root.cOnSurface
                                onClicked: root.idleInhibitor.inhibited = !root.idleInhibitor.inhibited
                            }

                            QuickToggle {
                                Layout.fillWidth: true
                                icon: "󰹑"
                                label: "Screenshot"
                                subLabel: "Capture Screen"
                                active: false
                                activeColor: root.cSecondary
                                surfaceColor: Qt.rgba(root.cSurfaceContainerHigh.r, root.cSurfaceContainerHigh.g, root.cSurfaceContainerHigh.b, 0.75)
                                textColor: root.cOnSurface
                                onClicked: root.screenshot.takeScreenshot("screen")
                            }

                            QuickToggle {
                                Layout.fillWidth: true
                                icon: root.hyprsunset.enabled ? "󰖔" : "󰖙"
                                label: "Night Light"
                                subLabel: root.hyprsunset.enabled ? "On" : "Off"
                                active: root.hyprsunset.enabled
                                activeColor: QsSingletons.Theme.verm
                                surfaceColor: Qt.rgba(root.cSurfaceContainerHigh.r, root.cSurfaceContainerHigh.g, root.cSurfaceContainerHigh.b, 0.75)
                                textColor: root.cOnSurface
                                onClicked: {
                                    root.hyprsunset.requested = !root.hyprsunset.requested
                                }
                            }

                            QuickToggle {
                                Layout.fillWidth: true
                                Layout.columnSpan: 2
                                icon: root.powerProfiles.getProfileIcon(root.powerProfiles.activeProfile)
                                label: "Power Mode"
                                subLabel: root.powerProfiles.getProfileLabel(root.powerProfiles.activeProfile)
                                active: root.powerProfiles.activeProfile === "performance"
                                activeColor: QsSingletons.Theme.vermBurn
                                surfaceColor: Qt.rgba(root.cSurfaceContainerHigh.r, root.cSurfaceContainerHigh.g, root.cSurfaceContainerHigh.b, 0.75)
                                textColor: root.cOnSurface
                                onClicked: {
                                    var profiles = ["balanced", "performance", "power-saver"]
                                    var current = root.powerProfiles.activeProfile
                                    var next = profiles[(profiles.indexOf(current) + 1) % profiles.length]
                                    root.powerProfiles.setProfile(next)
                                }
                            }
                        }
                        
                        // Divider
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: root.cBorder
                        }
                        
                        // Sliders Section
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            
                            VolumeSlider {
                                Layout.fillWidth: true
                                audio: root.audio
                            }
                            
                            BrightnessSlider {
                                Layout.fillWidth: true
                                brightness: root.brightness
                            }
                        }
                        
                        // Divider
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: root.cBorder
                        }
                        
                        // System Stats
                        SystemStats {
                            Layout.fillWidth: true
                            systemUsage: root.systemUsage
                        }
                        
                        // Media Card
                        MediaCard {
                            Layout.fillWidth: true
                            mpris: root.mpris
                            
                        }
                        
                        // Notifications
                        NotificationList {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(260, Math.max(80, root.height - 600))
                            notifs: root.notifs
                            
                        }
                        
                        // Bottom padding
                        Item { Layout.preferredHeight: 4 }
                    }
                }
            }
        }
    }
    
    // Header Button Component
    component HeaderButton: Rectangle {
        id: headerBtn
        property string icon
        property string tooltip: ""
        signal clicked()
        
        width: 40
        height: 40
        radius: 20
        color: headerBtnMouse.containsMouse 
            ? Qt.rgba(root.cOnSurface.r, root.cOnSurface.g, root.cOnSurface.b, 0.1) 
            : root.cSurfaceContainer
        
        Behavior on color {
            ColorAnimation {
                duration: Material3Anim.short3
                easing.bezierCurve: Material3Anim.standard
            }
        }
        
        scale: headerBtnMouse.pressed ? 0.92 : 1.0
        
        Behavior on scale {
            NumberAnimation {
                duration: Material3Anim.short2
                easing.bezierCurve: Material3Anim.standard
            }
        }
        
        Text {
            anchors.centerIn: parent
            text: headerBtn.icon
            font.family: "Material Design Icons"
            font.pixelSize: 18
            color: root.cOnSurface
        }
        
        MouseArea {
            id: headerBtnMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: headerBtn.clicked()
        }
        
        ToolTip.visible: headerBtnMouse.containsMouse && headerBtn.tooltip !== ""
        ToolTip.text: headerBtn.tooltip
        ToolTip.delay: 500
    }
}
