pragma Singleton
import QtQuick
import Quickshell
import "../config" as QsConfig
import qs.config

/**
 * Pill palette facade.
 *
 * All mode switching (dynamic vs static, dark vs light) is handled by the
 * Appearance adapter (config/Appearance.qml). This singleton simply maps the
 * old public token names onto Appearance's resolved tokens, so existing
 * consumers keep working unchanged while the engine underneath is replaced.
 *
 * Flame canvas tokens remain literal hex strings (#rrggbb) — a color property
 * serializes to #aarrggbb and corrupts the gradient render.
 */
Singleton {
    // --- Surfaces -----------------------------------------------------
    readonly property color tileBg: QsConfig.Appearance.yemiTileBg
    readonly property color cardTop: QsConfig.Appearance.yemiCardTop
    readonly property color cardBot: QsConfig.Appearance.yemiCardBot
    readonly property color ghost: QsConfig.Appearance.m3.surfaceContainerHighest || "#3a3a3a"

    // --- Text ---------------------------------------------------------
    readonly property color cream: QsConfig.Appearance.yemiCream
    readonly property color bright: QsConfig.Appearance.yemiBright
    readonly property color subtle: QsConfig.Appearance.yemiSubtle
    readonly property color dim: QsConfig.Appearance.yemiDim
    readonly property color faint: QsConfig.Appearance.yemiFaint
    readonly property color iconDim: QsConfig.Appearance.yemiSubtle

    // --- Accents (verm family) ----------------------------------------
    readonly property color onGlow: QsConfig.Appearance.yemiPrimary
    readonly property color verm: Qt.darker(QsConfig.Appearance.yemiPrimary, 1.18)
    readonly property color vermLit: QsConfig.Appearance.yemiPrimary
    readonly property color vermDeep: QsConfig.Appearance.yemiPrimaryContainer
    readonly property color vermDim: Qt.darker(QsConfig.Appearance.yemiPrimary, 1.5)
    readonly property color vermDimDeep: Qt.darker(QsConfig.Appearance.yemiPrimary, 2.2)
    readonly property color vermBurn: Qt.darker(QsConfig.Appearance.yemiPrimaryContainer, 1.1)
    readonly property color tickRest: QsConfig.Appearance.yemiDim

    // --- Borders ------------------------------------------------------
    readonly property color border: QsConfig.Appearance.yemiBorder

    // --- Flame Canvas Strings (MUST remain strings, not colors) -------
    readonly property string flameInk: QsConfig.Appearance.flameInk
    readonly property string flameEmber: QsConfig.Appearance.flameEmber
    readonly property string flameBurn: QsConfig.Appearance.flameBurn
    readonly property string flameTip: QsConfig.Appearance.flameTip

    // --- Derived Alphas (depend on 'cream') ---------------------------
    readonly property color hair: Qt.alpha(cream, 0.13)
    readonly property color hairSoft: Qt.alpha(cream, 0.08)
    readonly property color sheen: Qt.alpha(cream, 0.07)
    readonly property color threadBg: Qt.alpha(cream, 0.13)
    readonly property color frameBg: Qt.alpha(cream, 0.055)
    readonly property color frameBorder: Qt.alpha(cream, 0.10)
    readonly property color creamMenu: Qt.alpha(cream, 0.82)

    // --- Fixed Tokens -------------------------------------------------
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.55)
    readonly property real shadowOpacity: 0.5
    readonly property var fontFamilies: Qt.fontFamilies()
    readonly property string font: (Flags.uiFont.length > 0 && fontFamilies.indexOf(Flags.uiFont) >= 0) ? Flags.uiFont : "Inter"
    readonly property string fontJp: "Zen Kaku Gothic New"

    /**
     * MPRIS trackArtists arrives as a JS array from some players and as a
     * plain string from others (Spotify); calling join on the string throws
     * and kills the whole binding. Handles both, falls back to trackArtist.
     */
    function joinArtists(artists, single) {
        if (artists && typeof artists.join === "function" && artists.length > 0)
            return artists.join(", ");
        if (artists && String(artists).length > 0)
            return String(artists);
        return single ? String(single) : "";
    }
}