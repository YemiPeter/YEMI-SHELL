//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick 6.10
import "services" as QsServices
import "modules/osd"

ShellRoot {
    id: root

    // Initialize services immediately
    readonly property var notifs: QsServices.Notifs
    readonly property var pywal: QsServices.Pywal
    readonly property var audio: QsServices.Audio
    readonly property var brightness: QsServices.Brightness

    // === Launcher IPC Handler (for Hyprland keybinds) ===
    IpcHandler {
        target: "launcher"

        function toggle(): void {
            if (root.launcherVisible && root.activeTab === 0) {
                root.launcherVisible = false
            } else {
                root.activeTab = 0
                root.launcherVisible = true
            }
        }
    }

    // === Wallpaper IPC Handler ===
    IpcHandler {
        target: "wallpaper"

        function toggle(): void {
            if (root.launcherVisible && root.activeTab === 1) {
                root.launcherVisible = false
            } else {
                root.activeTab = 1
                if (!root.wallsLoaded) root.loadWallpapers()
                root.launcherVisible = true
            }
        }

        function random(): void {
            randomWallProc.running = true
        }
    }

    // === Music IPC Handler ===
    IpcHandler {
        target: "music"

        function toggle(): void {
            root.toggleMusic()
        }
    }

    // === Colors IPC Handler (for after-wall.sh) ===
    IpcHandler {
        target: "colors"

        function reload(): void {
            if (!ipcColorLoadProc.running) ipcColorLoadProc.running = true
        }
    }

    // === Settings IPC Handler ===
    IpcHandler {
        target: "settings"

        property var settingsWindow: null

        function toggle(): void {
            if (!settingsWindow) {
                // Dynamically load the settings window
                var component = Qt.createComponent("modules/settings/SettingsWindow.qml");
                if (component.status === Component.Ready) {
                    settingsWindow = component.createObject(root);
                } else {
                    console.error("❌ Failed to load SettingsWindow:", component.errorString());
                    return;
                }
            }
            
            if (settingsWindow) {
                settingsWindow.toggle();
            }
        }
    }

    // Direct NotificationServer to ensure it starts
    NotificationServer {
        id: notificationServer

        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            console.log("📬 [ShellRoot] Notification received:", notif.appName, notif.summary);
            notif.tracked = true;
            notifs.addNotification(notif);
        }

        Component.onCompleted: {
            console.log("🔔 NotificationServer registered on D-Bus");
        }
    }

    Loader {
        id: barLoader
        source: "modules/bar/BarWrapper.qml"
    }

    // Notification popups in top-right corner
    Loader {
        id: notificationPopupsLoader
        source: "modules/bar/components/NotificationPopups.qml"
    }

    // OSD overlays (volume and brightness)
    Wrapper {
        pywal: root.pywal
    }

    // Music Panel
    Loader {
        id: musicPanelLoader
        source: "modules/music/MusicPanel.qml"
    }

    // === Path Properties ===
    property string homePath: Quickshell.env("HOME")
    property string configPath: homePath + "/.config/quickshell"
    property string wallpaperPath: homePath + "/wallpapers"
    property string cachePath: homePath + "/.cache"
    property string statePath: configPath + "/state"

    // === Music Panel State Properties ===
    property bool musicVisible: false
    property int savedGifIndex: 0
    function toggleMusic() { musicVisible = !musicVisible }

    // === Launcher State Properties ===
    property bool launcherVisible: false
    property int activeTab: 0
    property string searchTerm: ""
    property var appList: []
    property var appUsage: ({})
    property var filteredApps: {
        var source = appList
        var usage = appUsage
        if (searchTerm !== "") {
            var result = []
            for (var i = 0; i < source.length; i++) {
                var entry = source[i]
                if (entry.name.toLowerCase().includes(searchTerm) || entry.exec.toLowerCase().includes(searchTerm)) {
                    result.push(entry)
                }
            }
            source = result
        }
        var sorted = source.slice().sort(function(a, b) {
            var countA = usage[a.name] || 0
            var countB = usage[b.name] || 0
            if (countB !== countA) return countB - countA
            return a.name.localeCompare(b.name)
        })
        return sorted
    }
    property int selectedIndex: 0
    property string wallSearchTerm: ""
    property var wallpaperList: []
    property var filteredWallpapers: {
        if (wallSearchTerm === "") return wallpaperList
        var result = []
        for (var i = 0; i < wallpaperList.length; i++) {
            if (wallpaperList[i].name.toLowerCase().includes(wallSearchTerm)) {
                result.push(wallpaperList[i])
            }
        }
        return result
    }
    property int wallSelectedIndex: 0
    property string currentWallpaper: ""
    property bool wallsLoaded: false
    property bool thumbsReady: false
    property bool walApplying: false
    property var wallpaperHashes: ({})

    // === Launcher Functions ===
    function toggleLauncher() { launcherVisible = !launcherVisible }

    function launchApp(app) {
        launchProc.command = ["bash", "-c", app.exec + " &"]
        launchProc.running = true
        var usage = appUsage
        var updated = {}
        for (var key in usage) updated[key] = usage[key]
        updated[app.name] = (updated[app.name] || 0) + 1
        appUsage = updated
        saveUsageProc.command = ["bash", "-c", "echo '" + JSON.stringify(updated) + "' > '" + root.configPath + "/app_usage.json'"]
        saveUsageProc.running = true
        root.launcherVisible = false
    }

    function applyWallpaper(wallpaper) {
        root.currentWallpaper = wallpaper.path
        root.walApplying = true
        applyWallProc.command = ["bash", "-c",
            "awww img '" + wallpaper.path + "' --transition-type any --transition-duration 2 & " +
            root.homePath + "/.config/skwd-wall/after-wall.sh '" + wallpaper.path + "'"
        ]
        applyWallProc.running = true
    }

    function loadWallpapers() {
        root.wallpaperList = []
        root.wallsLoaded = false
        root.thumbsReady = false
        if (!wallpaperListProc.running) wallpaperListProc.running = true
    }

    // === Launcher Processes ===
    Process { id: launchProc }

    Process {
        id: loadUsageProc
        command: ["bash", "-c", "cat '" + root.configPath + "/app_usage.json' 2>/dev/null || echo '{}'"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try { root.appUsage = JSON.parse(data.trim()) } catch(e) { root.appUsage = {} }
            }
        }
    }

    Process { id: saveUsageProc }

    Process {
        id: appListProc
        command: ["bash", "-c",
            "for f in /usr/share/applications/*.desktop " + root.homePath + "/.local/share/applications/*.desktop; do " +
            "  [ -f \"$f\" ] || continue; " +
            "  grep -qi '^NoDisplay=true' \"$f\" && continue; " +
            "  grep -qi '^Hidden=true' \"$f\" && continue; " +
            "  name=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2-); " +
            "  exec=$(grep -m1 '^Exec=' \"$f\" | cut -d= -f2- | sed 's/ %[fFuUdDnNickvm]//g'); " +
            "  icon=$(grep -m1 '^Icon=' \"$f\" | cut -d= -f2-); " +
            "  [ -z \"$name\" ] && continue; " +
            "  [ -z \"$exec\" ] && continue; " +
            "  printf '%s\\t%s\\t%s\\n' \"$name\" \"$exec\" \"$icon\"; " +
            "done | sort -f -t$'\\t' -k1,1 | awk -F'\\t' '!seen[$1]++'"
        ]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line.length === 0) return
                var parts = line.split("\t")
                if (parts.length < 2) return
                var current = root.appList.slice()
                current.push({ name: parts[0], exec: parts[1], icon: parts.length > 2 ? parts[2] : "" })
                root.appList = current
            }
        }
    }

    Process {
        id: thumbDirProc
        command: ["mkdir", "-p", root.cachePath + "/wallpaper-thumbs"]
        onExited: root.loadWallpapers()
    }

    Process {
        id: wallpaperListProc
        command: ["bash", "-c", "find '" + root.wallpaperPath + "' -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.png' -o -iname '*.webp' \\) ! -name '.*' 2>/dev/null | sort"]
        stdout: SplitParser {
            onRead: data => {
                var path = data.trim()
                if (path.length === 0) return
                var parts = path.split("/")
                var name = parts[parts.length - 1]
                var current = root.wallpaperList.slice()
                current.push({ name: name, path: path })
                root.wallpaperList = current
            }
        }
        onExited: {
            root.wallsLoaded = true
            if (!thumbGenProc.running) thumbGenProc.running = true
        }
    }

    Process {
        id: thumbGenProc
        command: ["bash", "-c",
            "THUMB_DIR='" + root.cachePath + "/wallpaper-thumbs' && " +
            "WALL_DIR='" + root.wallpaperPath + "' && " +
            "cd \"$THUMB_DIR\" && " +
            "find \"$WALL_DIR\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.png' -o -iname '*.webp' \\) ! -name '.*' 2>/dev/null | " +
            "while IFS= read -r f; do " +
            "  hash=$(echo -n \"$f\" | md5sum | cut -d' ' -f1); " +
            "  thumb=\"$THUMB_DIR/${hash}.jpg\"; " +
            "  if [ ! -f \"$thumb\" ] || [ \"$f\" -nt \"$thumb\" ]; then " +
            "    if command -v vipsthumbnail >/dev/null 2>&1; then " +
            "      case \"$f\" in " +
            "        *.gif) convert \"${f}[0]\" -thumbnail 180x120^ -gravity center -extent 180x120 -quality 85 \"$thumb\" 2>/dev/null ;; " +
            "        *) vipsthumbnail \"$f\" -s 180x120 -o \"$thumb\" 2>/dev/null || convert \"$f\" -thumbnail 180x120^ -gravity center -extent 180x120 -quality 85 \"$thumb\" 2>/dev/null ;; " +
            "      esac; " +
            "    else " +
            "      case \"$f\" in " +
            "        *.gif) convert \"${f}[0]\" -thumbnail 180x120^ -gravity center -extent 180x120 -quality 85 \"$thumb\" 2>/dev/null ;; " +
            "        *) convert \"$f\" -thumbnail 180x120^ -gravity center -extent 180x120 -quality 85 \"$thumb\" 2>/dev/null ;; " +
            "      esac; " +
            "    fi; " +
            "  fi; " +
            "done"
        ]
        onExited: {
            root.thumbsReady = true
            if (!hashAllProc.running) hashAllProc.running = true
        }
    }

    Process {
        id: hashAllProc
        command: ["bash", "-c", "for f in '" + root.wallpaperPath + "'/*; do [ -f \"$f\" ] && echo \"$f|$(echo -n \"$f\" | md5sum | cut -d' ' -f1)\"; done"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split("|")
                if (parts.length === 2 && parts[0] && parts[1]) {
                    var updated = root.wallpaperHashes
                    updated[parts[0]] = parts[1]
                    root.wallpaperHashes = updated
                    root.wallpaperHashesChanged()
                }
            }
        }
    }

    Process {
        id: currentWallProc
        command: ["bash", "-c", "readlink -f '" + root.wallpaperPath + "/current' 2>/dev/null || echo ''"]
        stdout: SplitParser { onRead: data => root.currentWallpaper = data.trim() }
    }

    Process {
        id: randomWallProc
        property string wallPath: ""
        command: ["bash", "-c", "find '" + root.wallpaperPath + "' -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) ! -name '.*' 2>/dev/null | shuf -n1"]
        stdout: SplitParser {
            onRead: data => { randomWallProc.wallPath = data.trim() }
        }
        onExited: {
            if (randomWallProc.wallPath.length > 0) {
                var parts = randomWallProc.wallPath.split("/")
                var name = parts[parts.length - 1]
                root.applyWallpaper({ name: name, path: randomWallProc.wallPath })
            }
        }
    }

    Process {
        id: applyWallProc
        onExited: {
            root.walApplying = false
        }
    }

    Process {
        id: ipcColorLoadProc
        command: ["bash", "-c", "echo reload"]
        onExited: {
            root.pywal.reload()
        }
    }

    Process {
        id: initStateDir
        command: ["bash", "-c",
            "mkdir -p '" + root.configPath + "/state' '" + root.wallpaperPath + "' && " +
            "touch '" + root.configPath + "/app_usage.json'"
        ]
        onExited: {
            if (!appListProc.running) appListProc.running = true
            if (!currentWallProc.running) currentWallProc.running = true
            if (!loadSavedGifIndexProc.running) loadSavedGifIndexProc.running = true
            thumbDirProc.running = true
        }
    }

    Process {
        id: loadSavedGifIndexProc
        command: ["bash", "-c", "cat '" + root.statePath + "/gif-index' 2>/dev/null || echo '0'"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                var idx = parseInt(data.trim())
                root.savedGifIndex = isNaN(idx) ? 0 : idx
            }
        }
    }

    Process {
        id: saveStateProc
        property string stateKey: ""
        property string stateValue: ""
        command: ["bash", "-c", "mkdir -p '" + root.statePath + "' && echo '" + stateValue + "' > '" + root.statePath + "/" + stateKey + "'"]
    }

    function saveState(key, value) {
        saveStateProc.stateKey = key
        saveStateProc.stateValue = value
        saveStateProc.running = true
    }

    Component.onCompleted: {
        console.log("QuickShell loaded successfully!")
        initStateDir.running = true
    }
}
