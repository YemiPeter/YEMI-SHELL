#!/usr/bin/env bash
# set-wallpaper.sh — SINGLE wallpaper setter for YemiShell.
#
# Usage: set-wallpaper.sh <compositor> <action> [path]
#   compositor : "hyprland" | "niri"  (passed in from QML, never re-detected here)
#   action     : "init"  -> restore last wallpaper (or pick one)
#                "set"   -> set the wallpaper given by [path]
#                "restore" -> paint [path] (or last from state) WITHOUT touching the
#                            state file or re-running after-wall.sh color pipeline.
#                            Used by Niri "hide main wallpaper" → restore: syncSkwd
#                            fires on every startup with backdropHideWallpaper=false
#                            and passes the LIVE state-file pick — re-applies via
#                            skwd without clobbering the real state file.
#                (any)   -> pick a random wallpaper from the bag
#
# What init/set/(random) always do:
#   * writes the state file ~/.local/state/quickshell-wallpaper
#   * runs the single color writer after-wall.sh (bash)
# What "restore" does (subset):
#   * re-applies the pick via skwd-helm (no transition on restore)
#   * NO state-file write, NO after-wall.sh, NO hyprctl reload
#     (the state file already names the current on-screen pick; restore is
#      purely "sync skwd onto the same pick the QML backdrop is showing")
# On every compositor:
#   * skwd-helm (skwd-wall v2) is the ONLY paint engine. There is no awww
#     fallback anymore — awww was retired (it double-painted a stale layer
#     behind skwd and desynced from the state file). If the helm apply fails
#     the failure is surfaced (notify-send + exit 1) instead of silently
#     leaving the previous wallpaper up.
#   * Transitions are skwd's own (configured per-wallpaper in its picker's
#     sceneProperties / v2 settings). The old flags.json transition* keys fed
#     the awww path only and are now dead.

set -euo pipefail

COMPOSITOR="${1:-}"
shift || true
CMD="${1:-set}"
shift || true

WPDIR="$HOME/Pictures/Wallpapers"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-wallpaper"
BAG="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-wallpaper-bag"
FLAGS_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/flags.json"
SCRIPTS_DIR="$HOME/.config/quickshell/scripts"

# ---------------------------------------------------------------------------
# Wallpaper bag (random/shuffle source). Ported from the old wallpaper.sh so
# the dispatcher is self-contained and the only thing that paints.
# ---------------------------------------------------------------------------
list_pics() {
    find "$WPDIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \)
}

refill_bag() {
    local current="" shuffled
    [ -r "$STATE" ] && current=$(cat "$STATE")
    shuffled=$(list_pics | shuf)
    [ -n "$shuffled" ] || return 0
    if [ "$(printf '%s\n' "$shuffled" | head -n1)" = "$current" ] && [ "$(printf '%s\n' "$shuffled" | wc -l)" -gt 1 ]; then
        shuffled=$(printf '%s\n' "$shuffled" | tail -n +2; printf '%s\n' "$current")
    fi
    mkdir -p "$(dirname "$BAG")"
    printf '%s\n' "$shuffled" > "$BAG"
}

pop_bag() {
    local line refilled=false
    mkdir -p "$(dirname "$BAG")"
    (
        flock 9
        while :; do
            if [ ! -s "$BAG" ]; then
                [ "$refilled" = true ] && exit 1
                refill_bag
                refilled=true
                [ -s "$BAG" ] || exit 1
            fi
            line=$(head -n1 "$BAG")
            tail -n +2 "$BAG" > "$BAG.tmp" && mv "$BAG.tmp" "$BAG"
            if [ -f "$line" ]; then
                printf '%s\n' "$line"
                exit 0
            fi
        done
    ) 9>"$BAG.lock"
}

wait_helm() {
    # skwd-walld starts via systemd with --wait-for-session; helm IPC (wall.sock)
    # may not exist yet when init runs at login. Poll briefly, then give up with
    # a loud failure (the caller decides whether that is fatal).
    local i
    for i in $(seq 1 40); do
        skwd-helm current >/dev/null 2>&1 && return 0
        sleep 0.25
    done
    return 1
}

fail_loud() {
    echo "[set-wallpaper] ERROR: $1" >&2
    command -v notify-send >/dev/null 2>&1 && \
        notify-send -u critical -a set-wallpaper "Wallpaper error" "$1" >/dev/null 2>&1 || true
}

# ---------------------------------------------------------------------------
# Animated picks (GIF/video). skwd paints these NATIVELY (skwd-wall-vk /
# skwd-paper-v2, "video" type — verified live, shader crossfade included).
# The old mpvpaper pipeline (list_outputs/stop_mpvpaper/start_mpvpaper/
# first_frame) was deleted after native playback was confirmed: no external
# video engine, no first-frame cache, one renderer for everything.
# ---------------------------------------------------------------------------
is_animated() {
    case "${1,,}" in
        *.mp4|*.webm|*.mkv|*.avi|*.mov|*.gif) return 0 ;;
        *) return 1 ;;
    esac
}

# ---------------------------------------------------------------------------
# Resolve the target picture
# ---------------------------------------------------------------------------
case "$CMD" in
    init)
        if [ -r "$STATE" ] && pic=$(cat "$STATE") && [ -f "$pic" ]; then
            :
        else
            pic=$(pop_bag) || true
        fi
        ;;
    set)
        pic="${1:-}"
        [ -f "$pic" ] || { echo "[set-wallpaper] no such wallpaper: $pic" >&2; exit 1; }
        ;;
    restore)
        # "restore" = re-apply via skwd without touching state file or color
        # pipeline. Path arg is the live state-file pick from Walls.restoreProc;
        # if absent (state file empty on first run) fall back to STATE (same
        # as init).
        if [ $# -ge 1 ] && [ -n "${1:-}" ] && [ -f "${1:-}" ]; then
            pic="$1"
        elif [ -r "$STATE" ] && pic=$(cat "$STATE") && [ -f "$pic" ]; then
            :
        else
            pic=$(pop_bag) || true
        fi
        ;;
    *)
        pic=$(pop_bag) || true
        ;;
esac

[ -n "$pic" ] || exit 0

# ---------------------------------------------------------------------------
# skwd readiness (boot race): skwd-walld runs via systemd --wait-for-session,
# so at login the helm IPC socket may lag the shell's first init paint. Wait
# briefly; init failing to reach skwd is a loud, visible error, not a silent
# stale desktop.
# ---------------------------------------------------------------------------
if ! wait_helm; then
    fail_loud "skwd-walld unreachable (skwd-helm current timed out); wallpaper not painted"
    exit 1
fi

# ---------------------------------------------------------------------------
# Animated-wallpaper engine flags (mpvpaper). See is_animated() above.
# NOTE: the old transitionEnable/transitionType/... flags.json keys were only
# ever consumed by the retired awww paint path. skwd owns transitions now
# (per-wallpaper via its own settings), so those keys are dead and are not
# read here anymore.
# ---------------------------------------------------------------------------
V_ENGINE="$(jq -r '.wallpaperVideoEngine // true' "$FLAGS_FILE" 2>/dev/null || echo true)"

# ---------------------------------------------------------------------------
# Record the choice (QML Backdrop reads this on every compositor)
# SKIPPED for "restore": the state file already names the real on-screen pick.
# Restore re-applies via skwd from the live state-file pick, which must NOT
# be rewritten (it already names the on-screen pick; restore's job is purely
# to sync skwd to it, never to touch the state file).
# ---------------------------------------------------------------------------
if [ "$CMD" != "restore" ]; then
    mkdir -p "$(dirname "$STATE")"
    printf '%s\n' "$pic" > "$STATE"
fi

# ---------------------------------------------------------------------------
# Paint — every compositor. Engine selection: skwd-helm (v2) is the ONLY
# engine. awww was retired (it painted a stale layer behind skwd's and
# desynced from the state file); the flags.json transition* keys fed only
# that dead awww path. Transitions are skwd's own, configured per-wallpaper
# in its picker (sceneProperties) / v2 settings.
#
# Animated picks (GIF/video) are painted NATIVELY by skwd (skwd-wall-vk /
# skwd-paper-v2 render them as "video" type — verified live: `skwd-helm apply
# dancing-cat.gif` launched skwd-wall-vk with a --transition-from shader
# crossfade). No mpvpaper, no first-frame extraction: PAINT_PIC is always the
# pick itself, so the color pipeline sees the real media file (after-wall.sh
# extracts its own frame / falls back internally if image-only). "restore"
# is a pure re-apply of the pick already on screen.
#
# The wallpaperVideoEngine flag is kept as a master kill-switch for animated
# picks: if the user turns it OFF, animated files are refused with a loud
# error instead of being painted (skwd would play them anyway otherwise).
# ---------------------------------------------------------------------------
PAINT_PIC="$pic"
if [ "$CMD" != "restore" ] && [ "$V_ENGINE" != "true" ] && is_animated "$pic"; then
    fail_loud "animated wallpaper picked but wallpaperVideoEngine is off: $pic"
    exit 1
fi
if ! skwd-helm apply "$pic"; then
    fail_loud "skwd-helm apply failed: $pic"
    exit 1
fi
if [ "$COMPOSITOR" = "hyprland" ] && [ "$CMD" != "restore" ]; then
    hyprctl reload >/dev/null 2>&1 || true
fi

# ---------------------------------------------------------------------------
# Single color writer (init/set/random only). Restore never runs the color
# pipeline on purpose: the on-screen wallpaper hasn't changed (we're just
# re-syncing skwd to the pick already on screen), so the palette stays
# correct and we avoid re-triggering wallust / reload storms.
# ---------------------------------------------------------------------------
if [ "$CMD" != "restore" ]; then
    bash "$SCRIPTS_DIR/after-wall.sh" "dynamic" "$PAINT_PIC" >/dev/null 2>&1 || true
fi
