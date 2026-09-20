pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../singletons" as QsSingletons

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
                        // Display follows the Master Audio safe max; the Audio
                        // service is what enforces the actual cap.
                        const cap = Math.round((QsSingletons.Flags.audioSafeMax ?? 1.5) * 100)
                        root.percentage = Math.max(0, Math.min(cap, vol))
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
        if (QsSingletons.Flags.debug) console.log("📊 [VolumeMonitor] Service loaded - reading from wpctl")
    }
}
