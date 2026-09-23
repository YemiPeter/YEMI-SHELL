pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.compositor
import "../../../singletons" as QsSingletons

/**
 * Wallpaper bridge: keeps a warm in-memory snapshot of ~/Pictures/Wallpapers so
 * the wallpaper strip opens instantly without shelling out on demand. A
 * refresh first runs the thumbnail script (generating missing 512px previews
 * and pruning ones whose source is gone), then re-lists the directory
 * newest-first and finally re-reads the state file set-wallpaper.sh maintains,
 * so `current` always names the wallpaper on screen. Thumbnails land before
 * the list so strip delegates never bind to a not-yet-existing file; a
 * refresh arriving while the pipeline runs sets `pending` and replays once
 * the state lands. Applying routes through set-wallpaper.sh so the picker
 * shares the exact paint, palette and state path with the random keybind.
 *
 * Entries are plain objects: { path, name, mtime, thumb } where path is the
 * absolute source file, mtime its modification time in epoch seconds and
 * thumb the absolute path of the cached preview png.
 */
Singleton {
    id: root

    property var entries: []
    readonly property int count: entries.length
    property string current: ""
    property bool pending: false

    readonly property string wpDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property string thumbDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/quickshell-wp-thumbs/"
    readonly property string thumbScript: (Quickshell.env("RICE_HOME") || (Quickshell.env("HOME") + "/.config")) + "/hypr/scripts/wallpaper-thumbs.sh"
    // Single compositor-aware dispatcher (set-wallpaper.sh). Resolved against
    // RICE_HOME with a real fallback so Niri — which has no hypr/ dir — still
    // finds it. The compositor is passed in explicitly (never re-detected).
    readonly property string setScript: (Quickshell.env("RICE_HOME") || (Quickshell.env("HOME") + "/.config")) + "/quickshell/scripts/set-wallpaper.sh"
    readonly property string stateFile: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell-wallpaper"

    function refresh() {
        if (thumbProc.running || listProc.running || stateProc.running) {
            pending = true;
            return;
        }
        thumbProc.running = true;
    }

    /**
     * set-wallpaper.sh blocks through the whole paint + color pipeline,
     * easily 1-2s; a pick landing in that window used to be silently
     * swallowed. Now the newest request is queued and replayed once the
     * running paint exits, so rapid iteration converges on the last pick.
     */
    property string queuedApply: ""
    property string lastAppliedPath: ""

    function apply(path) {
        if (applyProc.running) {
            queuedApply = path;
            return;
        }
        root.lastAppliedPath = path;
        // "Hide main wallpaper": don't push the pick to skwd — the QuickShell
        // backdrop overlay is the sole renderer, matching iNiR's
        // backdrop.hideWallpaper semantics.
        // Keep the in-memory current so Backdrop shows the pick, and still run
        // the color pipeline.
        // Niri-only: no Backdrop on Hyprland, so never skip the real paint (skwd) here.
        if (QsSingletons.Flags.backdropHideWallpaper && Compositor.isNiri) {
            root.current = path;
            // Still record the pick in the state file: WallpaperState (which
            // Backdrop actually renders) watches it, and it lets the skwd
            // resume / next-login restore land on the last pick.
            stateWriteProc.wallPath = path;
            stateWriteProc.running = true;
            afterWallProc.wallPath = path;
            afterWallProc.running = true;
            return;
        }
        applyProc.command = ["bash", root.setScript, Compositor.runningCompositor, "set", path];
        applyProc.running = true;
    }

    function trash(path) {
        trashProc.command = ["gio", "trash", path];
        trashProc.running = true;
        var kept = [];
        for (var i = 0; i < entries.length; i++)
            if (entries[i].path !== path)
                kept.push(entries[i]);
        entries = kept;
    }

    Process {
        id: trashProc
        onExited: function(exitCode) {
            if (exitCode !== 0)
                root.refresh();
        }
    }

    Process {
        id: thumbProc
        command: ["sh", root.thumbScript]
        onExited: listProc.running = true
    }

    Process {
        id: listProc
        command: ["sh", "-c", "find \"$1\" -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \\) -printf '%T@\\t%p\\n' | sort -rn", "_", root.wpDir]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n");
                var out = [];
                for (var i = 0; i < lines.length; i++) {
                    var tab = lines[i].indexOf("\t");
                    if (tab < 1)
                        continue;
                    var path = lines[i].substring(tab + 1);
                    var name = path.substring(path.lastIndexOf("/") + 1);
                    out.push({
                        path: path,
                        name: name,
                        mtime: parseFloat(lines[i].substring(0, tab)),
                        thumb: root.thumbDir + name + ".png"
                    });
                }
                // A no-op refresh used to reassign `entries` unconditionally,
                // resetting the strip's model on every open — every visible
                // tile was torn down and its thumbnail re-decoded from disk
                // mid-morph (the recurring blank-thumb flash). Skip the
                // assignment when the listing is identical (paths + mtimes).
                var old = root.entries;
                var same = old.length === out.length;
                for (var i = 0; same && i < out.length; i++)
                    same = old[i].path === out[i].path && old[i].mtime === out[i].mtime;
                if (!same)
                    root.entries = out;
                stateProc.running = true;
            }
        }
    }

    Process {
        id: stateProc
        command: ["sh", "-c", "cat \"$1\" 2>/dev/null || true", "_", root.stateFile]
        stdout: StdioCollector {
            onStreamFinished: {
                // While "hide main wallpaper" is on the external daemon never
                // wrote the state file, so keep showing the applied pick.
                if (QsSingletons.Flags.backdropHideWallpaper)
                    root.current = root.lastAppliedPath;
                else
                    root.current = this.text.trim();
                if (root.pending) {
                    root.pending = false;
                    Qt.callLater(root.refresh);
                }
            }
        }
    }

    Process {
        id: applyProc
        onExited: function(exitCode) {
                // The dispatcher already ran the single color writer (after-wall.sh);
                // just refresh the in-memory current from the state file.
                if (exitCode === 0) {
                    stateProc.running = true
                } else if (!root.queuedApply.length) {
                    stateProc.running = true   // only run directly if apply failed
                }

                if (root.queuedApply.length) {
                    var next = root.queuedApply;
                    root.queuedApply = "";
                    root.lastAppliedPath = next;
                    applyProc.command = ["bash", root.setScript, Compositor.runningCompositor, "set", next];
                    applyProc.running = true;
                    return;
                }
            }
    }

    Process {
        id: afterWallProc
        property string wallPath: ""
        property string mood: QsSingletons.Flags.systemMood
        command: ["bash",
                  Quickshell.env("RICE_HOME") + "/quickshell/scripts/after-wall.sh",
                  mood,
                  wallPath]
        onExited: stateProc.running = true
    }

    // ── skwd-picker return path ──────────────────────────────────────────────
    // $mod+Shift+W opens skwd's OWN picker, which never touches
    // set-wallpaper.sh. Without this watcher such a pick repainted the
    // wallpaper but left the state file and the whole palette stale — skwd
    // still emits skwd.wall.applied, so skwd-wall-sync.sh consumes that event,
    // writes the state file and re-runs the single color writer. Idempotent
    // with the dispatcher: picks that DID go through set-wallpaper.sh produce
    // the same path, so the sync script sees no change and skips re-theming.
    Process {
        id: skwdSyncProc
        // Hyprland-only for now: that is the compositor this return path was
        // verified on. Niri keeps its existing backdrop lifecycle untouched.
        running: Compositor.isHyprland
        command: ["bash", (Quickshell.env("RICE_HOME") || (Quickshell.env("HOME") + "/.config")) + "/quickshell/scripts/skwd-wall-sync.sh"]
        onExited: skwdSyncRestart.start()
    }

    Timer {
        id: skwdSyncRestart
        interval: 2000
        onTriggered: if (!skwdSyncProc.running) skwdSyncProc.running = true
    }

    Component.onCompleted: {
        refresh();
        syncSkwd(QsSingletons.Flags.backdropHideWallpaper, true);
    }

    // ── Hyprland startup self-heal ───────────────────────────────────────────
    // The login paint is done by autostart.lua's detached `set-wallpaper.sh
    // hyprland init`, which now waits out skwd-walld's slow session detection
    // (~56s at boot) before applying. syncSkwd() below is a Niri-only path, so
    // on Hyprland nothing here previously noticed if that init had failed —
    // the session simply kept a bare desktop until the user re-picked.
    //
    // One best-effort "restore" once skwd's helm IPC answers, which is idempotent
    // with the init (both re-apply the same state-file pick; skwd treats a
    // repeat apply of the current wallpaper as a no-op). Cheap insurance, and
    // it converges the desktop on the last pick if init lost the race for any
    // reason. Runs once per shell start, not on a timer.
    Process {
        id: hyprStartupRestore
        running: Compositor.isHyprland
        command: ["bash", "-c",
                  "S=\"${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/skwd-wall-v2/wall.sock\"; " +
                  "for i in $(seq 1 180); do [ -S \"$S\" ] && break; sleep 0.5; done; " +
                  "P=$(cat \"$1\" 2>/dev/null); " +
                  "if [ -n \"$P\" ] && [ -f \"$P\" ]; then " +
                  "  exec bash \"$2\" hyprland restore \"$P\"; " +
                  "else " +
                  "  exec bash \"$2\" hyprland init; " +
                  "fi",
                  "_", root.stateFile, root.setScript]
    }

    // ── "Hide wallpaper" ↔ skwd lifecycle ────────────────────────────────────
    // Niri: when the setting is ON, skwd's paint is frozen (skwd-helm pause)
    // so the QML Backdrop becomes the only renderer; when turned OFF (or at
    // startup with the setting OFF) it is resumed. Hyprland keeps skwd
    // painting regardless — pausing it there would leave a frozen desktop
    // under the shell. (skwd-helm pause/resume replaces the old awww
    // kill/restore lifecycle; awww was retired.)
    function syncSkwd(hide, initial) {
        if (!Compositor.isNiri)
            return;
        if (hide) {
            pauseProc.running = true;
        } else if (initial) {
            // Startup with hide OFF: skwd repaints its own last wallpaper on
            // launch, but the state file is the shell's source of truth and
            // the two can diverge (e.g. picks made while the backdrop owned
            // the screen). Re-apply the state-file pick via the dispatcher's
            // "restore" — paint only, no state write, no color pipeline.
            syncProc.running = true;
        } else {
            resumeProc.running = true;
        }
    }

    Connections {
        target: QsSingletons.Flags
        function onBackdropHideWallpaperChanged() {
            root.syncSkwd(QsSingletons.Flags.backdropHideWallpaper, false);
        }
    }

    Process {
        id: pauseProc
        command: ["skwd-helm", "pause"]
    }

    Process {
        id: resumeProc
        command: ["skwd-helm", "resume"]
    }

    Process {
        id: syncProc
        // Startup sync (Niri, hide OFF): bring skwd onto the state file's
        // pick via set-wallpaper.sh restore. Falls back to init when the
        // state file is empty or names a missing file.
        command: ["bash", "-c",
                  "P=$(cat \"$1\" 2>/dev/null); " +
                  "if [ -n \"$P\" ] && [ -f \"$P\" ]; then " +
                  "  exec bash \"$2\" \"$3\" restore \"$P\"; " +
                  "else " +
                  "  exec bash \"$2\" \"$3\" init; " +
                  "fi",
                  "_", root.stateFile, root.setScript, Compositor.runningCompositor]
    }

    Process {
        id: stateWriteProc
        property string wallPath: ""
        command: ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s\\n' \"$2\" > \"$1\"", "_", root.stateFile, wallPath]
    }
}
