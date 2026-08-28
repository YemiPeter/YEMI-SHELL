/**
 * parallax.js — Pure parallax math, zero dependencies.
 *
 * Exposes preset profiles and computes effective scale/position/offsets
 * from config values. No renderer, no QML types — just numbers.
 */

const PRESETS = {
    subtle:   { zoom: 1.02,  workspaceShift: 0.3, panelShift: 0.1,  widgetDepth: 1.1  },
    balanced: { zoom: 1.05,  workspaceShift: 0.5, panelShift: 0.15, widgetDepth: 1.15 },
    immersive:{ zoom: 1.10,  workspaceShift: 1.0, panelShift: 0.3,  widgetDepth: 1.3  }
};

function preset(name) {
    return PRESETS[name] ?? PRESETS.balanced
}

function detectPreset(zoom, workspaceShift, panelShift, widgetDepth) {
    const z = zoom ?? 1.0
    const ws = workspaceShift ?? 0
    const p  = panelShift  ?? 0
    const wd = widgetDepth ?? 1.0

    for (const [name, cfg] of Object.entries(PRESETS)) {
        if (Math.abs(z - cfg.zoom) < 0.02
            && Math.abs(ws - cfg.workspaceShift) < 0.1
            && Math.abs(p - cfg.panelShift) < 0.05
            && Math.abs(wd - cfg.widgetDepth) < 0.05) {
            return name
        }
    }
    return "custom"
}

function effectiveScale(zoom, axis = "horizontal") {
    const z = zoom ?? 1.0
    if (axis === "vertical") return Math.max(1.0, z)
    return Math.max(1.0, z)
}

function parallaxPosition(workspaceIndex, maxWorkspaces, shiftAmount, zoom) {
    const ws = workspaceIndex ?? 1
    const max = Math.max(1, maxWorkspaces)
    const shift = shiftAmount ?? 0.5
    const z = zoom ?? 1.05

    const maxShift = (z - 1) / 2
    const step = maxShift * shift
    const totalTravel = maxShift * 2
    const progress = max > 1 ? (ws - 1) / (max - 1) : 0

    return progress * totalTravel
}

function axisValue(axis, workspaceIndex, maxWorkspaces, shiftAmount, zoom) {
    if (axis === "vertical")
        return parallaxPosition(workspaceIndex, maxWorkspaces, shiftAmount, zoom)
    return parallaxPosition(workspaceIndex, maxWorkspaces, shiftAmount, zoom)
}
