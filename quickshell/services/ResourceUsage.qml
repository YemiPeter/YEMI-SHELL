pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// iNiR-compatible ResourceUsage API for the waffle widgets panel.
// Proxies CPU/memory from SystemUsage and adds swap tracking (SystemUsage
// does not expose swap). Keeps the ported WidgetsContent.qml unchanged.
Singleton {
    id: root

    property real cpuUsage: SystemUsage.cpuPerc             // 0..1
    property real memoryUsed: SystemUsage.memUsed           // bytes
    readonly property real memoryUsedPercentage: SystemUsage.memPerc // 0..1
    readonly property string maxAvailableMemoryString: SystemUsage.maxAvailableMemoryString

    property real swapTotal: 0    // bytes
    property real swapUsed: 0     // bytes
    readonly property real swapUsedPercentage: swapTotal > 0 ? swapUsed / swapTotal : 0
    readonly property string maxAvailableSwapString: root._formatBytes(swapTotal)

    function _formatBytes(bytes) {
        if (bytes >= 1073741824) {
            const gb = bytes / 1073741824
            return Math.round(gb) + " GB"
        }
        const mb = bytes / 1048576
        return Math.round(mb) + " MB"
    }

    function ensureRunning() {
        SystemUsage.ensureRunning()
        if (!swapTimer.running) swapTimer.start()
    }

    function stop() {
        if (swapTimer.running) swapTimer.stop()
    }

    Process {
        id: swapProcess
        running: false
        command: ["/bin/sh", "-c", "free -b | grep '^Swap:'"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/)
                if (parts[0] === "Swap:" && parts.length >= 3) {
                    root.swapTotal = parseInt(parts[1]) || 0
                    root.swapUsed = parseInt(parts[2]) || 0
                }
            }
        }
    }

    Timer {
        id: swapTimer
        interval: 2000
        repeat: true
        onTriggered: swapProcess.running = true
    }
}
