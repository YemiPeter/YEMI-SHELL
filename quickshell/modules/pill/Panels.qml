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
        { item: noVisualUiRow, kind: "toggle", get: function () { return Flags.altSwitcherNoVisualUi; }, set: function (v) { Flags.altSwitcherNoVisualUi = v; } },
        { item: advanceOnTapRow, kind: "toggle", get: function () { return Flags.altSwitcherAdvanceOnTap || Flags.altSwitcherNoVisualUi; }, set: function (v) { if (!Flags.altSwitcherNoVisualUi) Flags.altSwitcherAdvanceOnTap = v; } },
        { item: layoutRow, kind: "seg", vals: ["grid", "list", "compact"],
          get: function () { return Flags.altSwitcherLayout; },
          set: function (v) { Flags.altSwitcherLayout = v; } }
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
            id: noVisualUiRow
            surface: root
            name: "No visual UI"
            sub: "Cycle windows without showing the switcher"
            icon: "visibility-off"
            last: false

            LinkToggle {
                s: root.s
                on: Flags.altSwitcherNoVisualUi
                onToggled: Flags.altSwitcherNoVisualUi = !Flags.altSwitcherNoVisualUi
            }
        }

        SettingsRow {
            id: advanceOnTapRow
            surface: root
            name: "Advance on tap"
            sub: Flags.altSwitcherNoVisualUi ? "Forced on by cycle-only mode" : "Alt+Tab switches windows immediately"
            icon: "arrows-right-left"
            last: false

            LinkToggle {
                s: root.s
                // Cycle-only mode has no UI left to confirm a selection with,
                // so it forces this on and locks the toggle.
                on: Flags.altSwitcherAdvanceOnTap || Flags.altSwitcherNoVisualUi
                onToggled: {
                    if (!Flags.altSwitcherNoVisualUi)
                        Flags.altSwitcherAdvanceOnTap = !Flags.altSwitcherAdvanceOnTap
                }
            }
        }

        SettingsRow {
            id: layoutRow
            surface: root
            name: "Layout"
            sub: "Switcher design"
            icon: "layout-grid"
            last: true

            SettingsSeg {
                s: root.s
                options: [
                    { label: "Grid", value: "grid" },
                    { label: "List", value: "list" },
                    { label: "Icons", value: "compact" }
                ]
                value: Flags.altSwitcherLayout
                onPicked: (v) => Flags.altSwitcherLayout = v
            }
        }
    }
}
