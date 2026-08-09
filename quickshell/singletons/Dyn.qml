pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Live wallpaper-derived palette (colors.json v2).
 *
 * after-wall.sh (the single writer) runs matugen and writes a v2 contract to
 * ~/.cache/yemi-shell/colors.json:
 *
 *   {
 *     "version": 2,
 *     "generator": "matugen",
 *     "dark":  { ... 24 material tokens ... },
 *     "light": { ... 24 material tokens ... }
 *   }
 *
 * This singleton watches that file, parses the nested dark/light objects into
 * Dyn.darkScheme / Dyn.lightScheme and exposes the currently active one
 * (Dyn.active), which follows Flags.systemMood ("dark" or "light").
 *
 * The old flat aliases (Dyn.surface, Dyn.primary, Dyn.cream, ...) are kept as
 * colour-typed properties that resolve against the ACTIVE scheme, so existing
 * consumers keep working while the Appearance/Theme facade is migrated in
 * later sections.
 *
 * Falls back to a warm, hand-picked palette when the file is missing, corrupt,
 * or does not carry "version": 2 so the shell never crashes and always yields
 * a usable scheme. reload() is re-entrant and idempotent: it reassigns the
 * scheme objects (and bumps `revision`) so QML bindings re-evaluate every
 * time, even when only the mood changes with the same underlying file.
 */
Singleton {
    id: root

    /// Bumped on every successful reload / mood change so bindings refresh.
    readonly property int revision: _revision
    property int _revision: 0

    /// Raw v2 contract copy (metadata).
    readonly property var data: _data
    property var _data: ({})

    /// Full dark and light M3 schemes (each an object of string tokens).
    readonly property var darkScheme: _darkScheme
    property var _darkScheme: ({})

    readonly property var lightScheme: _lightScheme
    property var _lightScheme: ({})

    /// Currently active scheme, following Flags.systemMood ("dark"/"light").
    readonly property var active: (Flags.systemMood === "light") ? root._lightScheme : root._darkScheme

    // ------------------------------------------------------------------
    // Kept flat aliases — resolve against the ACTIVE scheme so existing
    // consumers (Theme, Appearance, pill/bar/osd components) keep working.
    // Touching `revision` forces these to re-evaluate on reload/mood change.
    // ------------------------------------------------------------------

    // --- Original 17 tokens -------------------------------------------
    readonly property color surface: active && active.surface !== undefined ? active.surface : "#15130b"
    readonly property color surfaceContainer: active && active.surface_container !== undefined ? active.surface_container : "#232016"
    readonly property color surfaceContainerLow: active && active.surface_container_low !== undefined ? active.surface_container_low : "#1e1b12"
    readonly property color surfaceContainerHigh: active && active.surface_container_high !== undefined ? active.surface_container_high : "#2d2a1f"
    readonly property color surfaceContainerHighest: active && active.surface_container_highest !== undefined ? active.surface_container_highest : "#383529"
    readonly property color primary: active && active.primary !== undefined ? active.primary : "#dac76f"
    readonly property color primaryContainer: active && active.primary_container !== undefined ? active.primary_container : "#633f00"
    readonly property color onPrimaryContainer: active && active.on_primary_container !== undefined ? active.on_primary_container : "#ffddb3"
    readonly property color outline: active && active.outline !== undefined ? active.outline : "#9c8f80"
    readonly property color outlineVariant: active && active.outline_variant !== undefined ? active.outline_variant : "#4f4539"

    // Derived Yemi text/accent ramp — mapped to M3 tone families for contrast
    // safety. Refined by the Appearance adapter (Section 8); these safe
    // fallbacks keep text readable in either mood.
    readonly property color cream: active && active.on_surface !== undefined ? active.on_surface : "#e6d6cb"
    readonly property color bright: active && active.on_surface !== undefined ? active.on_surface : "#fff6f0"
    readonly property color subtle: active && active.on_surface_variant !== undefined ? active.on_surface_variant : "#b9a99e"
    readonly property color dim: active && active.outline !== undefined ? active.outline : "#8a7d74"
    readonly property color faint: active && active.outline_variant !== undefined ? active.outline_variant : "#6f635b"
    readonly property color iconDim: active && active.on_surface_variant !== undefined ? active.on_surface_variant : "#cdbfb4"
    readonly property color tickRest: active && active.outline !== undefined ? active.outline : "#cbb6a3"

    // --- New M3 flat aliases ------------------------------------------
    readonly property color surfaceContainerLowest: active && active.surface_container_lowest !== undefined ? active.surface_container_lowest : "#100d06"
    readonly property color onSurface: active && active.on_surface !== undefined ? active.on_surface : "#e6e2de"
    readonly property color onSurfaceVariant: active && active.on_surface_variant !== undefined ? active.on_surface_variant : "#cbc6ba"
    readonly property color secondary: active && active.secondary !== undefined ? active.secondary : "#e3c29c"
    readonly property color secondaryContainer: active && active.secondary_container !== undefined ? active.secondary_container : "#453321"
    readonly property color tertiary: active && active.tertiary !== undefined ? active.tertiary : "#e2c1a5"
    readonly property color tertiaryContainer: active && active.tertiary_container !== undefined ? active.tertiary_container : "#3d2c1f"
    readonly property color inverseSurface: active && active.inverse_surface !== undefined ? active.inverse_surface : "#f0e3d8"
    readonly property color inverseOnSurface: active && active.inverse_on_surface !== undefined ? active.inverse_on_surface : "#332a20"
    readonly property color error: active && active.error !== undefined ? active.error : "#ffb4ab"
    readonly property color errorContainer: active && active.error_container !== undefined ? active.error_container : "#93000a"
    readonly property color onError: active && active.on_error !== undefined ? active.on_error : "#690005"
    readonly property color onErrorContainer: active && active.on_error_container !== undefined ? active.on_error_container : "#ffdad6"

    // ------------------------------------------------------------------
    // Internal state
    // ------------------------------------------------------------------
    readonly property string colorsPath: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/yemi-shell/colors.json"

    /// Hand-picked warm fallback used when the file is missing or corrupt.
    readonly property var fallbackDark: ({
        "primary": "#dac76f",
        "on_primary": "#3f2d00",
        "primary_container": "#633f00",
        "on_primary_container": "#ffddb3",
        "secondary": "#e3c29c",
        "secondary_container": "#453321",
        "tertiary": "#e2c1a5",
        "tertiary_container": "#3d2c1f",
        "surface": "#15130b",
        "surface_container_lowest": "#100d06",
        "surface_container_low": "#1e1b12",
        "surface_container": "#232016",
        "surface_container_high": "#2d2a1f",
        "surface_container_highest": "#383529",
        "on_surface": "#f0e3d8",
        "on_surface_variant": "#cdbbb0",
        "outline": "#9c8f80",
        "outline_variant": "#4f4539",
        "inverse_surface": "#f0e3d8",
        "inverse_on_surface": "#332a20",
        "error": "#ffb4ab",
        "on_error": "#690005",
        "error_container": "#93000a",
        "on_error_container": "#ffdad6"
    })

    readonly property var fallbackLight: ({
        "primary": "#633f00",
        "on_primary": "#ffffff",
        "primary_container": "#ffddb3",
        "on_primary_container": "#201200",
        "secondary": "#715f45",
        "secondary_container": "#fde3bd",
        "tertiary": "#755946",
        "tertiary_container": "#ffdbc0",
        "surface": "#fffbff",
        "surface_container_lowest": "#ffffff",
        "surface_container_low": "#fdf2e7",
        "surface_container": "#f7ece1",
        "surface_container_high": "#f1e7dc",
        "surface_container_highest": "#ece1d6",
        "on_surface": "#211a13",
        "on_surface_variant": "#514438",
        "outline": "#837467",
        "outline_variant": "#d6c3b4",
        "inverse_surface": "#372f26",
        "inverse_on_surface": "#fdf0e4",
        "error": "#ba1a1a",
        "on_error": "#ffffff",
        "error_container": "#ffdad6",
        "on_error_container": "#410002"
    })

    /// Parse a scheme object from the v2 contract, merging safe fallbacks.
    function _normalize(scheme, fallback) {
        var out = {};
        for (var key in fallback) {
            // If the file is missing a key, carry the fallback value only.
            out[key] = (scheme && scheme[key] !== undefined) ? scheme[key] : fallback[key];
        }
        return out;
    }

    /// Re-read the file. Never throws; a bad read just keeps the last good
    /// values (or the warm fallback palette).
    function reload() {
        var dScheme, lScheme, obj;
        try {
            var t = file.text();
            if (t && t.trim().length > 0) {
                obj = JSON.parse(t);
                if (obj && obj.version === 2 && obj.dark && obj.light) {
                    dScheme = obj.dark;
                    lScheme = obj.light;
                }
            }
        } catch (e) {
            obj = undefined;
        }

        if (dScheme && lScheme) {
            root._darkScheme = root._normalize(dScheme, root.fallbackDark);
            root._lightScheme = root._normalize(lScheme, root.fallbackLight);
            root._data = obj; // keep the raw contract for metadata
        } else {
            // Missing, corrupt, or not version 2: safe warm fallbacks.
            root._darkScheme = root._normalize({}, root.fallbackDark);
            root._lightScheme = root._normalize({}, root.fallbackLight);
            root._data = {};
        }

        root._revision++; // force all bindings keyed off revision to refresh
    }

    FileView {
        id: file
        path: root.colorsPath
        blockLoading: true
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoadFailed: function (error) {
            reload(); // keep fallbacks; bump revision so bindings settle
        }
    }

    Component.onCompleted: reload()
}