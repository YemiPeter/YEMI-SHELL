import QtQuick
import Quickshell.Io
import "Singletons"

/**
 * Audio mixer surface. Shows volume faders for each sink (audio output).
 * STUB: Full Pipewire integration required for real sink enumeration.
 */
PillSurface {
    id: root
    mTop: 15
    mLeft: 17
    mRight: 17
    mBottom: 14

    property int faderCount: 4

    implicitHeight: faderRow.implicitHeight + 24 * s
    implicitWidth: 93 * Math.max(4, faderCount) * s

    readonly property bool hasPipewire: false

    function stepFocused(deltaPct) { return false; }
    function moveFocus(dir) { }
    function focusNext() { }

    Row {
        id: faderRow
        anchors.centerIn: parent
        spacing: 12 * root.s

        Repeater {
            model: root.faderCount

            delegate: VFader {
                width: 40 * root.s
                height: 160 * root.s
                s: root.s
                value: 0.7 - modelData * 0.1
                label: "Ch " + (modelData + 1)
            }
        }
    }
}
