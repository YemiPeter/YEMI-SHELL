#!/bin/bash
# Sync pill colors using the wallpaper path passed in directly
WALL_PATH="$1"
STATE="$HOME/.local/state/yemi-shell/current-wallpaper"
SCRIPT_DIR="$HOME/.config/quickshell/scripts"

[ -f "$WALL_PATH" ] || exit 0

mkdir -p "$(dirname "$STATE")"
echo "$WALL_PATH" > "$STATE"
bash "$SCRIPT_DIR/after-wall.sh" "$WALL_PATH"
