pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property real mult: Flags.reduceMotion ? 0.4 : 1
    readonly property bool reduce: Flags.reduceMotion
    readonly property int fast:     Math.round(140 * mult)
    readonly property int standard: Math.round(300 * mult)
    readonly property int morph:    Math.round(420 * mult)
    readonly property int shapeshift: Math.round(820 * mult)
    readonly property int glide:    Math.round(260 * mult)
    readonly property int heat:     Math.round(1100 * mult)
    readonly property int easeStandard: Easing.OutCubic
    readonly property int easeMorph:    Easing.BezierSpline

    /**
     * Liquid morph curve, cubic-bezier(0.16, 1, 0.3, 1). Front-loaded like an
     * exponential chase but with a long, visible settle tail. Use with
     * easeMorph (BezierSpline).
     */
    readonly property var morphCurve: [0.16, 1, 0.3, 1, 1, 1]

    /**
     * Material 3 expressive "spring" — the tokens caelestia shell
     * (components/Anim.qml and the module Wrapper.qml files) drives its pop-in
     * surfaces with. Unlike morphCurve's soft settle, this curve overshoots
     * past 1.0 before settling, so a scale/position driven by it visibly
     * "springs". Use with easeMorph (BezierSpline).
     */
    readonly property int expressive: Math.round(500 * mult)       // M3 expressive default spatial
    readonly property var springCurve: [0.34, 1.56, 0.64, 1, 1, 1] // M3 cubic-bezier(0.34, 1.56, 0.64, 1)
    readonly property real rSmall: 7
    readonly property real rTile:  13

    /** Looping scan/pairing breath pulse. */
    readonly property int pulse: Math.round(420 * mult)
}
