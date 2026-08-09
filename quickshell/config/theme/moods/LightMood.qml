pragma Singleton
import QtQuick

/**
 * Light static mood definition.
 *
 * Pure static values — no wallpaper-derived or runtime logic is referenced.
 * These are the hardcoded Light-mode surfaces, text, borders and effects used
 * when the static palette source is active. Text is near-black on near-white
 * surfaces.
 *
 * Note: `shadowStrength` and `highlightAlpha` are intentionally `property` (not
 * `readonly`) so a later orchestrator can tone them without a rebuild; the
 * colour tokens are frozen constants.
 */
QtObject {
    id: mood

    // --- Surfaces (pure white / near-white) ---------------------------
    readonly property color tileBg: "#ffffff"
    readonly property color cardTop: "#ffffff"
    readonly property color cardBot: "#f5f5f5"
    readonly property color ghost: "#e0e0e0"

    // --- Text (near-black ramp) ---------------------------------------
    readonly property color cream: "#141414"
    readonly property color bright: "#000000"
    readonly property color dim: "#616161"
    readonly property color subtle: "#757575"
    readonly property color faint: "#9e9e9e"
    readonly property color iconDim: "#757575"

    // --- Borders ------------------------------------------------------
    readonly property color border: "#e0e0e0"
    readonly property color hair: "#d0d0d0"
    readonly property color hairSoft: "#dcdcdc"

    // --- Effects ------------------------------------------------------
    property real shadowStrength: 0.35
    property real highlightAlpha: 0.08
}