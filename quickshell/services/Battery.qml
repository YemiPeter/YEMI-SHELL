pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.modules.common
import qs.services

/**
 * Battery state singleton for the Waffle substrate.
 *
 * Reads live battery data from UPower (display device) so the General
 * settings page's charge-limit threshold and low/critical warnings
 * actually fire. Exposes chargeLimitSupported / chargeLimitAdjustable
 * (both referenced by WGeneralPage.qml but missing from the old stub) by
 * probing sysfs charge-control sysfs files.
 */
Singleton {
    id: root

    readonly property var dev: UPower.displayDevice

    // --- Basic presence / state (mirrors Pill/Battery.qml contract) ---
    readonly property bool present: dev !== null && dev.ready && dev.isLaptopBattery && dev.isPresent
    readonly property real frac: dev ? Math.max(0, Math.min(1, dev.percentage)) : 0
    readonly property int pct: Math.round(frac * 100)
    readonly property int state: dev ? dev.state : UPowerDeviceState.Unknown
    readonly property bool charging: state === UPowerDeviceState.Charging
    readonly property bool full: state === UPowerDeviceState.FullyCharged || pct >= 100
    readonly property bool discharging: state === UPowerDeviceState.Discharging

    // --- Config-driven thresholds (from General settings page) ---
    readonly property int lowThreshold: Config.options?.battery?.low ?? 20
    readonly property int criticalThreshold: Config.options?.battery?.critical ?? 5
    readonly property bool notifyFull: Config.options?.battery?.notifyFull ?? true
    readonly property bool chargeLimitEnable: Config.options?.battery?.chargeLimit?.enable ?? false
    readonly property int chargeLimitThreshold: Config.options?.battery?.chargeLimit?.threshold ?? 80

    // --- Charge-limit capability detection (sysfs) ---
    // Many ThinkPad/ASUS/Lenovo laptops expose charge-control thresholds via
    // /sys/class/power_supply/BAT*/charge_control_*_threshold. Read-only files
    // mean "supported but not user-adjustable"; no files means unsupported.
    readonly property bool _probeRunning: false
    property bool _sysfsSupported: false
    property bool _sysfsAdjustable: false

    readonly property bool chargeLimitSupported: root._sysfsSupported || root.chargeLimitEnable
    readonly property bool chargeLimitAdjustable: root._sysfsAdjustable

    // --- Low / critical warning state ---
    property bool _notifiedLow: false
    property bool _notifiedCritical: false
    property bool _notifiedFull: false

    // ---- Capability probe ----
    // Run a shell glob over /sys/class/power_supply/BAT*/charge_control_*
    // to determine whether the kernel exposes charge-limit sysfs files and
    // whether they're writable (adjustable).
    function _probeChargeLimit(): void {
        sysfsChargeProbe.running = true
    }

    Process {
        id: sysfsChargeProbe
        command: [
            "/usr/bin/bash", "-c",
            "files=(/sys/class/power_supply/BAT*/charge_control_*_threshold 2>/dev/null); " +
            "if [ ${#files[@]} -gt 0 ]; then " +
            "  writable=0; " +
            "  for f in \"${files[@]}\"; do [ -w \"$f\" ] && writable=1; done; " +
            "  echo \"supported:$([ \"$writable\" = \"1\" ] && echo yes || echo no)\"; " +
            "else " +
            "  echo \"none\"; " +
            "fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const txt = layout.text.trim();
                if (txt.startsWith("none")) {
                    root._sysfsSupported = false;
                    root._sysfsAdjustable = false;
                } else {
                    root._sysfsSupported = true;
                    root._sysfsAdjustable = txt.includes("writable:yes");
                }
            }
        }
    }

    // ---- Notifications / sounds on battery events ----
    Connections {
        target: dev
        enabled: root.present

        function onStateChanged() {
            root._notifiedFull = false;
            root._notifiedLow = false;
            root._notifiedCritical = false;
        }
    }

    Timer {
        id: warnTimer
        interval: 5000
        repeat: true
        running: root.present && root.discharging
        onTriggered: {
            if (root.chargeLimitEnable && root.present && root.charging && root.pct >= root.chargeLimitThreshold && !root._notifiedFull) {
                root._notifiedFull = true;
                root._postNotification(Translation.tr("Battery full"), Translation.tr("Battery reached %1%").replace("%1", root.chargeLimitThreshold));
                if (Config.options?.sounds?.battery ?? false)
                    Audio.playSystemSound("complete")
            }

            if (!root.discharging) return;

            const low = root.pct <= root.lowThreshold && !root._notifiedLow;
            const crit = root.pct <= root.criticalThreshold && !root._notifiedCritical;
            if (crit) {
                root._notifiedCritical = true;
                root._postNotification(Translation.tr("Critical battery"), Translation.tr("Battery at %1%. Suspending soon.").replace("%1", root.pct));
                if (Config.options?.sounds?.battery ?? false)
                    Audio.playSystemSound("battery-low")
            } else if (low) {
                root._notifiedLow = true;
                root._postNotification(Translation.tr("Low battery"), Translation.tr("Battery at %1%").replace("%1", root.pct));
                if (Config.options?.sounds?.battery ?? false)
                    Audio.playSystemSound("battery-low")
            }

            if (root.notifyFull && root.charging && root.full && !root._notifiedFull) {
                root._notifiedFull = true;
                root._postNotification(Translation.tr("Battery full"), Translation.tr("Battery is fully charged"));
                if (Config.options?.sounds?.battery ?? false)
                    Audio.playSystemSound("complete")
            }
        }
    }

    function _postNotification(summary, body) {
        Quickshell.execDetached([
            "/usr/bin/notify-send",
            "-u", "normal",
            "-a", "yemishell",
            "--icon", "battery",
            summary, body
        ])
    }

    // ---- Charge-limit application ----
    // Only fires when chargeLimitEnable is true and the kernel exposes writable
    // sysfs threshold files. Sets both start and end threshold so the battery
    // stops charging at the configured level.
    function _applyChargeLimit(threshold) {
        if (!root._sysfsAdjustable || !root.chargeLimitEnable) return;
        applyChargeLimitProc.command = [
            "/usr/bin/bash", "-c",
            "for f in /sys/class/power_supply/BAT*/charge_control_*_threshold; do " +
            "  [ -w \"$f\" ] || continue; " +
            "  echo \"@0 " + threshold + "\" > \"$f\"; " +
            "done"
        ]
        applyChargeLimitProc.running = true;
    }

    Process {
        id: applyChargeLimitProc
        command: []
        onExited: (code, status) => {
            if (code !== 0)
                console.warn("[Battery] Failed to apply charge limit (code:", code, ")")
        }
    }

    Component.onCompleted: {
        root._probeChargeLimit();
        chargeProbeTimer.start();
    }

    // Re-apply charge limit whenever config changes (settings UI writes)
    Connections {
        target: Config
        function onConfigChanged() {
            if (root.chargeLimitEnable && root._sysfsAdjustable)
                root._applyChargeLimit(root.chargeLimitThreshold)
        }
    }

    // Re-probe every 30s in case hotplugged devices appear
    Timer {
        id: chargeProbeTimer
        interval: 30000
        repeat: true
        running: true
        onTriggered: root._probeChargeLimit()
    }
}
