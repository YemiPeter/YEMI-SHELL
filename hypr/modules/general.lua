-- ═════════════════════════════════════════════════════════════════════════════
-- General look & feel — animations, misc, cursor
-- ═════════════════════════════════════════════════════════════════════════════
-- Converted from the inline hyprlang blocks that used to live at the bottom of
-- hyprland.conf (animations { }, misc { }, cursor { }).
--
-- NOTE: general/decoration (gaps, rounding, blur, shadow) are NOT set here.
-- Those are owned by modules/decoration.lua, which the pill's Look surface
-- rewrites live. Setting them here too would fight that writer.
--
-- (decoration.lua itself is still hyprlang — a separate, pending change.)

hl.config({
    animations = {
        enabled = true,
    },

    misc = {
        disable_hyprland_logo        = true,
        animate_manual_resizes       = true,
        animate_mouse_windowdragging = true,

        -- Kept exactly as the live hyprland.conf had them: the DPMS-on-input
        -- keys are set, the comment about flicker only ever applied to vrr
        -- (which is still NOT set — Intel iGPU VRR renegotiation flickers).
        mouse_move_enables_dpms = true,
        key_press_enables_dpms  = true,
    },

    cursor = {
        inactive_timeout = 3,
    },
})

-- ── Animation curves ─────────────────────────────────────────────────────────
-- hyprlang:  bezier = <name>, x1, y1, x2, y2
hl.curve("bounce",  { type = "bezier", points = { {0.0, 1.25}, {0.15, 1.0}  } })
hl.curve("buttery", { type = "bezier", points = { {0.1, 1.15}, {0.15, 1.02} } })
hl.curve("smooth",  { type = "bezier", points = { {0.0, 0.0},  {0.12, 1.0}  } })
-- NOTE: the name `linear` shadows one of Hyprland's built-in curve names; the
-- example config defines it identically ({0,0}→{1,1}), so redefining it here
-- is harmless. Kept for byte-for-byte fidelity with the old hyprlang config.

-- ── Animations ───────────────────────────────────────────────────────────────
-- hyprlang:  animation = <leaf>, <enabled>, <speed>, <curve>[, <style>]
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 4.5, bezier = "bounce",  style = "slide" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 3.5, bezier = "smooth",  style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4,   bezier = "buttery", style = "slide" })

hl.animation({ leaf = "fadeIn",     enabled = true, speed = 3.5, bezier = "smooth" })
hl.animation({ leaf = "fadeOut",    enabled = true, speed = 3,   bezier = "smooth" })
hl.animation({ leaf = "fadeDim",    enabled = true, speed = 4,   bezier = "smooth" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 4,   bezier = "smooth" })

hl.animation({ leaf = "workspaces",        enabled = true, speed = 4.5, bezier = "buttery", style = "slidefade 10%" })
hl.animation({ leaf = "specialWorkspace",  enabled = true, speed = 4.5, bezier = "buttery", style = "slidefadevert -15%" })

hl.animation({ leaf = "border",      enabled = true, speed = 7,  bezier = "smooth" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 35, bezier = "linear", style = "loop" })

hl.animation({ leaf = "layersIn",  enabled = true, speed = 4, bezier = "bounce", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 3, bezier = "smooth", style = "slide" })
