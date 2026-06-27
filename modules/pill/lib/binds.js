/**
 * Keybind parser for the keybinds surface.
 * Reads Hyprland binds.lua format and exposes parsed bindings.
 */

function parse(bindsText) {
    const binds = [];
    const lines = bindsText.split("\n");
    for (const line of lines) {
        const trimmed = line.trim();
        if (!trimmed || trimmed.startsWith("--")) continue;
        // Simple parse: look for bind = { ... } patterns
        const match = trimmed.match(/bind\s*=\s*\{([^}]+)\}/);
        if (match) {
            const inner = match[1];
            const mods = (inner.match(/mods\s*=\s*"([^"]+)"/) || [])[1] || "";
            const key = (inner.match(/key\s*=\s*"([^"]+)"/) || [])[1] || "";
            const action = (inner.match(/action\s*=\s*"([^"]+)"/) || [])[1] || "";
            const desc = (inner.match(/description\s*=\s*"([^"]+)"/) || [])[1] || "";
            binds.push({ mods, key, action, description: desc || action });
        }
    }
    return binds;
}

function rebind(binds, index, newAction) {
    if (index >= 0 && index < binds.length) {
        binds[index].action = newAction;
    }
}

function editAction(binds, index) {
    return binds[index] ? binds[index].action : "";
}

function editCmd(binds, index) {
    return binds[index] ? binds[index].description || binds[index].action : "";
}

function editName(binds, index) {
    return binds[index] ? binds[index].key : "";
}

function inUse(binds, action) {
    return binds.some(b => b.action === action);
}

function add(binds, mods, key, action, description) {
    binds.push({ mods, key, action, description: description || action });
}

function del(binds, index) {
    if (index >= 0 && index < binds.length)
        binds.splice(index, 1);
}
