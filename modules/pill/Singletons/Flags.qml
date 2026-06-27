pragma Singleton
import QtQuick
import "../../../singletons" as QsSingletons

/**
 * Shim: re-exports the project-wide Flags singleton so pill files
 * using `import "Singletons"` find `Flags.dnd` etc. without changes.
 * Do NOT add new properties here — add them in singletons/Flags.qml.
 */
QtObject {
    id: root

    readonly property bool dnd: QsSingletons.Flags.dnd
    readonly property bool keepAwake: QsSingletons.Flags.keepAwake
    readonly property bool time12h: QsSingletons.Flags.time12h
    readonly property bool clockSeconds: QsSingletons.Flags.clockSeconds
    readonly property bool showGlyphs: QsSingletons.Flags.showGlyphs
    readonly property string paletteMode: QsSingletons.Flags.paletteMode
    readonly property real uiScale: QsSingletons.Flags.uiScale
    readonly property bool reduceMotion: QsSingletons.Flags.reduceMotion
    readonly property int manualHue: QsSingletons.Flags.manualHue
    readonly property bool manualDark: QsSingletons.Flags.manualDark
    readonly property real manualSat: QsSingletons.Flags.manualSat
    readonly property string uiFont: QsSingletons.Flags.uiFont
    readonly property real pillOpacity: QsSingletons.Flags.pillOpacity
    readonly property bool pillBlur: QsSingletons.Flags.pillBlur
    readonly property int idleLockMin: QsSingletons.Flags.idleLockMin
    readonly property int idleScreenOffMin: QsSingletons.Flags.idleScreenOffMin
    readonly property int idleSuspendMin: QsSingletons.Flags.idleSuspendMin
    readonly property string weatherCity: QsSingletons.Flags.weatherCity
    readonly property int recordCountdown: QsSingletons.Flags.recordCountdown
    readonly property string recordDir: QsSingletons.Flags.recordDir
    readonly property int recordFps: QsSingletons.Flags.recordFps
    readonly property string recordQuality: QsSingletons.Flags.recordQuality
    readonly property bool recordCursor: QsSingletons.Flags.recordCursor
    readonly property bool recordMic: QsSingletons.Flags.recordMic
    readonly property bool recordDesktop: QsSingletons.Flags.recordDesktop
    readonly property int recordClearedBefore: QsSingletons.Flags.recordClearedBefore
}

