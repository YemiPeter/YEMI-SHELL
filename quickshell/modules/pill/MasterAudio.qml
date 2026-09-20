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
 *  1. Pick the output. A dropdown (the same DisplayPicker the Display and
 *     Input surfaces use) lists every sink PipeWire knows, but the service
 *     also switches on its own: the moment a Bluetooth
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
    property bool deviceOpen: false

    /// The dropdown's options: every sink PipeWire knows, labelled with the
    /// same friendly names the service uses elsewhere.
    readonly property var deviceOptions: root.outputDevices.map(function (d) {
        return { label: root.audio.friendlyDeviceName(d), value: Number(d.id) }
    })

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
    function pickDevice(id) {
        for (var i = 0; i < root.outputDevices.length; i++) {
            if (Number(root.outputDevices[i].id) === Number(id)) {
                root.audio.setDefaultSink(root.outputDevices[i])
                return
            }
        }
    }
    rows: [
        { item: deviceRow, kind: "act",
          act: function () { root.deviceOpen = !root.deviceOpen; } },
        { item: safeguardRow, kind: "toggle",
          get: function () { return Flags.audioSafeguard; },
          set: function (v) { Flags.audioSafeguard = v; } },
        // Safe max only exists while the safeguard is armed: keep it out of the
        // registry when it is hidden so it cannot consume an arrow key.
        ...(safeguard ? [{ item: safeMaxRow, kind: "seg", vals: [1.0, 1.1, 1.25, 1.5],
              get: function () { return Flags.audioSafeMax; },
              set: function (v) { Flags.audioSafeMax = v; } }] : [])
    ]
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
            sub: root.outputDevices.length + " available · Bluetooth auto-switch on"
            icon: "monitor"
            last: false

            GlyphIcon {
                anchors.verticalCenter: parent.verticalCenter
                width: 14 * root.s
                height: 14 * root.s
                name: root.deviceOpen ? "chevron-up" : "chevron-down"
                color: Theme.iconDim
                stroke: 2
            }
        }

        DisplayPicker {
            width: parent.width
            s: root.s
            label: "Speakers"
            options: root.deviceOptions
            value: Number(root.sink?.id ?? -1)
            open: root.deviceOpen
            onRequestToggle: root.deviceOpen = !root.deviceOpen
            onPicked: (v) => {
                root.pickDevice(v);
                root.deviceOpen = false;
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
