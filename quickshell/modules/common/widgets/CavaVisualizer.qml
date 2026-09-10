import QtQuick
import qs.services
import "../../../singletons" as Singletons

/**
   Bar/spectrum visualizer (VU meter). Renders vertical bars on a Row via
   Repeater. Bars grow from bottom up, colored with Theme tokens.
*/
Item {
    id: root
    property var points: CavaService.points
    readonly property real maxVisualizerValue: 1000
    property int smoothing: 2
    property bool live: true
    property color colorLow: Singletons.Theme.tileBg
    property color colorMed: Singletons.Theme.cream
    property color colorHigh: Singletons.Theme.verm
    property int barCount: 50
    property real barSpacing: 2 * Singletons.Motion.scale
    property real barMinHeight: 2 * Singletons.Motion.scale
    property real barRadius: 3 * Singletons.Motion.scale

    Row {
        id: barsRow
        anchors.fill: parent
        spacing: root.barSpacing

        Repeater {
            id: barsRepeater
            model: root.barCount

            Item {
                id: barWrapper
                required property int index
                width: (root.width - (root.barCount - 1) * root.barSpacing) / root.barCount
                height: root.height

                property real barValue: {
                    if (!root.live || !root.points || root.points.length === 0) return 0
                    var n = root.points.length
                    var idx = Math.floor((index / root.barCount) * n)
                    idx = Math.min(idx, n - 1)
                    return root.points[idx] / root.maxVisualizerValue
                }

                property real smoothedValue: {
                    var v = barValue
                    if (root.smoothing > 0) {
                        var s = root.smoothing
                        var sum = v
                        var cnt = 1
                        for (var k = 1; k <= s; k++) {
                            var l = index - k
                            if (l >= 0) { sum += barWrapperAt(l); cnt++ }
                            var r = index + k
                            if (r < root.barCount) { sum += barWrapperAt(r); cnt++ }
                        }
                        v = sum / cnt
                    }
                    return v
                }

                function barWrapperAt(i) {
                    if (!root.points || root.points.length === 0) return 0
                    var n = root.points.length
                    var idx = Math.floor((i / root.barCount) * n)
                    idx = Math.min(idx, n - 1)
                    return root.points[idx] / root.maxVisualizerValue
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    width: parent.width
                    height: Math.max(root.barMinHeight, root.height * smoothedValue)
                    color: root.colorHigh
                    radius: root.barRadius

                    // Gradient-like color shift based on value
                    readonly property color barColor: {
                        if (smoothedValue > 0.8) return root.colorHigh
                        if (smoothedValue > 0.5) return root.colorMed
                        return root.colorLow
                    }
                    color: barColor
                }
            }
        }
    }

    Timer {
        interval: 50
        repeat: true
        running: root.live
        triggerOnStart: true
        onTriggered: {
            var dummy = root.points
        }
    }
}
