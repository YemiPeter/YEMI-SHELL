-- ═════════════════════════════════════════════════════════════════════════════
-- Live decoration settings (edited via the pill's Look surface)
-- ═════════════════════════════════════════════════════════════════════════════
-- Converted from hyprlang to Lua as part of the 0.57 migration. Two hyprlang
-- blocks became ONE hl.config call:
--
--   general { ... }      ->  hl.config({ general = { ... } })
--   decoration { ... }   ->  hl.config({ decoration = { ... } })
--
-- The pill's Look surface rewrites the individual `name = value` lines in place
-- (see quickshell/modules/pill/lib/setDeco.js), so the field ORDER and the
-- `name = value` spacing below are load-bearing: that writer matches
-- "field = literal" and splices the new literal back in. Keep one field per
-- line, keep the trailing commas, and do not reorder without updating setDeco.js.
--
-- The "Reset to default" source of truth is decoration.defaults.lua.

hl.config({
    general = {
        gaps_in = 16,
        gaps_out = 11,
        layout = "dwindle",
        border_size = 0,
    },

    decoration = {
        rounding = 9,
        active_opacity = 0.80,
        inactive_opacity = 1.00,
        dim_inactive = true,
        dim_strength = 0.04,

        shadow = {
            enabled = true,
            range = 18,
            render_power = 3,
            color = "rgba(00000040)",
            offset = "0 6",
        },

        blur = {
            enabled = false,
            size = 4,
            passes = 4,
            ignore_opacity = true,
            new_optimizations = true,
            special = true,
            popups = true,
            xray = false,
            vibrancy = 0.1696,
        },
    },
})

