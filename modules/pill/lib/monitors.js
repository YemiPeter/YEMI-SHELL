/**
 * Display monitor parser for the display surface.
 * Parses Hyprland monitors.lua output and provides mode lists.
 */

function parseMonitors(text) {
    const monitors = [];
    const lines = text.split("\n");
    let current = null;

    for (const line of lines) {
        const trimmed = line.trim();
        if (!trimmed || trimmed.startsWith("--")) continue;

        // Monitor declaration
        const monMatch = trimmed.match(/monitor\s*=\s*(\S+)/);
        if (monMatch) {
            if (current) monitors.push(current);
            current = { name: monMatch[1], modes: [] };
            continue;
        }

        // Mode line
        if (current && trimmed.startsWith("mode = ")) {
            const modeMatch = trimmed.match(/mode\s*=\s*(\d+)x(\d+)(?:\s*@\s*([\d.]+))?/);
            if (modeMatch) {
                current.modes.push({
                    w: parseInt(modeMatch[1]),
                    h: parseInt(modeMatch[2]),
                    refresh: modeMatch[3] ? parseFloat(modeMatch[3]) : 60,
                    label: modeMatch[1] + "×" + modeMatch[2] + (modeMatch[3] ? " @" + modeMatch[3] + "Hz" : "")
                });
            }
        }
    }
    if (current) monitors.push(current);
    return monitors;
}

function findMonitor(monitors, name) {
    return monitors.find(m => m.name === name) || null;
}
