pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// FirstRunExperience — first-run onboarding flow.
// Shell by Yemi service. Detects the very first launch via
// a marker file in the shell state dir, then runs the onboarding (a welcome
// notification + optional default wallpaper). The welcome surface itself is
// referenced by welcomeQmlPath so the UI can show it. enableNextTime() /
// disableNextTime() toggle the marker so onboarding can be replayed or silenced.
// Convention: safe defaults, plain English, `_log()` gating,
// Notifications.send, IpcHandler.
Singleton {
    id: root

    // ── Paths ──────────────────────────────────────────────────────────────
    readonly property string firstRunFilePath: {
        const xdg = Quickshell.env("XDG_STATE_HOME")
        const base = xdg && xdg.length ? xdg : (Quickshell.env("HOME") + "/.local/state")
        return base + "/quickshell/firstrun.json"
    }

    readonly property string welcomeQmlPath: {
        const rh = Quickshell.env("RICE_HOME")
        const base = rh && rh.length ? rh : (Quickshell.env("HOME") + "/.config")
        return base + "/quickshell/modules/pill/WelcomeDialog.qml"
    }

    // ── State ──────────────────────────────────────────────────────────────
    property bool ready: false
    property bool firstRun: false

    property string firstRunFileContent: '{"seen":true,"version":1}'
    property string firstRunNotifSummary: "Welcome to Shell by Yemi"
    property string firstRunNotifBody: "Press Super to open the launcher. Tweak everything from the Settings surface."
    property string defaultWallpaperPath: ""

    // ── Public API ─────────────────────────────────────────────────────────
    function load() {
        _marker.reload()
        root.ready = true
        root.onReadyChanged()
        _log("loaded; firstRun =", root.firstRun)
    }

    function onReadyChanged() {
        // Hook for consumers; matches the service's public shape.
    }

    /// Run onboarding for a fresh install.
    function handleFirstRun() {
        root.firstRun = true
        Notifications.send({
            appName: "Quickshell",
            summary: root.firstRunNotifSummary,
            body: root.firstRunNotifBody,
            icon: "starred-symbolic",
            urgency: NotificationUrgency.Low,
            timeout: 9000
        })
        _writeMarker()
        _log("handled first run; welcome notification sent")
    }

    /// Force onboarding to run again on the next launch.
    function enableNextTime() {
        _rmProc.running = true
        root.firstRun = true
        _log("first-run re-enabled")
    }

    /// Suppress onboarding (write the marker now so it is never treated as first run).
    function disableNextTime() {
        _writeMarker()
        root.firstRun = false
        _log("first-run disabled")
    }

    function status() {
        return JSON.stringify({
            ready: root.ready,
            firstRun: root.firstRun,
            marker: root.firstRunFilePath
        })
    }

    // ── Internal ───────────────────────────────────────────────────────────
    function _log() {
        if (Quickshell.env("QS_DEBUG") === "1")
            console.log("[FirstRun]", arguments[0], arguments[1], arguments[2])
    }

    function _writeMarker() {
        _writeProc.running = true
    }

    FileView {
        id: _marker
        path: root.firstRunFilePath
        blockLoading: true
        printErrors: false
        onLoaded: {
            // Marker exists -> not a first run.
            root.firstRun = false
        }
        onLoadFailed: function (error) {
            if (error === FileViewError.FileNotFound) {
                root.firstRun = true
                root.handleFirstRun()
            }
        }
    }

    Process {
        id: _writeProc
        property string target: ""
        command: ["sh", "-c", "echo '" + root.firstRunFileContent + "' > '" + root.firstRunFilePath + "'"]
        onExited: _log("marker written")
    }

    Process {
        id: _rmProc
        command: ["rm", "-f", root.firstRunFilePath]
        onExited: _log("marker removed")
    }

    // ── IPC ────────────────────────────────────────────────────────────────
    IpcHandler {
        target: "firstrun"
        function status() { return root.status() }
        function enable() { root.enableNextTime(); return "re-enabled" }
        function disable() { root.disableNextTime(); return "disabled" }
    }

    Component.onCompleted: root.load()
}
