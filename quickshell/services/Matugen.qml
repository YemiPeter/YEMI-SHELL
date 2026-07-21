pragma Singleton

import Quickshell
import QtQuick 6.10

Singleton {
    id: root

    // Path to the generated colors file that Matugen will create
    readonly property string colorsPath: Quickshell.env("RICE_HOME") + "/quickshell/state/colors.qml"

    // Function to reload colors after wallpaper change
    function reload(): void {
        // Colors will be automatically loaded from the generated file
        console.log("🔄 [Matugen] Colors reloaded from:", colorsPath)
    }

    // Function to apply a new wallpaper and generate colors
    function applyWallpaper(imagePath: string): void {
        // Execute matugen to generate new colors based on the wallpaper
        var proc = Quickshell.Process();
        var matugenConfigPath = Quickshell.env("RICE_HOME") + "/quickshell/dist/matugen/config.toml";
        var cmd = ["matugen", "image", imagePath, "-c", matugenConfigPath];

        proc.execute(cmd);
        console.log("🎨 [Matugen] Generating colors for:", imagePath);
    }
}