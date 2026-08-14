-- Waffle layer rules for glass blur effects
-- Applied via module sourcing into hyprland.conf

layerrule = "blur on, match:namespace wBackground"
layerrule = "ignore_alpha 0, match:namespace wBackground"
layerrule = "blur on, match:namespace wBackdrop"
layerrule = "ignore_alpha 0, match:namespace wBackdrop"
