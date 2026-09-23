#!/usr/bin/env bash
# logout.sh — clean session teardown for YemiShell.
#
# WHY THIS EXISTS
#   skwd-walld does not die with the compositor. It lives in the systemd USER
#   manager (user@UID.service: WantedBy=default.target, session.slice), not in
#   the compositor's graphical-session scope. So when Hyprland exits on logout,
#   the daemon survives, prints "Broken pipe (os error 32)" and keeps running
#   while detached from any Wayland connection — verified live:
#
#     15:57:28  skwd-walld: Io error: Broken pipe (os error 32)
#     15:57:38  new Hyprland starts (session-5.scope)
#     /proc/<skwd-walld>/fd -> no wayland fd
#
#   Restart=on-failure never fires (it did not crash). On the NEXT login that
#   same deaf daemon is reused, its stale wall.sock still answers
#   `skwd-helm current`, so the wallpaper never repaints: a black, blank
#   desktop.
#
#   Stopping the unit here means the next login starts a FRESH skwd-walld that
#   attaches to the new compositor. start-shell.sh also detects and restarts a
#   stale daemon defensively (for logouts that bypass this script, e.g. a
#   crash), so the two together cover both paths.
#
# Order matters: stop skwd FIRST (while the compositor is still alive, so the
# layers are torn down cleanly and no stale socket is left behind), then ask
# the compositor to exit.

set -u

COMPOSITOR="${1:-hyprland}"

# 1. Stop the wallpaper daemon. Best-effort: a failure here is not fatal for
#    logout, start-shell.sh will clean up a survivor on the way back in.
systemctl --user stop skwd-walld.service >/dev/null 2>&1 || true

# 2. Let go of the compositor. Hyprland: `exit`; niri: `quit`.
case "$COMPOSITOR" in
    niri)
        niri msg action quit >/dev/null 2>&1 || true
        ;;
    *)
        hyprctl dispatch exit >/dev/null 2>&1 || true
        ;;
esac

exit 0
