pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Single owner of screen vibrance (nvibrant) and external-monitor brightness
 * (ddcutil) for the mixer. The persisted vibrance percent is the source of
 * truth: loaded and re-applied once at startup so the tint survives a reboot,
 * and every later set both pushes to nvibrant and writes back the state file.
 * DDC monitors come from `ddcutil detect` (one brightness fader each); the
 * setvcp/getvcp wire format lives here so every caller speaks it the same.
 * The internal laptop backlight (eDP, no DDC/CI) is driven separately via
 * brightnessctl and gated on /sys/class/backlight being present, so a desktop
 * exposes nothing.
 */
Singleton {
    id: root

    // ADAPTED: ricelin → quickshell
    readonly property string stateFile: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell/nvibrant-value"

    property int vibrance: 40

    /**
     * DDC-capable monitors from `ddcutil detect`: [{ bus, label }] with label
     * taken from the DRM connector, falling back to the I2C bus number.
     */
    property var ddcMonitors: []

    /** True once an internal backlight has been found under /sys/class/backlight. */
    property bool backlightPresent: false

    /** Current internal-backlight level, 0..100. */
    property int backlightPct: 75

    /**
     * Loads the persisted vibrance percent and applies it once, so the saved
     * tint is restored on boot. Singletons init lazily, so a startup caller
     * must reference this for the restore to fire.
     */
    function restore() {
        var raw = vibState.text();
        var v = parseInt((raw || "40").trim());
        root.vibrance = isNaN(v) ? 40 : v;
        if (raw && raw.trim().length)
            applyVibrance(root.vibrance);
    }

    /**
     * Sets the screen vibrance to `pct` percent: pushes it to nvibrant and
     * persists it to the state file. `vibrance` mirrors the last set value.
     */
    function setVibrance(pct) {
        root.vibrance = Math.round(pct);
        applyVibrance(pct);
        saveVibrance(pct);
    }

    function applyVibrance(pct) {
        var raw = Math.round(Math.max(0, Math.min(100, pct)) * 1023 / 100);
        // nvibrant CLI: nvibrant set <value>
        Quickshell.execDetached(["nvibrant", "set", String(raw)]);
    }

    function saveVibrance(pct) {
        vibState.setText(String(Math.round(pct)));
    }

    function detectBacklight() {
        blProc.running = true;
    }

    function setBacklight(pct) {
        if (!root.backlightPresent) return;
        root.backlightPct = Math.max(0, Math.min(100, Math.round(pct)));
        Quickshell.execDetached(["brightnessctl", "set", String(root.backlightPct) + "%"]);
    }

    Process {
        id: blProc
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/backlight-detect.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "present") {
                    root.backlightPresent = true;
                }
            }
        }
    }

    FileView {
        id: vibState
        path: root.stateFile
        blockLoading: true
        printErrors: false
    }

    Component.onCompleted: detectBacklight()
}
