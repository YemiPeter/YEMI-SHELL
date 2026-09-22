#!/usr/bin/env bash
# skwd-wall-sync.sh — return-path glue between skwd-wall v2 and YemiShell.
#
# Streams `skwd-helm watch` (JSON events) and, on every skwd.wall.applied
# event, writes the applied path into the shell's state file. This keeps
# Backdrop, the pill and the color pipeline in sync when a wallpaper is
# picked from skwd's OWN picker ($mod+Shift+W -> skwd-wall-v2), which does
# not go through set-wallpaper.sh.
#
# Idempotent with the dispatcher: picks made through set-wallpaper.sh emit
# the same daemon event, but the hook then writes the very path the
# dispatcher already wrote — a no-op rewrite, never a fight.
#
# Runs as a long-lived Quickshell Process (started by Walls.qml); dies with
# the shell.
set -uo pipefail

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-wallpaper"
mkdir -p "$(dirname "$STATE")"

skwd-helm watch 2>/dev/null | while IFS= read -r line; do
    # Cheap pre-filter before paying for jq on every event line.
    case "$line" in
        *'"skwd.wall.applied"'*) ;;
        *) continue ;;
    esac
    path="$(printf '%s' "$line" | jq -r '.data.path // empty' 2>/dev/null)" || continue
    [ -n "$path" ] && [ -f "$path" ] || continue
    # Only rewrite when it actually differs (avoids needless Backdrop reloads).
    [ "$(cat "$STATE" 2>/dev/null)" = "$path" ] || printf '%s\n' "$path" > "$STATE"
done
