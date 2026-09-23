#!/usr/bin/env bash
# logout.sh — clean session teardown for YemiShell.
#
# WHY THIS EXISTS
#   This session is launched by uwsm (DESKTOP_SESSION=hyprland-uwsm; the
#   compositor runs inside wayland-wm@hyprland.desktop.service). uwsm owns the
#   session lifecycle and its man page is explicit:
#
#     "Do not use compositor's native exit mechanism or kill its process
#      directly."
#
#   ...because doing so skips uwsm's clean shutdown: the compositor dies while
#   uwsm still considers the session live, so the session is left half-dead
#   instead of returning to the display manager. The visible symptoms are
#   "logout does nothing" and a blank wallpaper on the way out.
#
#   The correct request is `uwsm stop`, which tears the session down in order
#   (systemd stops the user units in reverse) and then stops the compositor.
#
# WALLPAPER
#   skwd-walld is NOT stopped here any more. It is WantedBy=default.target, so
#   it is owned by the user manager and unwound correctly by uwsm's ordered
#   shutdown. Stopping it manually (as an earlier version of this script did)
#   left the unit inactive while the session was still up, and something later
#   re-spawned the daemon into the compositor's own unit
#   (cgroup .../wayland-wm@hyprland.desktop.service) where it had no clean
#   attach — which is what produced the blank wallpaper.
#
#   If a daemon does survive a logout for any reason, start-shell.sh detects it
#   on the way back in (it compares the daemon's age against the compositor's
#   and restarts the unit when the daemon is older) and re-attaches it. That is
#   the single place that should ever need to repair a stale daemon.

set -u

COMPOSITOR="${1:-hyprland}"

# Close the picker overlay if it is open, so it does not try to keep painting
# into a session that is going away. Best-effort and non-fatal.
if command -v skwd-helm >/dev/null 2>&1; then
    skwd-helm ui close >/dev/null 2>&1 || true
fi

# Let go of the session the way the session manager expects.
#
# `uwsm stop` is the documented path: it stops the graphical session units and
# the compositor together, in order. Preferred whenever uwsm is present, which
# covers both the Hyprland and Niri entries on this machine.
if command -v uwsm >/dev/null 2>&1; then
    exec uwsm stop
fi

# --- Fallbacks: no uwsm on PATH ---------------------------------------------
# Nothing below runs on a normal uwsm login. Kept so a session started outside
# uwsm (a bare TTY launch, or a future non-uwsm entry) still logs out cleanly
# rather than doing nothing.

case "$COMPOSITOR" in
    niri)
        niri msg action quit >/dev/null 2>&1 || true
        ;;
    *)
        # Hyprland without uwsm: ask the Lua dispatcher to exit rather than
        # using the older `hyprctl dispatch exit`, which is the form the uwsm
        # documentation warns against.
        hyprctl eval 'hl.dispatch(hl.dsp.exit())' >/dev/null 2>&1 \
            || hyprctl dispatch exit >/dev/null 2>&1 || true
        ;;
esac

exit 0

