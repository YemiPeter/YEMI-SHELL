pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.compositor
import "lib/setDeco.js" as SetDeco
import "Singletons"

/**
 * ALT TAB sub-surface: behaviour and layout controls for the window switcher,
 * styled exactly like the Bar sub-surface — flat SettingsRows on the surface,
 * no card background. Values persist through Flags (flags.json) so they survive
 * a restart. Reached from the Panels index via the "Alt Tab" nav row and morphs
 * back to it on the back chevron.
 *
 * "Advance on tap" is force-locked ON while "No visual UI" is active: cycle-only
 * mode never shows a UI, so there is nothing left to confirm a selection with.
 *
 * "Card opacity" is deliberately not its own blur switch — the switcher card's
 * frost belongs to the general blur toggle in Look (decoration.lua
 * blur.enabled). This row therefore says what the card will actually do: while
 * that toggle is off the card renders solid, so the opacity only bites when the
 * general blur is on. "Alignment" is a list-layout-only control: grid and icons
 * are centred by definition, so the row appears only while Layout is "List".
 */
SettingsSurface {
    id: root

    backSurface: "panels"
    implicitHeight: content.implicitHeight

    readonly property bool listLayout: Flags.altSwitcherLayout === "list"

    /**
     * Mirrors the general blur toggle owned by the Look surface, so the opacity
     * row can describe the card's real behaviour instead of promising frost the
     * compositor will not deliver. A live binding over a watched FileView, with
     * watchChanges set explicitly (it defaults to false), so Look's write to
     * decoration.lua keeps the label honest without a restart.
     */
    readonly property string decoPath: Quickshell.env("RICE_HOME") + "/hypr/modules/decoration.lua"
    FileView {
        id: decoFile
        path: root.decoPath
        blockLoading: true
        watchChanges: true
        printErrors: false
    }
    readonly property bool blurOff: Compositor.isHyprland
        && SetDeco.getBlockField(decoFile.text(), "blur", "enabled") === "false"

    rows: [
        { item: altTabRow, kind: "toggle", get: function () { return Flags.altSwitcherEnabled; }, set: function (v) { Flags.altSwitcherEnabled = v; } },
        { item: noVisualUiRow, kind: "toggle", get: function () { return Flags.altSwitcherNoVisualUi; }, set: function (v) { Flags.altSwitcherNoVisualUi = v; } },
        { item: advanceOnTapRow, kind: "toggle", get: function () { return Flags.altSwitcherAdvanceOnTap || Flags.altSwitcherNoVisualUi; }, set: function (v) { if (!Flags.altSwitcherNoVisualUi) Flags.altSwitcherAdvanceOnTap = v; } },
        { item: layoutRow, kind: "seg", vals: ["grid", "list", "compact"],
          get: function () { return Flags.altSwitcherLayout; },
          set: function (v) { Flags.altSwitcherLayout = v; } },
        { item: opacityRow, kind: "seg", vals: [0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0],
          get: function () { return Math.round(Flags.altSwitcherBackgroundOpacity * 10) / 10; },
          set: function (v) { Flags.altSwitcherBackgroundOpacity = v; } },
        // Alignment only exists for the list layout, so it only joins the
        // keyboard registry while that layout is picked — a hidden row must
        // never swallow an arrow key.
        ...(listLayout ? [{ item: alignRow, kind: "seg", vals: ["center", "right"],
              get: function () { return Flags.altSwitcherPanelAlignment; },
              set: function (v) { Flags.altSwitcherPanelAlignment = v; } }] : [])
    ]

    /**
     * Mirrors Background's inline stepper: the −/+ pair plus the value readout,
     * for the controls that step through a range instead of picking a mode.
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

    Column {
        id: content
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        SettingsHeader {
            s: root.s
            title: "ALT TAB"
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
            last: false

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

        // List-only: the grid and icon layouts are centred by definition, so the
        // row stays out of the way (and out of the keyboard registry) unless the
        // list card can actually be moved.
        SettingsRow {
            id: alignRow
            surface: root
            visible: root.listLayout
            name: "Alignment"
            sub: "Where the list card sits on screen"
            icon: "align-cards"
            last: false

            SettingsSeg {
                s: root.s
                options: [
                    { label: "Center", value: "center" },
                    { label: "Right", value: "right" }
                ]
                value: Flags.altSwitcherPanelAlignment
                onPicked: (v) => Flags.altSwitcherPanelAlignment = v
            }
        }

        SettingsRow {
            id: opacityRow
            surface: root
            name: "Card opacity"
            sub: root.blurOff ? "Held solid — general blur is off in Look" : "Card frost strength"
            icon: "opacity"
            last: true

            Stepper {
                display: Math.round(Flags.altSwitcherBackgroundOpacity * 100) + "%"
                onStepped: (dir) => {
                    var next = Math.max(0.4, Math.min(1.0, Math.round(Flags.altSwitcherBackgroundOpacity * 10 + dir) / 10));
                    if (Math.abs(next - Flags.altSwitcherBackgroundOpacity) < 0.001)
                        return;
                    Flags.altSwitcherBackgroundOpacity = next;
                }
            }
        }
    }
}
