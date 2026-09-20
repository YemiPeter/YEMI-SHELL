pragma ComponentBehavior: Bound

import QtQuick
import "Singletons"

/**
 * PANELS index sub-surface: one nav row per overlay-panel group, styled exactly
 * like the Appearance sub-surface — flat SettingsRows on the surface, no card
 * background. Each row morphs the pill into that group's own card (Alt Tab is
 * AltTab.qml, Master Audio is MasterAudio.qml), the same way Appearance's "Bar"
 * row opens BarPills. Reached from the settings index; morphs back on the back
 * chevron.
 */
SettingsSurface {
    id: root

    backSurface: "settings"
    implicitHeight: content.implicitHeight

    rows: [
        { item: altTabNavRow, kind: "nav", surface: "alttab" },
        { item: masterAudioNavRow, kind: "nav", surface: "masteraudio" }
    ]

    Column {
        id: content
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        SettingsHeader {
            s: root.s
            title: "PANELS"
            showBack: true
        }

        Item { width: 1; height: 12 * root.s }

        SettingsRow {
            id: altTabNavRow
            surface: root
            name: "Alt Tab"
            sub: "Switcher behaviour & layout"
            icon: "app-window"
            last: false

            GlyphIcon {
                width: 16 * root.s
                height: 16 * root.s
                name: "chevron-right"
                color: root.focusRowItem === altTabNavRow ? Theme.cream : Theme.iconDim
                stroke: 1.9
            }
        }

        SettingsRow {
            id: masterAudioNavRow
            surface: root
            name: "Master Audio"
            sub: "Output device, safeguard & Bluetooth auto-switch"
            icon: "speaker"
            last: true

            GlyphIcon {
                width: 16 * root.s
                height: 16 * root.s
                name: "chevron-right"
                color: root.focusRowItem === masterAudioNavRow ? Theme.cream : Theme.iconDim
                stroke: 1.9
            }
        }
    }
}

