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
    
    // Updated backlight path
    readonly property string backlightPath: "/sys/class/backlight/intel_backlight/brightness"
    readonly property string maxBrightnessPath: "/sys/class/backlight/intel_backlight/max_brightness"
    
    property int currentValue: 0
    property int maxValue: 255
    property bool isSetting: false
    
    Component.onCompleted: {
        readMaxBrightness()
        readBrightness()
        updateTimer.start()
    }
    
    function readMaxBrightness() {
        maxBrightnessProcess.running = true
    }
    
    function readBrightness() {
        brightnessProcess.running = true
    }
    
    function setBrightness(value) {
        root.isSetting = true
        brightness = Math.max(0.05, Math.min(1, value))
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
