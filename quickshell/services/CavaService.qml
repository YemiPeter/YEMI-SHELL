pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Single cava process shared across all visualizers (waveform/spectrum widgets,
// media player cards, music panel, etc).
//
// Before this service, every CavaProcess instance spawned its own subprocess
// even though they all read the same PipeWire stream with identical config —
// 2+ cava processes idle-running at ~1.4% CPU each.
//
// Consumers subscribe()/unsubscribe() to drive lifecycle. While _subscribers > 0
// one process runs; bars are broadcast via the `points` property.
//
// Config (framerate/sensitivity/bars/stereo) is global, so a single process
// satisfies every consumer with identical output. Per-consumer rendering
// (colors, scale, bar count downsample) happens in the widget layer.
Singleton {
    id: root

    property int _subscribers: 0
    readonly property bool active: _subscribers > 0

    property list<real> points: []

    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell"
    readonly property string configPath: stateDir + "/cava_config.txt"
    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/quickshell/scripts/cava/generate_config.sh"

    // Config from Flags (runtime), with fallbacks
    readonly property int cfgFramerate: 60
    readonly property int cfgSensitivity: 100
    readonly property int cfgBars: 0
    readonly property bool cfgStereo: false
    readonly property int effectiveBars: cfgBars > 0 ? cfgBars : 50

    readonly property string playerDesktopEntry: {
        return Players.active?.desktopEntry ?? ""
    }

    function subscribe(): void {
        _subscribers++
        if (_subscribers === 1) {
            stopDebounce.stop()
            if (!cavaProc.running && !configGen.running)
                configGen.running = true
        }
    }

    function unsubscribe(): void {
        _subscribers = Math.max(0, _subscribers - 1)
        if (_subscribers === 0)
            stopDebounce.restart()
    }

    // Restart when player or config changes while active
    onPlayerDesktopEntryChanged: if (active) configRestart.restart()

    Connections {
        target: Players
        function onActiveChanged(): void {
            if (root.active) configRestart.restart()
        }
    }

    Timer {
        id: configRestart
        interval: 300
        onTriggered: {
            if (cavaProc.running) {
                root._pendingRestart = true
                cavaProc.running = false
            } else if (root.active) {
                configGen.running = true
            }
        }
    }

    // Defer process teardown so brief unsubscribe/subscribe cycles
    // (e.g. panel close + immediate reopen) don't churn the subprocess.
    Timer {
        id: stopDebounce
        interval: 800
        repeat: false
        onTriggered: {
            cavaProc.running = false
        }
    }

    property bool _pendingRestart: false

    Process {
        id: configGen
        command: ["bash", root.scriptPath, root.configPath,
                  root.cfgFramerate, root.cfgSensitivity, root.effectiveBars,
                  root.cfgStereo ? "true" : "false", root.playerDesktopEntry]
        running: false
        onFinished: {
            if (root.active && !cavaProc.running) {
                cavaProc.running = true
            }
        }
    }

    Process {
        id: cavaProc
        command: ["cava", "-p", root.configPath]
        running: false
        required: false
        stdinEnabled: false
        onRunningChanged: {
            if (!running && root._pendingRestart && root.active) {
                root._pendingRestart = false
                configGen.running = true
            }
        }

        ReadChannel {
            id: cavaStdout
            onData: {
                var vals = data.trim().split(/[\s,]+/).map(function(v) {
                    var f = parseFloat(v)
                    return isNaN(f) ? 0 : f
                })
                root.points = vals
            }
        }
    }

    Component.onCompleted: {
        // CavaService is a singleton; nothing to do here
    }
}
