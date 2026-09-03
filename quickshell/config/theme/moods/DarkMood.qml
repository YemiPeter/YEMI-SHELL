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

    // --- Surfaces (warm dark, Ricelin parity) -------------------------
    readonly property color tileBg: "#211711"
    readonly property color cardTop: "#2e231b"
    readonly property color cardBot: "#221813"
    readonly property color ghost: "#594636"

    // --- Text (near-white ramp) ---------------------------------------
    readonly property color cream: "#f0f0f0"
    readonly property color bright: "#ffffff"
    readonly property color dim: "#aaaaaa"
    readonly property color subtle: "#9e9e9e"
    readonly property color faint: "#757575"
    readonly property color iconDim: "#a0a0a0"

    // --- Borders (warm brown, blends with warm surfaces) --------------
    readonly property color border: "#3a2a22"
    readonly property color hair: "#2a1d17"
    readonly property color hairSoft: "#1f1612"

    // --- Effects ------------------------------------------------------
    property real shadowStrength: 0.55
    property real highlightAlpha: 0.13
}