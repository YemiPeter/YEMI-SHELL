pragma Singleton
import QtQuick
import "../../../singletons" as QsSingletons

/**
 * Shim: re-exports the project-wide Theme singleton so pill files
 * using `import "Singletons"` find `Theme.cream` etc. without changes.
 * Do NOT add new properties here — add them in singletons/Theme.qml.
 */
QtObject {
    id: root

    readonly property bool dyn: QsSingletons.Theme.dyn

    // Colors
    readonly property color onGlow: QsSingletons.Theme.onGlow
    readonly property color verm: QsSingletons.Theme.verm
    readonly property color vermLit: QsSingletons.Theme.vermLit
    readonly property color vermDeep: QsSingletons.Theme.vermDeep
    readonly property color cream: QsSingletons.Theme.cream
    readonly property color bright: QsSingletons.Theme.bright
    readonly property color dim: QsSingletons.Theme.dim
    readonly property color cardTop: QsSingletons.Theme.cardTop
    readonly property color cardBot: QsSingletons.Theme.cardBot
    readonly property color border: QsSingletons.Theme.border
    readonly property color shadow: QsSingletons.Theme.shadow
    readonly property color tileBg: QsSingletons.Theme.tileBg
    readonly property color subtle: QsSingletons.Theme.subtle
    readonly property color faint: QsSingletons.Theme.faint
    readonly property color iconDim: QsSingletons.Theme.iconDim
    readonly property color hair: QsSingletons.Theme.hair
    readonly property color hairSoft: QsSingletons.Theme.hairSoft
    readonly property color sheen: QsSingletons.Theme.sheen
    readonly property color vermDim: QsSingletons.Theme.vermDim
    readonly property color vermDimDeep: QsSingletons.Theme.vermDimDeep
    readonly property color vermBurn: QsSingletons.Theme.vermBurn
    readonly property color tickRest: QsSingletons.Theme.tickRest
    readonly property color threadBg: QsSingletons.Theme.threadBg
    readonly property color flameCore: QsSingletons.Theme.flameCore
    readonly property color flameGlow: QsSingletons.Theme.flameGlow

    // Flame canvas ramp (string type, not color)
    readonly property string flameInk: QsSingletons.Theme.flameInk
    readonly property string flameEmber: QsSingletons.Theme.flameEmber
    readonly property string flameBurn: QsSingletons.Theme.flameBurn
    readonly property string flameTip: QsSingletons.Theme.flameTip

    readonly property color todayWarm: QsSingletons.Theme.todayWarm
    readonly property color ghost: QsSingletons.Theme.ghost
    readonly property color frameBg: QsSingletons.Theme.frameBg
    readonly property color frameBorder: QsSingletons.Theme.frameBorder
    readonly property color creamMenu: QsSingletons.Theme.creamMenu
    readonly property real shadowOpacity: QsSingletons.Theme.shadowOpacity
    readonly property var fontFamilies: QsSingletons.Theme.fontFamilies
    readonly property string font: QsSingletons.Theme.font
    readonly property string fontJp: QsSingletons.Theme.fontJp

    // Functions
    function joinArtists(artists, single) {
        return QsSingletons.Theme.joinArtists(artists, single);
    }
}
