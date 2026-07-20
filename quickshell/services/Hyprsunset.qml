pragma Singleton
import QtQuick 6.10
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: false
    property bool requested: false

    onRequestedChanged: {
        if (requested) {
            startProc.running = true
        } else {
            killProc.running = true
        }
    }

    Process {
        id: startProc
        command: ["nohup", "hyprsunset", "-t", "4500"]
        onExited: checkProc.running = true
    }

    Process {
        id: killProc
        command: ["pkill", "-x", "hyprsunset"]
        onExited: checkProc.running = true
    }

    Process {
        id: checkProc
        command: ["bash", "-c", "sleep 0.3 && pgrep -x hyprsunset"]
        onExited: code => { root.enabled = (code === 0) }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: checkProc.running = true
    }

    Component.onCompleted: checkProc.running = true
}
