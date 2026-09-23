-- ═════════════════════════════════════════════════════════════════════════════
-- YEMI-SHELL — Hyprland Lua configuration (entrypoint)
-- ═════════════════════════════════════════════════════════════════════════════
--
-- WHY LUA
--   Hyprland 0.55 introduced Lua configs; the old hyprlang (.conf) format is
--   deprecated and STOPS BEING READ in 0.57 (hyprwm/Hyprland#15538). 0.56
--   prints a deprecation banner on every start. This file is the real Lua
--   entrypoint, so 0.57 will load it without any further change.
--
-- ENTRYPOINT
--   Hyprland prefers ~/.config/hypr/hyprland.lua over hyprland.conf when both
--   exist. hyprland.conf is kept as a fallback (see the note at the bottom of
--   this file) but is no longer the source of truth.
--
-- LAYOUT
--   Modular, mirroring the old modules/ split. Each module is a real Lua file
--   pulled in with require(); Hyprland resolves these relative to this file's
--   directory (the lua/ search path has $XDG_CONFIG_HOME/hypr on it).
--
--     modules/general.lua     general / decoration / animations / misc / cursor
--     modules/input.lua       input + cursor device settings
--     modules/monitors.lua    monitor layout
--     modules/env.lua         environment variables
--     modules/autostart.lua   login-time process spawning
--     modules/binds.lua       keybinds + mouse binds
--     modules/rules.lua       window rules + layer rules
--
-- NOTE the old *.lua files in modules/ were hyprlang text behind a .lua
-- extension — the extension had been changed but the contents never converted,
-- so nothing had actually migrated. They are all rewritten here as genuine Lua.
-- ═════════════════════════════════════════════════════════════════════════════

require("modules.env")
require("modules.general")
require("modules.input")
require("modules.monitors")
require("modules.autostart")
require("modules.rules")
require("modules.binds")

-- Loaded LAST so the Look surface's live values win over general.lua's defaults
-- for the fields the two share (general.lua sets the animation/misc/cursor
-- blocks; this one owns general.gaps_* + the whole decoration block).
require("modules.decoration")
