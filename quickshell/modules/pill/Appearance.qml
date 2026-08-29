pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "Singletons"

/**
 * APPEARANCE sub-surface: the clock format and seconds, the glyph
 * toggle that gates every surface header, the palette mode (static flame or
 * dynamic per-wallpaper), the system mood (dark or light), the UI scale and a
 * reduce-motion switch. Reached from the settings index and morphs back to it
 * on an empty click or the back chevron.
 *
     * Color source and system mood are independent switches. Changing either
     * rebuilds the rice colour set through after-wall.sh (the single writer of
     * colors.json) AND applies the matching host dark/light theme via
     * apply-system-theme.sh (GNOME gsettings color-scheme / KDE colorscheme),
     * so the whole desktop follows the pill's mood.
 */
SettingsSurface {
    id: root

    backSurface: "settings"
    implicitHeight: content.implicitHeight

    /// Single entry point for color generation - routes through after-wall.sh
    /// which is the only script that writes colors.json, and through
    /// apply-system-theme.sh which applies the host GTK/KDE dark/light theme.
    function applyMode(wallPath) {
        var mood = Flags.systemMood;
        colorProc.exec(["sh", "-c",
            'sh "$HOME/.config/quickshell/scripts/after-wall.sh" "' + mood + '" "' + (wallPath || "") + '"']);
        systemThemeProc.exec(["sh", "-c",
            'sh "$HOME/.config/quickshell/scripts/apply-system-theme.sh" "' + mood + '"']);
    }
    
    /// Process that calls after-wall.sh (Phase 0: single writer pattern)
    Process {
        id: colorProc
        onExited: (code) => {
            if (Flags.debug) console.log("[Appearance] Color process exited with code:", code)
        }
    }

    /// Process that applies the host dark/light theme to match the mood
    /// (GNOME color-scheme/gtk-theme via gsettings, KDE via plasma/kvantum).
    Process {
        id: systemThemeProc
        onExited: (code) => {
            if (Flags.debug) console.log("[Appearance] System theme process exited with code:", code)
        }
    }

    rows: [
        { item: timeRow, kind: "seg", vals: [false, true], get: function () { return Flags.time12h; }, set: function (v) { Flags.time12h = v; } },
        { item: secRow, kind: "toggle", get: function () { return Flags.clockSeconds; }, set: function (v) { Flags.clockSeconds = v; } },
        { item: paletteRow, kind: "seg", vals: ["static", "dynamic"], get: function () { return Flags.paletteMode; }, set: function (v) { Flags.paletteMode = v; root.applyMode(); } },
        { item: themeRow, kind: "seg", vals: ["yemi", "aurora"], get: function () { return Flags.themeStyle; }, set: function (v) { Flags.themeStyle = v; } },
        { item: moodRow, kind: "seg", vals: ["dark", "light"], get: function () { return Flags.systemMood; }, set: function (v) { Flags.systemMood = v; root.applyMode(); } },
        { item: scaleRow, kind: "seg", vals: [0.9, 1.0, 1.1, 1.25], get: function () { return Flags.uiScale; }, set: function (v) { Flags.uiScale = v; } },
        { item: motionRow, kind: "toggle", get: function () { return Flags.reduceMotion; }, set: function (v) { Flags.reduceMotion = v; } },
        { item: overviewRow, kind: "toggle", get: function () { return Flags.altSwitcherEnabled; }, set: function (v) { Flags.altSwitcherEnabled = v; } },
        { item: fontRow, kind: "nav", surface: "fontpicker" }
    ]

    Column {
        id: content
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        SettingsHeader {
            s: root.s
            title: "APPEARANCE"
            showBack: true
        }

        Item { width: 1; height: 12 * root.s }

        SettingsRow {
            id: timeRow
            surface: root
            name: "Time format"
            icon: "clock"

            SettingsSeg {
                s: root.s
                options: [{ label: "24H", value: false }, { label: "12H", value: true }]
                value: Flags.time12h
                onPicked: (v) => Flags.time12h = v
            }
        }

        SettingsRow {
            id: secRow
            surface: root
            name: "Clock seconds"
            icon: "stopwatch"

            LinkToggle {
                s: root.s
                on: Flags.clockSeconds
                onToggled: Flags.clockSeconds = !Flags.clockSeconds
            }
        }

        SettingsRow {
            id: paletteRow
            surface: root
            name: "Palette"
            icon: "palette"
        
            SettingsSeg {
                s: root.s
                options: [{ label: "Static", value: "static" }, { label: "Dynamic", value: "dynamic" }]
                value: Flags.paletteMode
                onPicked: (v) => { Flags.paletteMode = v; root.applyMode(); }
            }
        }
        
        SettingsRow {
            id: moodRow
            surface: root
            name: "System mood"
            icon: "sun"
        
            SettingsSeg {
                s: root.s
                options: [{ label: "Dark", value: "dark" }, { label: "Light", value: "light" }]
                value: Flags.systemMood
                onPicked: (v) => { Flags.systemMood = v; root.applyMode(); }
            }
        }

        SettingsRow {
            id: themeRow
            surface: root
            name: "Theme style"
            icon: "blur_on"

            SettingsSeg {
                s: root.s
                options: [{ label: "Yemi", value: "yemi" }, { label: "Aurora", value: "aurora" }]
                value: Flags.themeStyle
                onPicked: (v) => { Flags.themeStyle = v; }
            }
        }

        SettingsRow {
            id: scaleRow
            surface: root
            name: "UI scale"
            icon: "scaling"

            SettingsSeg {
                s: root.s
                options: [{ label: "90%", value: 0.9 }, { label: "100%", value: 1.0 }, { label: "110%", value: 1.1 }, { label: "125%", value: 1.25 }]
                value: Flags.uiScale
                onPicked: (v) => Flags.uiScale = v
            }
        }

        SettingsRow {
            id: motionRow
            surface: root
            name: "Reduce motion"
            icon: "waves"

            LinkToggle {
                s: root.s
                on: Flags.reduceMotion
                onToggled: Flags.reduceMotion = !Flags.reduceMotion
            }
        }

        SettingsRow {
            id: overviewRow
            surface: root
            name: "Overview (Alt+Tab)"
            icon: "view-grid"

            LinkToggle {
                s: root.s
                on: Flags.altSwitcherEnabled
                onToggled: Flags.altSwitcherEnabled = !Flags.altSwitcherEnabled
            }
        }

        SettingsRow {
            id: fontRow
            surface: root
            name: "Font"
            icon: "type"
            sub: Flags.uiFont.length > 0 ? Flags.uiFont : "Inter"
            last: true

            GlyphIcon {
                width: 16 * root.s
                height: 16 * root.s
                name: "chevron-right"
                color: root.focusRowItem === fontRow ? Theme.cream : Theme.iconDim
                stroke: 1.9
            }
        }
    }
}
