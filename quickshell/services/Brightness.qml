pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    
    property real brightness: 0.5
    property real maxBrightness: 1.0
    
    // Alias for easier access
    readonly property real level: brightness
    readonly property int percentage: Math.round(brightness * 100)
    
    // Dynamic backlight device discovery
    property string backlightDevice: ""
    readonly property string backlightPath: backlightDevice.length > 0 ? "/sys/class/backlight/" + backlightDevice + "/brightness" : ""
    readonly property string maxBrightnessPath: backlightDevice.length > 0 ? "/sys/class/backlight/" + backlightDevice + "/max_brightness" : ""
    readonly property bool backlightAvailable: backlightDevice.length > 0
    
    property int currentValue: 0
    property int maxValue: 255
    property bool isSetting: false
    
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
}
