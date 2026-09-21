#!/usr/bin/env bash
# set-wallpaper.sh — SINGLE wallpaper setter for YemiShell.
#
# Usage: set-wallpaper.sh <compositor> <action> [path]
#   compositor : "hyprland" | "niri"  (passed in from QML, never re-detected here)
#   action     : "init"  -> restore last wallpaper (or pick one)
#                "set"   -> set the wallpaper given by [path]
#                "restore" -> paint [path] (or last from state) WITHOUT touching the
#                            state file or re-running after-wall.sh color pipeline.
#                            Used by Niri "hide main wallpaper" → restore: syncAwww
#                            fires on every startup with backdropHideWallpaper=false
#                            and passes the LIVE state-file pick — repaints awww
#                            without clobbering the real state file.
#                (any)   -> pick a random wallpaper from the bag
#
# What init/set/(random) always do:
#   * writes the state file ~/.local/state/quickshell-wallpaper
#   * runs the single color writer after-wall.sh (bash)
# What "restore" does (subset):
#   * ensures the awww daemon + paints via `awww img`
#   * NO state-file write, NO after-wall.sh, NO hyprctl reload
#     (the state file already names the current on-screen pick; restore is
#      purely "sync awww onto the same pick the QML backdrop is showing")
# On Hyprland only (init/set/random):
#   * ensures the awww daemon and paints via `awww img`
#   * reloads hyprland (so any hyprland-side color consumers refresh)
# On Niri (init/set/random):
#   * the QML Backdrop layer renders the image from the state file, so no
#     external daemon is invoked — the dispatcher just records the choice.
#
# Transition duration: the Settings UI labels the value in MILLISECONDS
# (200-3000, default 800). awww documents --transition-duration as SECONDS,
# so we divide by 1000 here and nowhere else. The flags schema stays "ms".

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
    find "$WPDIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \)
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

ensure_daemon() {
    # awww is compositor-agnostic: skwd's picker paints through it on Niri
    # too, so the dispatcher must be able to spawn it everywhere.
    awww query >/dev/null 2>&1 && return 0
    local attempt i
    for attempt in 1 2 3 4 5; do
        awww-daemon >/dev/null 2>&1 &
        for i in $(seq 1 15); do
            awww query >/dev/null 2>&1 && return 0
            sleep 0.2
        done
    done
    return 1
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
        # "restore" = repaint awww without touching state file or color pipeline.
        # Path arg is the live state-file pick from Walls.restoreProc; if absent
        # (state file empty on first run) fall back to STATE (same as init).
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
# Transition flags (seconds conversion done here)
# ---------------------------------------------------------------------------
T_ENABLE="$(jq -r '.transitionEnable // true' "$FLAGS_FILE" 2>/dev/null || echo true)"
T_TYPE="$(jq -r '.transitionType // "fade"' "$FLAGS_FILE" 2>/dev/null || echo fade)"
T_DIR="$(jq -r '.transitionDirection // "right"' "$FLAGS_FILE" 2>/dev/null || echo right)"
T_DUR="$(jq -r '.transitionDuration // 800' "$FLAGS_FILE" 2>/dev/null || echo 800)"
T_FPS="$(jq -r '.transitionFps // 60' "$FLAGS_FILE" 2>/dev/null || echo 60)"
T_STEP="$(jq -r '.transitionStep // 90' "$FLAGS_FILE" 2>/dev/null || echo 90)"

AWWW_ARGS=()
if [ "$T_ENABLE" = "true" ]; then
    AWWW_ARGS+=(--transition-type "$T_TYPE" --transition-fps "$T_FPS" --transition-step "$T_STEP")
    if [ "$T_TYPE" != "simple" ] && [ "$T_TYPE" != "none" ]; then
        # ms -> seconds for awww (UI keeps labeling "ms")
        T_DUR_SECONDS="$(awk "BEGIN { printf \"%.3f\", $T_DUR / 1000 }")"
        AWWW_ARGS+=(--transition-duration "$T_DUR_SECONDS")
    fi
    if [ "$T_TYPE" = "wipe" ] || [ "$T_TYPE" = "wave" ]; then
        case "$T_DIR" in
            left)   AWWW_ARGS+=(--transition-angle 180) ;;
            top)    AWWW_ARGS+=(--transition-angle 270) ;;
            bottom) AWWW_ARGS+=(--transition-angle 90) ;;
            *)      AWWW_ARGS+=(--transition-angle 0) ;;
        esac
    fi
fi

# ---------------------------------------------------------------------------
# Record the choice (QML Backdrop reads this on every compositor)
# SKIPPED for "restore": the state file already names the real on-screen pick.
# Restore repaints awww from the live state-file pick, which must NOT be
# rewritten (it already names the on-screen pick; restore's job is purely to
# sync awww to it, never to touch the state file).
# ---------------------------------------------------------------------------
if [ "$CMD" != "restore" ]; then
    mkdir -p "$(dirname "$STATE")"
    printf '%s\n' "$pic" > "$STATE"
fi

# ---------------------------------------------------------------------------
# Paint — every compositor. The Pill picker must repaint the same awww layer
# skwd's picker paints through, otherwise the desktop wallpaper goes stale on
# Niri while the QML backdrop changes. hyprctl reload stays Hyprland-only and
# only for "real" transitions (restore never reloads).
# ---------------------------------------------------------------------------
# Paint — every compositor. Engine selection: skwd-helm (v2) is the adopted
# background owner once installed (v1->v2 migration); awww stays the fallback.
# The helm branch is exit-checked: if the binary exists but dies (e.g. newer
# GLIBC than the system before an update), we fall through to awww so the
# screen always repaints and never desyncs from the state file. skwd v2's
# effects are configured in its own v2 config, so the awww transition args
# above only apply to the awww path.
if command -v skwd-helm >/dev/null 2>&1 && skwd-helm apply "$pic"; then
    :
else
    ensure_daemon || true
    awww img "$pic" "${AWWW_ARGS[@]}" || true
fi
if [ "$COMPOSITOR" = "hyprland" ] && [ "$CMD" != "restore" ]; then
    hyprctl reload >/dev/null 2>&1 || true
fi

# ---------------------------------------------------------------------------
# Single color writer (init/set/random only). Restore never runs the color
# pipeline on purpose: the on-screen wallpaper hasn't changed (we're just
# re-painting the same awww that was there before it was killed), so the
# palette stays correct and we avoid re-triggering wallust / reload storms.
# ---------------------------------------------------------------------------
if [ "$CMD" != "restore" ]; then
    bash "$SCRIPTS_DIR/after-wall.sh" "dynamic" "$pic" >/dev/null 2>&1 || true
fi
