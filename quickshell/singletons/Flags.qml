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
    property alias themeStyle: adapter.themeStyle
    property alias systemMood: adapter.systemMood
    property alias staticGrayscaleAccents: adapter.staticGrayscaleAccents
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
    property alias altSwitcherEnabled: adapter.altSwitcherEnabled
    property alias backdropEffects: adapter.backdropEffects
    property alias backdropDim: adapter.backdropDim
    property alias backdropVignette: adapter.backdropVignette
    property alias backdropEnable: adapter.backdropEnable
    property alias backdropVignetteEnable: adapter.backdropVignetteEnable
    property alias backdropVignetteRadius: adapter.backdropVignetteRadius
    property alias backdropBlurRadius: adapter.backdropBlurRadius
    property alias backdropSaturation: adapter.backdropSaturation
    property alias backdropContrast: adapter.backdropContrast
    property alias backdropEnableAnimation: adapter.backdropEnableAnimation
    property alias backdropEnableAnimatedBlur: adapter.backdropEnableAnimatedBlur
    property alias backdropUseMainWallpaper: adapter.backdropUseMainWallpaper
    property alias backdropWallpaperPath: adapter.backdropWallpaperPath
    property alias wallpaperSelectionTarget: adapter.wallpaperSelectionTarget
    property alias parallaxEnable: adapter.parallaxEnable
    property alias parallaxZoom: adapter.parallaxZoom
    property alias parallaxStrength: adapter.parallaxStrength

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
    property string themeStyle: "yemi"
    property string systemMood: "dark"
            property bool staticGrayscaleAccents: false
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
            property bool altSwitcherEnabled: true
    property bool backdropEffects: true
    property real backdropDim: 0.20
    property real backdropVignette: 0.35
    property bool backdropEnable: true
    property bool backdropVignetteEnable: true
    property real backdropVignetteRadius: 0.7
    property real backdropBlurRadius: 0
    property real backdropSaturation: 0
    property real backdropContrast: 0
    property bool backdropEnableAnimation: false
    property bool backdropEnableAnimatedBlur: false
    property bool backdropUseMainWallpaper: true
    property string backdropWallpaperPath: ""
    property string wallpaperSelectionTarget: ""
            property bool parallaxEnable: true
            property real parallaxZoom: 1.08
            property real parallaxStrength: 0.5
        }
    }
}