-- ═════════════════════════════════════════════════════════════════════════════
-- Monitor layout
-- ═════════════════════════════════════════════════════════════════════════════
-- Converted from hyprlang:
--   monitor=eDP-1,1920x1080@120.03500,0x0,1.00
--
-- The old single-line positional form maps to named fields. Keep the refresh
-- rate as written: this panel runs at ~120 Hz and Hyprland accepts a fractional
-- value here.

hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@120.03500",
    position = "0x0",
    scale    = 1.00,
})

