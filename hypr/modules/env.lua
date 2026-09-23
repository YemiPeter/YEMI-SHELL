-- ═════════════════════════════════════════════════════════════════════════════
-- Environment variables
-- ═════════════════════════════════════════════════════════════════════════════
-- Converted from hyprlang:
--   env = KEY,VALUE   ->   hl.env("KEY", "VALUE")

hl.env("XCURSOR_THEME",       "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE",        "12")
hl.env("HYPRCURSOR_SIZE",     "12")
hl.env("QT_QPA_PLATFORMTHEME", "kde")

-- RICE_HOME is NOT set here. It is exported portably by environment.d/rice.conf
-- (/home/yemi/.config) and fish/config.fish; install.sh ensure_rice_home()
-- regenerates it on fresh installs. Quickshell falls back to $HOME/.config when
-- RICE_HOME is unset, so the shell works either way.

