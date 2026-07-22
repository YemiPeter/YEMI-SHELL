//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.compositor
import QtQuick 6.10
import "services" as QsServices
import "singletons" as QsSingletons
import "modules/pill" as Pill

ShellRoot {
    id: root

    // Reference to the bar window (set when BarWrapper loads)
    property var barWindow: null

    // Compositor integration
    readonly property var compositor: Compositor

    // Initialize services immediately
    readonly property var notifs: QsServices.Notifs
    readonly property var matugen: QsServices.Matugen
    readonly property var audio: QsServices.Audio
    readonly property var brightness: QsServices.Brightness

    // === Wallpaper IPC Handler ===
    IpcHandler {
        target: "wallpaper"

        function random(): void {
            randomWallProc.running = true
        }

  function toggle(mon: string): void {
    var target = mon || (compositor.focusedMonitor?.name || "");
    if (target.length > 0)
      QsSingletons.PillState.toggleSurface(target, "wallpaper");
  }

 }
    // === Music IPC Handler ===
    IpcHandler {
        target: "music"

        function toggle(): void {
            root.toggleMusic()
        }
    }

    // === Colors IPC Handler (for matugen) ===
    IpcHandler {
        target: "colors"

        function reload(): void {
            if (!ipcColorLoadProc.running) ipcColorLoadProc.running = true
        }
    }

    // === AltSwitcher IPC Handler ===
    IpcHandler {
        target: "altSwitcher"

        function toggle(): void {
            if (altSwitcherLoader.item) altSwitcherLoader.item.toggle()
        }

        function open(): void {
            if (altSwitcherLoader.item) altSwitcherLoader.item.open()
        }

        function close(): void {
            if (altSwitcherLoader.item) altSwitcherLoader.item.close()
        }

        function next(): void {
            if (altSwitcherLoader.item) altSwitcherLoader.item.next()
        }

        function previous(): void {
            if (altSwitcherLoader.item) altSwitcherLoader.item.previous()
        }
    }

    // === Settings Window State (outside IPC to avoid serialization) ===
    QtObject {
        id: settingsState
        property var settingsWindow: null
    }

    // === Settings IPC Handler ===
    IpcHandler {
        target: "settings"

        function toggle(): void {
            if (!settingsState.settingsWindow) {
                var component = Qt.createComponent("modules/settings/SettingsWindow.qml");
                if (component.status === Component.Ready) {
                    settingsState.settingsWindow = component.createObject(root);
                } else {
                    console.error("❌ Failed to load SettingsWindow:", component.errorString());
                    return;
                }
            }
            
            if (settingsState.settingsWindow) {
                settingsState.settingsWindow.toggle();
            }
        }
    }

    // === Pill IPC Handler ===
    // Single entry point for all pill surfaces. Each function takes a monitor
    // name and toggles that surface via the PillState singleton, which
    // PillOverlay.qml reads to drive the morphing pill.
    //
    // Usage from Hyprland: qs ipc call pill <surface> <monitor>
    // e.g. qs ipc call pill launcher eDP-1
    IpcHandler {
      target: "pill"

      function launcher(mon: string): void {
        var target = mon || (compositor.focusedMonitor?.name || "");
        if (target.length > 0)
          QsSingletons.PillState.toggleSurface(target, "launcher");
      }

      function mixer(mon: string): void {
        var target = mon || (compositor.focusedMonitor?.name || "");
        if (target.length > 0)
          QsSingletons.PillState.toggleSurface(target, "mixer");
      }

      function calendar(mon: string): void {
        var target = mon || (compositor.focusedMonitor?.name || "");
        if (target.length > 0)
          QsSingletons.PillState.toggleSurface(target, "calendar");
      }

      function clipboard(mon: string): void {
        var target = mon || (compositor.focusedMonitor?.name || "");
        if (target.length > 0)
          QsSingletons.PillState.toggleSurface(target, "clipboard");
      }

      function power(mon: string): void {
        var target = mon || (compositor.focusedMonitor?.name || "");
        if (target.length > 0)
          QsSingletons.PillState.toggleSurface(target, "power");
      }

      function settings(mon: string): void {
        var target = mon || (compositor.focusedMonitor?.name || "");
        if (target.length > 0)
          QsSingletons.PillState.toggleSurface(target, "settings");
      }

      function keybinds(mon: string): void {
        var target = mon || (compositor.focusedMonitor?.name || "");
        if (target.length > 0)
          QsSingletons.PillState.toggleSurface(target, "keybinds");
      }

      function wallpaper(mon: string): void {
        var target = mon || (compositor.focusedMonitor?.name || "");
        if (target.length > 0)
          QsSingletons.PillState.toggleSurface(target, "wallpaper");
      }

      function link(mon: string): void {
        var target = mon || (compositor.focusedMonitor?.name || "");
        if (target.length > 0)
          QsSingletons.PillState.toggleSurface(target, "link");
      }

      function media(mon: string): void {
        var target = mon || (compositor.focusedMonitor?.name || "");
        if (target.length > 0)
          QsSingletons.PillState.toggleSurface(target, "media");
      }

      function sysmon(mon: string): void {
        var target = mon || (compositor.focusedMonitor?.name || "");
        if (target.length > 0)
          QsSingletons.PillState.toggleSurface(target, "sysmon");
      }

      function peek(mon: string): void {
        QsSingletons.PillState.peek(mon);
      }

      function hide(): void { QsSingletons.PillState.close(); }
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
        onLoaded: root.barWindow = item
    }


    // Pill overlay windows (one per screen)
    Variants {
        model: Quickshell.screens
        Pill.PillOverlay {
            modelData: modelData
            barWindow: root.barWindow
        }
    }


    // Music Panel
    Loader {
        id: musicPanelLoader
        source: "modules/music/MusicPanel.qml"
    }

    // Alt+Tab window switcher (temporarily disabled — Scope has no visual surface)
    // Next step: convert to PanelWindow, see modules/altswitcher/AltSwitcher.qml header for full status
    // Loader {
    //     id: altSwitcherLoader
    //     source: "modules/altswitcher/AltSwitcher.qml"
    // }
    Item { id: altSwitcherLoader; property var item: null }

    // === Path Properties ===
    property string homePath: Quickshell.env("HOME")
    property string riceHome: Quickshell.env("RICE_HOME") || homePath + "/.config"
    property string configPath: riceHome + "/quickshell"
    property string wallpaperPath: homePath + "/Pictures/Wallpapers"
    property string cachePath: homePath + "/.cache"
    property string statePath: configPath + "/state"

    // === Music Panel State Properties ===
    property bool musicVisible: false
    property int savedGifIndex: 0
    function toggleMusic() { musicVisible = !musicVisible }
    property string wallSearchTerm: ""
    property var wallpaperList: []
    property var filteredWallpapers: {
        if (wallSearchTerm === "") return wallpaperList
        var result = []
        for (var i = 0; i < wallpaperList.length; i++)
            if (wallpaperList[i].name.toLowerCase().includes(wallSearchTerm))
                result.push(wallpaperList[i])
        return result
    }
    property int wallSelectedIndex: 0
    property string currentWallpaper: ""
    property bool wallsLoaded: false
    property bool thumbsReady: false
    property bool walApplying: false
    property var wallpaperHashes: ({})

    function applyWallpaper(wallpaper) {
        root.currentWallpaper = wallpaper.path
        root.walApplying = true
 applyWallProc.command = ["bash", "-c", "skwd wall apply '{\"name\":\"'" + wallpaper.name + "'\"}'"]
 applyWallProc.running = true
    }

    function loadWallpapers() {
        root.wallpaperList = []
        root.wallsLoaded = false
        root.thumbsReady = false
        if (!wallpaperListProc.running) wallpaperListProc.running = true
    }

    // === Processes ===
    Process { id: launchProc }

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
        command: ["bash", "-c", "for f in '" + root.wallpaperPath + "/*'; do [ -f \"$f\" ] && echo \"$f|$(echo -n \"$f\" | md5sum | cut -d' ' -f1)\"; done"]
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
            root.matugen.reload()
        }
    }

    Process {
        id: initStateDir
        command: ["bash", "-c",
            "mkdir -p '" + root.configPath + "/state' '" + root.wallpaperPath + "' && " +
            "touch '" + root.configPath + "/app_usage.json'"
        ]
        onExited: {
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