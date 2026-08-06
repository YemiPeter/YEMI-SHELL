pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../singletons" as QsSingletons

Singleton {
    id: root
    
    property bool powered: false
    property bool connected: false
    property string deviceName: ""
    
    // Check status periodically
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statusProc.running = true
    }
    
    Process {
        id: statusProc
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.powered = text.includes("Powered: yes")
            }
        }
    }
    
    onPoweredChanged: {
        if (powered) {
            // If powered on, check connection
            connectedProc.running = true
        } else {
            connected = false
            deviceName = ""
        }
    }
    
    Process {
        id: connectedProc
        command: ["bluetoothctl", "info"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.connected = text.includes("Connected: yes")
                if (root.connected) {
                    const nameMatch = text.match(/Name: (.*)/)
                    root.deviceName = nameMatch ? nameMatch[1] : "Device"
                } else {
                    root.deviceName = ""
                }
            }
        }
    }
    
    function togglePower() {
        console.log(">>> togglePower called, powered =", powered)
        const state = powered ? "off" : "on"
        toggleProc.exec(["bluetoothctl", "power", state])
    }
    
    Process {
        id: toggleProc
        onExited: (code) => {
            if (QsSingletons.Flags.debug) console.log("[Bluetooth] Power toggle exited with code:", code)
            statusProc.running = true
        }
    }
}
