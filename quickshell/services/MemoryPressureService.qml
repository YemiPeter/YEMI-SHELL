pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Memory pressure monitoring for JSGCHeap accumulation.
// Qt's V4 JS engine creates memfd mappings that persist as "(deleted)" after
// Loader teardown. This service monitors that accumulation and notifies the
// user when a reload would help reclaim memory. Ported from Waffle
// iNiR MemoryPressureService (Config/Translation swapped for safe defaults).
Singleton {
    id: root

    // ── Safe defaults (no Config) ─────────────────────────────────────────
    readonly property bool enabled: true
    readonly property int deletedMappingsThreshold: 300
    readonly property int checkIntervalMs: 300000  // check every 5 min

    // ── State ─────────────────────────────────────────────────────────────
    property int currentDeletedMappings: 0
    property int currentTotalMappings: 0
    property bool notificationShown: false
    property bool userDismissed: false

    // ── Public API ────────────────────────────────────────────────────────
    function forceGc() {
        gc()
        _log("gc() forced")
    }

    function restart() {
        _log("user requested reload")
        Notifications.send({
            appName: "Quickshell",
            summary: "Reloading shell...",
            body: "",
            icon: "system-reboot-symbolic",
            urgency: NotificationUrgency.Low,
            timeout: 2000
        })
        // Small delay so the notification shows
        Qt.callLater(() => {
            Quickshell.execDetached(["qs", "ipc", "call", "reload"])
        })
    }

    function dismiss() {
        root.userDismissed = true
        root.notificationShown = false
        _log("user dismissed memory warning")
    }

    function reset() {
        root.userDismissed = false
        root.notificationShown = false
        _log("reset state")
    }

    function getStats() {
        return JSON.stringify({
            deletedMappings: root.currentDeletedMappings,
            totalMappings: root.currentTotalMappings,
            threshold: root.deletedMappingsThreshold,
            notificationShown: root.notificationShown,
            userDismissed: root.userDismissed,
            enabled: root.enabled
        })
    }

    // ── Internal ──────────────────────────────────────────────────────────
    function _log() {
        if (Quickshell.env("QS_DEBUG") === "1")
            console.log("[MemoryPressure]", arguments[0], arguments[1], arguments[2])
    }

    function _checkMemoryPressure() {
        if (!root.enabled)
            return
        _mapsReader.running = true
    }

    function _notifyUser() {
        if (root.notificationShown || root.userDismissed)
            return

        root.notificationShown = true
        const mbEstimate = Math.round(root.currentDeletedMappings * 0.5)  // ~0.5 MB per mapping

        Notifications.send({
            appName: "Quickshell",
            summary: "Memory usage is high (~" + mbEstimate + " MB accumulated). A reload would free it. Run: qs ipc call reload",
            body: "",
            icon: "dialog-warning-symbolic",
            urgency: NotificationUrgency.Normal,
            timeout: 0
        })
        _log("notified user, estimated leak:", mbEstimate, "MB")
    }

    // ── Timers ────────────────────────────────────────────────────────────
    Timer {
        id: _checkTimer
        interval: root.checkIntervalMs
        repeat: true
        running: root.enabled
        onTriggered: root._checkMemoryPressure()
    }

    // ── Maps reader ───────────────────────────────────────────────────────
    Process {
        id: _mapsReader
        command: ["sh", "-c", "grep -c 'JSGCHeap.*deleted' /proc/self/maps 2>/dev/null || echo 0; grep -c JSGCHeap /proc/self/maps 2>/dev/null || echo 0"]
        stdout: SplitParser {
            property int lineNum: 0
            onRead: line => {
                const val = parseInt(line.trim()) || 0
                if (lineNum === 0) {
                    root.currentDeletedMappings = val
                } else {
                    root.currentTotalMappings = val
                }
                lineNum++
            }
        }
        onExited: function (code, status) {
            _mapsReader.stdout.lineNum = 0

            if (root.currentDeletedMappings >= root.deletedMappingsThreshold) {
                _log("threshold exceeded:", root.currentDeletedMappings, ">=", root.deletedMappingsThreshold)
                root._notifyUser()
            }
        }
    }

    // ── IPC ───────────────────────────────────────────────────────────────
    IpcHandler {
        target: "memory"
        function collect() { root.forceGc(); return "gc() called" }
        function stats() { return root.getStats() }
        function restart() { root.restart(); return "reloading..." }
        function dismiss() { root.dismiss(); return "dismissed" }
        function reset() { root.reset(); return "reset" }
    }

    Component.onCompleted: {
        if (!root.enabled)
            return
        Qt.callLater(() => {
            _checkTimer.start()
        })
    }
}
