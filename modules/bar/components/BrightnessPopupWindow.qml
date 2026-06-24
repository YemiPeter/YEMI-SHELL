import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../../../services" as QsServices
import "../../../singletons" as QsSingletons

// Material 3 Expressive Brightness Popup
PanelWindow {
    id: popupWindow
    
    property bool shouldShow: false
    property bool isHovered: false
    readonly property var brightness: QsServices.Brightness
    
    // Material 3 colors
    readonly property color m3Surface: Qt.rgba(QsSingletons.Theme.cardBot.r, QsSingletons.Theme.cardBot.g, QsSingletons.Theme.cardBot.b, 1.0)
    readonly property color m3Primary: QsSingletons.Theme.verm ?? "#f9e2af"
    readonly property color m3OnSurface: QsSingletons.Theme.cream
    
    screen: Quickshell.screens[0]
    
    anchors {
        top: true
        right: true
    }
    
    margins {
        right: 4
        top: 4
    }
    
    implicitWidth: 320
    implicitHeight: contentColumn.implicitHeight + 32
    color: "transparent"
    visible: shouldShow || container.opacity > 0
    
    // Material 3 animated container
    Item {
        id: container
        anchors.fill: parent
        scale: 0.85
        opacity: 0
        transformOrigin: Item.TopRight
        
        // Bouncy entrance
        SequentialAnimation {
            running: popupWindow.shouldShow
            ParallelAnimation {
                NumberAnimation {
                    target: container
                    property: "scale"
                    from: 0.7
                    to: 1.08
                    duration: 280
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: container
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 250
                }
            }
            NumberAnimation {
                target: container
                property: "scale"
                to: 1.0
                duration: 220
                easing.type: Easing.OutBack
                easing.overshoot: 1.8
            }
        }
        
        // Quick exit
        ParallelAnimation {
            running: !popupWindow.shouldShow && container.opacity > 0
            NumberAnimation {
                target: container
                property: "scale"
                to: 0.85
                duration: 200
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: container
                property: "opacity"
                to: 0
                duration: 200
            }
        }
        
        // Shadow
        Rectangle {
            anchors.fill: backgroundRect
            anchors.margins: -6
            radius: backgroundRect.radius + 3
            color: "transparent"
            
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.35)
                shadowBlur: 0.8
                shadowVerticalOffset: 8
            }
        }
    
        // Material 3 surface
        Rectangle {
            id: backgroundRect
            anchors.fill: parent
            color: m3Surface
            radius: 16
            
            border.color: Qt.rgba(m3Primary.r, m3Primary.g, m3Primary.b, 0.2)
            border.width: 1
            
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: popupWindow.isHovered = true
                onExited: {
                    popupWindow.isHovered = false
                    popupWindow.shouldShow = false
                }
            }
        }
    }
    
    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12
        
        // Header
        Text {
            text: "Brightness"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.weight: Font.DemiBold
            color: QsSingletons.Theme.cream
        }
        
        // Brightness control
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Text {
                    text: "󰃠"
                    font.family: "Material Design Icons"
                    font.pixelSize: 20
                    color: QsSingletons.Theme.cream
                }
                
                Text {
                    text: "Display"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    color: Qt.rgba(QsSingletons.Theme.cream.r, QsSingletons.Theme.cream.g, QsSingletons.Theme.cream.b, 0.7)
                }
                
                Item { Layout.fillWidth: true }
                
                Text {
                    text: brightness.percentage + "%"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: QsSingletons.Theme.cream
                }
            }
            
            // Brightness slider
            Slider {
                id: brightnessSlider
                Layout.fillWidth: true
                from: 0
                to: 100
                value: brightness.percentage
                
                onMoved: {
                    brightness.setBrightness(value / 100)
                }
                
                background: Rectangle {
                    x: brightnessSlider.leftPadding
                    y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                    implicitWidth: 200
                    implicitHeight: 6
                    width: brightnessSlider.availableWidth
                    height: implicitHeight
                    radius: 3
                    color: Qt.rgba(QsSingletons.Theme.cream.r, QsSingletons.Theme.cream.g, QsSingletons.Theme.cream.b, 0.1)
                    
                    Rectangle {
                        width: brightnessSlider.visualPosition * parent.width
                        height: parent.height
                        color: QsSingletons.Theme.verm
                        radius: 3
                        
                        Behavior on width {
                            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                        }
                    }
                }
                
                handle: Rectangle {
                    x: brightnessSlider.leftPadding + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
                    y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                    implicitWidth: 18
                    implicitHeight: 18
                    radius: 9
                    color: QsSingletons.Theme.cream
                    border.color: QsSingletons.Theme.verm
                    border.width: 2
                    
                    Behavior on x {
                        NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                    }
                }
            }
            
            // Quick brightness presets
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                
                Repeater {
                    model: [
                        { label: "25%", value: 0.25 },
                        { label: "50%", value: 0.5 },
                        { label: "75%", value: 0.75 },
                        { label: "100%", value: 1.0 }
                    ]
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        radius: 6
                        color: Qt.rgba(QsSingletons.Theme.cream.r, QsSingletons.Theme.cream.g, QsSingletons.Theme.cream.b, 0.1)
                        
                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: QsSingletons.Theme.cream
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: brightness.setBrightness(modelData.value)
                            
                            onPressed: parent.color = Qt.rgba(QsSingletons.Theme.cream.r, QsSingletons.Theme.cream.g, QsSingletons.Theme.cream.b, 0.2)
                            onReleased: parent.color = Qt.rgba(QsSingletons.Theme.cream.r, QsSingletons.Theme.cream.g, QsSingletons.Theme.cream.b, 0.1)
                        }
                    }
                }
            }
        }
    }
}
