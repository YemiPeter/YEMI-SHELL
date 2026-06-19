#!/bin/bash
# toggle-colormode.sh — cycles color mode: auto → dark → light → auto
# State file is the single source of truth for ThemeToggle.qml and after-wall.sh

STATE_FILE="$HOME/.config/quickshell/state/colormode"
COLORS_FILE="$HOME/.cache/wal/colors.json"
mkdir -p "$(dirname "$STATE_FILE")"

# Read current mode — default to "dark" if file missing
current=$(cat "$STATE_FILE" 2>/dev/null || echo "dark")

# Cycle: auto → dark → light → auto
case "$current" in
    auto)  next="dark"  ;;
    dark)  next="light" ;;
    light) next="auto"  ;;
    *)     next="dark"  ;;
esac

echo "$next" > "$STATE_FILE"

# Re-apply wal based on the new mode
# Get the current wallpaper path from colors.json
wallpaper=""
if [ -f "$COLORS_FILE" ]; then
    wallpaper=$(python3 -c "
import json, sys
try:
    with open('$COLORS_FILE') as f:
        data = json.load(f)
    print(data.get('wallpaper', ''))
except:
    pass
" 2>/dev/null)
fi

if [ -z "$wallpaper" ] || [ ! -f "$wallpaper" ]; then
    # No valid wallpaper — just update state, skip wal
    exit 0
fi

case "$next" in
    dark)
        wal -i "$wallpaper" --backend wal
        ;;
    light)
        wal -i "$wallpaper" --backend wal -l
        ;;
    auto)
        # Detect brightness using ImageMagick
        if command -v identify >/dev/null 2>&1; then
            brightness=$(identify -format "%[fx:mean]" "$wallpaper" 2>/dev/null | head -1)
            is_light=$(awk "BEGIN { print ($brightness > 0.5) ? 1 : 0 }")
            if [ "$is_light" = "1" ]; then
                wal -i "$wallpaper" --backend wal -l
            else
                wal -i "$wallpaper" --backend wal
            fi
        else
            # Fallback: default to dark
            wal -i "$wallpaper" --backend wal
        fi
        ;;
esac

exit 0
