pragma Singleton

import Quickshell
import QtQuick 6.10
import qs.services
import "../singletons" as QsSingletons

Singleton {
    id: root

    // Path to the generated colors file that Matugen will create
    readonly property string colorsPath: Quickshell.env("RICE_HOME") + "/quickshell/state/colors.qml"

    // Function to reload colors after wallpaper change.
    // Previously this only logged — the A→B pipeline bridge was broken.
    // Now it delegates to MaterialThemeLoader.reapplyTheme() which re-reads
    // generated/colors.json and applies colors to Appearance.m3colors.
    function reload(): void {
        if (QsSingletons.Flags.debug) console.log("🔄 [Matugen] reload() → delegating to MaterialThemeLoader.reapplyTheme()")
        MaterialThemeLoader.reapplyTheme()
    }

    // Function to apply a new wallpaper and generate colors
    function applyWallpaper(imagePath: string): void {
        // Execute matugen to generate new colors based on the wallpaper
        var proc = Quickshell.Process();
        var matugenConfigPath = Quickshell.env("RICE_HOME") + "/quickshell/dist/matugen/config.toml";
        var cmd = ["matugen", "image", imagePath, "-c", matugenConfigPath];

        proc.execute(cmd);
        if (QsSingletons.Flags.debug) console.log("🎨 [Matugen] Generating colors for:", imagePath);
    }
}