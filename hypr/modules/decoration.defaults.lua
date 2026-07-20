-- Shell by Yemi — House Style Defaults
-- DO NOT EDIT. This is the "Reset to Default" source of truth.
-- Live edits go in decoration.lua instead.

general {
    gaps_in = 5
    gaps_out = 10
    layout = dwindle
    border_size = 0
}

decoration {
    rounding = 15
    active_opacity = 1
    inactive_opacity = 0.9
    dim_inactive = true
    dim_strength = 0.04

    shadow {
        enabled = true
        range = 18
        render_power = 3
        color = rgba(00000040)
        offset = 0 6
    }

    blur {
        enabled = true
        size = 3
        passes = 2
        ignore_opacity = true
        new_optimizations = true
        special = true
        popups = true
        xray = false
        vibrancy = 0.1696
    }
}
