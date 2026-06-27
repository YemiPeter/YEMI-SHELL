/**
 * Decoration (rounded corners) setter for the look surface.
 * Writes to Hyprland's decoration.lua config.
 */

function setRounding(rounding) {
    const path = Quickshell.env("HOME") + "/.config/hypr/modules/decoration.lua";
    // In full impl: read file, update rounding value, write back
    // For now: just log
    console.log("Set decoration rounding to:", rounding);
}

function getRounding() {
    // In full impl: parse decoration.lua
    return 12;
}
