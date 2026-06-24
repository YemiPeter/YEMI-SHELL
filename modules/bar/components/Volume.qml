import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Io
import "../../../services" as QsServices
import "../../../singletons" as QsSingletons
import "../../../components/effects"

// Volume indicator with number - no popup
Item {
    id: root
    
    property var barWindow
    property var volumePopup  // Kept for compatibility but not used
    
    readonly property var audio: QsServices.Audio
    readonly property var volumeMonitor: QsServices.VolumeMonitor
    readonly property bool isHovered: mouseArea.containsMouse
    readonly property bool isMuted: volumeMonitor.muted
    readonly property int percentage: volumeMonitor.percentage
    
    implicitWidth: volumeRow.implicitWidth
    implicitHeight: 20
    
    RowLayout {
        id: volumeRow
        anchors.centerIn: parent
        spacing: 3
        
        // Volume icon
        Text {
            id: volumeIcon
            
            text: {
                if (isMuted) return "󰖁"
                if (percentage >= 70) return "󰕾"
                if (percentage >= 30) return "󰖀"
                return "󰕿"
            }
            
            font.family: "Material Design Icons"
            font.pixelSize: 14

            color: {
                if (isMuted) return Qt.rgba(QsSingletons.Theme.cream.r, QsSingletons.Theme.cream.g, QsSingletons.Theme.cream.b, 0.35)
                if (isHovered) return QsSingletons.Theme.onGlow
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
        
        // Percentage number with animated transitions
        Text {
            id: volumeText
            
            text: percentage
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 10
            font.weight: Font.Medium
            
            color: {
                if (isMuted) return Qt.rgba(QsSingletons.Theme.cream.r, QsSingletons.Theme.cream.g, QsSingletons.Theme.cream.b, 0.35)
                return Qt.rgba(QsSingletons.Theme.cream.r, QsSingletons.Theme.cream.g, QsSingletons.Theme.cream.b, 0.7)
            }
            
            Behavior on color {
                ColorAnimation { duration: 150 }
            }
            
            // Number change animation
            Behavior on text {
                SequentialAnimation {
                    NumberAnimation {
                        target: volumeText
                        property: "scale"
                        to: 1.15
                        duration: 80
                    }
                    NumberAnimation {
                        target: volumeText
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
        
        onWheel: wheel => {
            var delta = wheel.angleDelta.y > 0 ? "2%+" : "2%-"
            volAdjProc.command = ["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", delta]
            volAdjProc.running = true
        }

        onClicked: barToggleMuteProc.running = true
    }

    Process {
        id: volAdjProc
        command: ["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", "0%+"]
    }

    Process {
        id: barToggleMuteProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
    }

    // Volume change pulse
    Connections {
        target: volumeMonitor
        function onPercentageChanged() {
            pulseAnim.restart()
        }
    }
    
    SequentialAnimation {
        id: pulseAnim
        
        NumberAnimation {
            target: volumeIcon
            property: "scale"
            to: 1.2
            duration: 80
        }
        NumberAnimation {
            target: volumeIcon
            property: "scale"
            to: isHovered ? 1.05 : 1.0
            duration: 120
        }
    }
}
