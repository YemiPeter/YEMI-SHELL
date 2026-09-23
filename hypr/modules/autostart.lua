exec-once = hyprctl setcursor Bibata-Modern-Ice 12
exec-once = systemctl --user start hyprpolkitagent
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
# Wallpaper restore at login. set-wallpaper.sh now waits for skwd-walld's helm
# IPC socket (up to ~90s) before painting, because skwd's session detector
# needs ~56s at boot to notice the Wayland session. Run it detached with
# setsid so it survives as a background process instead of holding up the
# rest of this exec-once batch — the paint lands whenever skwd is ready.
exec-once = setsid --fork bash -c '~/.config/quickshell/scripts/set-wallpaper.sh hyprland init' >/dev/null 2>&1
