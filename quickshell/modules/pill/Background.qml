pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "Singletons"

/**
 * BACKGROUND sub-surface: tunes the wallpaper backdrop that QuickShell draws on
 * its WlrLayer.Background window (see modules/background/Backdrop.qml). The
 * values persist through Flags (flags.json) so they survive a restart and are
 * shared across every surface. Reached from the settings index; morphs back on
 * the back chevron.
 */
SettingsSurface {
    id: root

    backSurface: "settings"
    implicitHeight: content.implicitHeight
    rows: []

    component Stepper: Row {
        id: step

        property real value: 0
        property string display: ""
        signal stepped(int dir)

        spacing: 6 * root.s

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 26 * root.s
            height: 26 * root.s
            radius: Motion.rSmall * root.s
            color: minusArea.containsMouse ? Theme.frameBg : Theme.tileBg
            border.width: 1
            border.color: Theme.border
            Behavior on color { ColorAnimation { duration: Motion.fast } }

            Text {
                anchors.centerIn: parent
                text: "−"
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 14 * root.s
                font.weight: Font.Bold
            }

            MouseArea {
                id: minusArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: step.stepped(-1)
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: 44 * root.s
            horizontalAlignment: Text.AlignHCenter
            text: step.display
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 12 * root.s
            font.weight: Font.DemiBold
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 26 * root.s
            height: 26 * root.s
            radius: Motion.rSmall * root.s
            color: plusArea.containsMouse ? Theme.frameBg : Theme.tileBg
            border.width: 1
            border.color: Theme.border
            Behavior on color { ColorAnimation { duration: Motion.fast } }

            Text {
                anchors.centerIn: parent
                text: "+"
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 14 * root.s
                font.weight: Font.Bold
            }

            MouseArea {
                id: plusArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: step.stepped(1)
            }
        }
    }

    component GroupLabel: Text {
        topPadding: 16 * root.s
        bottomPadding: 6 * root.s
        color: Theme.faint
        font.family: Theme.font
        font.pixelSize: 8.5 * root.s
        font.weight: Font.Bold
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1.2 * root.s
    }

    component FieldRow: Item {
        id: frow
        property string label: ""
        property string caption: ""
        default property alias control: ctrl.data

        width: parent ? parent.width : 0
        height: 34 * root.s

        Column {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1 * root.s

            Text {
                text: frow.label
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 12.5 * root.s
                font.weight: Font.Medium
            }

            Text {
                visible: frow.caption.length > 0
                text: frow.caption
                color: Theme.faint
                font.family: Theme.font
                font.pixelSize: 9 * root.s
                font.weight: Font.Medium
            }
        }

        Item {
            id: ctrl
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: childrenRect.width
            height: childrenRect.height
        }
    }

    Column {
        id: content
        z: 100
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0
        height: root.height + root.mBottom * root.s
        clip: true

        SettingsHeader {
            s: root.s
            title: "BACKGROUND"
            showBack: true
        }

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12 * root.s
            anchors.rightMargin: 12 * root.s
            spacing: 0

            GroupLabel { text: "Backdrop" }

            FieldRow {
                label: "Effects"
                caption: "Dim and vignette behind the UI"
                LinkToggle {
                    s: root.s
                    on: Flags.backdropEffects
                    onToggled: Flags.backdropEffects = !Flags.backdropEffects
                }
            }

            FieldRow {
                label: "Dim"
                caption: "How much the wallpaper darkens"
                visible: Flags.backdropEffects
                height: Flags.backdropEffects ? 34 * root.s : 0
                Stepper {
                    value: Flags.backdropDim
                    display: (Flags.backdropDim * 100).toFixed(0) + "%"
                    onStepped: (dir) => {
                        var next = Math.max(0, Math.min(1, Math.round((Flags.backdropDim + dir * 0.05) * 100) / 100));
                        if (next === Flags.backdropDim)
                            return;
                        Flags.backdropDim = next;
                    }
                }
            }

            FieldRow {
                label: "Vignette"
                caption: "Darken the screen edges"
                visible: Flags.backdropEffects
                height: Flags.backdropEffects ? 34 * root.s : 0
                Stepper {
                    value: Flags.backdropVignette
                    display: (Flags.backdropVignette * 100).toFixed(0) + "%"
                    onStepped: (dir) => {
                        var next = Math.max(0, Math.min(1, Math.round((Flags.backdropVignette + dir * 0.05) * 100) / 100));
                        if (next === Flags.backdropVignette)
                            return;
                        Flags.backdropVignette = next;
                    }
                }
            }

            Item { width: 1; height: 10 * root.s }
        }
    }
}
