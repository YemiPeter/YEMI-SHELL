pragma Singleton

import QtQuick
import Quickshell
import qs.compositor

Singleton {
    id: root

    readonly property bool multiMonitorEnabled: Config.options?.background?.multiMonitor?.enable ?? false
    readonly property var wallpapersByMonitorRef: Config.options?.background?.wallpapersByMonitor ?? []
    readonly property string globalWallpaperPath: Config.options?.background?.wallpaperPath ?? ""
    readonly property bool globalAnimationEnabled: Config.options?.background?.enableAnimation ?? true
    readonly property string globalFillMode: Config.options?.background?.fillMode ?? "fill"

    readonly property int screenCount: Quickshell.screens.length
    readonly property var screenNames: {
        const names = []
        for (const screen of Quickshell.screens) {
            names.push(getMonitorName(screen))
        }
        return names
    }

    property var effectivePerMonitor: ({})

    function isVideoPath(path): bool {
        if (!path) return false
        const lower = path.toLowerCase()
        return lower.endsWith(".mp4") || lower.endsWith(".webm") || lower.endsWith(".mkv")
            || lower.endsWith(".avi") || lower.endsWith(".mov")
    }

    function isGifPath(path): bool {
        if (!path) return false
        return path.toLowerCase().endsWith(".gif")
    }

    function isAnimatedPath(path): bool {
        return isVideoPath(path) || isGifPath(path)
    }

    function mediaTypeLabel(path): string {
        if (isVideoPath(path)) return "Video"
        if (isGifPath(path)) return "GIF"
        if (!path) return ""
        return "Image"
    }

    function mediaTypeIcon(path): string {
        if (isVideoPath(path)) return "movie"
        if (isGifPath(path)) return "gif"
        if (!path) return "image_not_supported"
        return "image"
    }

    function getFocusedMonitor(): string {
        return Compositor.focusedMonitor?.name ?? ""
    }

    function refresh() {
        const result = {}
        const screens = Quickshell.screens

        if (!multiMonitorEnabled) {
            for (const screen of screens) {
                const monitorName = getMonitorName(screen)
                if (monitorName) {
                    result[monitorName] = {
                        path: globalWallpaperPath,
                        isVideo: isVideoPath(globalWallpaperPath),
                        isGif: isGifPath(globalWallpaperPath),
                        isAnimated: isAnimatedPath(globalWallpaperPath),
                        hasCustomWallpaper: false
                    }
                }
            }
        } else {
            const byMonitorMap = {}
            for (const entry of wallpapersByMonitorRef) {
                if (entry && entry.monitor) {
                    const p = entry.path ?? ""
                    byMonitorMap[entry.monitor] = {
                        path: p,
                        isVideo: isVideoPath(p),
                        isGif: isGifPath(p),
                        isAnimated: isAnimatedPath(p),
                        hasCustomWallpaper: true,
                        workspaceFirst: entry.workspaceFirst,
                        workspaceLast: entry.workspaceLast,
                        backdropPath: entry.backdropPath ?? ""
                    }
                }
            }

            for (const screen of screens) {
                const monitorName = getMonitorName(screen)
                if (monitorName) {
                    result[monitorName] = byMonitorMap[monitorName] ?? {
                        path: globalWallpaperPath,
                        isVideo: isVideoPath(globalWallpaperPath),
                        isGif: isGifPath(globalWallpaperPath),
                        isAnimated: isAnimatedPath(globalWallpaperPath),
                        hasCustomWallpaper: false
                    }
                }
            }
        }

        const newStr = JSON.stringify(result)
        if (JSON.stringify(effectivePerMonitor) === newStr) return
        effectivePerMonitor = result
    }

    function getMonitorName(screen): string {
        if (!screen) return ""
        return screen.name ?? ""
    }

    Component.onCompleted: refresh()

    onMultiMonitorEnabledChanged: refresh()
    onWallpapersByMonitorRefChanged: refresh()
    onGlobalWallpaperPathChanged: refresh()

    Connections {
        target: Quickshell
        function onScreensChanged() { root.refresh() }
    }

    Timer {
        id: configChangeDebounce
        interval: 80
        onTriggered: root.refresh()
    }
    Connections {
        target: Config
        function onConfigChanged() { configChangeDebounce.restart() }
    }
}
