pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Screen-recorder backend, shared by the recorder surface, the pill's hover
 * cluster record indicator and the record OSD. gpu-screen-recorder is the
 * encoder (cross-vendor nvenc/vaapi/cpu); this singleton owns the capture
 * settings, builds the argv from them, starts and stops the recorder and keeps
 * a live `recording` flag polled from the real process so an externally started
 * or stopped recorder is reflected too.
 *
 * STUB: Full implementation requires gpu-screen-recorder, Pipewire integration,
 * and the Hypr scripts (record.sh, rec-thumbs.sh). This stub provides the
 * property interface so surfaces can compile and the pill can open without
 * crashing. Replace with full implementation when Pipewire service is ready.
 */
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string defaultDir: home + "/Videos/Recordings"
    // ADAPTED: ricelin → quickshell
    readonly property string thumbDir: (Quickshell.env("XDG_CACHE_HOME") || (home + "/.cache")) + "/quickshell/rec-thumbs/"
    readonly property string thumbScript: home + "/.config/quickshell/scripts/rec-thumbs.sh"
    readonly property string outDir: {
        var d = Flags.recordDir;
        return d && d.length > 0 ? d : defaultDir;
    }

    property bool recording: false
    property bool quickChoosing: false
    property bool quickScreenChoosing: false
    property string quickMon: ""
    property var monitors: []
    property int countdown: 0
    property string status: ""

    function prepareScreen(name) {
        root.quickMon = name || "";
        root.quickChoosing = false;
        root.quickScreenChoosing = false;
        root.emitTargetReady("screen:" + (name || ""));
    }

    function prepareWindow() {
        root.quickChoosing = false;
        root.quickScreenChoosing = true;
        root.monitors = Quickshell.screens;
    }

    function pickMonitor(name) {
        root.quickScreenChoosing = false;
        root.quickMon = name || "";
        root.emitTargetReady("screen:" + (name || ""));
    }

    function emitTargetReady(token) {
        root.status = "ready:" + token;
        // In full impl: start countdown, then start recording
    }

    function emitTargetAborted() {
        root.quickChoosing = false;
        root.quickScreenChoosing = false;
        root.status = "";
    }

    function start(token) {
        root.recording = true;
        root.status = "recording";
        // In full impl: launch gpu-screen-recorder with token-derived args
    }

    function stop() {
        root.recording = false;
        root.countdown = 0;
        root.status = "";
        // In full impl: SIGINT to gsr, wait for file, notify
    }

    function cancel() {
        root.recording = false;
        root.countdown = 0;
        root.quickChoosing = false;
        root.quickScreenChoosing = false;
        root.status = "";
    }

    function refreshRecent() {
        // STUB: would run thumb script then re-read output dir
    }

    function pickDir() {
        // STUB: would open native folder picker
        return root.outDir;
    }

    signal targetReady(string token)
    signal targetAborted()
}
