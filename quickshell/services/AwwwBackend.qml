pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.compositor

Singleton {
    id: root

    readonly property string awwwBin: "awww"
    readonly property bool available: _available
    property bool _available: false

    readonly property int defaultTransitionDurationMs: 800
    readonly property int defaultTransitionFps: 60
    readonly property int defaultSimpleStep: 5
    readonly property int defaultSpatialStep: 30

    function supportsMainWallpaper(path) {
        if (!path) return false
        const lower = path.toLowerCase()
        return !lower.endsWith(".gif") && !lower.endsWith(".mp4") && !lower.endsWith(".webm")
            && !lower.endsWith(".mkv") && !lower.endsWith(".avi") && !lower.endsWith(".mov")
    }

    function normalizedAwwwTransitionType(type, direction) {
        const t = String(type ?? "crossfade").toLowerCase().trim()
        if (t === "crossfade") return "fade"
        if (t === "slide" || t === "directional") return direction ?? "right"
        if (t === "random") return "random"
        return t
    }

    function apply(path, monitorName = "", options = ({})) {
        if (!root._available) return
        const normalizedPath = String(path ?? "").trim()
        if (!normalizedPath) return

        const transitionType = options.transitionType ?? "fade"
        const transitionDuration = options.transitionDuration ?? 0.8
        const transitionFps = options.transitionFps ?? 60
        const simpleStep = options.simpleStep ?? 5
        const spatialStep = options.spatialStep ?? 30
        const bezier = options.bezier ?? ""
        const angle = options.angle ?? ""
        const pos = options.pos ?? ""
        const wave = options.wave ?? ""

        const args = [root.awwwBin, "img"]
        if (monitorName && monitorName.length > 0) {
            args.push("-o", monitorName)
        }
        args.push("-t", transitionType)
        if (transitionDuration > 0 && transitionType !== "simple" && transitionType !== "none")
            args.push("--transition-duration", String(transitionDuration))
        if (transitionFps > 0)
            args.push("--transition-fps", String(transitionFps))
        if (simpleStep > 0 && (transitionType === "simple" || transitionType === "none"))
            args.push("--transition-step", String(simpleStep))
        if (spatialStep > 0 && transitionType !== "simple" && transitionType !== "none" && transitionType !== "fade")
            args.push("--transition-step", String(spatialStep))
        if (bezier && bezier.length > 0)
            args.push("--transition-bezier", bezier)
        if (angle && angle.length > 0)
            args.push("--transition-angle", angle)
        if (pos && pos.length > 0)
            args.push("--transition-pos", pos)
        if (wave && wave.length > 0)
            args.push("--transition-wave", wave)
        args.push(normalizedPath)

        Quickshell.execDetached(args)
    }

    function clear(monitorName = "", color = "0x000000") {
        if (!root._available) return
        const args = [root.awwwBin, "clear"]
        if (monitorName && monitorName.length > 0)
            args.push("-o", monitorName)
        args.push(color)
        Quickshell.execDetached(args)
    }

    function query() {
        // awww query reports the current wallpaper path, but there is no
        // synchronous process API exposed here; callers currently expect null.
        if (!root._available) return null
        return null
    }

    // Probe whether the awww binary is available at startup. A Process must be
    // declared as a child object (not constructed inline inside a function).
    Process {
        id: checkAvailabilityProc
        command: [root.awwwBin, "--help"]
        running: true
        onExited: function(exitCode) {
            root._available = exitCode === 0
        }
    }
}
