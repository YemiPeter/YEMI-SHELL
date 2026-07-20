pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Monitor volume directly from wpctl
Singleton {
    id: root

    property int percentage: 50
    property bool muted: false

    Timer {
        interval: 500
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            volProc.running = true
            muteProc.running = true
        }
    }

    // Get volume from wpctl
    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]

        stdout: StdioCollector {
            onStreamFinished: {
                // Format: "Volume: 0.70" or "Volume: 0.70 MUTED"
                const match = text.match(/([\d.]+)/)
                if (match) {
                    const vol = Math.round(parseFloat(match[1]) * 100)
                    if (vol !== root.percentage) {
                        root.percentage = Math.max(0, Math.min(150, vol))
                    }
                }
            }
        }
    }

    // Get mute state from wpctl
    Process {
        id: muteProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.muted = text.includes("MUTED")
            }
        }
    }

    Component.onCompleted: {
        console.log("📊 [VolumeMonitor] Service loaded - reading from wpctl")
    }
}
