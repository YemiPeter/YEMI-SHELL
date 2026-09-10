pragma ComponentBehavior: Bound

import qs.services
import QtQuick

// Wavy cava line on the media card (port of iNiR's CavaWavyLine from
// BarMediaPlayerItem). Sine carrier modulated by smoothed cava magnitudes,
// redrawn at ~30fps. Points self-bind to CavaService like WaveVisualizer;
// consumers drive the cava lifecycle with CavaProcess { active: ... }.
Canvas {
    id: root

    property var points: CavaService.points
    property color color: "white"
    property real lineWidth: 3
    property real amplitudeScale: 1.0
    property real maxVisualizerValue: 1000
    property int smoothing: 2

    // Animation loop to drive the wave phase even if cava points are static
    property real phase: 0
    property var smoothPoints: []

    onPointsChanged: root.requestPaint()

    Timer {
        interval: 32 // ~30fps
        running: root.visible
        repeat: true
        onTriggered: {
            root.phase += 0.1
            root.requestPaint()
        }
    }

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        var points = root.points;
        var n = points.length;
        // Flat line when silent (no cava points or player paused)
        if (n < 2) {
            ctx.beginPath();
            ctx.moveTo(0, height / 2);
            ctx.lineTo(width, height / 2);
            ctx.strokeStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.3);
            ctx.lineWidth = 1;
            ctx.stroke();
            return;
        }

        // Window smoothing for a nicer curve
        var smoothWindow = root.smoothing;
        root.smoothPoints = [];
        for (var i = 0; i < n; ++i) {
            var sum = 0, count = 0;
            for (var j = -smoothWindow; j <= smoothWindow; ++j) {
                var idx = Math.max(0, Math.min(n - 1, i + j));
                sum += points[idx];
                count++;
            }
            root.smoothPoints.push(sum / count);
        }

        ctx.beginPath();
        var centerY = height / 2;
        var maxVal = root.maxVisualizerValue || 1000.0;

        ctx.moveTo(0, centerY);

        for (i = 0; i < n; ++i) {
            var x = (i / (n - 1)) * width;
            var magnitude = (root.smoothPoints[i] / maxVal) * (height / 2) * root.amplitudeScale;
            var waveCarrier = Math.sin(i * 0.5 + root.phase);
            var y = centerY + magnitude * waveCarrier * 3;

            ctx.lineTo(x, y);
        }

        ctx.strokeStyle = root.color;
        ctx.lineWidth = root.lineWidth;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.stroke();
    }
}