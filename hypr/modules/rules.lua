-- ═════════════════════════════════════════════════════════════════════════════
-- Window rules + layer rules
-- ═════════════════════════════════════════════════════════════════════════════
-- Converted from hyprlang:
--   windowrule = match:class X, opacity A B   ->  hl.window_rule({ match = {...}, opacity = ... })
--   layerrule  = blur on, match:namespace X   ->  hl.layer_rule({ match = {...}, blur = true })
--
-- In Lua the matcher moves into a `match = { }` table and the effects become
-- named fields. Every rule gets a `name` so it can be updated or toggled later
-- via the returned handle.

-- ── Per-application transparency ─────────────────────────────────────────────
-- hyprlang `opacity A B` = active opacity, inactive opacity. The old rules only
-- ever changed the active value and left inactive at 1, so active_opacity is
-- the only field that differs from the default.
local transparent_apps = {
    { class = "Lorien",        active = 0.8  },
    { class = "sublime_text",  active = 0.88 },
    { class = "thunar",        active = 0.9  },
    { class = "Thunar",        active = 0.9  },
    { class = "VSCodium",      active = 0.88 },
    { class = "codium",        active = 0.88 },
    { class = "org.pwmt.zathura", active = 0.9 },
    { class = "ghostty",       active = 0.85 },
    { class = "firefox",       active = 1.0  },
}

for _, app in ipairs(transparent_apps) do
    hl.window_rule({
        name  = "opacity-" .. app.class,
        match = { class = app.class },
        -- `opacity` is a STRING "<active> <inactive>", not a table. A table
        -- raises: field 'opacity': string type requires a string.
        opacity = app.active .. " 1.0",
    })
end

-- ── MPV media player: floating, centred, fixed size ──────────────────────────
hl.window_rule({
    name  = "mpv-float",
    match = { class = "mpv" },
    float = true,
})
hl.window_rule({
    name  = "mpv-size",
    match = { class = "mpv" },
    size  = { 640, 360 },
})
hl.window_rule({
    name  = "mpv-center",
    match = { class = "mpv" },
    center = true,
})
hl.window_rule({
    name     = "mpv-opacity",
    match    = { class = "mpv" },
    opacity  = "1.0 1.0",
})

-- Floating windows centre automatically.
hl.window_rule({
    name  = "float-center",
    match = { float = true },
    center = true,
})

-- ── Scratch terminal ─────────────────────────────────────────────────────────
hl.window_rule({
    name  = "scratchterm-float",
    match = { class = "scratchterm" },
    float = true,
})
hl.window_rule({
    name  = "scratchterm-size",
    match = { class = "scratchterm" },
    size  = { "85%", "70%" },
})
hl.window_rule({
    name  = "scratchterm-center",
    match = { class = "scratchterm" },
    center = true,
})

-- ═════════════════════════════════════════════════════════════════════════════
-- Layer rules (blur / ignore_alpha / animation)
-- ═════════════════════════════════════════════════════════════════════════════
-- ignore_alpha 0 means "do not ignore any alpha", i.e. blur is driven by the
-- surface's alpha — that is Hyprland's default, so those rules only need the
-- blur enabled. The old `ignore_alpha = 0` lines are therefore folded into the
-- corresponding blur rule rather than repeated.
--
-- NOTE: swaync and waybar are not part of this rice any more (YemiShell's pill
-- replaced them). Their rules are kept only if those programs are still in use;
-- see the note below.

local blurred_namespaces = {
    "quickshell",             -- main shell layer surface
    "pill",                   -- pill surfaces
    "pill-tray",              -- tray dropdown
}

for _, ns in ipairs(blurred_namespaces) do
    hl.layer_rule({
        name       = "blur-" .. ns,
        match      = { namespace = ns },
        blur       = true,
        ignore_alpha = 0,
    })
end

-- AltSwitcher overlay — "let the alt be just the alt".
-- The layer surface is full-screen but visually transparent everywhere except
-- the centred card, so:
--  * blur/ignore_alpha frost ONLY the card's pixels (alpha > 0); the desktop
--    around it stays sharp and unblurred.
--  * `animation fade` replaces the global layersIn/layersOut (bounce+slide)
--    animation that made the full-screen surface visibly wobble on every
--    Alt+Tab — the layer now just fades, and the card itself fades via QML
--    (300ms in / 140ms out).
hl.layer_rule({
    name         = "altswitcher-blur",
    match        = { namespace = "quickshell:altSwitcher" },
    blur         = true,
    ignore_alpha = 0,
})
hl.layer_rule({
    name      = "altswitcher-anim",
    match     = { namespace = "quickshell:altSwitcher" },
    animation = "fade",
})

-- ── Legacy notification daemon (swaync) ──────────────────────────────────────
-- Kept verbatim from the old config in case swaync is still installed. Delete
-- this block if YemiShell's own notification surface has fully replaced it.
hl.layer_rule({
    name         = "swaync-center-blur",
    match        = { namespace = "swaync-control-center" },
    blur         = true,
    ignore_alpha = 0,
})
hl.layer_rule({
    name         = "swaync-window-blur",
    match        = { namespace = "swaync-notification-window" },
    blur         = true,
    ignore_alpha = 0,
})

-- ── Legacy bar (waybar) ──────────────────────────────────────────────────────
-- Same caveat as swaync above.
hl.layer_rule({
    name         = "waybar-blur",
    match        = { namespace = "waybar" },
    blur         = true,
    ignore_alpha = 0,
})
