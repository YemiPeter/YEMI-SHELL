pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Shared session flags persisted to a small JSON file and watched for
 * external change, so every Shell by Yemi daemon (pill, bar, sidebar)
 * reads and writes the same Do-Not-Disturb and Keep-Awake state live
 * without a second notification server or idle inhibitor. Toggling in
 * one surface updates the others on the next file event, and the state
 * survives a daemon restart.
 *
 * Merged from Shell by Yemi's Flags.qml – this is now the unified
 * project-wide Flags.
 */
Singleton {
    id: root

    /// Whether debug-level console logging is enabled
    readonly property bool debug: {
        const envDebug = Quickshell.env("QS_DEBUG")
        return envDebug === "1" || envDebug === "true"
    }

    property alias dnd: adapter.dnd
    property alias keepAwake: adapter.keepAwake
    property alias time12h: adapter.time12h
    property alias clockSeconds: adapter.clockSeconds
    property alias paletteMode: adapter.paletteMode
    property alias systemMood: adapter.systemMood
    property alias uiScale: adapter.uiScale
    property alias reduceMotion: adapter.reduceMotion
    property alias manualHue: adapter.manualHue
    property alias manualDark: adapter.manualDark
    property alias manualSat: adapter.manualSat
    property alias uiFont: adapter.uiFont
    property alias pillOpacity: adapter.pillOpacity
    property alias pillBlur: adapter.pillBlur
    property alias idleLockMin: adapter.idleLockMin
    property alias idleScreenOffMin: adapter.idleScreenOffMin
    property alias idleSuspendMin: adapter.idleSuspendMin
    property alias weatherCity: adapter.weatherCity
    property alias recordCountdown: adapter.recordCountdown
    property alias recordDir: adapter.recordDir
    property alias recordFps: adapter.recordFps
    property alias recordQuality: adapter.recordQuality
    property alias recordCursor: adapter.recordCursor
    property alias recordMic: adapter.recordMic
    property alias recordDesktop: adapter.recordDesktop
    property alias recordClearedBefore: adapter.recordClearedBefore

    FileView {
        id: file
        path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell/flags.json"
        blockLoading: true
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: function(error) {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter
            property bool dnd: false
            property bool keepAwake: false
            property bool time12h: false
            property bool clockSeconds: false
            property string paletteMode: "dynamic"
            property string systemMood: "dark"
            property real uiScale: 1.0
            property bool reduceMotion: false
            property int manualHue: 30
            property bool manualDark: true
            property real manualSat: 0.5
            property string uiFont: ""
            property real pillOpacity: 0.55
            property bool pillBlur: false
            property int recordCountdown: 5
            property string recordDir: ""
            property int recordFps: 60
            property string recordQuality: "high"
            property bool recordCursor: true
            property bool recordMic: true
            property bool recordDesktop: true
            property int idleLockMin: 5
            property int idleScreenOffMin: 6
            property int idleSuspendMin: 0
            property string weatherCity: ""
            property real recordClearedBefore: 0
        }
    }
}