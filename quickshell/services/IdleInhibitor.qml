pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../singletons" as QsSingletons

Singleton {
    id: root
    
    property bool inhibited: false
    property int inhibitorPid: -1
    
    onInhibitedChanged: {
        if (QsSingletons.Flags.debug) console.log("☕ [IdleInhibitor] Inhibited changed to:", inhibited)
        if (inhibited) {
            enableInhibitor()
        } else {
            disableInhibitor()
        }
    }
    
    function enableInhibitor() {
        if (QsSingletons.Flags.debug) console.log("☕ [IdleInhibitor] Enabling caffeine mode...")
        enableProcess.running = true
    }
    
    function disableInhibitor() {
        if (QsSingletons.Flags.debug) console.log("☕ [IdleInhibitor] Disabling caffeine mode...")
        disableProcess.running = true
    }
    
    // Enable idle inhibitor using systemd-inhibit
    Process {
        id: enableProcess
        command: ["/bin/sh", "-c", "systemd-inhibit --what=idle --who=QuickShell --why='Caffeine mode enabled' sleep infinity & echo $!"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                const pid = parseInt(data.trim())
                if (!isNaN(pid) && pid > 0) {
                    root.inhibitorPid = pid
                    if (QsSingletons.Flags.debug) console.log("☕ [IdleInhibitor] Started with PID:", pid)
                }
            }
        }
    }
    
    // Disable idle inhibitor
    Process {
        id: disableProcess
        command: ["/bin/sh", "-c", root.inhibitorPid > 0 ? 
                  `kill ${root.inhibitorPid} 2>/dev/null || pkill -f 'systemd-inhibit.*QuickShell'` :
                  "pkill -f 'systemd-inhibit.*QuickShell'"]
        running: false
        
        onExited: {
            root.inhibitorPid = -1
            if (QsSingletons.Flags.debug) console.log("☕ [IdleInhibitor] Stopped")
        }
    }
    
    Component.onCompleted: {
        if (QsSingletons.Flags.debug) console.log("☕ [IdleInhibitor] Service loaded")
    }
}
