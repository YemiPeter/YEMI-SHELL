pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Pomodoro / timer service. Ported from Waffle iNiR TimerService: Config and
// Translation dropped for safe defaults and plain English. Drives its own 1s
// tick so countdownString updates smoothly regardless of the pill clock precision.
Singleton {
    id: root

    // ── Safe defaults (no Config) ─────────────────────────────────────────
    readonly property int focusTime: 1500        // 25 min
    readonly property int breakTime: 300         // 5 min
    readonly property int longBreakTime: 900     // 15 min
    readonly property int cyclesBeforeLongBreak: 4

    // ── State ─────────────────────────────────────────────────────────────
    property bool pomodoroRunning: false
    property bool pomodoroPaused: false
    property string currentPhase: "focus"        // "focus" | "break" | "longBreak"
    property int completedCycles: 0
    property int remainingSeconds: 0

    readonly property string countdownString: _fmt(root.remainingSeconds)

    // ── Public API ─────────────────────────────────────────────────────────
    function start() {
        root.currentPhase = "focus"
        root.remainingSeconds = root.focusTime
        root.pomodoroRunning = true
        root.pomodoroPaused = false
        _log("start focus", root.focusTime)
    }

    function pause() {
        if (!root.pomodoroRunning)
            return
        root.pomodoroPaused = !root.pomodoroPaused
        _log("pause toggled", root.pomodoroPaused)
    }

    function reset() {
        root.pomodoroRunning = false
        root.pomodoroPaused = false
        root.currentPhase = "focus"
        root.completedCycles = 0
        root.remainingSeconds = 0
        _log("reset")
    }

    function getStatus() {
        return JSON.stringify({
            running: root.pomodoroRunning,
            paused: root.pomodoroPaused,
            phase: root.currentPhase,
            remainingSeconds: root.remainingSeconds,
            countdown: root.countdownString,
            completedCycles: root.completedCycles
        })
    }

    // ── Internal ───────────────────────────────────────────────────────────
    function _log() {
        if (Quickshell.env("QS_DEBUG") === "1")
            console.log("[TimerService]", arguments[0], arguments[1])
    }

    function _fmt(sec) {
        sec = Math.max(0, sec | 0)
        const m = Math.floor(sec / 60)
        const s = sec % 60
        return String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0")
    }

    function _notify(title, body) {
        Notifications.send({
            appName: "Quickshell Timer",
            summary: title,
            body: body,
            icon: "timer-symbolic",
            urgency: NotificationUrgency.Normal,
            timeout: 6000
        })
    }

    function _onPhaseComplete() {
        if (root.currentPhase === "focus") {
            root.completedCycles++
            const isLong = (root.completedCycles % root.cyclesBeforeLongBreak === 0)
            root.currentPhase = isLong ? "longBreak" : "break"
            root.remainingSeconds = isLong ? root.longBreakTime : root.breakTime
            _notify("Focus session complete",
                    isLong ? "Nice work — take a long break." : "Time for a short break.")
        } else {
            root.currentPhase = "focus"
            root.remainingSeconds = root.focusTime
            _notify("Break over", "Back to focus.")
        }
    }

    Timer {
        id: tickTimer
        interval: 1000
        repeat: true
        running: root.pomodoroRunning && !root.pomodoroPaused
        onTriggered: {
            root.remainingSeconds--
            if (root.remainingSeconds <= 0)
                root._onPhaseComplete()
        }
    }

    // ── IPC ────────────────────────────────────────────────────────────────
    IpcHandler {
        target: "timer"
        function start() { root.start(); return "started" }
        function pause() { root.pause(); return root.pomodoroPaused ? "paused" : "resumed" }
        function reset() { root.reset(); return "reset" }
        function status() { return root.getStatus() }
    }
}
