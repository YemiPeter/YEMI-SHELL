#!/usr/bin/env bash
set -euo pipefail

WPDIR="$HOME/Pictures/Wallpapers"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-wallpaper"
BAG="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-wallpaper-bag"

ensure_daemon() {
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

daemon_was_running=true
awww query >/dev/null 2>&1 || daemon_was_running=false
ensure_daemon || exit 0

cmd="${1:-}"

if [ "$cmd" = "init" ]; then
    [ "$daemon_was_running" = true ] && exit 0
    if [ -r "$STATE" ] && pic=$(cat "$STATE") && [ -f "$pic" ]; then
        :
    else
        pic=$(pop_bag) || exit 0
    fi
elif [ "$cmd" = "set" ]; then
    pic="${2:-}"
    [ -f "$pic" ] || exit 1
else
    pic=$(pop_bag) || exit 0
fi

    [ -n "$pic" ] || exit 0

    FLAGS_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/flags.json"
    T_ENABLE="$(jq -r '.transitionEnable // true' "$FLAGS_FILE" 2>/dev/null || echo true)"
    T_TYPE="$(jq -r '.transitionType // "fade"' "$FLAGS_FILE" 2>/dev/null || echo fade)"
    T_DIR="$(jq -r '.transitionDirection // "right"' "$FLAGS_FILE" 2>/dev/null || echo right)"
    T_DUR="$(jq -r '.transitionDuration // 800' "$FLAGS_FILE" 2>/dev/null || echo 800)"
    T_FPS="$(jq -r '.transitionFps // 60' "$FLAGS_FILE" 2>/dev/null || echo 60)"
    T_STEP="$(jq -r '.transitionStep // 90' "$FLAGS_FILE" 2>/dev/null || echo 90)"

    AWWW_ARGS=(--transition-type "$T_TYPE" --transition-fps "$T_FPS" --transition-step "$T_STEP")
    if [ "$T_TYPE" != "simple" ] && [ "$T_TYPE" != "none" ]; then
        AWWW_ARGS+=(--transition-duration "$T_DUR")
    fi
    if [ "$T_TYPE" = "wipe" ] || [ "$T_TYPE" = "wave" ]; then
        case "$T_DIR" in
            left)  AWWW_ARGS+=(--transition-angle 180) ;;
            top)   AWWW_ARGS+=(--transition-angle 270) ;;
            bottom)AWWW_ARGS+=(--transition-angle 90) ;;
            *)     AWWW_ARGS+=(--transition-angle 0) ;;
        esac
    fi

    awww img "$pic" "${AWWW_ARGS[@]}"

    mkdir -p "$(dirname "$STATE")"
    printf '%s\n' "$pic" > "$STATE"

# Delegate color generation to the single quickshell writer so colors.json
# stays in the Dyn.qml-expected schema. wallpaper.sh only sets the image +
# state here; after-wall.sh owns the palette.
python3 "$HOME/.config/quickshell/scripts/after-wall.sh" "dynamic" "$pic" >/dev/null 2>&1 || true
hyprctl reload >/dev/null 2>&1 || true
busctl --user call com.mitchellh.ghostty /com/mitchellh/ghostty org.gtk.Actions \
    Activate "sava{sv}" reload-config 0 0 >/dev/null 2>&1 || true
