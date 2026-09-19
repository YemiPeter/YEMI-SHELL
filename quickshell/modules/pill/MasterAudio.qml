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
 * Three jobs, in the order the user meets them:
 *
 *  1. Drive the master sink — volume, mute and which output device is default.
 *     Every write goes through `Audio.setVolume`/`Audio.stepVolume`, so the
 *     service's ramp and clamp apply and the mixer fader, bar popup, OSD and
 *     keybinds all land on the same value.
 *
 *  2. Own the safeguard. `Audio` no longer hardcodes its ceiling: the flags set
 *     here (`audioSafeguard`, `audioSafeMax`) are what `Audio.effectiveMax`
 *     reads, so "Volume safeguard" OFF means the unguarded behaviour (up to the
 *     200% hard ceiling) and ON means every writer stops at the chosen safe max.
 *     "Safe max volume" only exists while the safeguard is armed, so it joins the
 *     keyboard registry only then — a hidden row must never swallow an arrow key
 *     (same rule as AltTab's Alignment row).
 *
 *  3. Show what is actually playing. PipeWire happily lets two streams from one
 *     source stack on the same sink, which is the classic "why is this so loud,
 *     and why didn't it stop" trap: the list below makes both visible, and the
 *     duplicate row reports "2 × Firefox" with a one-click older-stream mute.
 *     "Mute duplicate streams" arms that same action as an automatic guard.
 *
 * Stream rows are mouse-driven by design: their model is live PipeWire state, so
 * they stay out of the static keyboard registry the fixed rows use.
 */
SettingsSurface {
    id: root

    backSurface: "panels"
    implicitHeight: content.implicitHeight

    readonly property var audio: QsServices.Audio
    readonly property var sink: root.audio ? root.audio.sink : null
    readonly property bool safeguard: Flags.audioSafeguard
    readonly property var streams: root.audio ? root.audio.activeStreams : []
    readonly property var dupGroups: root.audio ? root.audio.duplicateGroups : []
    readonly property var outputDevices: root.audio ? root.audio.outputDevices : []

    readonly property int masterPct: root.sink?.audio ? Math.round(root.sink.audio.volume * 100) : 0
    readonly property bool masterMuted: root.sink?.audio ? root.sink.audio.muted : false

    /// Transient feedback for the duplicate action (cleared by `actionClear`).
    property string lastAction: ""
    Timer {
        id: actionClear
        interval: 2600
        onTriggered: root.lastAction = ""
    }

    /// 2.5% rungs, so arrow keys and a row click step the master volume in the
    /// same fine increments, from silence to the 200% hard ceiling.
    readonly property var volumeVals: {
        var out = []
        for (var i = 0; i <= 80; i++)
            out.push(i / 40)
        return out
    }
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
    function duplicateSummary() {
        var parts = []
        for (var i = 0; i < root.dupGroups.length; i++)
            parts.push(root.dupGroups[i].nodes.length + " × " + root.dupGroups[i].key)
        return parts.join(" · ")
    }
    function muteOlder() {
        var muted = root.audio.muteOlderDuplicates()
        root.lastAction = muted > 0
            ? ("Muted " + muted + " older stream" + (muted === 1 ? "" : "s"))
            : "Nothing left to mute"
        actionClear.restart()
    }
    rows: [
        { item: volumeRow, kind: "seg", vals: volumeVals,
          get: function () { return Math.round((root.sink?.audio?.volume ?? 0) * 40) / 40; },
          set: function (v) { root.audio.setVolume(v); } },
        { item: muteRow, kind: "toggle",
          get: function () { return root.masterMuted; },
          set: function (v) { if (root.sink?.audio) root.sink.audio.muted = v; } },
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
              set: function (v) { Flags.audioSafeMax = v; } }] : []),
        { item: autoDupRow, kind: "toggle",
          get: function () { return Flags.audioAutoMuteDuplicates; },
          set: function (v) { Flags.audioAutoMuteDuplicates = v; } },
        // The duplicate action only exists while duplicates do.
        ...(dupGroups.length > 0 ? [{ item: dupRow, kind: "act",
              act: function () { root.muteOlder(); } }] : [])
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
    component MiniButton: Rectangle {
        id: mbtn

        property string label: ""
        signal clicked()

        implicitWidth: mbtnLabel.implicitWidth + 22 * root.s
        implicitHeight: 26 * root.s
        radius: 8 * root.s
        color: mbtnArea.containsMouse ? Theme.frameBg : Theme.tileBg
        border.width: 1
        border.color: Theme.border
        Behavior on color { ColorAnimation { duration: Motion.fast } }

        Text {
            id: mbtnLabel
            anchors.centerIn: parent
            text: mbtn.label
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 10.5 * root.s
            font.weight: Font.Bold
        }

        MouseArea {
            id: mbtnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mbtn.clicked()
        }
    }


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
            id: volumeRow
            surface: root
            name: "Master volume"
            sub: root.masterMuted ? "Muted" : "Output level"
            icon: root.masterMuted ? "speaker-off" : "speaker"
            last: false

            Stepper {
                display: root.masterPct + "%"
                onStepped: (dir) => root.audio.stepVolume(dir * 5)
            }
        }

        SettingsRow {
            id: muteRow
            surface: root
            name: "Mute output"
            sub: root.masterMuted ? "Silenced" : "Sound is on"
            icon: "speaker-off"
            last: false

            LinkToggle {
                s: root.s
                on: root.masterMuted
                onToggled: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
            }
        }

        SettingsRow {
            id: deviceRow
            surface: root
            name: "Output device"
            sub: root.currentDeviceLabel()
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
            last: false

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

        SettingsRow {
            id: autoDupRow
            surface: root
            name: "Mute duplicate streams"
            sub: Flags.audioAutoMuteDuplicates
                ? "Older copies are silenced automatically"
                : "Same source playing twice stays as it is"
            icon: "arrows-right-left"
            last: root.streams.length === 0 && root.dupGroups.length === 0

            LinkToggle {
                s: root.s
                on: Flags.audioAutoMuteDuplicates
                onToggled: Flags.audioAutoMuteDuplicates = !Flags.audioAutoMuteDuplicates
            }
        }

        SettingsRow {
            id: dupRow
            surface: root
            visible: root.dupGroups.length > 0
            name: "Duplicate audio"
            sub: root.lastAction.length > 0 ? root.lastAction : root.duplicateSummary()
            icon: "close"
            last: root.streams.length === 0

            MiniButton {
                label: "Mute older"
                onClicked: root.muteOlder()
            }
        }
        Text {
            width: parent.width
            topPadding: 16 * root.s
            bottomPadding: 8 * root.s
            leftPadding: 14 * root.s
            visible: root.streams.length > 0
            text: "NOW PLAYING"
            color: Theme.faint
            font.family: Theme.font
            font.pixelSize: 9.5 * root.s
            font.weight: Font.DemiBold
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 1.3 * root.s
        }

        Repeater {
            model: root.streams

            SettingsRow {
                required property var modelData
                required property int index

                surface: root
                name: root.audio.streamLabel(modelData)
                sub: (modelData.audio && modelData.audio.muted) ? "Muted" : "Playing"
                icon: (modelData.audio && modelData.audio.muted) ? "speaker-off" : "speaker"
                last: index === root.streams.length - 1

                Row {
                    spacing: 8 * root.s

                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 116 * root.s
                        height: 16 * root.s

                        HFader {
                            anchors.fill: parent
                            s: root.s
                            // Streams read 0–100% here; the sink cap is the real
                            // guard, per-stream boost is deliberately not offered.
                            value: Math.min(1, modelData.audio ? modelData.audio.volume : 0)
                            on: !(modelData.audio && modelData.audio.muted)
                            onMoved: (v) => { if (modelData.audio) modelData.audio.volume = v }
                            onCommitted: (v) => root.audio.setStreamVolume(modelData, v)
                        }
                    }

                    LinkToggle {
                        anchors.verticalCenter: parent.verticalCenter
                        s: root.s
                        on: modelData.audio ? modelData.audio.muted : false
                        onToggled: root.audio.toggleStreamMute(modelData)
                    }
                }
            }
        }

        // Nothing is feeding the sink: say so instead of showing an empty gap.
        SettingsRow {
            id: idleRow
            surface: root
            visible: root.streams.length === 0
            name: "Nothing playing"
            sub: "No app is streaming to the output right now"
            icon: "music"
            last: true

            Item { width: 1; height: 1 }
        }
    }
}

