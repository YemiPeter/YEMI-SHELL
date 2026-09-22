#!/usr/bin/env bash
# Boot-time launcher for the YemiShell quickshell instance.
#
# WHY THIS EXISTS
#   `exec-once = quickshell ...` in hyprland.conf races session startup: the
#   Wayland socket may not be listening yet and skwd-walld may not be up, so
#   the shell can exit immediately and never come back (exec-once runs exactly
#   once). The visible symptom is a session with no bar and no wallpaper pill.
#
#   Two other traps this guards against:
#     1. Launching bare `quickshell` (no -p) loads the DEFAULT config from
#        ~/.config/quickshell/shell.qml only if it exists as `default`;
#        otherwise you get a config-less shell with no bar/pill. Always pass
#        an explicit -p path.
#     2. A leftover instance (e.g. from reload-shell.sh) holds the single-
#        instance lock; --no-duplicate makes that a clean no-op rather than a
#        second competing shell.

set -u

CONFIG_DIR="${RICE_HOME:-$HOME/.config}/quickshell"
CONFIG="$CONFIG_DIR/shell.qml"
LOG="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/start-shell.log"

mkdir -p "$(dirname "$LOG")"

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*" >>"$LOG"; }

log "--- start-shell.sh invoked ---"

# Nothing to launch if the config is missing; say so loudly instead of
# silently producing a bar-less session.
if [[ ! -f "$CONFIG" ]]; then
    log "FATAL: config not found at $CONFIG"
    exit 1
fi

# 1. Wait for the Wayland socket to actually accept connections.
#    XDG_RUNTIME_DIR/WAYLAND_DISPLAY is the compositor's own socket.
for _ in $(seq 1 50); do
    if [[ -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/${WAYLAND_DISPLAY:-wayland-1}" ]]; then
        log "wayland socket ready (${WAYLAND_DISPLAY:-wayland-1})"
        break
    fi
    sleep 0.1
done

# 2. Give skwd-walld a moment so the shell's wallpaper restore has a backend.
#    Not a hard requirement: the shell works without it, the wallpaper does not.
for _ in $(seq 1 30); do
    if pgrep -x skwd-walld >/dev/null 2>&1; then
        log "skwd-walld is up"
        break
    fi
    sleep 0.1
done

# 3. Launch, retrying once. A very early exit usually means we lost the race
#    above; a single retry covers that without risking a crash loop.
for attempt in 1 2; do
    if pgrep -f "quickshell -p $CONFIG" >/dev/null 2>&1; then
        log "an instance is already running; nothing to do"
        exit 0
    fi

    log "launching quickshell (attempt $attempt)"
    setsid --fork quickshell -p "$CONFIG" >>"$LOG" 2>&1 </dev/null

    # Give it time to either stabilise or die during startup.
    for _ in $(seq 1 30); do
        sleep 0.2
        if pgrep -f "quickshell -p $CONFIG" >/dev/null 2>&1; then
            log "quickshell is running"
            exit 0
        fi
    done
    log "attempt $attempt exited during startup"
done

log "FATAL: quickshell failed to stay up after 2 attempts"
exit 1
