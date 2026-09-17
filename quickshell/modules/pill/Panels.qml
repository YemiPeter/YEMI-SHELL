pragma ComponentBehavior: Bound

import QtQuick
import "Singletons"

/**
 * PANELS sub-surface: switches for the pill's overlay panels, styled exactly
 * like the Appearance sub-surface — flat SettingsRows on the surface, no card
 * background. Values persist through Flags (flags.json) so they survive a
 * restart. Reached from the settings index; morphs back on the back chevron.
 */
SettingsSurface {
    id: root

    backSurface: "settings"
    implicitHeight: content.implicitHeight

    rows: [
        { item: altTabRow, kind: "toggle", get: function () { return Flags.altSwitcherEnabled; }, set: function (v) { Flags.altSwitcherEnabled = v; } },
        { item: advanceOnTapRow, kind: "toggle", get: function () { return Flags.altSwitcherAdvanceOnTap; }, set: function (v) { Flags.altSwitcherAdvanceOnTap = v; } }
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
            id: altTabRow
            surface: root
            name: "Overview (Alt+Tab)"
            icon: "app-window"
            last: false

            LinkToggle {
                s: root.s
                on: Flags.altSwitcherEnabled
                onToggled: Flags.altSwitcherEnabled = !Flags.altSwitcherEnabled
            }
        }

        SettingsRow {
            id: advanceOnTapRow
            surface: root
            name: "Advance on tap"
            sub: "Alt+Tab switches windows immediately"
            icon: "arrows-right-left"
            last: true

            LinkToggle {
                s: root.s
                on: Flags.altSwitcherAdvanceOnTap
                onToggled: Flags.altSwitcherAdvanceOnTap = !Flags.altSwitcherAdvanceOnTap
            }
        }
    }
}
