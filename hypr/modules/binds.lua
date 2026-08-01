# Shell by Yemi — keybinds, edited via pill Keybinds surface
#
# ─────────────────────────────────────────────────────────────────────────────
# SECTION 1 — APPS, WORKSPACES & ACTIONS
# ─────────────────────────────────────────────────────────────────────────────

# Launcher
bind = $mod, space, exec, qs ipc call pill launcher eDP-1              # Luncher 

# Terminals
bind = $mod, Return, exec, kitty                                       # Terminal
bind = $mod, T, exec, ghostty                                          # Terminal
bind = $mod SHIFT, RETURN, exec, [float; size 700 400] kitty           # Floating Terminal

# File manager
bind = $mod, E, exec, ~/.config/hypr/scripts/file-manager.sh           # File Manager (dolphin > thunar >  nautilus)

# Close window
bind = $mod, Q, killactive                                             # Close window

# Wallpaper
bind = $mod, W, exec, qs ipc call wallpaper toggle eDP-1               # Wallpaper settings

# Lock screen
bind = $mod, X, exec, ~/.config/hypr/scripts/lock.sh                   # Lock screen

# Music
bind = $mod, M, exec, qs ipc call music toggle                         # Music player

# Clipboard
bind = $mod, C, exec, qs ipc call pill clipboard eDP-1                 # Clipboard history

# Region screenshot (was togglespecialworkspace)
bind = $mod, S, exec, bash -c 'mkdir -p $HOME/Pictures/Screenshots && grim -g "$(slurp)" $HOME/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && notify-send "Screenshot Saved" "Area captured" -i camera-photo'

# Full screenshot
bind = $mod SHIFT, S, exec, bash -c 'mkdir -p $HOME/Pictures/Screenshots && grim $HOME/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && notify-send "Screenshot Saved" "Full screen captured" -i camera-photo'

# Region screenshot (alternate key)
bind = $mod CTRL, S, exec, bash -c 'mkdir -p $HOME/Pictures/Screenshots && grim -g "$(slurp)" $HOME/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && notify-send "Screenshot Saved" "Area captured" -i camera-photo'

# Settings overlay
bind = ALT, S, exec, qs ipc call settings toggle                   # Settings overlay

# Screen recording
bind = $mod, R, exec, gpu-screen-recorder -w screen -f 30 -a default_output -o ~/screen-recordings/$(date +%Y-%m-%d_%H-%M-%S).mp4 & notify-send "Recording Started"
bind = $mod SHIFT, R, exec, killall -SIGINT gpu-screen-recorder && notify-send "Recording Stopped"

# Workspace navigation
bind = $mod, 1, workspace, 1                                     # Workspace 1
bind = $mod, 2, workspace, 2                                     # Workspace 2
bind = $mod, 3, workspace, 3                                     # Workspace 3
bind = $mod, 4, workspace, 4                                     # Workspace 4
bind = $mod, 5, workspace, 5                                     # Workspace 5
bind = $mod, 6, workspace, 6                                     # Workspace 6
bind = $mod, 7, workspace, 7                                     # Workspace 7
bind = $mod, 8, workspace, 8                                     # Workspace 8
bind = $mod, 9, workspace, 9                                     # Workspace 9
bind = $mod, mouse_down, workspace, e+1                          # Next workspace
bind = $mod, mouse_up, workspace, e-1                            # Previous workspace

# Move to workspace
bind = $mod SHIFT, 1, movetoworkspace, 1                         # Move to workspace 1
bind = $mod SHIFT, 2, movetoworkspace, 2                         # Move to workspace 2
bind = $mod SHIFT, 3, movetoworkspace, 3                         # Move to workspace 3
bind = $mod SHIFT, 4, movetoworkspace, 4                         # Move to workspace 4
bind = $mod SHIFT, 5, movetoworkspace, 5                         # Move to workspace 5
bind = $mod SHIFT, 6, movetoworkspace, 6                         # Move to workspace 6
bind = $mod SHIFT, 7, movetoworkspace, 7                         # Move to workspace 7
bind = $mod SHIFT, 8, movetoworkspace, 8                         # Move to workspace 8
bind = $mod SHIFT, 9, movetoworkspace, 9                         # Move to workspace 9

# ⚠️ ORPHANED — special workspace concept removed (togglespecialworkspace deleted).
#     No way to return from special workspace. Awaiting rebind/delete decision.
bind = $mod SHIFT, S, movetoworkspace, special                   # Move to special workspace (DEAD)

# Layout
bind = $mod, P, pseudo                                           # Pseudo
bind = $mod, J, layoutmsg, togglesplit                           # Toggle split

# Skwd wall toggle
bind = $mod SHIFT, W, exec, skwd wall toggle                     # Skwd wall toggle

# Define
bind = , Menu, exec, ~/.config/scripts/define.sh

# Debug
bind = SUPER, F12, exec, hyprctl activeworkspace -j >> /tmp/fs-debug.log 2>&1

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 2 — NAVIGATION, WINDOW MANAGEMENT & HARDWARE
# ─────────────────────────────────────────────────────────────────────────────

# Fullscreen
bind = $mod, F, fullscreen                                       # Fullscreen

# Toggle floating
bind = $mod SHIFT, space, togglefloating                         # Toggle floating state

# Focus movement (arrows)
bind = $mod, Left, movefocus, l                                  # Move focus left
bind = $mod, Down, movefocus, d                                  # Move focus down
bind = $mod, Up, movefocus, u                                    # Move focus up
bind = $mod, Right, movefocus, r                                 # Move focus right

# Move window (arrows)
bind = $mod SHIFT, Left, movewindow, l                           # Move window left
bind = $mod SHIFT, Down, movewindow, d                           # Move window down
bind = $mod SHIFT, Up, movewindow, u                             # Move window up
bind = $mod SHIFT, Right, movewindow, r                          # Move window right

# Resize window
binde = $mod CTRL, Left, resizeactive, -20 0                     # Resize window left
binde = $mod CTRL, Right, resizeactive, 20 0                     # Resize window right
binde = $mod CTRL, Up, resizeactive, 0 -20                       # Resize window up
binde = $mod CTRL, Down, resizeactive, 0 20                      # Resize window down

# Cycle windows
bind = $mod, Tab, cyclenext, next                                # Cycle windows forward
bind = $mod SHIFT, Tab, cyclenext, prev                          # Cycle windows backward

# Mouse binds
bindm = $mod, mouse:272, movewindow
bindm = $mod, mouse:273, resizewindow

