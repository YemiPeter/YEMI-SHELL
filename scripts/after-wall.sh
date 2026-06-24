#!/bin/bash
# Run wallcolors.py to generate ~/.cache/ricelin/colors.json from wallpaper
python3 "$(dirname "$0")/../.Ricelin/configs/hypr/scripts/wallcolors.py" "$1"
