pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Display brightness control.
 * - Internal laptop backlight via sysfs + brightnessctl (preserved behavior).
 * - External monitors via DDC/CI (ddcutil). Safe if ddcutil is missing.
 * Ported per-shell BrightnessMonitor model from the iNiR/Waffle reference.
 */
Singleton {
    id: root

    signal brightnessChanged()

    // ===== Existing laptop backlight (preserved) =====
    property real brightness: 0.5
    property real maxBrightness: 1.0

    // Alias for easier access
    readonly property real level: brightness
    readonly property int percentage: Math.round(brightness * 100)

    // Dynamic backlight device discovery
    property string backlightDevice: ""
    readonly property string backlightPath: backlightDevice.length > 0 ? "/sys/class/backlight/" + backlightDevice + "/brightness" : ""
    readonly property string maxBrightnessPath: backlightDevice.length > 0 ? "/sys/class/backlight/" + backlightDevice + "/max_brightness" : ""

    property int currentValue: 0
    property int maxValue: 255
    property bool isSetting: false

    // Root-level raw max for the internal backlight (DDC monitors carry their own)
    property int rawMaxBrightness: 100

    Component.onCompleted: {
        discoverProc.running = true
    }

    function readMaxBrightness() {
        if (backlightAvailable) maxBrightnessProcess.running = true
    }

    function readBrightness() {
        if (backlightAvailable) brightnessProcess.running = true
    }

    function setBrightness(value) {
        root.isSetting = true
        brightness = Math.max(0.01, Math.min(1, value))
        setBrightnessProcess.command = [
            "bash", "-c",
            "brightnessctl set " + Math.round(brightness * 100) + "%"
        ]
        setBrightnessProcess.running = true
        pauseTimer.restart()
    }

    function increaseBrightness() {
        setBrightness(brightness + 0.05)
    }

    function decreaseBrightness() {
        setBrightness(brightness - 0.05)
    }

    onMaxValueChanged: {
        if (maxValue > 0) root.rawMaxBrightness = maxValue
    }

    onBrightnessChanged: root.brightnessChanged()

    // Discover backlight device
    Process {
        id: discoverProc
        command: ["bash", "-c", "ls /sys/class/backlight/ 2>/dev/null | head -1"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const device = data.trim()
                if (device.length > 0) {
                    root.backlightDevice = device
                    readMaxBrightness()
                    readBrightness()
                    updateTimer.start()
                } else {
                    console.warn("Brightness: no backlight device found in /sys/class/backlight/")
                }
            }
        }
    }

    // Read max brightness
    Process {
        id: maxBrightnessProcess
        command: ["/bin/cat", maxBrightnessPath]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const value = parseInt(data.trim())
                if (!isNaN(value) && value > 0) {
                    maxValue = value
                }
            }
        }
    }

    // Read current brightness
    Process {
        id: brightnessProcess
        command: ["/bin/cat", backlightPath]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const value = parseInt(data.trim())
                if (!isNaN(value)) {
                    currentValue = value
                    brightness = maxValue > 0 ? value / maxValue : 0
                }
            }
        }
    }

    // Set brightness process
    Process {
        id: setBrightnessProcess
        running: false
        onExited: code => {
            if (code !== 0)
                console.warn("Brightness: brightnessctl failed, exit code:", code)
        }
    }

    // Update timer - optimized interval
    Timer {
        id: updateTimer
        interval: 500
        repeat: true
        triggeredOnStart: true
        running: !root.isSetting
        onTriggered: readBrightness()
    }

    Timer {
        id: pauseTimer
        interval: 1500
        repeat: false
        onTriggered: root.isSetting = false
    }

    // ===== Per-screen / DDC (ported from Waffle/iNiR) =====
    property var ddcMonitors: []

    readonly property list<BrightnessMonitor> monitors: Quickshell.screens.map(screen => monitorComp.createObject(root, {
        screen
    }))

    function getMonitorForScreen(screen) {
        return monitors.find(m => m.screen === screen)
    }

    // DDC detection - safe if ddcutil missing (process fails, no crash)
    Process {
        id: ddcProc
        command: ["ddcutil", "detect", "--brief"]
        stdout: SplitParser {
            splitMarker: "\n\n"
            onRead: data => {
                if (data.startsWith("Display ")) {
                    const lines = data.split("\n").map(l => l.trim())
                    const modelLine = lines.find(l => l.startsWith("Monitor:"))
                    const busLine = lines.find(l => l.startsWith("I2C bus:"))
                    if (modelLine && busLine) {
                        root.ddcMonitors.push({
                            model: modelLine.split(":")[2],
                            busNum: busLine.split("/dev/i2c-")[1]
                        })
                    }
                }
            }
        }
        onExited: root.ddcMonitorsChanged()
    }

    onMonitorsChanged: {
        ddcMonitors = []
        ddcProc.running = true
    }

    Process {
        id: setProc
    }

    component BrightnessMonitor: QtObject {
        id: monitor

        required property ShellScreen screen

        readonly property bool isDdc: {
            const match = root.ddcMonitors.find(m => screen.model?.includes(m.model) && !root.monitors.slice(0, root.monitors.indexOf(this)).some(mon => mon.busNum === m.busNum))
            return !!match
        }

        readonly property string busNum: {
            const match = root.ddcMonitors.find(m => screen.model?.includes(m.model) && !root.monitors.slice(0, root.monitors.indexOf(this)).some(mon => mon.busNum === m.busNum))
            return match?.busNum ?? ""
        }

        property int rawMaxBrightness: 100
        property real brightness: monitor.isDdc ? 0 : root.brightness
        property bool ready: false

        function setBrightness(value) {
            value = Math.max(0, Math.min(1, value))
            if (monitor.isDdc)
                monitor.brightness = value
            else
                root.setBrightness(value)
        }

        function initialize() {
            monitor.ready = false
            if (monitor.isDdc) {
                initProc.command = ["ddcutil", "-b", busNum, "getvcp", "10", "--brief"]
                initProc.running = true
            } else {
                // Internal screen: mirror the proven root backlight path
                monitor.ready = true
            }
        }

        readonly property Process initProc: Process {
            stdout: SplitParser {
                onRead: data => {
                    const parts = data.split(" ")
                    const current = parseInt(parts[3])
                    const max = parseInt(parts[4])
                    if (!isNaN(max) && max > 0)
                        monitor.rawMaxBrightness = max
                    if (!isNaN(current))
                        monitor.brightness = current / monitor.rawMaxBrightness
                    monitor.ready = true
                }
            }
        }

        // Delay for DDC monitors (slow, misbehaves on rapid changes)
        property var setTimer: Timer {
            id: setTimer
            interval: monitor.isDdc ? 300 : 0
            onTriggered: syncBrightness()
        }

        function syncBrightness() {
            const brightnessValue = Math.max(monitor.brightness, 0)
            const rawValueRounded = Math.max(Math.floor(brightnessValue * monitor.rawMaxBrightness), 1)
            setProc.command = monitor.isDdc
                ? ["ddcutil", "-b", busNum, "setvcp", "10", rawValueRounded]
                : ["brightnessctl", "--class", "backlight", "s", rawValueRounded, "--quiet"]
            setProc.startDetached()
        }

        onBrightnessChanged: {
            if (!monitor.ready)
                return
            if (monitor.isDdc) {
                root.brightnessChanged()
                monitor.setTimer.restart()
            }
            // non-DDC: root.brightnessChanged() already emitted by the root handler
        }

        Component.onCompleted: initialize()
        onBusNumChanged: initialize()
    }

    Component {
        id: monitorComp

        BrightnessMonitor {}
    }

    reloadableId: "brightness"
}
