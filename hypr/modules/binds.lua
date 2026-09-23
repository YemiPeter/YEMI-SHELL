-- ═════════════════════════════════════════════════════════════════════════════
-- Keybinds + mouse binds  (edited via the pill's Keybinds surface)
-- ═════════════════════════════════════════════════════════════════════════════
-- Converted from hyprlang `bind = MODS, KEY, DISPATCHER, ARGS`.
-- In Lua:  hl.bind("<mods> + <key>", <dispatcher>, <flags?>)
--
-- Dispatchers come from the hl.dsp.* table. `exec` becomes hl.dsp.exec_cmd(),
-- window/workspace actions become hl.dsp.window.* / hl.dsp.focus({ workspace })
-- and so on. Flags (locked/repeating/mouse) are the trailing table.

local mod  = "SUPER"
local modS = "SUPER + SHIFT"
local modC = "SUPER + CTRL"
local alt  = "ALT"
local altS = "ALT + SHIFT"

-- Program shorthands, so the binds read like the old config.
local terminal       = "kitty"
local terminalAlt    = "ghostty"
local fileManagerCmd = "~/.config/hypr/scripts/file-manager.sh"

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 1 — APPS, WORKSPACES & ACTIONS
-- ═════════════════════════════════════════════════════════════════════════════

-- Launcher
hl.bind(mod .. " + space", hl.dsp.exec_cmd("qs ipc call pill launcher eDP-1"))

-- Terminals
hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + T",      hl.dsp.exec_cmd(terminalAlt))
-- Floating terminal: hyprlang's `[float; size 700 400]` exec rule maps to
-- window-rule-ish flags on the spawned window, expressed here as a shell run.
hl.bind(modS .. " + Return",
        hl.dsp.exec_cmd("hyprctl dispatch exec '[float; size 700 400] " .. terminal .. "'"))

-- File manager (dolphin > thunar > nautilus)
hl.bind(mod .. " + E", hl.dsp.exec_cmd(fileManagerCmd))

-- Close window
hl.bind(mod .. " + Q", hl.dsp.window.close())

-- Wallpaper settings
hl.bind(mod .. " + W", hl.dsp.exec_cmd("qs ipc call wallpaper toggle eDP-1"))

-- Lock screen
hl.bind(mod .. " + X", hl.dsp.exec_cmd("~/.config/hypr/scripts/lock.sh"))

-- Music player
hl.bind(mod .. " + M", hl.dsp.exec_cmd("qs ipc call music toggle"))

-- Clipboard history
hl.bind(mod .. " + C", hl.dsp.exec_cmd("qs ipc call pill clipboard eDP-1"))

-- Screenshots. These are shell pipelines/command substitution, so they run via
-- bash -c rather than hl.exec_cmd's argv form.
local screenshotArea =
    "bash -c 'mkdir -p $HOME/Pictures/Screenshots && " ..
    "grim -g \"$(slurp)\" $HOME/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && " ..
    "notify-send \"Screenshot Saved\" \"Area captured\" -i camera-photo'"
local screenshotFull =
    "bash -c 'mkdir -p $HOME/Pictures/Screenshots && " ..
    "grim $HOME/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && " ..
    "notify-send \"Screenshot Saved\" \"Full screen captured\" -i camera-photo'"

hl.bind(mod .. " + S",  hl.dsp.exec_cmd(screenshotArea))
hl.bind(modS .. " + S", hl.dsp.exec_cmd(screenshotFull))
hl.bind(modC .. " + S", hl.dsp.exec_cmd(screenshotArea))

-- Screen recording. NOTE the original hyprlang lines were `exec, CMD & CMD2`
-- with no shell wrapper, so `&`/`&&` went through Hyprland's own exec parsing
-- (it splits on pipes/&&/& but not on $(), so the $(date …) stayed literal).
-- Wrapped in bash -c here so $() expands and the background/&& operators are
-- unambiguous — strictly an improvement over the old behaviour.
hl.bind(mod .. " + R", hl.dsp.exec_cmd(
    "bash -c 'gpu-screen-recorder -w screen -f 30 -a default_output " ..
    "-o ~/screen-recordings/$(date +%Y-%m-%d_%H-%M-%S).mp4 & notify-send \"Recording Started\"'"))
hl.bind(modS .. " + R", hl.dsp.exec_cmd(
    "bash -c 'killall -SIGINT gpu-screen-recorder && notify-send \"Recording Stopped\"'"))


-- ── Workspace navigation + move ──────────────────────────────────────────────
-- Generated in a loop instead of 18 hand-written lines.
for i = 1, 9 do
    hl.bind(mod .. " + " .. i,  hl.dsp.focus({ workspace = i }))
    hl.bind(modS .. " + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- ⚠️ ORPHANED — the special-workspace concept was removed (togglespecialworkspace
--    was deleted), so this move has no way back. Kept inert pending a decision.
-- hl.bind(modS .. " + S", hl.dsp.window.move({ workspace = "special" }))

-- Layout. `hl.dsp.layout(...)` covers layout dispatchers such as layoutmsg;
-- the stub's HL.LayoutNamespace only lists register(), which is for custom
-- layout providers, so dsp.layout is the right table here.
hl.bind(mod .. " + P", hl.dsp.window.pseudo())
hl.bind(mod .. " + J", hl.dsp.layout("togglesplit"))

-- Skwd wallpaper picker (v2)
hl.bind(modS .. " + W", hl.dsp.exec_cmd("skwd-wall-v2"))

-- Define helper + debug
-- NOTE: hyprlang's `bind = , Menu, exec, …` (empty mods) becomes just the bare
-- key name in Lua — there is no leading comma. Verified against the reference
-- config, which binds bare keys as hl.bind("Print", …) / hl.bind("XF86…", …).
hl.bind("Menu", hl.dsp.exec_cmd("~/.config/scripts/define.sh"))
hl.bind("SUPER + F12", hl.dsp.exec_cmd(
    "bash -c 'hyprctl activeworkspace -j >> /tmp/fs-debug.log 2>&1'"))

-- ═════════════════════════════════════════════════════════════════════════════
-- SECTION 2 — NAVIGATION, WINDOW MANAGEMENT & HARDWARE
-- ═════════════════════════════════════════════════════════════════════════════

-- Fullscreen
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())

-- Toggle floating
hl.bind(modS .. " + space", hl.dsp.window.float({ action = "toggle" }))

-- Focus movement
hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))

-- Move window
hl.bind(modS .. " + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(modS .. " + down",  hl.dsp.window.move({ direction = "down" }))
hl.bind(modS .. " + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(modS .. " + right", hl.dsp.window.move({ direction = "right" }))

-- Resize window (held keys => repeating)
hl.bind(modC .. " + left",  hl.dsp.window.resize({ x = -20, y = 0 }),  { repeating = true })
hl.bind(modC .. " + right", hl.dsp.window.resize({ x = 20,  y = 0 }),  { repeating = true })
hl.bind(modC .. " + up",    hl.dsp.window.resize({ x = 0,   y = -20 }), { repeating = true })
hl.bind(modC .. " + down",  hl.dsp.window.resize({ x = 0,   y = 20 }),  { repeating = true })

-- Cycle windows
hl.bind(mod .. " + Tab",  hl.dsp.window.cycle_next())
hl.bind(modS .. " + Tab", hl.dsp.window.cycle_next({ prev = true }))

-- Alt+Tab — YemiShell Overview (altSwitcher). See modules/altswitcher/AltSwitcher.qml
hl.bind(alt .. " + Tab",  hl.dsp.exec_cmd("qs ipc call altSwitcher next"))
hl.bind(altS .. " + Tab", hl.dsp.exec_cmd("qs ipc call altSwitcher previous"))
-- Release-triggered (hyprlang `bindr`): commits and closes the Overview when the
-- Panels → "Advance on tap" flag is on (gated inside the switcher).
hl.bind(alt .. " + Alt_L", hl.dsp.exec_cmd("qs ipc call altSwitcher releaseCommit"),
        { release = true })

-- Mouse binds — exactly as in Hyprland's shipped example config
-- (/usr/share/hypr/hyprland.lua:290-291): drag/resize dispatchers with the
-- { mouse = true } flag; the stub's BindOptions table is incomplete here but
-- the example is authoritative.
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })


