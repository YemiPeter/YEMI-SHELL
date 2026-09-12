#!/bin/bash
# after-wall.sh — SINGLE WRITER of colors.json
# Usage: after-wall.sh <mood> [wallpaper-path]
#
# v2 default path: uses the dominance engine to write ~/.cache/yemi-shell/colors.json in the
# v2 schema (version, generator, wallpaper, seed, scheme_type, dark.{24}, light.{24})
# and fans out terminal.json + hypr-colors.lua from the dominance palette.
#
# Legacy path: set YEMI_LEGACY_COLORS=1 to use the original wallcolors.py pipeline,
# which writes colors.json (old pill schema), terminal.json and hypr-colors.lua
# together.

set -euo pipefail

MOOD="${1:-dark}"
WALL_PATH="${2:-}"
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/yemi-shell"
FLAGS_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/flags.json"

# Forcible env overrides
SCHEME_TYPE="${YEMI_SCHEME_TYPE:-scheme-content}"
LEGACY="${YEMI_LEGACY_COLORS:-0}"

# Derive mode from flags.json if not forced
PMODE="$(jq -r '.paletteMode // "dynamic"' "$FLAGS_FILE" 2>/dev/null || echo dynamic)"

# Resolve the wallpaper (either forced, or the state file).
resolve_wallpaper() {
    local wp="$WALL_PATH"
    if [ -z "$wp" ]; then
        wp="$(cat "${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-wallpaper" 2>/dev/null || true)"
    fi
    if [ ! -f "$wp" ]; then
        echo "[yemi-shell] no wallpaper found (required for dynamic mode)" >&2
        exit 1
    fi
    printf '%s' "$wp"
}

# ---------------------------------------------------------------------------
# Backdrop color source (D1#6): when the user opts to theme the shell from the
# backdrop image, derive colors from the separately-configured backdrop image
# rather than the main wallpaper. Only applies when a separate backdrop image
# is actually configured (backdropUseMainWallpaper=false + backdropWallpaperPath).
# ---------------------------------------------------------------------------
maybe_use_backdrop_colors() {
    local theme_from_backdrop
    theme_from_backdrop="$(jq -r '.backdropThemeColors // false' "$FLAGS_FILE" 2>/dev/null || echo false)"
    if [ "$theme_from_backdrop" != "true" ]; then
        return 0
    fi
    local use_main backdrop_path
    use_main="$(jq -r '.backdropUseMainWallpaper // true' "$FLAGS_FILE" 2>/dev/null || echo true)"
    backdrop_path="$(jq -r '.backdropWallpaperPath // ""' "$FLAGS_FILE" 2>/dev/null || echo "")"
    if [ "$use_main" = "true" ] || [ -z "$backdrop_path" ] || [ ! -f "$backdrop_path" ]; then
        echo "[yemi-shell] backdropThemeColors on but no separate backdrop image configured; using main wallpaper" >&2
        return 0
    fi
    echo "[yemi-shell] deriving theme colors from backdrop image: $backdrop_path" >&2
    WALL_PATH="$backdrop_path"
}

# ---------------------------------------------------------------------------
# LEGACY PATH — original wallcolors.py pipeline
# ---------------------------------------------------------------------------
if [ "$LEGACY" = "1" ]; then
    if [ "$PMODE" = "static" ]; then
        python3 "$SCRIPTS/wallcolors.py" --mode static --mood "$MOOD"
    else
        WALL_PATH="$(resolve_wallpaper)"
        maybe_use_backdrop_colors
        python3 "$SCRIPTS/wallcolors.py" --mode dynamic --mood "$MOOD" "$WALL_PATH"
    fi

else
    # -------------------------------------------------------------------------
    # V2 PATH — dominance engine colors.json v2
    # -------------------------------------------------------------------------
    WALL_PATH="$(resolve_wallpaper)"
    maybe_use_backdrop_colors
    mkdir -p "$CACHE"

    # Run the dominance engine once — it emits BOTH dark and light in one call,
    # so color derivation and dark/light emission happen in a single capture.
    ENGINE_JSON="$(python3 "$SCRIPTS/dominance-engine.py" "$WALL_PATH" 2>/dev/null || true)"

    if [ -z "$ENGINE_JSON" ]; then
        echo "[yemi-shell] dominance engine failed to produce a color scheme" >&2
        exit 1
    fi

    # -------------------------------------------------------------------------
    # Write colors.json v2 ATOMICALLY (.tmp → cat > target) so QML never reads a
    # half file and the inode stays stable for FileView live-reload.
    # -------------------------------------------------------------------------
    printf '%s' "$ENGINE_JSON" > "$CACHE/colors.json.tmp"
    cat "$CACHE/colors.json.tmp" > "$CACHE/colors.json" && rm "$CACHE/colors.json.tmp"

    # -------------------------------------------------------------------------
    # terminal.json — fan-out source for apply-terminal-colors.py (single source
    # of truth for all terminal emulators). Derived from the dominance palette's
    # dark block. Basic mapping; readability polish is Phase 4.
    # -------------------------------------------------------------------------
    printf '%s' "$ENGINE_JSON" | jq -c \
        '{term0:.dark.surface_container_lowest,
          term1:.dark.error,
          term2:.dark.tertiary,
          term3:.dark.secondary,
          term4:.dark.primary,
          term5:.dark.tertiary_container,
          term6:.dark.primary_container,
          term7:.dark.on_surface,
          term8:.dark.surface_container_highest,
          term9:.dark.error_container,
          term10:.dark.tertiary_container,
          term11:.dark.secondary_container,
          term12:.dark.primary_container,
          term13:.dark.secondary_container,
          term14:.dark.primary_container,
          term15:.dark.on_surface_variant,
          primary:.dark.primary}' > "$CACHE/terminal.json.tmp"
    cat "$CACHE/terminal.json.tmp" > "$CACHE/terminal.json" && rm "$CACHE/terminal.json.tmp"

    # -------------------------------------------------------------------------
    # hypr-colors.lua — active/inactive border colors for Hyprland.
    # -------------------------------------------------------------------------
    active="$(printf '%s' "$ENGINE_JSON" | jq -r '.dark.primary')"
    inactive="$(printf '%s' "$ENGINE_JSON" | jq -r '.dark.surface_container_high')"
    printf 'return {\n    active = "%s",\n    inactive = "%s",\n}\n' "$active" "$inactive" \
        > "$CACHE/hypr-colors.lua.tmp"
    cat "$CACHE/hypr-colors.lua.tmp" > "$CACHE/hypr-colors.lua" && rm "$CACHE/hypr-colors.lua.tmp"
fi

# Fan terminal.json out to kitty / ghostty / etc.
python3 "$SCRIPTS/apply-terminal-colors.py" || true

# Debug logging: report file state before IPC, call IPC without hiding errors,
# and report exit code after so we can trace failures in the IPC roundtrip.
echo "[after-wall.sh] About to call IPC reload"

# Signal quickshell to re-read (registered target, not the dead matugenReload)
# NOTE: intentionally not redirecting stderr/stdout or swallowing errors so we
# can see failures during diagnosis.
qs ipc call colors reload
echo "[after-wall.sh] IPC call completed with exit code: $?"
