pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.compositor
import "lib/setInput.js" as SetInput
import "lib/setInputNiri.js" as SetNiri
import "Singletons"

/**
 * INPUT sub-surface: edits the pointer and cursor settings that live in the
 * Hyprland Lua modules or the Niri KDL config, writing each change straight
 * back to its source so the choice survives a restart.
 *
 * HYPRLAND:
 *   Pointer fields rewrite input.lua and reload Hyprland; sensitivity steps
 *   through a small −/value/+ control while the accel profile uses the shared
 *   segmented control. Cursor size and theme apply live through `hyprctl
 *   setcursor` with no reload, and persist by rewriting the XCURSOR/HYPRCURSOR
 *   env lines and the autostart setcursor call.
 *
 * NIRI:
 *   Pointer and cursor fields are rewritten directly into
 *   config.d/10-input-and-cursor.kdl. Niri auto-reloads the config on save so
 *   no extra reload command is needed. The theme list is scanned from the
 *   installed icon themes that carry a `cursors/` folder.
 *
 * Reached from the settings index; morphs back on the back chevron.
 */
SettingsSurface {
    id: root

    backSurface: "settings"
    implicitHeight: content.implicitHeight
    rows: []

    // ── Hyprland paths ──────────────────────────────────────────────────
    readonly property string inputPath: Quickshell.env("RICE_HOME") + "/hypr/modules/input.lua"
    readonly property string envPath: Quickshell.env("RICE_HOME") + "/hypr/modules/env.lua"
    readonly property string autostartPath: Quickshell.env("RICE_HOME") + "/hypr/modules/autostart.lua"

    // ── Niri paths ──────────────────────────────────────────────────────
    readonly property string niriInputPath: Quickshell.env("RICE_HOME") + "/niri/config.d/10-input-and-cursor.kdl"

    property real sensitivity: 0
    property string accelProfile: "flat"
    property int cursorSize: 24
    property string cursorTheme: "Bibata-Modern-Ice"
    property var cursorThemes: []
    property bool themeOpen: false

    property string inputText: ""
    property string envText: ""
    property string autostartText: ""
    property string niriInputText: ""

    readonly property var accelOptions: [
        { label: "Flat", value: "flat" },
        { label: "Adaptive", value: "adaptive" }
    ]

    onActiveChanged: {
        if (active) {
            if (Compositor.isHyprland) {
                inputFile.reload();
                envFile.reload();
                autostartFile.reload();
                seed();
            } else if (Compositor.isNiri) {
                niriFile.reload();
                seedNiri();
            }
            themeProc.running = true;
        } else {
            themeOpen = false;
            focusRowItem = null;
            kbIndex = -1;
        }
    }

    /**
     * Seeds every control from the live Hyprland source files. Numbers fall
     * back to the defaults when a field is missing so a partially hand-edited
     * config never leaves a control blank.
     */
    function seed() {
        root.inputText = inputFile.text();
        root.envText = envFile.text();
        root.autostartText = autostartFile.text();

        var inp = root.inputText;
        var sens = parseFloat(SetInput.getField(inp, "sensitivity"));
        root.sensitivity = isNaN(sens) ? 0 : sens;
        var ap = SetInput.getField(inp, "accel_profile");
        root.accelProfile = ap.length > 0 ? ap : "flat";

        var env = root.envText;
        var cs = parseInt(SetInput.getField(env, "XCURSOR_SIZE"), 10);
        root.cursorSize = isNaN(cs) ? 24 : cs;
        var ct = SetInput.getField(env, "XCURSOR_THEME");
        root.cursorTheme = ct.length > 0 ? ct : "Bibata-Modern-Ice";
    }

    /**
     * Seeds every control from the live Niri KDL config. Falls back to the
     * same defaults as the Hyprland path when a field is absent.
     */
    function seedNiri() {
        root.niriInputText = niriFile.text();
        var text = root.niriInputText;

        // Niri stores pointer speed as accel-speed (-1.0 … 1.0) and the
        // profile as accel-profile ("flat" | "adaptive").
        var speed = parseFloat(SetNiri.getField(text, "accel-speed"));
        root.sensitivity = isNaN(speed) ? 0 : Math.max(-1, Math.min(1, speed));
        var ap = SetNiri.getField(text, "accel-profile");
        root.accelProfile = ap.length > 0 ? ap : "flat";

        var cs = parseInt(SetNiri.getField(text, "xcursor-size"), 10);
        root.cursorSize = isNaN(cs) ? 24 : cs;
        var ct = SetNiri.getField(text, "xcursor-theme");
        root.cursorTheme = ct.length > 0 ? ct : "Bibata-Modern-Ice";
    }

    /**
     * Hyprland: rewrites one input.lua field to `literal` (already formatted
     * by the caller) and reloads Hyprland so the change takes effect at once.
     */
    function writeInputField(name, literal) {
        if (!Compositor.isHyprland)
            return;
        var res = SetInput.setField(root.inputText, name, literal);
        if (!res.ok)
            return;
        root.inputText = res.text;
        inputWriter.setText(res.text);
        reloadProc.running = true;
    }

    /**
     * Niri: rewrites the accel-profile or accel-speed field inside the KDL
     * config. Always rebuilds the mouse block for these two fields so the
     * block never holds more than one of each, even if setField only
     * replaced the first of several active lines. Niri auto-reloads
     * the file on change, so no extra reload command is needed.
     */
    function writeNiriField(name, literal) {
        if (!Compositor.isNiri)
            return;
        var res = SetNiri.setField(root.niriInputText, name, literal);
        if (res.ok) {
            root.niriInputText = res.text;
        }
        // Always rebuild the mouse block for these two fields so the block
        // never holds more than one of each, even if setField only replaced
        // the first of several active lines.
        if (name === "accel-profile" || name === "accel-speed") {
            var speed = name === "accel-speed" ? parseFloat(literal) : root.sensitivity;
            if (isNaN(speed)) speed = 0;
            var mouseRes = SetNiri.upsertMouseBlock(root.niriInputText, root.accelProfile, speed);
            if (mouseRes !== root.niriInputText) {
                root.niriInputText = mouseRes;
                niriWriter.setText(mouseRes);
                return;
            }
        }
        if (res.ok) {
            niriWriter.setText(res.text);
        }
    }

    /**
     * Hyprland: applies a cursor theme/size pair live via `hyprctl setcursor`,
     * then persists it by rewriting the XCURSOR/HYPRCURSOR env lines and the
     * autostart setcursor call. No Hyprland reload is needed for the cursor.
     */
    function applyCursor(theme, size) {
        if (Compositor.isHyprland) {
            setcursorProc.theme = theme;
            setcursorProc.size = size;
            setcursorProc.running = true;

            var env = root.envText;
            var e1 = SetInput.setEnv(env, "XCURSOR_THEME", theme);
            var e2 = SetInput.setEnv(e1.ok ? e1.text : env, "XCURSOR_SIZE", String(size));
            var e3 = SetInput.setEnv(e2.ok ? e2.text : (e1.ok ? e1.text : env), "HYPRCURSOR_SIZE", String(size));
            if (e3.ok || e2.ok || e1.ok) {
                root.envText = e3.ok ? e3.text : (e2.ok ? e2.text : e1.text);
                envWriter.setText(root.envText);
            }

            var auto = SetInput.setCursorLine(root.autostartText, theme, size);
            if (auto.ok) {
                root.autostartText = auto.text;
                autostartWriter.setText(auto.text);
            }
        } else if (Compositor.isNiri) {
            // Niri: rewrite the cursor block in the KDL config. Niri
            // auto-reloads, so the change lands immediately.
            var res = SetNiri.upsertCursorBlock(root.niriInputText, theme, size);
            if (res !== root.niriInputText) {
                root.niriInputText = res;
                niriWriter.setText(res);
            }
        }
    }

    function clampSensitivity(v) {
        return Math.max(-1, Math.min(1, Math.round(v * 10) / 10));
    }

    // ── Hyprland file watchers ──────────────────────────────────────────
    FileView {
        id: inputFile
        path: root.inputPath
        blockLoading: true
        printErrors: false
    }

    FileView {
        id: inputWriter
        path: root.inputPath
        atomicWrites: true
        printErrors: false
    }

    FileView {
        id: envFile
        path: root.envPath
        blockLoading: true
        printErrors: false
    }

    FileView {
        id: envWriter
        path: root.envPath
        atomicWrites: true
        printErrors: false
    }

    FileView {
        id: autostartFile
        path: root.autostartPath
        blockLoading: true
        printErrors: false
    }

    FileView {
        id: autostartWriter
        path: root.autostartPath
        atomicWrites: true
        printErrors: false
    }

    // ── Niri file watchers ─────────────────────────────────────────────
    FileView {
        id: niriFile
        path: root.niriInputPath
        blockLoading: true
        printErrors: false
    }

    FileView {
        id: niriWriter
        path: root.niriInputPath
        atomicWrites: true
        printErrors: false
        onSaveFailed: (err) => {
            if (Flags.debug) console.log("input: niri write failed: " + err);
        }
    }

    // ── Hyprland processes ─────────────────────────────────────────────
    Process {
        id: reloadProc
        command: ["setsid", "-f", "sh", "-c", "sleep 0.4; hyprctl reload"]
    }

    Process {
        id: setcursorProc
        property string theme: ""
        property int size: 24
        command: ["hyprctl", "setcursor", theme, String(size)]
    }

    // ── Shared: cursor theme scanner ───────────────────────────────────
    Process {
        id: themeProc
        command: ["sh", "-c", "{ printf '%s\\n' \"$HOME/.icons\" \"$HOME/.local/share/icons\" /usr/share/icons; printf '%s' \"${XDG_DATA_DIRS:-/usr/local/share:/usr/share}\" | tr ':' '\\n' | sed 's#/*$#/icons#'; } | sort -u | while IFS= read -r d; do [ -d \"$d\" ] || continue; for t in \"$d\"/*/; do [ -d \"$t/cursors\" ] && basename \"$t\"; done; done | sort -u"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n").filter(function (l) { return l.trim().length > 0; });
                root.cursorThemes = lines;
            }
        }
    }

    component Stepper: Row {
        id: step

        property real value: 0
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

    component GroupLabel: Text {
        topPadding: 16 * root.s
        bottomPadding: 6 * root.s
        color: Theme.faint
        font.family: Theme.font
        font.pixelSize: 8.5 * root.s
        font.weight: Font.Bold
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1.2 * root.s
    }

    component FieldRow: Item {
        id: frow
        property string label: ""
        default property alias control: ctrl.data

        width: parent ? parent.width : 0
        height: 34 * root.s

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, parent.width - ctrl.width - 12 * root.s)
            elide: Text.ElideRight
            text: frow.label
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 12.5 * root.s
            font.weight: Font.Medium
        }

        Item {
            id: ctrl
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: childrenRect.width
            height: childrenRect.height
        }
    }

    Column {
        id: content
        z: 100
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0
        height: root.height + root.mBottom * root.s
        clip: true

        SettingsHeader {
            s: root.s
            title: "INPUT"
            showBack: true
        }

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12 * root.s
            anchors.rightMargin: 12 * root.s
            spacing: 0

            GroupLabel { text: "Pointer" }

            FieldRow {
                label: "Sensitivity"
                Stepper {
                    value: root.sensitivity
                    display: root.sensitivity.toFixed(1)
                    onStepped: (dir) => {
                        var next = root.clampSensitivity(root.sensitivity + dir * 0.1);
                        if (next === root.sensitivity)
                            return;
                        root.sensitivity = next;
                        if (Compositor.isHyprland)
                            root.writeInputField("sensitivity", String(next));
                        else if (Compositor.isNiri)
                            root.writeNiriField("accel-speed", String(next));
                    }
                }
            }

            FieldRow {
                label: "Acceleration"
                SettingsSeg {
                    s: root.s
                    options: root.accelOptions
                    value: root.accelProfile
                    onPicked: (v) => {
                        root.accelProfile = v;
                        if (Compositor.isHyprland)
                            root.writeInputField("accel_profile", "\"" + v + "\"");
                        else if (Compositor.isNiri)
                            root.writeNiriField("accel-profile", "\"" + v + "\"");
                    }
                }
            }

            GroupLabel { text: "Cursor" }

            FieldRow {
                label: "Size"
                Stepper {
                    value: root.cursorSize
                    display: String(root.cursorSize)
                    onStepped: (dir) => {
                        var next = Math.max(12, Math.min(96, root.cursorSize + dir * 4));
                        if (next === root.cursorSize)
                            return;
                        root.cursorSize = next;
                        root.applyCursor(root.cursorTheme, next);
                    }
                }
            }

            Item { width: 1; height: 8 * root.s }

            DisplayPicker {
                width: parent.width
                s: root.s
                label: "Theme"
                options: root.cursorThemes.map(function (t) { return { label: t, value: t }; })
                value: root.cursorTheme
                open: root.themeOpen
                onRequestToggle: root.themeOpen = !root.themeOpen
                onPicked: (v) => {
                    root.cursorTheme = v;
                    root.themeOpen = false;
                    root.applyCursor(v, root.cursorSize);
                }
            }

            Item { width: 1; height: 10 * root.s }
        }
    }
}
