import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../pill/Singletons"
import "../../../singletons" as QsSingletons
import "../../../components/effects"

// Brightness indicator with number - no popup
Item {
    id: root
    
    property var barWindow
    property string screenName
    
    readonly property var brightness: Devices
    readonly property bool isHovered: mouseArea.containsMouse
    readonly property int percentage: brightness?.backlightPct ?? 0
    
    implicitWidth: brightnessRow.implicitWidth
    implicitHeight: 20
    
    RowLayout {
        id: brightnessRow
        anchors.centerIn: parent
        spacing: 3
        
        // Brightness icon
        Text {
            id: brightnessIcon
            
            text: {
                if (percentage >= 75) return "󰃠"
                if (percentage >= 50) return "󰃟"
                if (percentage >= 25) return "󰃞"
                return "󰃝"
            }
            
            font.family: "Material Design Icons"
            font.pixelSize: 14

            color: {
                if (isHovered) return QsSingletons.Theme.onGlow
                if (percentage >= 75) return Qt.rgba(QsSingletons.Theme.verm.r, QsSingletons.Theme.verm.g, QsSingletons.Theme.verm.b, 0.85)
                return QsSingletons.Theme.cream
            }
            
            Behavior on color {
                ColorAnimation { duration: 150 }
            }
            
            scale: isHovered ? 1.05 : 1.0
            Behavior on scale {
                NumberAnimation { duration: 100 }
            }
        }
        
        // Percentage number
        Text {
            id: brightnessText
            
            text: percentage
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 10
            font.weight: Font.Medium
            
            color: Qt.rgba(QsSingletons.Theme.cream.r, QsSingletons.Theme.cream.g, QsSingletons.Theme.cream.b, 0.7)
            
            Behavior on color {
                ColorAnimation { duration: 150 }
            }
            
            // Number change animation
            Behavior on text {
                SequentialAnimation {
                    NumberAnimation {
                        target: brightnessText
                        property: "scale"
                        to: 1.15
                        duration: 80
                    }
                    NumberAnimation {
                        target: brightnessText
                        property: "scale"
                        to: 1.0
                        duration: 100
                    }
                }
            }
        }
    }
    
    // Interaction area
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    
        onClicked: {
            QsSingletons.PillState.toggleSurface(root.screenName, "mixer")
        }
    
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) {
                brightness.increaseBacklight()
            } else {
                brightness.decreaseBacklight()
            }
        }
    }
    
    // Brightness change pulse
    Connections {
        target: brightness
        function onBacklightPctChanged() {
            pulseAnim.restart()
        }
    }
    
    SequentialAnimation {
        id: pulseAnim
        
        NumberAnimation {
            target: brightnessIcon
            property: "scale"
            to: 1.2
            duration: 80
        }
        NumberAnimation {
            target: brightnessIcon
            property: "scale"
            to: isHovered ? 1.05 : 1.0
            duration: 120
        }
    }
}
