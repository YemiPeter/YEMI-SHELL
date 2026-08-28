exec-once = hyprctl setcursor Bibata-Modern-Ice 32
exec-once = systemctl --user start hyprpolkitagent
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = ~/.config/hypr/scripts/wallpaper.sh init
