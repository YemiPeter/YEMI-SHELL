# Shell by Yemi — waffle-family keybinds
#
# Sourced from hyprland.conf AFTER binds.lua so waffle binds override
# matching pill binds when present.
#
# ─────────────────────────────────────────────────────────────────────────────
# SECTION 1 — LAUNCHER (Start Menu / Search)
# ─────────────────────────────────────────────────────────────────────────────

# Same key as the pill launcher in binds.lua (Mod+Space) so there is no
# keybind mismatch between the two panel families.
# In waffle mode: opens/toggles the start menu (GlobalStates.searchOpen).
# The `search` IpcHandler is registered by WaffleStartMenu.qml.
bind = $mod, space, exec, qs ipc call search toggle                     # Start menu / search
