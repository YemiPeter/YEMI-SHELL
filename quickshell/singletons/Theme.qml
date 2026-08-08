 pragma Singleton
import QtQuick
import Quickshell

/**
 * Pill palette. Two sources: the curated washi/flame hex below is the identity
 * and the default, used whenever the dynamic-palette flag is off. With the flag
 * on, the surfaces and the whole accent ramp follow the wallpaper through the
 * matugen-fed `Dyn` singleton, while the text family, light veils and shadow
 * stay locked here so copy keeps its contrast on any generated background. Each
 * token is a single ternary, so static mode renders byte-identical to the fixed
 * theme and only the colours that should breathe with the wallpaper do.
 */
Singleton {
    readonly property bool dyn: Flags.paletteMode !== "static"

    /**
     * Static palettes for fallback when dynamic mode is off.
     * Dark mode: near-black surfaces, near-white text, minimal accent
     * Light mode: near-white surfaces, near-black text
     */
    readonly property var staticPaletteDark: ({
        // Surfaces - pure black with dark gray containers (iNiR materialBlackColors)
        surface: "#000000",
        surfaceContainerLow: "#0d0d0d",
        surfaceContainerHigh: "#1a1a1a",
        surfaceContainerHighest: "#242424",

        // Accent - pure grayscale
        onGlow: "#a0a0a0",

        // Verdict/destructive states - grayscale
        verm: "#a0a0a0",
        vermLit: "#b0b0b0",
        vermDeep: "#8a2c14",
        vermDim: "#8a5440",
        vermDimDeep: "#5a3526",
        vermBurn: "#8a2c14",

        // Neutral tonality - cool grays
        cream: "#141414",
        bright: "#0d0d0d",
        dim: "#545454",
        subtle: "#aaaaaa",
        faint: "#757575",
        iconDim: "#a0a0a0",

        // Cards & tiles
        cardTop: "#141414",
        cardBot: "#0d0d0d",
        border: "#3a3a3a",
        tileBg: "#000000",
        tickRest: "#a0a0a0",
        ghost: "#3a3a3a",

        // Flame elements - grayscale
        flameCore: "#ffffff",
        flameInk: "#a0a0a0",
        flameEmber: "#444444",
        flameBurn: "#444444",
        flameTip: "#f0f0f0",

        todayWarm: "#ffffff",
    })

    readonly property var staticPaletteLight: ({
        // Surfaces - pure white with light gray containers
        surface: "#ffffff",
        surfaceContainerLow: "#f5f5f5",
        surfaceContainerHigh: "#e0e0e0",
        surfaceContainerHighest: "#d0d0d0",

        // Accent - pure grayscale
        onGlow: "#5a5a5a",

        // Verdict/destructive states - grayscale
        verm: "#a0a0a0",
        vermLit: "#b0b0b0",
        vermDeep: "#8a2c14",
        vermDim: "#8a5440",
        vermDimDeep: "#5a3526",
        vermBurn: "#8a2c14",

        // Neutral tonality - grays
        cream: "#f0f0f0",
        bright: "#ffffff",
        dim: "#e0e0e0",
        subtle: "#9e9e9e",
        faint: "#616161",
        iconDim: "#757575",

        // Cards & tiles
        cardTop: "#ffffff",
        cardBot: "#f5f5f5",
        border: "#e0e0e0",
        tileBg: "#ffffff",
        tickRest: "#9e9e9e",
        ghost: "#e0e0e0",

        // Flame elements - grayscale
        flameCore: "#000000",
        flameInk: "#5a5a5a",
        flameEmber: "#e0e0e0",
        flameBurn: "#eeeeee",
        flameTip: "#f0f0f0",

        todayWarm: "#f0f0f0",
    })

    readonly property var staticPalette: Flags.systemMood === "dark" ? staticPaletteDark : staticPaletteLight

    /**
     * Bright warm pop shared by the flame glow, charging glyphs, the recording
     * countdown, the unread inbox dot, the calendar's today cell and the held
     * power tile. The dynamic branch uses the wallpaper accent (Dyn.primary):
     * matugen's on-primary-container does not populate here and collapses the
     * token to black, while the accent always loads and contrasts the pill
     * surface. Static mode keeps the fixed warm hex.
     */
    readonly property color onGlow: dyn ? Dyn.primary : staticPalette.onGlow

    readonly property color verm:     dyn ? Qt.darker(Dyn.primary, 1.18) : staticPalette.verm
    readonly property color vermLit:  dyn ? Dyn.primary : staticPalette.vermLit
    readonly property color vermDeep: dyn ? Dyn.primaryContainer : staticPalette.vermDeep
    readonly property color cream:    dyn ? Dyn.cream : staticPalette.cream
    readonly property color bright:   dyn ? Dyn.bright : staticPalette.bright
    readonly property color dim:      dyn ? Dyn.dim : staticPalette.dim
    readonly property color cardTop:  dyn ? Dyn.surfaceContainerHigh : staticPalette.cardTop
    readonly property color cardBot:  dyn ? Dyn.surfaceContainerLow : staticPalette.cardBot
    readonly property color border:   dyn ? Dyn.outlineVariant : staticPalette.border
    readonly property color shadow:   Qt.rgba(0, 0, 0, 0.55)
    readonly property color tileBg:   dyn ? Dyn.surface : staticPalette.tileBg
    readonly property color subtle:   dyn ? Dyn.subtle : staticPalette.subtle
    readonly property color faint:    dyn ? Dyn.faint : staticPalette.faint
    readonly property color iconDim:  dyn ? Dyn.iconDim : staticPalette.iconDim
    readonly property color hair:     Qt.alpha(cream, 0.13)
    readonly property color hairSoft: Qt.alpha(cream, 0.08)
    readonly property color sheen:    Qt.alpha(cream, 0.07)
    readonly property color vermDim:   dyn ? Qt.darker(Dyn.primary, 1.5) : staticPalette.vermDim
    readonly property color vermDimDeep: dyn ? Qt.darker(Dyn.primary, 2.2) : staticPalette.vermDimDeep
    readonly property color vermBurn:  dyn ? Qt.darker(Dyn.primaryContainer, 1.1) : staticPalette.vermBurn
    readonly property color tickRest:  dyn ? Dyn.tickRest : staticPalette.tickRest
    readonly property color threadBg:  Qt.alpha(cream, 0.13)
    readonly property color flameCore: dyn ? Qt.lighter(onGlow, 1.03) : staticPalette.flameCore
    readonly property color flameGlow: dyn ? onGlow : staticPalette.onGlow

    /**
     * Flame canvas ramp: literal hex strings (color type won't work), fed
     * directly to Canvas addColorStop/strokeStyle. A color property serializes
     * to #aarrggbb and corrupts the gradient render, so the dynamic branch passes
     * matugen's raw hex strings through untouched rather than any Qt.darker math.
     */
    readonly property string flameInk:   dyn ? Dyn.primary : staticPalette.flameInk
    readonly property string flameEmber: dyn ? Dyn.primaryContainer : staticPalette.flameEmber
    readonly property string flameBurn:  dyn ? Dyn.primaryContainer : staticPalette.flameBurn
    readonly property string flameTip:   dyn ? Dyn.onPrimaryContainer : staticPalette.flameTip
    readonly property color todayWarm: dyn ? onGlow : staticPalette.todayWarm
    readonly property color ghost:     dyn ? Dyn.surfaceContainerHighest : staticPalette.ghost
    readonly property color frameBg:      Qt.alpha(cream, 0.055)
    readonly property color frameBorder:  Qt.alpha(cream, 0.10)
    readonly property color creamMenu:     Qt.alpha(cream, 0.82)
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
