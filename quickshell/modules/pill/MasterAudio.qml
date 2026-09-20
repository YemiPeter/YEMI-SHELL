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
 *  1. Pick the output. The "Output device" row is itself the dropdown: one
 *     click grows the speaker list straight out of the row — every sink
 *     PipeWire knows, no separate chip or divider underneath. The service
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
            sub: root.currentDeviceLabel() + "  ·  Bluetooth auto-switch on"
            icon: "monitor"
            last: false
            // The speaker list below is part of this row, not a separate
            // section: no hairline between them while it is expanded.
            showHairline: !root.deviceOpen

            GlyphIcon {
                anchors.verticalCenter: parent.verticalCenter
                width: 14 * root.s
                height: 14 * root.s
                name: root.deviceOpen ? "chevron-up" : "chevron-down"
                color: Theme.iconDim
                stroke: 2
            }
        }

        // The speaker list grows straight out of the row above: one click on
        // "Output device" reveals every sink, no separate chip and no extra
        // divider between the row and its options — they are the same control.
        // Closed, the panel takes no space, so the column has no gap.
        Rectangle {
            width: parent.width
            visible: root.deviceOpen
            height: root.deviceOpen
                ? Math.min(root.deviceOptions.length, 5) * 26 * root.s + 8 * root.s
                : 0
            radius: 9 * root.s
            color: Theme.cardBot
            border.width: 1
            border.color: Theme.hairSoft
            clip: true

            ListView {
                anchors.fill: parent
                anchors.margins: 4 * root.s
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.deviceOptions

                delegate: Rectangle {
                    id: devOpt
                    required property var modelData
                    readonly property bool current: Number(root.sink?.id ?? -1) === modelData.value

                    width: ListView.view.width
                    height: 26 * root.s
                    radius: 7 * root.s
                    color: devHover.hovered ? Theme.frameBg
                        : (devOpt.current ? Qt.alpha(Theme.vermLit, 0.14) : "transparent")

                    HoverHandler { id: devHover }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 9 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 18 * root.s
                        text: devOpt.modelData.label
                        color: devOpt.current ? Theme.vermLit : Theme.subtle
                        font.family: Theme.font
                        font.pixelSize: 11 * root.s
                        font.weight: devOpt.current ? Font.Bold : Font.Medium
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.pickDevice(devOpt.modelData.value)
                            root.deviceOpen = false
                        }
                    }
                }
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
