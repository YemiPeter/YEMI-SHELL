// WallpaperManager: Unified wallpaper setter singleton
// Bridges pill and settings UI through a single source of truth
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions
import "root:"

Singleton {
    id: root

    // Current wallpaper path from config (single source of truth)
    readonly property string currentWallpaper: Config.options?.background?.wallpaperPath ?? ""

    // Running state exposed for external checks
    // This allows Walls.qml and other consumers to check if a wallpaper apply is in progress
    readonly property bool isRunning: applyProc.running

    // Signal emitted when a wallpaper apply operation completes
    signal applyCompleted(int exitCode)

    /**
     * Set wallpaper by path
     * Thin wrapper around switchwall.sh - the script handles:
     * 1. Applying the wallpaper
     * 2. Writing to config.json
     * 3. Color regeneration (matugen/wallust)
     */
    function setWallpaper(path: string): void {
        const normalizedPath = FileUtils.trimFileProtocol(String(path ?? ""))
        if (!normalizedPath || normalizedPath.length === 0) return

        const command = [
            Directories.wallpaperSwitchScriptPath,
            "--image", normalizedPath,
            "--mode", (Appearance.m3colors.darkmode ? "dark" : "light"),
            "--skip-config-write"
        ]
        applyProc.exec(command)
    }

    Process {
        id: applyProc
        onStarted: {
            // Debug logging for tracking apply operations
            console.log("WallpaperManager.setWallpaper: started apply process")
        }
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                console.error("WallpaperManager.setWallpaper: switchwall.sh failed with exit code", exitCode,
                              "path:", Directories.wallpaperSwitchScriptPath)
            } else {
                console.log("WallpaperManager.setWallpaper: completed successfully")
            }
            // Notify listeners that apply is complete
            root.applyCompleted(exitCode)
            // Let switchwall.sh handle config write and color regen
            // The state file is read by Walls.qml via stateProc
        }
    }
}