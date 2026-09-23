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

# 0. Recover from a STALE skwd-walld left over from the previous session.
#
#    THE LOGOUT BUG. skwd-walld lives in user@UID.service (the systemd user
#    manager: WantedBy=default.target, session.slice) — NOT in the graphical
#    session scope that the compositor owns. So when you log out and the
#    compositor exits, skwd-walld SURVIVES and simply loses its Wayland
#    connection. Verified live on this machine:
#
#      15:57:28  skwd-walld: Io error: Broken pipe (os error 32)
#      15:57:38  new Hyprland starts in session-5.scope
#      /proc/<skwd>/fd  -> no wayland fd (detached from the compositor)
#      pgrep skwd-wall  -> only a ZOMBIE skwd-wall-still
#
#    Restart=on-failure never fires because the daemon did not crash; it just
#    went deaf. The next login then reuses that deaf daemon: its old wall.sock
#    still answers `skwd-helm current`, so set-wallpaper.sh's readiness check
#    passes and every `skwd-helm apply` is posted to a daemon whose renderer is
#    dead. Result: the wallpaper never repaints — a black, blank desktop until
#    the user re-picks by hand.
#
#    Detect it by comparing process ages: if skwd-walld is OLDER than the
#    compositor we are now running under (larger `etimes` = started earlier),
#    it cannot be attached to it — it is the survivor of the previous session.
#    Restart the unit so it re-runs session detection against the live
#    compositor.
#
#    Do NOT try to detect staleness from /proc/<pid>/fd looking for a Wayland
#    socket: skwd-walld itself never holds one (it delegates rendering to a
#    child skwd-wall-still), so that test reads "detached" even for a perfectly
#    healthy daemon and would restart it on every single login. Age is the
#    reliable signal; verified against both the stale case (daemon 330s vs
#    compositor 278s -> stale) and the healthy case (daemon 21s vs compositor
#    307s -> fresh).
if pgrep -x skwd-walld >/dev/null 2>&1; then
    skwd_start="$(ps -o etimes= -C skwd-walld 2>/dev/null | tr -d ' ' | sort -n | head -n1)"
    comp_pid="$(pgrep -x Hyprland 2>/dev/null | head -n1)"
    [[ -n "$comp_pid" ]] || comp_pid="$(pgrep -x niri 2>/dev/null | head -n1)"
    comp_start=""
    [[ -n "$comp_pid" ]] && comp_start="$(ps -o etimes= -p "$comp_pid" 2>/dev/null | tr -d ' ')"

    if [[ -n "$skwd_start" && -n "$comp_start" && "$skwd_start" -gt "$comp_start" ]]; then
        log "stale skwd-walld (age ${skwd_start}s > compositor ${comp_start}s) — restarting to re-attach"
        systemctl --user restart skwd-walld.service >>"$LOG" 2>&1 || \
            log "WARN: failed to restart skwd-walld.service"
    else
        log "skwd-walld is fresh (age ${skwd_start:-?}s vs compositor ${comp_start:-?}s)"
    fi
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
#
#    Wait for the helm IPC *socket*, not the skwd-walld process. The process
#    is spawned by systemd within a second of login and `pgrep -x skwd-walld`
#    therefore passes immediately, but skwd-walld only creates
#    $XDG_RUNTIME_DIR/skwd-wall-v2/wall.sock AFTER its session detector sees
#    the Wayland session — measured at 56s on this machine at boot, because
#    the daemon starts before Hyprland has exported WAYLAND_DISPLAY into the
#    systemd user session. Waiting on the process alone made this check a
#    no-op and let the shell (and its wallpaper init) race a backend that was
#    not listening yet. Budget ~90s to clear that case with margin.
SKWD_SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/skwd-wall-v2/wall.sock"
for _ in $(seq 1 180); do
    if [ -S "$SKWD_SOCK" ]; then
        log "skwd-walld helm socket is up"
        break
    fi
    sleep 0.5
done
if [ ! -S "$SKWD_SOCK" ]; then
    # Not fatal: launch anyway, the shell is still usable without a wallpaper.
    log "WARN: skwd helm socket never appeared; launching without a paint backend"
fi

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
