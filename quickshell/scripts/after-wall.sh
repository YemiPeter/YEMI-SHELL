#!/bin/bash
# after-wall.sh — SINGLE WRITER of colors.json
# Usage: after-wall.sh <mood> [wallpaper-path]
#
# v2 default path: uses Matugen to write ~/.cache/yemi-shell/colors.json in the
# v2 schema (version, generator, wallpaper, seed, scheme_type, dark.{24}, light.{24})
# and fans out terminal.json + hypr-colors.lua from Matugen's base16 output.
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
# LEGACY PATH — original wallcolors.py pipeline
# ---------------------------------------------------------------------------
if [ "$LEGACY" = "1" ]; then
    if [ "$PMODE" = "static" ]; then
        python3 "$SCRIPTS/wallcolors.py" --mode static --mood "$MOOD"
    else
        WALL_PATH="$(resolve_wallpaper)"
        python3 "$SCRIPTS/wallcolors.py" --mode dynamic --mood "$MOOD" "$WALL_PATH"
    fi

else
    # -------------------------------------------------------------------------
    # V2 PATH — Matugen colors.json v2
    # -------------------------------------------------------------------------
    WALL_PATH="$(resolve_wallpaper)"
    mkdir -p "$CACHE"

    # Run Matugen once per mode so the mode-resolved `.default` token can be read
    # directly. (A single dump also embeds both variants, but two resolved runs are
    # unambiguous and match the documented output contract.)
    DARK_JSON="$(matugen image "$WALL_PATH" -j hex -m dark --dry-run -t "$SCHEME_TYPE" -q --source-color-index 0 2>/dev/null || true)"
    LIGHT_JSON="$(matugen image "$WALL_PATH" -j hex -m light --dry-run -t "$SCHEME_TYPE" -q --source-color-index 0 2>/dev/null || true)"

    if [ -z "$DARK_JSON" ] || [ -z "$LIGHT_JSON" ]; then
        echo "[yemi-shell] matugen failed to produce a color scheme" >&2
        exit 1
    fi

    # The 24 Material 3 role tokens required by the v2 schema.
    TOKENS='{primary,on_primary,primary_container,on_primary_container,secondary,secondary_container,tertiary,tertiary_container,surface,surface_container_lowest,surface_container_low,surface_container,surface_container_high,surface_container_highest,on_surface,on_surface_variant,outline,outline_variant,inverse_surface,inverse_on_surface,error,on_error,error_container,on_error_container}'


    # Extract a mode-resolved block object from a matugen JSON string.
    scheme_block() { # $1 = matugen json string, $2 = mode (dark|light)
        printf '%s' "$1" | jq -c --arg m "$2" ".colors | $TOKENS | with_entries(.value = .value[\$m].color)"
    }

    dark_block="$(scheme_block "$DARK_JSON" dark)"
    light_block="$(scheme_block "$LIGHT_JSON" light)"

    seed="$(printf '%s' "$DARK_JSON" | jq -r '.colors.source_color.default.color')"

    # -------------------------------------------------------------------------
    # Write colors.json v2 ATOMICALLY (.tmp → mv) so QML never reads a half file.
    # -------------------------------------------------------------------------
    jq -n \
        --arg wallpaper "$WALL_PATH" \
        --arg seed "$seed" \
        --arg scheme_type "$SCHEME_TYPE" \
        --argjson dark "$dark_block" \
        --argjson light "$light_block" \
        '{version:2,generator:"matugen",wallpaper:$wallpaper,seed:$seed,scheme_type:$scheme_type,dark:$dark,light:$light}' \
        > "$CACHE/colors.json.tmp"
    mv -f "$CACHE/colors.json.tmp" "$CACHE/colors.json"

    # -------------------------------------------------------------------------
    # terminal.json — fan-out source for apply-terminal-colors.py (single source
    # of truth for all terminal emulators). Rebuilt from Matugen base16 with the
    # exact same termN mapping wallcolors.py produced.
    # -------------------------------------------------------------------------
    printf '%s' "$DARK_JSON" | jq -c \
        --arg primary "$(printf '%s' "$DARK_JSON" | jq -r '.colors.primary.dark.color')" \
        '{term0:.base16.base00.dark.color,
          term1:.base16.base08.dark.color,
          term2:.base16.base0b.dark.color,
          term3:.base16.base0a.dark.color,
          term4:.base16.base0d.dark.color,
          term5:.base16.base0e.dark.color,
          term6:.base16.base0c.dark.color,
          term7:.base16.base05.dark.color,
          term8:.base16.base03.dark.color,
          term9:.base16.base08.dark.color,
          term10:.base16.base0b.dark.color,
          term11:.base16.base0a.dark.color,
          term12:.base16.base0d.dark.color,
          term13:.base16.base0e.dark.color,
          term14:.base16.base0c.dark.color,
          term15:.base16.base07.dark.color,
          primary:$primary}' > "$CACHE/terminal.json.tmp"
    mv -f "$CACHE/terminal.json.tmp" "$CACHE/terminal.json"

    # -------------------------------------------------------------------------
    # hypr-colors.lua — active/inactive border colors for Hyprland.
    # -------------------------------------------------------------------------
    active="$(printf '%s' "$DARK_JSON" | jq -r '.colors.primary.dark.color')"
    inactive="$(printf '%s' "$DARK_JSON" | jq -r '.base16.base01.dark.color')"
    printf 'return {\n    active = "%s",\n    inactive = "%s",\n}\n' "$active" "$inactive" \
        > "$CACHE/hypr-colors.lua.tmp"
    mv -f "$CACHE/hypr-colors.lua.tmp" "$CACHE/hypr-colors.lua"
fi

# Fan terminal.json out to kitty / ghostty / etc.
python3 "$SCRIPTS/apply-terminal-colors.py" || true

# Signal quickshell to re-read (registered target, not the dead matugenReload)
qs ipc call colors reload 2>/dev/null || true
