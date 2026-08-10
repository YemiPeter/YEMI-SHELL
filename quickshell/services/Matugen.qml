pragma Singleton

import Quickshell
import QtQuick 6.10
import "../singletons" as QsSingletons

/**
 * Color reload shim (Phase 0: dead code removal).
 *
 * This service is retained for IPC compatibility but its applyWallpaper()
 * method is deprecated. The single source of truth for color generation
 * is now after-wall.sh → colors.json → Dyn.qml.
 *
 * Use QsSingletons.Dyn.reload() or "qs ipc call colors reload" instead.
 */
Singleton {
    id: root

    /// Trigger Dyn.qml to reload colors.json (watches file changes anyway, but this forces it)
    function reload(): void {
        QsSingletons.Dyn.reload()
        if (QsSingletons.Flags.debug) console.log("[Matugen] Dyn reloaded")
    }
}