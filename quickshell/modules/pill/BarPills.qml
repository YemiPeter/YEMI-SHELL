pragma ComponentBehavior: Bound

import QtQuick
import "Singletons"

/**
 * BAR sub-surface: per-element visibility toggles for the floating bar strip —
 * the left (workspaces) pill, the right (status) pills, both at once, the
 * dock-style running-app strip, and the floating drop shadow. Reached from
 * Appearance via the "Bar" nav row and morphs back to it on the back chevron or
 * an empty click.
 */
SettingsSurface {
    id: root

    backSurface: "appearance"
    implicitHeight: content.implicitHeight
    rows: [
        { item: leftRow, kind: "toggle", get: function () { return Flags.barLeftVisible; }, set: function (v) { Flags.barLeftVisible = v; } },
        { item: rightRow, kind: "toggle", get: function () { return Flags.barRightVisible; }, set: function (v) { Flags.barRightVisible = v; } },
        { item: sidesRow, kind: "toggle", get: function () { return Flags.barLeftVisible || Flags.barRightVisible; }, set: function (v) { Flags.barLeftVisible = v; Flags.barRightVisible = v; } },
        { item: appsRow, kind: "toggle", get: function () { return Flags.barAppIcons; }, set: function (v) { Flags.barAppIcons = v; } },
        { item: shadowRow, kind: "toggle", get: function () { return Flags.barShadow; }, set: function (v) { Flags.barShadow = v; } }
    ]

    Column {
        id: content
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        SettingsHeader {
            s: root.s
            title: "BAR"
            showBack: true
        }

        Item { width: 1; height: 12 * root.s }

        SettingsRow {
            id: leftRow
            surface: root
            icon: "monitor"
            name: "Left pill"
            sub: "Workspaces pill"

            LinkToggle {
                s: root.s
                on: Flags.barLeftVisible
                onToggled: Flags.barLeftVisible = !Flags.barLeftVisible
            }
        }

        SettingsRow {
            id: rightRow
            surface: root
            icon: "cog"
            name: "Right pill"
            sub: "Status pills (volume, network, battery)"

            LinkToggle {
                s: root.s
                on: Flags.barRightVisible
                onToggled: Flags.barRightVisible = !Flags.barRightVisible
            }
        }

        // Master toggle: hides/shows BOTH side pills at once. On when either
        // side is visible; toggling flips both together.
        SettingsRow {
            id: sidesRow
            surface: root
            icon: "check"
            name: "Sides"
            sub: "Hide/show both side pills at once"

            LinkToggle {
                s: root.s
                on: Flags.barLeftVisible || Flags.barRightVisible
                onToggled: {
                    var show = !(Flags.barLeftVisible || Flags.barRightVisible);
                    Flags.barLeftVisible = show;
                    Flags.barRightVisible = show;
                }
            }
        }

        SettingsRow {
            id: appsRow
            surface: root
            icon: "app-window"
            name: "App icons"
            sub: "Dock-style running-app strip"

            LinkToggle {
                s: root.s
                on: Flags.barAppIcons
                onToggled: Flags.barAppIcons = !Flags.barAppIcons
            }
        }

        SettingsRow {
            id: shadowRow
            surface: root
            last: true
            icon: "cloud"
            name: "Floating shadow"
            sub: "Drop shadows behind pills & icons"

            LinkToggle {
                s: root.s
                on: Flags.barShadow
                onToggled: Flags.barShadow = !Flags.barShadow
            }
        }
    }
}