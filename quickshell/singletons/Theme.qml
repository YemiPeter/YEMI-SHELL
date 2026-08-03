pragma Singleton
import QtQuick
import Quickshell
import qs.modules.common

/**
 * Pill palette — now sourced from the LIVE Matugen pipeline.
 *
 * Previously this read from `Dyn` (the wallcolors.py HSL pipeline), which is
 * now retired. The dynamic branch now reads from `Appearance.m3colors` /
 * `Appearance.colors` — the switchwall.sh → Matugen → MaterialThemeLoader
 * pipeline that feeds the whole shell. Static mode keeps the curated washi/flame
 * hex as the identity/default.
 *
 * The token names are unchanged so the ~1030 pill references keep working; only
 * the data source is re-pointed to the live pipeline.
 */
Singleton {
    readonly property bool dyn: Flags.paletteMode !== "static"

    // ── Live pipeline sources (Appearance) ──────────────────────────────
    readonly property color _primary:      Appearance.colors.colPrimary
    readonly property color _primaryContainer: Appearance.colors.colPrimaryContainer
    readonly property color _onPrimaryContainer: Appearance.colors.colOnPrimaryContainer
    readonly property color _onSurface:    Appearance.colors.colOnSurface
    readonly property color _onBackground: Appearance.m3colors.m3onBackground
    readonly property color _surface:      Appearance.colors.colLayer0Base
    readonly property color _surfaceLow:   Appearance.colors.colLayer1Base
    readonly property color _surfaceHigh:  Appearance.colors.colLayer2Base
    readonly property color _surfaceHighest: Appearance.colors.colLayer3Base
    readonly property color _outlineVariant: Appearance.colors.colOutlineVariant

    // Alpha helper for onSurface-derived tokens
    function _onSurfaceA(a: real): color {
        return Qt.rgba(_onSurface.r, _onSurface.g, _onSurface.b, a)
    }

    // Convert a color to a #rrggbb hex string (for Canvas gradients)
    function _toHex(c: color): string {
        return "#" + ((1 << 24) | (Math.round(c.r * 255) << 16) | (Math.round(c.g * 255) << 8) | Math.round(c.b * 255)).toString(16).slice(1)
    }

    /**
     * Bright warm pop shared by the flame glow, charging glyphs, the recording
     * countdown, the unread inbox dot, the calendar's today cell and the held
     * power tile. Dynamic branch uses the wallpaper accent (m3primary).
     * Static mode keeps the fixed warm hex.
     */
    readonly property color onGlow: dyn ? _primary : "#ff9a64"

    readonly property color verm:     dyn ? Qt.darker(_primary, 1.18) : "#c0442b"
    readonly property color vermLit:  dyn ? _primary : "#e0563b"
    readonly property color vermDeep: dyn ? _primaryContainer : "#a3371f"
    readonly property color cream:    dyn ? _onSurface : "#e6d6cb"
    readonly property color bright:   dyn ? _onBackground : "#fff6f0"
    readonly property color dim:      dyn ? _onSurfaceA(0.6) : "#8a7d74"
    readonly property color cardTop:  dyn ? _surfaceHigh : "#2e231b"
    readonly property color cardBot:  dyn ? _surfaceLow : "#221813"
    readonly property color border:   dyn ? _outlineVariant : "#3a2a22"
    readonly property color shadow:     Qt.rgba(0, 0, 0, 0.55)
    readonly property color tileBg:   dyn ? _surface : "#211711"
    readonly property color subtle:   dyn ? _onSurfaceA(0.75) : "#b9a99e"
    readonly property color faint:    dyn ? _onSurfaceA(0.45) : "#6f635b"
    readonly property color iconDim:  dyn ? _onSurfaceA(0.8) : "#cdbfb4"
    readonly property color hair:     Qt.alpha(cream, 0.13)
    readonly property color hairSoft: Qt.alpha(cream, 0.08)
    readonly property color sheen:    Qt.alpha(cream, 0.07)
    readonly property color vermDim:   dyn ? Qt.darker(_primary, 1.5) : "#8a5440"
    readonly property color vermDimDeep: dyn ? Qt.darker(_primary, 2.2) : "#5a3526"
    readonly property color vermBurn:  dyn ? Qt.darker(_primaryContainer, 1.1) : "#8a2c14"
    readonly property color tickRest:  dyn ? _onSurfaceA(0.7) : "#cbb6a3"
    readonly property color threadBg:  Qt.alpha(cream, 0.13)
    readonly property color flameCore: dyn ? Qt.lighter(onGlow, 1.03) : "#ffd9c2"
    readonly property color flameGlow: dyn ? onGlow : "#ff9a64"

    /**
     * Flame canvas ramp: literal hex strings (color type won't work), fed
     * directly to Canvas addColorStop/strokeStyle. A color property serializes
     * to #aarrggbb and corrupts the gradient render, so the dynamic branch
     * converts the live m3colors to hex strings via the local _toHex().
     */
    readonly property string flameInk:   dyn ? _toHex(_primary) : "#f0795a"
    readonly property string flameEmber: dyn ? _toHex(_primaryContainer) : "#7e2812"
    readonly property string flameBurn:  dyn ? _toHex(_primaryContainer) : "#8a2c14"
    readonly property string flameTip:   dyn ? _toHex(_onPrimaryContainer) : "#ffb38a"
    readonly property color todayWarm: dyn ? onGlow : "#ffb38a"
    readonly property color ghost:     dyn ? _surfaceHighest : "#594636"
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