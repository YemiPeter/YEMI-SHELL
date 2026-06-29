import QtQuick
import "Singletons"

/**
 * Battery surface for the pill. Shows charge percentage, state, and time
 * remaining. Gated by Battery.present so desktops without a battery hide
 * cleanly.
 */
PillSurface {
    id: root
    mTop: 15
    mLeft: 17
    mRight: 17
    mBottom: 14

    readonly property real pct: Battery.pct
    readonly property bool charging: Battery.charging
    readonly property bool full: Battery.full
    readonly property bool low: Battery.low
    readonly property string timeStr: Battery.timeStr
    readonly property string stateLabel: Battery.stateLabel

    implicitHeight: col.implicitHeight + 24 * s
    implicitWidth: 316 * s

    Component.onCompleted: {
        console.log("[BATTERY] onCompleted: implicitWidth:", implicitWidth, "implicitHeight:", implicitHeight, "s:", s);
    }
    onImplicitHeightChanged: console.log("[BATTERY] implicitHeight changed:", implicitHeight, "s:", s)
    onImplicitWidthChanged: console.log("[BATTERY] implicitWidth changed:", implicitWidth, "s:", s)

    Column {
        id: col
        anchors.centerIn: parent
        spacing: 8 * root.s

        Text {
            text: Battery.pct + "%"
            color: root.low ? Theme.vermLit : (root.charging ? Theme.flameGlow : Theme.cream)
            font.family: Theme.font
            font.pixelSize: 28 * root.s
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }

        Text {
            text: root.stateLabel
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 11 * root.s
        }

        Text {
            visible: root.timeStr.length > 0
            text: root.timeStr
            color: Theme.subtle
            font.family: Theme.font
            font.pixelSize: 10 * root.s
        }
    }
}
