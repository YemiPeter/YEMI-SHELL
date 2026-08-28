#!/usr/bin/env bash
# set-wallpaper.sh — SINGLE wallpaper setter for YemiShell.
#
# Usage: set-wallpaper.sh <compositor> <action> [path]
#   compositor : "hyprland" | "niri"  (passed in from QML, never re-detected here)
#   action     : "init"  -> restore last wallpaper (or pick one)
#                "set"   -> set the wallpaper given by [path]
#                (any)   -> pick a random wallpaper from the bag
#
# What it always does:
#   * writes the state file ~/.local/state/quickshell-wallpaper
#   * runs the single color writer after-wall.sh (bash)
# On Hyprland only:
#   * ensures the awww daemon and paints via `awww img`
#   * reloads hyprland (so any hyprland-side color consumers refresh)
# On Niri:
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
    [ "$COMPOSITOR" = "hyprland" ] || return 0
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
# ---------------------------------------------------------------------------
mkdir -p "$(dirname "$STATE")"
printf '%s\n' "$pic" > "$STATE"

# ---------------------------------------------------------------------------
# Paint — Hyprland only. Niri renders the QML layer from the state file.
# ---------------------------------------------------------------------------
if [ "$COMPOSITOR" = "hyprland" ]; then
    ensure_daemon || true
    awww img "$pic" "${AWWW_ARGS[@]}" || true
    hyprctl reload >/dev/null 2>&1 || true
fi

# ---------------------------------------------------------------------------
# Single color writer (always)
# ---------------------------------------------------------------------------
bash "$SCRIPTS_DIR/after-wall.sh" "dynamic" "$pic" >/dev/null 2>&1 || true
