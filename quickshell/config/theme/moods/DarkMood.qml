pragma Singleton
import QtQuick

/**
 * Dark static mood definition.
 *
 * Pure static values — no wallpaper-derived or runtime logic is referenced.
 * These are the hardcoded Dark-mode surfaces, text, borders and effects used
 * when the static palette source is active. Text is near-white on near-black
 * surfaces.
 *
 * Note: `shadowStrength` and `highlightAlpha` are intentionally `property` (not
 * `readonly`) so a later orchestrator can tone them without a rebuild; the
 * colour tokens are frozen constants.
 */
QtObject {
    id: mood

    // --- Surfaces (pure black / near-black) ---------------------------
    readonly property color tileBg: "#000000"
    readonly property color cardTop: "#141414"
    readonly property color cardBot: "#0d0d0d"
    readonly property color ghost: "#3a3a3a"

    // --- Text (near-white ramp) ---------------------------------------
    readonly property color cream: "#f0f0f0"
    readonly property color bright: "#ffffff"
    readonly property color dim: "#aaaaaa"
    readonly property color subtle: "#9e9e9e"
    readonly property color faint: "#757575"
    readonly property color iconDim: "#a0a0a0"

    // --- Borders ------------------------------------------------------
    readonly property color border: "#3a3a3a"
    readonly property color hair: "#2a2a2a"
    readonly property color hairSoft: "#1f1f1f"

    // --- Effects ------------------------------------------------------
    property real shadowStrength: 0.55
    property real highlightAlpha: 0.13
}