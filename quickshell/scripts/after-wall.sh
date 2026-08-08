#!/bin/bash
# after-wall.sh — SINGLE WRITER of colors.json
# Usage: after-wall.sh <mood> [wallpaper-path]

set -euo pipefail

MOOD="${1:-dark}"
WALL_PATH="${2:-}"
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
FLAGS_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/flags.json"

# Derive mode from flags.json if not forced
PMODE="$(jq -r '.paletteMode // "dynamic"' "$FLAGS_FILE" 2>/dev/null || echo dynamic)"

if [ "$PMODE" = "static" ]; then
    python3 "$SCRIPTS/wallcolors.py" --mode static --mood "$MOOD"
else
    # Dynamic mode needs a wallpaper
    if [ -z "$WALL_PATH" ]; then
        WALL_PATH="$(cat "${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-wallpaper" 2>/dev/null || true)"
    fi
    [ -f "$WALL_PATH" ] || { echo "[yemi-shell] no wallpaper for dynamic mode"; exit 1; }
    python3 "$SCRIPTS/wallcolors.py" --mode dynamic --mood "$MOOD" "$WALL_PATH"
fi

python3 "$SCRIPTS/apply-terminal-colors.py"

# Signal quickshell to re-read (registered target, not the dead matugenReload)
qs ipc call colors reload 2>/dev/null || true
