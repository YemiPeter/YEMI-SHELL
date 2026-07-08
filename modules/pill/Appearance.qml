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
 * Color source and system mood are independent switches — changing either
 * rebuilds the rice colour set through wallcolors.py and reloads Hyprland
 * and the terminal.
 */
SettingsSurface {
    id: root

    backSurface: "settings"
    implicitHeight: content.implicitHeight

    function applyMode() {
        if (Flags.paletteMode === "dynamic") {
            dynamicProc.mood = Flags.systemMood;
            dynamicProc.running = true;
        } else {
            staticProc.mood = Flags.systemMood;
            staticProc.running = true;
        }
        systemThemeProc.running = true;
    }
    
    Process {
        id: staticProc
        property string mood: "dark"
        command: ["sh", "-c",
            "python3 \"$HOME/.config/hypr/scripts/wallcolors.py\" --mode static --mood \"$1\" && hyprctl reload >/dev/null 2>&1; busctl --user call com.mitchellh.ghostty /com/mitchellh/ghostty org.gtk.Actions Activate \"sava{sv}\" reload-config 0 0 >/dev/null 2>&1 || true",
            "sh", mood]
    }
    
    Process {
        id: dynamicProc
        property string mood: "dark"
        command: ["sh", "-c",
            "f=\"${XDG_STATE_HOME:-$HOME/.local/state}/yemi-shell-wallpaper\"; pic=$(cat \"$f\" 2>/dev/null); [ -f \"$pic\" ] && python3 \"$HOME/.config/hypr/scripts/wallcolors.py\" --mode dynamic --mood \"$1\" \"$pic\" >/dev/null 2>&1; hyprctl reload >/dev/null 2>&1; busctl --user call com.mitchellh.ghostty /com/mitchellh/ghostty org.gtk.Actions Activate \"sava{sv}\" reload-config 0 0 >/dev/null 2>&1 || true",
            "sh", mood]
    }
    
    Process {
        id: systemThemeProc
        command: ["sh", "-c",
            "\"$HOME/.config/quickshell/scripts/apply-system-theme.sh\" \"$1\"",
            "sh", Flags.systemMood]
    }

    rows: [
        { item: timeRow, kind: "seg", vals: [false, true], get: function () { return Flags.time12h; }, set: function (v) { Flags.time12h = v; } },
        { item: secRow, kind: "toggle", get: function () { return Flags.clockSeconds; }, set: function (v) { Flags.clockSeconds = v; } },
        { item: paletteRow, kind: "seg", vals: ["static", "dynamic"], get: function () { return Flags.paletteMode; }, set: function (v) { Flags.paletteMode = v; root.applyMode(); } },
        { item: moodRow, kind: "seg", vals: ["dark", "light"], get: function () { return Flags.systemMood; }, set: function (v) { Flags.systemMood = v; root.applyMode(); } },
        { item: scaleRow, kind: "seg", vals: [0.9, 1.0, 1.1, 1.25], get: function () { return Flags.uiScale; }, set: function (v) { Flags.uiScale = v; } },
        { item: motionRow, kind: "toggle", get: function () { return Flags.reduceMotion; }, set: function (v) { Flags.reduceMotion = v; } },
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
