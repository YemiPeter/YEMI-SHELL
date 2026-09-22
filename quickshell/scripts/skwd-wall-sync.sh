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
#
# On every applied event it (1) writes the state file and (2) drives the
# single color writer after-wall.sh, because picking from skwd's own picker
# never touches set-wallpaper.sh. Without step (2) a skwd-picker pick left
# the wallpaper right and the palette stale.
set -uo pipefail

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-wallpaper"
FLAGS="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/flags.json"
AFTER_WALL="$(cd "$(dirname "$0")" && pwd)/after-wall.sh"
mkdir -p "$(dirname "$STATE")"

# Static palette mode means the palette is pinned, not derived from the
# wallpaper; re-running the pipeline there would fight the user's pinned
# choice, so only dynamic mode re-themes.
palette_mode="$(jq -r '.paletteMode // "dynamic"' "$FLAGS" 2>/dev/null || echo dynamic)"

skwd-helm watch 2>/dev/null | while IFS= read -r line; do
    # Cheap pre-filter before paying for jq on every event line.
    case "$line" in
        *'"skwd.wall.applied"'*) ;;
        *) continue ;;
    esac
    path="$(printf '%s' "$line" | jq -r '.data.path // empty' 2>/dev/null)" || continue
    [ -n "$path" ] && [ -f "$path" ] || continue
    # Only rewrite when it actually differs (avoids needless Backdrop reloads).
    changed=0
    [ "$(cat "$STATE" 2>/dev/null)" = "$path" ] || changed=1
    [ "$changed" = "1" ] && printf '%s\n' "$path" > "$STATE"

    # Re-theme on real changes only: skwd emits the same applied event for the
    # picks set-wallpaper.sh already coloured, and re-running the pipeline on
    # those would duplicate work and cause a visible palette flicker.
    [ "$changed" = "1" ] || continue
    [ "$palette_mode" = "dynamic" ] || continue
    "$AFTER_WALL" "${YEMI_MOOD:-$(jq -r '.systemMood // "dark"' "$FLAGS" 2>/dev/null || echo dark)}" "$path" || true
done
