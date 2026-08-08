pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Live wallpaper-derived palette (colors.json v2).
 *
 * after-wall.sh (the single writer) hands off colour generation to matugen,
 * which writes a small JSON contract to ~/.cache/yemi-shell/colors.json on
 * every wallpaper change. This singleton watches that file, parses it into the
 * two named schemes (Dyn.dark, Dyn.light) and exposes the currently active one
 * (Dyn.active), which follows Flags.systemMood ("dark" or "light").
 *
 * The old flat aliases (Dyn.surface, Dyn.primary, Dyn.cream, ...) are kept and
 * resolve to the ACTIVE scheme, so existing consumers keep working while the
 * Appearance/Theme facade is migrated in later sections.
 *
 * Falls back to a warm, hand-picked palette when the file is missing or
 * corrupt so the shell never crashes and always yields a usable scheme. The
 * reload() function is re-entrant and idempotent: it reassigns the scheme
 * objects (and bumps `revision`) so QML bindings re-evaluate every time, even
 * when the mood changes with the same underlying file.
 */
Singleton {
    id: root

    /// Bumped on every successful reload / mood change so bindings refresh.
    readonly property int revision: _revision
    property int _revision: 0

    /// Metadata from the v2 file (raw contract copy).
    readonly property var data: _data
    property var _data: ({})

    /// Dark and light M3 schemes (each an object of string tokens).
    readonly property var dark: _dark
    property var _dark: ({})

    readonly property var light: _light
    property var _light: ({})

    /// The currently active scheme, following Flags.systemMood.
    readonly property var active: (Flags.systemMood === "light") ? root._light : root._dark

    // ------------------------------------------------------------------
    // Kept flat aliases — resolve against the ACTIVE scheme so existing
    // consumers (Theme, Appearance, pill/bar/osd components) keep working.
    // Touching `revision` forces these to re-evaluate on reload/mood change.
    // ------------------------------------------------------------------
    readonly property string surface: active && active.surface !== undefined ? active.surface : "#18120b"
    readonly property string surfaceContainer: active && active.surface_container !== undefined ? active.surface_container : "#251f17"
    readonly property string surfaceContainerLow: active && active.surface_container_low !== undefined ? active.surface_container_low : "#211b13"
    readonly property string surfaceContainerHigh: active && active.surface_container_high !== undefined ? active.surface_container_high : "#302921"
    readonly property string surfaceContainerHighest: active && active.surface_container_highest !== undefined ? active.surface_container_highest : "#3b342b"
    readonly property string primary: active && active.primary !== undefined ? active.primary : "#f5bd6f"
    readonly property string primaryContainer: active && active.primary_container !== undefined ? active.primary_container : "#633f00"
    readonly property string onPrimaryContainer: active && active.on_primary_container !== undefined ? active.on_primary_container : "#ffddb3"
    readonly property string outline: active && active.outline !== undefined ? active.outline : "#9c8f80"
    readonly property string outlineVariant: active && active.outline_variant !== undefined ? active.outline_variant : "#4f4539"
    readonly property string onSurface: active && active.on_surface !== undefined ? active.on_surface : "#e6e2de"
    readonly property string onSurfaceVariant: active && active.on_surface_variant !== undefined ? active.on_surface_variant : "#cbc6ba"
    readonly property string error: active && active.error !== undefined ? active.error : "#ffb4ab"

    // Derived Yemi text/accent ramp — currently mapped to surface-variant-ish
    // tone families for contrast safety. Refined by the Appearance adapter
    // (Section 8); these are safe fallbacks that stay readable either mood.
    readonly property string cream: active && active.on_surface !== undefined ? active.on_surface : "#e6d6cb"
    readonly property string bright: active && active.on_surface !== undefined ? active.on_surface : "#fff6f0"
    readonly property string subtle: active && active.on_surface_variant !== undefined ? active.on_surface_variant : "#b9a99e"
    readonly property string dim: active && active.outline !== undefined ? active.outline : "#8a7d74"
    readonly property string faint: active && active.outline_variant !== undefined ? active.outline_variant : "#6f635b"
    readonly property string iconDim: active && active.on_surface_variant !== undefined ? active.on_surface_variant : "#cdbfb4"
    readonly property string tickRest: active && active.outline !== undefined ? active.outline : "#cbb6a3"

    // ------------------------------------------------------------------
    // Internal state
    // ------------------------------------------------------------------
    readonly property string colorsPath: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/yemi-shell/colors.json"

    /// Hand-picked warm fallback used when the file is missing or corrupt.
    readonly property var fallbackDark: ({
        "primary": "#f5bd6f",
        "on_primary": "#3f2d00",
        "primary_container": "#633f00",
        "on_primary_container": "#ffddb3",
        "secondary": "#e3c29c",
        "secondary_container": "#453321",
        "tertiary": "#e2c1a5",
        "tertiary_container": "#3d2c1f",
        "surface": "#18120b",
        "surface_container_lowest": "#130d07",
        "surface_container_low": "#211b13",
        "surface_container": "#251f17",
        "surface_container_high": "#302921",
        "surface_container_highest": "#3b342b",
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
        var key, val;
        for (key in fallback) {
            // If the file is missing a key, carry the fallback value only.
            out[key] = (scheme && scheme[key] !== undefined) ? scheme[key] : fallback[key];
        }
        return out;
    }

    /// Re-read the file. Never throws; a bad read just keeps the last good values.
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
            root._dark = root._normalize(dScheme, root.fallbackDark);
            root._light = root._normalize(lScheme, root.fallbackLight);
            root._data = obj; // keep the raw contract for metadata
        } else {
            // Missing or corrupt: keep the safe fallback schemes.
            root._dark = root._normalize({}, root.fallbackDark);
            root._light = root._normalize({}, root.fallbackLight);
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
            if (error === FileViewError.FileNotFound)
                reload(); // keep fallbacks; bump revision so bindings settle
            else
                reload();
        }
    }

    Component.onCompleted: reload()
}
