import QtQuick
import qs.services
import "../../../singletons" as Singletons

/**
   Smooth waveform renderer on a Canvas. Reads the `points` array from
   CavaService and draws a smoothed single-line wave. Driven by playback
   state (playing on the pill, Playing on the music panel).
*/
Item {
    id: root
    property var points: CavaService.points
    readonly property real maxVisualizerValue: 1000
    property int smoothing: 2
    property bool live: true
    property color colorMed: Singletons.Theme.verm
    property real opacity: 1
    property real barCount: 50
    property real barSpacing: 0
    property real barMinHeight: 0
    property real barRadius: 0

    Canvas {
        id: canvas
        anchors.fill: parent

        readonly property real padding: 6 * Singletons.Motion.scale
        readonly property real usableW: width - 2 * padding
        readonly property real usableH: height - 2 * padding

        readonly property var smoothed: {
            var raw = root.points
            if (!root.live || !raw || raw.length === 0)
                return []

            var n = Math.min(raw.length, root.barCount)
            var step = raw.length / n
            var sampled = []
            for (var i = 0; i < n; i++) {
                var idx = Math.floor(i * step)
                sampled.push(raw[idx] / root.maxVisualizerValue)
            }

            // Simple linear smoothing
            var s = root.smoothing
            if (s > 0) {
                var out = []
                for (var j = 0; j < sampled.length; j++) {
                    var sum = 0
                    var cnt = 0
                    for (var k = -s; k <= s; k++) {
                        var idx2 = j + k
                        if (idx2 >= 0 && idx2 < sampled.length) {
                            sum += sampled[idx2]
                            cnt++
                        }
                    }
                    out.push(sum / cnt)
                }
                sampled = out
            }
            return sampled
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            if (width <= 0 || height <= 0) return

            var pts = smoothed
            if (!pts || pts.length === 0) return

            var pad = padding
            var uw = usableW
            var uh = usableH
            var midY = uh / 2 + pad

            ctx.fillStyle = root.colorMed
            ctx.globalAlpha = root.opacity

            ctx.beginPath()
            ctx.moveTo(pad, midY)

            var step = uw / pts.length
            for (var i = 0; i < pts.length; i++) {
                var x = pad + (i + 0.5) * step
                var y = midY - pts[i] * uh / 2
                if (i === 0) ctx.lineTo(x, y)
                else ctx.lineTo(x, y)
            }

            // Close at the bottom
            ctx.lineTo(pad + uw, midY + 0.5)
            ctx.lineTo(pad, midY + 0.5)
            ctx.closePath()
            ctx.fill()

            ctx.globalAlpha = 1
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    Connections {
        target: CavaService
        function onPointsChanged() { canvas.requestPaint() }
    }

    Timer {
        interval: 50
        repeat: true
        running: root.live
        triggerOnStart: true
        onTriggered: {
            if (root.points && root.points.length > 0)
                canvas.requestPaint()
        }
    }
}
