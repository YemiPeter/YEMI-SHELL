/**
 * Input method setter for the input surface.
 * Writes to Hyprland's input.lua config.
 */

function setKeyboardLayout(layout) {
    const path = Quickshell.env("HOME") + "/.config/hypr/modules/input.lua";
    // In full impl: read file, update kb_layout, write back
    console.log("Set keyboard layout to:", layout);
}

function getKeyboardLayout() {
    return "us";
}

function setTouchpadEnabled(enabled) {
    console.log("Touchpad enabled:", enabled);
}

function getTouchpadEnabled() {
    return true;
}
