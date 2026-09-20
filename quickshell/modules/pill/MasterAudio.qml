pragma ComponentBehavior: Bound

import QtQuick
import "Singletons"
import qs.services as QsServices

/**
 * MASTER AUDIO sub-surface: the pill's audio control room, reached from the
 * Panels index via the "Master Audio" nav row (sibling of the Alt Tab card).
 * Flat SettingsRows on the surface, no card background — the same idiom as
 * BarPills and AltTab, so the morph and the soul seam behave identically.
 *
 * Two jobs:
 *
 *  1. Pick the output. The stepper flips between every sink PipeWire knows,
 *     but the service also switches on its own: the moment a Bluetooth
 *     speaker connects it becomes the default output, and when it drops out
 *     the previous device is restored (see Audio.qml — no toggle, it just
 *     works, so there is no reason to visit KDE's audio settings).
 *
 *  2. Own the safeguard. `Audio` no longer hardcodes its ceiling: the flags
 *     set here (`audioSafeguard`, `audioSafeMax`) are what `Audio.effectiveMax`
 *     reads, so "Volume safeguard" OFF means the unguarded behaviour (up to
 *     the 200% hard ceiling) and ON means every writer stops at the chosen
 *     safe max. "Safe max volume" only exists while the safeguard is armed,
 *     so it joins the keyboard registry only then — a hidden row must never
 *     swallow an arrow key (same rule as AltTab's Alignment row).
 *
 * Master volume and mute are deliberately NOT here: the pill and the mixer
 * already own them. The duplicate-stream guard (a new stream from the same
 * source mutes the older one until the newcomer stops) is unconditional
 * service behaviour — there is nothing to toggle and nothing to watch.
 */
SettingsSurface {
    id: root

    backSurface: "panels"
    implicitHeight: content.implicitHeight

    readonly property var audio: QsServices.Audio
    readonly property var sink: root.audio ? root.audio.sink : null
    readonly property bool safeguard: Flags.audioSafeguard
    readonly property var outputDevices: root.audio ? root.audio.outputDevices : []

    readonly property var deviceIds: root.outputDevices.map(function (d) { return Number(d.id) })

    function currentDeviceIndex() {
        for (var i = 0; i < root.outputDevices.length; i++)
            if (Number(root.outputDevices[i].id) === Number(root.sink?.id ?? -1))
                return i
        return 0
    }
    function currentDeviceLabel() {
        if (root.outputDevices.length === 0)
            return "No device"
        return root.audio.friendlyDeviceName(root.outputDevices[root.currentDeviceIndex()])
    }
    function stepDevice(dir) {
        if (root.outputDevices.length < 2)
            return
        var next = root.currentDeviceIndex() + dir
        if (next < 0 || next >= root.outputDevices.length)
            return
        root.audio.setDefaultSink(root.outputDevices[next])
    }
    function pickDevice(id) {
        for (var i = 0; i < root.outputDevices.length; i++) {
            if (Number(root.outputDevices[i].id) === Number(id)) {
                root.audio.setDefaultSink(root.outputDevices[i])
                return
            }
        }
    }
    rows: [
        { item: deviceRow, kind: "seg", vals: deviceIds,
          get: function () { return root.deviceIds[root.currentDeviceIndex()] ?? -1; },
          set: function (v) { root.pickDevice(v); } },
        { item: safeguardRow, kind: "toggle",
          get: function () { return Flags.audioSafeguard; },
          set: function (v) { Flags.audioSafeguard = v; } },
        // Safe max only exists while the safeguard is armed: keep it out of the
        // registry when it is hidden so it cannot consume an arrow key.
        ...(safeguard ? [{ item: safeMaxRow, kind: "seg", vals: [1.0, 1.1, 1.25, 1.5],
              get: function () { return Flags.audioSafeMax; },
              set: function (v) { Flags.audioSafeMax = v; } }] : [])
    ]
    /**
     * Inline stepper, modelled on the AltTab card's so the two Panels children
     * read as one family: −/value/+ for the controls that step a range.
     */
    component Stepper: Row {
        id: step

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
            width: 62 * root.s
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
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

    /// Small pill button for row-level actions (the duplicate mute).
Column {
        id: content
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        SettingsHeader {
            s: root.s
            title: "AUDIO"
            showBack: true
        }

        Item { width: 1; height: 12 * root.s }

        SettingsRow {
            id: deviceRow
            surface: root
            name: "Output device"
            sub: root.currentDeviceLabel() + "  ·  Bluetooth auto-switch on"
            icon: "monitor"
            last: false

            Stepper {
                display: root.currentDeviceLabel()
                onStepped: (dir) => root.stepDevice(dir)
            }
        }

        SettingsRow {
            id: safeguardRow
            surface: root
            name: "Volume safeguard"
            sub: Flags.audioSafeguard
                ? ("Caps every control at " + Math.round(Flags.audioSafeMax * 100) + "%")
                : "Off — controls may reach 200%"
            icon: "bolt"
            last: false

            LinkToggle {
                s: root.s
                on: Flags.audioSafeguard
                onToggled: Flags.audioSafeguard = !Flags.audioSafeguard
            }
        }

        SettingsRow {
            id: safeMaxRow
            surface: root
            visible: root.safeguard
            name: "Safe max volume"
            sub: "Loudest the master may go with the safeguard on"
            icon: "scaling"
            last: true

            SettingsSeg {
                s: root.s
                options: [
                    { label: "100", value: 1.0 },
                    { label: "110", value: 1.1 },
                    { label: "125", value: 1.25 },
                    { label: "150", value: 1.5 }
                ]
                value: Flags.audioSafeMax
                onPicked: (v) => Flags.audioSafeMax = v
            }
        }

    }
}
