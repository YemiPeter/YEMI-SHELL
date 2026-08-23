pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * System package update checks (Arch / CachyOS).
 * Probes `checkupdates` (pacman-contrib) and counts pending packages.
 * Mirrors Waffle's inir/Updates.qml; thresholds/interval are safe local
 * defaults (no Config). Arch-only by design.
 */
Singleton {
    id: root

    property bool available: false
    property int count: 0

    readonly property bool updateAdvised: available && count > 75
    readonly property bool updateStronglyAdvised: available && count > 200

    function refresh() {
        if (!root.available)
            return
        checkUpdatesProc.running = true
    }

    // Initial availability probe on startup.
    Timer {
        triggeredOnStart: true
        interval: 1
        running: true
        repeat: false
        onTriggered: checkAvailabilityProc.running = true
    }

    // Periodic re-check (120 minutes).
    Timer {
        interval: 120 * 60 * 1000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Process {
        id: checkAvailabilityProc
        running: false
        command: ["which", "checkupdates"]
        onExited: function (exitCode) {
            root.available = (exitCode === 0)
            if (root.available)
                root.refresh()
        }
    }

    Process {
        id: checkUpdatesProc
        running: false
        command: ["checkupdates"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = (text ?? "").trim()
                root.count = t.length > 0 ? t.split("\n").length : 0
            }
        }
        onExited: function (exitCode) {
            if (exitCode !== 0)
                console.error("[Updates] checkupdates failed", exitCode)
        }
    }
}
