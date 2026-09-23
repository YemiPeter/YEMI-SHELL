-- ═════════════════════════════════════════════════════════════════════════════
-- Login-time autostart
-- ═════════════════════════════════════════════════════════════════════════════
-- Converted from hyprlang `exec-once = CMD`.
--
-- The example config suggests hl.on("hyprland.start", function() ... end) with
-- hl.exec_cmd(...) for autostart. That event form is the idiomatic Lua way and
-- is used for the plain one-shot spawns below. The cases that need shell
-- semantics (a pipeline redirect, or `setsid --fork` for a long-lived
-- background job) stay as explicit `bash -c` exec_cmd calls, because
-- hl.exec_cmd does not go through a shell when given a single string, and the
-- redirect/backgrounding would otherwise be passed as literal arguments.
--
-- NOTE: the skwd-walld daemon is NOT started here — it is started by the
-- fallback hyprland.conf's exec-once block AND independently by systemd
-- (WantedBy=default.target), so it is deliberately not duplicated.
--
-- NOTE: modules/autostart.lua is sourced by BOTH entrypoints, so the
-- `source = modules/autostart.lua` line must be removed from hyprland.conf
-- before this runs only once per login (pending cleanup).

hl.on("hyprland.start", function()
    -- The rice's shell (panel/pill/wallpaper wiring). start-shell.sh waits for
    -- the Wayland socket and the skwd daemon, then execs quickshell with an
    -- explicit -p path; it retries once if the first launch exits early.
    hl.exec_cmd("~/.config/quickshell/scripts/start-shell.sh")

    -- Cursor theme applied through hyprctl (needs the compositor up).
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 12")

    -- Polkit authentication agent for GUI sudo prompts.
    hl.exec_cmd("systemctl --user start hyprpolkitagent")

    -- Publish the Wayland/session identity into the systemd user manager. This
    -- is what lets user units (skwd-walld, portals, …) detect the session.
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Clipboard history. The redirect into cliphist is a shell pipeline, so it
    -- must run under bash -c rather than in hl.exec_cmd's argv form.
    hl.exec_cmd("bash -c 'wl-paste --type text  --watch cliphist store'")
    hl.exec_cmd("bash -c 'wl-paste --type image --watch cliphist store'")
end)

-- ── Wallpaper restore at login ───────────────────────────────────────────────
-- Runs DETACHED (setsid --fork) so it survives as a background process instead
-- of holding up startup, and so the paint lands whenever skwd is ready.
--
-- set-wallpaper.sh waits for skwd-walld's helm IPC socket (up to ~90s) before
-- painting, because skwd's session detector can need ~56s at boot to notice
-- the Wayland session — it starts before Hyprland has exported
-- WAYLAND_DISPLAY. Painting before that window closes is what produced
-- "wallpaper doesn't start on startup".
hl.exec_cmd("setsid --fork bash -c '~/.config/quickshell/scripts/set-wallpaper.sh hyprland init' >/dev/null 2>&1")

