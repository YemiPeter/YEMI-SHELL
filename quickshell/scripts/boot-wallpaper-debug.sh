#!/usr/bin/env bash
# One-time boot wallpaper debug helper — run at login before touching UI.

awww query >> ~/.local/state/wallpaper-boot-debug.log 2>&1
echo "---" >> ~/.local/state/wallpaper-boot-debug.log
cat "${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-wallpaper" >> ~/.local/state/wallpaper-boot-debug.log 2>&1
echo "---" >> ~/.local/state/wallpaper-boot-debug.log
pgrep -a awww-daemon >> ~/.local/state/wallpaper-boot-debug.log 2>&1
echo "=== $(date) ===" >> ~/.local/state/wallpaper-boot-debug.log
