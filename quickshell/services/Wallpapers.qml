pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.compositor
import "."
import "../singletons" as QsSingletons

Singleton {
    id: root

    signal changed()

    readonly property string wpDir: QsSingletons.Walls.wpDir
    readonly property string setScript: QsSingletons.Walls.setScript

    readonly property string globalWallpaperPath: Config.options?.background?.wallpaperPath ?? ""

    readonly property bool autoWallpaperEnabled: QsSingletons.Flags.autoWallpaperEnable
    readonly property int autoWallpaperInterval: QsSingletons.Flags.autoWallpaperInterval

    Timer {
        id: autoWallpaperTimer
        interval: root.autoWallpaperInterval * 60 * 1000
        running: root.autoWallpaperEnabled
        repeat: true
        onTriggered: root._cycleAutoWallpaper()
    }

    Connections {
        target: QsSingletons.Flags
        function onAutoWallpaperEnableChanged() { autoWallpaperTimer.restart() }
        function onAutoWallpaperIntervalChanged() { autoWallpaperTimer.restart() }
    }

    function _cycleAutoWallpaper() {
        const entries = QsSingletons.Walls.entries
        if (entries.length === 0) return
        const currentPath = Config.options?.background?.wallpaperPath ?? ""
        let randomIndex, filePath
        let attempts = 0
        do {
            randomIndex = Math.floor(Math.random() * entries.length)
            filePath = entries[randomIndex].path
            attempts++
        } while (filePath === currentPath && attempts < 5 && entries.length > 1)
        if (!filePath) return
        root.apply(filePath, true, "")
    }

    function currentMainWallpaperPath(monitorName = ""): string {
        const mainPath = currentMainWallpaperPath(monitorName)
        const normalizedTarget = target && target.length > 0 ? target : "main"

        switch (normalizedTarget) {
        case "backdrop": {
            const bd = Config.options?.background?.backdrop ?? {}
            if (!(bd.useMainWallpaper ?? true) && bd.wallpaperPath) return bd.wallpaperPath
            return mainPath
        }
        default:
            return mainPath
        }
    }

    function apply(path, darkMode = true, monitorName = "") {
        const normalizedPath = String(path ?? "").trim()
        if (!normalizedPath) return

        if (monitorName && monitorName.length > 0) {
            updatePerMonitorConfig(normalizedPath, monitorName)
            QsSingletons.Walls.apply(normalizedPath)
            root.changed()
            return
        }

        Config.setNestedValue("background.wallpaperPath", normalizedPath)
        QsSingletons.Walls.apply(normalizedPath)
        root.changed()
    }

    function applySelectionTarget(path, target = "main", darkMode = true, monitorName = "") {
        const normalizedPath = String(path ?? "").trim()
        if (!normalizedPath) return

        const normalizedTarget = target && target.length > 0 ? target : "main"

        switch (normalizedTarget) {
        case "backdrop":
            Config.setNestedValue("background.backdrop.useMainWallpaper", false)
            Config.setNestedValue("background.backdrop.wallpaperPath", normalizedPath)
            if (Config.options?.appearance?.wallpaperTheming?.useBackdropForColors ?? false)
                Quickshell.execDetached([QsSingletons.Walls.setScript, "--noswitch"])
            root.changed()
            return
        default:
            root.apply(normalizedPath, darkMode, monitorName)
            return
        }
    }

    function select(filePath, darkMode = true, monitorName = "", target = "") {
        const normalizedPath = String(filePath ?? "").trim()
        if (!normalizedPath) return

        const resolvedTarget = target && target.length > 0 ? target : "main"
        if (resolvedTarget !== "main") {
            root.applySelectionTarget(normalizedPath, resolvedTarget, darkMode, monitorName)
            return
        }

        root.apply(normalizedPath, darkMode, monitorName)
    }

    function randomFromCurrentFolder(darkMode = true, monitorName = "", target = "") {
        const entries = QsSingletons.Walls.entries
        if (entries.length === 0) return
        const randomIndex = Math.floor(Math.random() * entries.length)
        const filePath = entries[randomIndex].path
        root.select(filePath, darkMode, monitorName, target)
    }

    function updatePerMonitorConfig(path: string, monitorName: string) {
        const currentArray = Config.options?.background?.wallpapersByMonitor ?? []
        const newArray = []
        let currentEntry = null
        for (const entry of currentArray) {
            if (entry && entry.monitor === monitorName) {
                currentEntry = entry
            } else if (entry) {
                newArray.push(entry)
            }
        }

        newArray.push(Object.assign({}, currentEntry ?? {}, {
            monitor: monitorName,
            path: path
        }))

        Config.setNestedValue("background.wallpapersByMonitor", newArray)
    }

    function updatePerMonitorBackdropConfig(backdropPath: string, monitorName: string) {
        const currentArray = Config.options?.background?.wallpapersByMonitor ?? []
        const newArray = []
        let found = false
        for (const entry of currentArray) {
            if (!entry) continue
            if (entry.monitor === monitorName) {
                found = true
                newArray.push(Object.assign({}, entry, { backdropPath: backdropPath }))
            } else {
                newArray.push(entry)
            }
        }
        if (!found) {
            newArray.push({
                monitor: monitorName,
                path: Config.options?.background?.wallpaperPath ?? "",
                backdropPath: backdropPath
            })
        }
        Config.setNestedValue("background.wallpapersByMonitor", newArray)
    }

    function isCurrentWallpaperPath(path: string, target = "main", monitorName = ""): bool {
        const currentPath = currentWallpaperPathForTarget(target, monitorName)
        const normalized = String(path ?? "").trim()
        const current = String(currentPath ?? "").trim()
        return current.length > 0 && current === normalized
    }
}
