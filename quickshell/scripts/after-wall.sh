#!/bin/bash
# yemi-shell wallpaper color pipeline
#
# Flow:
#   wallpaper → wallcolors.py → ~/.cache/yemi-shell/terminal.json
#                             → ~/.cache/yemi-shell/colors.json (pill/UI)
#             → apply-terminal-colors.py → kitty/theme.conf
#                                        → ghostty/themes/yemi-auto
#             → quickshell color reload

set -euo pipefail

WALL_PATH="${1:-}"
MODE="${2:-dynamic}"
MOOD="${3:-dark}"
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"

[ -f "$WALL_PATH" ] || { echo "[yemi-shell] no wallpaper path given"; exit 1; }

# 1 — generate colors from wallpaper
# Mode: dynamic (follows wallpaper) or static (uses wallpaper as accent source)
# Mood: dark or light - controls surface lightness for contrast
python3 "$SCRIPTS/wallcolors.py" --mode "$MODE" --mood "$MOOD" "$WALL_PATH"

# 2 — fan out terminal.json to all terminal emulators
python3 "$SCRIPTS/apply-terminal-colors.py"

# 3 — signal quickshell to reload pill colors (via Dyn singleton)
qs ipc call colorsReload 2>/dev/null || true
