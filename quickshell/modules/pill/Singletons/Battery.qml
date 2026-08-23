pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

/**
 * Laptop-battery state for the pill, sourced from UPower's display device and
 * gated so a desktop without a battery reports `present` false (the hover
 * cluster and battery surface stay hidden). Exposes percentage, charge state, a
 * signed draw/charge wattage, capacity and optional health, plus a formatted
 * time-to-empty/full string. `low` flags a discharging battery at or below
 * `lowThreshold`; `critical` adds a lower `criticalThreshold`. Crossing a
 * threshold or reaching full charge emits `lowBattery` / `criticalBattery` /
 * `batteryFull`. Charge-limit (battery-care) state is probed read-only from
 * sysfs on startup.
 */
Singleton {
    id: root

    readonly property var dev: UPower.displayDevice

    // Configurable battery thresholds (iNiR-inspired), no Config dependency.
    property int lowThreshold: 20
    property int criticalThreshold: 10

    readonly property bool present: dev !== null && dev.ready && dev.isLaptopBattery && dev.isPresent
    readonly property real frac: dev ? Math.max(0, Math.min(1, dev.percentage)) : 0
    readonly property int pct: Math.round(frac * 100)
    readonly property int state: dev ? dev.state : UPowerDeviceState.Unknown

    readonly property bool charging: state === UPowerDeviceState.Charging
    readonly property bool full: state === UPowerDeviceState.FullyCharged || pct >= 100
    readonly property bool discharging: state === UPowerDeviceState.Discharging

    readonly property bool low: present && !charging && pct <= lowThreshold
    readonly property bool critical: present && !charging && pct <= criticalThreshold

    readonly property real rateW: !dev ? 0
        : (discharging ? -dev.changeRate : (charging ? dev.changeRate : 0))
    readonly property real capacityWh: dev ? dev.energyCapacity : 0

    readonly property bool healthSupported: dev ? dev.healthSupported : false
    readonly property int health: dev ? Math.round(dev.healthPercentage) : 0

    readonly property bool hasTime: !dev ? false
        : (charging ? dev.timeToFull > 0 : (discharging ? dev.timeToEmpty > 0 : false))
    readonly property string timeStr: !dev ? ""
        : (charging ? fmt(dev.timeToFull) : (discharging ? fmt(dev.timeToEmpty) : ""))

    readonly property string stateLabel: charging ? "Charging"
        : (full ? "On AC · Full"
        : (discharging ? "Discharging" : "On AC"))

    // Threshold state-change signals
    signal lowBattery()
    signal criticalBattery()
    signal batteryFull()

    property bool _wasLow: false
    property bool _wasCritical: false
    property bool _wasFull: false

    function evaluateBattery() {
        if (!root.present) {
            root._wasLow = false
            root._wasCritical = false
            root._wasFull = false
            return
        }
        if (root.low && !root._wasLow)
            root.lowBattery()
        root._wasLow = root.low
        if (root.critical && !root._wasCritical)
            root.criticalBattery()
        root._wasCritical = root.critical
        if (root.full && !root._wasFull)
            root.batteryFull()
        root._wasFull = root.full
    }

    onPctChanged: root.evaluateBattery()
    onChargingChanged: root.evaluateBattery()
    onPresentChanged: root.evaluateBattery()

    // Read-only charge-limit detection: one-shot bash probe over 4 sysfs paths
    readonly property bool chargeLimitSupported: _chargeLimitProbe.supported
    readonly property int chargeLimit: _chargeLimitProbe.value

    QtObject {
        id: _chargeLimitProbe
        property bool supported: false
        property int value: -1
    }

    Process {
        id: chargeLimitProbe
        running: true
        command: ["bash", "-c",
            "for p in /sys/class/power_supply/BAT0/charge_control_end_threshold " +
                      "/sys/class/power_supply/BAT1/charge_control_end_threshold " +
                      "/sys/class/power_supply/BAT0/charge_limit " +
                      "/sys/class/power_supply/BAT1/charge_limit; do " +
            "if [ -r \"$p\" ]; then v=$(cat \"$p\"); if [ \"$v\" -gt 0 ] 2>/dev/null; then echo \"$v\"; exit 0; fi; fi; done; exit 1"]
        stdout: SplitParser {
            onRead: data => {
                const v = parseInt(data.trim())
                if (!isNaN(v) && v > 0) {
                    _chargeLimitProbe.supported = true
                    _chargeLimitProbe.value = v
                }
            }
        }
    }

    Component.onCompleted: root.evaluateBattery()

    function fmt(sec) {
        var s = Math.max(0, Math.round(sec));
        var h = Math.floor(s / 3600);
        var m = Math.floor((s % 3600) / 60);
        if (h > 0)
            return h + "h " + m + "m";
        return m + "m";
    }
}
