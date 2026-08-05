pragma Singleton

import Quickshell
import QtQuick 6.10
import "../singletons" as QsSingletons

/**
 * Color reload shim (Phase 0: dead code removal).
 *
 * This service is retained for IPC compatibility but its applyWallpaper()
 * method is deprecated. The single source of truth for color generation
 * is now after-wall.sh → wallcolors.py → colors.json → Dyn.qml.
 *
 * Use QsSingletons.Dyn.reload() or "qs ipc call colorsReload" instead.
 */
Singleton {
    id: root

    // Deprecated: This was the dead code path. Dyn.qml now watches colors.json directly.
    // readonly property string colorsPath: Quickshell.env("RICE_HOME") + "/quickshell/state/colors.qml"

    /// Trigger Dyn.qml to reload colors.json (watches file changes anyway, but this forces it)
    function reload(): void {
        if (QsSingletons.Flags.debug) console.log("🔄 [Matugen/Phase0] Forcing Dyn.qml to reload colors.json")
        QsSingletons.Dyn.reload()
    }

    // DEPRECATED: Use after-wall.sh instead. This is kept for API compatibility.
    // Phase 0.4: Remove from qmldir after confirming no external callers
    function applyWallpaper(imagePath: string): void {
        console.warn("⚠️ [Matugen/Phase0] applyWallpaper() is deprecated. Use after-wall.sh directly.")
        // No-op: color generation now happens through after-wall.sh
    }
}