#!/usr/bin/env bash
# Compat shim — the legacy awww-based wallpaper.sh was retired (it painted a
# stale layer behind skwd and desynced from the state file). This maps the
# old CLI (wallpaper.sh <cmd> [path]) onto the single dispatcher
# (set-wallpaper.sh <compositor> <cmd> [path]).
set -euo pipefail
COMPOSITOR="${COMPOSITOR:-hyprland}"
exec "$HOME/.config/quickshell/scripts/set-wallpaper.sh" "$COMPOSITOR" "$@"
