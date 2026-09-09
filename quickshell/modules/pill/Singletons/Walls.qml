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
 * newest-first and finally re-reads the state file wallpaper.sh maintains, so
 * `current` always names the wallpaper on screen. Thumbnails land before the
 * list so strip delegates never bind to a not-yet-existing file; a refresh
 * arriving while the pipeline runs sets `pending` and replays once the state
 * lands. Applying routes through wallpaper.sh so the picker shares the exact
 * transition, palette and state path with the random keybind.
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
     * wallpaper.sh blocks through the whole transition (awww wave, wallust,
     * reload), easily 1-2s; a pick landing in that window used to be silently
     * swallowed. Now the newest request is queued and replayed once the
     * running transition exits, so rapid iteration converges on the last pick.
     */
    property string queuedApply: ""
    property string lastAppliedPath: ""

    function apply(path) {
        if (applyProc.running) {
            queuedApply = path;
            return;
        }
        root.lastAppliedPath = path;
        // "Hide main wallpaper": don't push the pick to the external wallpaper
        // daemon (skwd/wallpaper.sh) — the QuickShell backdrop overlay is the
        // sole renderer, matching iNiR's backdrop.hideWallpaper semantics.
        // Keep the in-memory current so Backdrop shows the pick, and still run
        // the color pipeline.
        // Niri-only: no Backdrop on Hyprland, so never skip the real paint (awww) here.
        if (QsSingletons.Flags.backdropHideWallpaper && Compositor.isNiri) {
            root.current = path;
            // Still record the pick in the state file: WallpaperState (which
            // Backdrop actually renders) watches it, and it lets the awww
            // restore (toggle off / next login) land on the last pick.
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
        command: ["sh", "-c", "find \"$1\" -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \\) -printf '%T@\\t%p\\n' | sort -rn", "_", root.wpDir]
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

    Component.onCompleted: {
        refresh();
        syncAwww(QsSingletons.Flags.backdropHideWallpaper);
    }

    // ── "Hide wallpaper" ↔ awww lifecycle ────────────────────────────────────
    // Niri: when the setting is ON, the awww background layer is killed so the
    // QML Backdrop becomes the only wallpaper. When turned OFF (or at startup
    // with the setting OFF), awww is brought back painting the state file's
    // pick via the dispatcher's init. Hyprland keeps awww alive regardless —
    // killing it there would leave a black desktop under the overlay.
    function syncAwww(hide) {
        if (!Compositor.isNiri)
            return;
        if (hide) {
            killProc.running = true;
        } else if (!restoreProc.running) {
            restoreProc.running = true;
        }
    }

    Connections {
        target: QsSingletons.Flags
        function onBackdropHideWallpaperChanged() {
            root.syncAwww(QsSingletons.Flags.backdropHideWallpaper);
        }
    }

    Process {
        id: killProc
        // Kill the awww background layer so the QML Backdrop becomes the sole
        // renderer. The old freeze-to-memory write (quickshell-wallpaper-awww)
        // was removed: restoreProc now reads the live state file, so the frozen
        // value had no remaining consumer and only ever went stale (it captured
        // what awww showed at hide-time, not the current on-screen pick).
        command: ["bash", "-c", "pkill -x awww-daemon || true"]
    }

    Process {
        id: restoreProc
        // Bring awww back in sync with the real on-screen pick. Reads the live
        // state file (quickshell-wallpaper) — NOT a frozen awww memory file —
        // because picks made while the backdrop owned the screen never reach
        // any awww-owned state; restoring from a stale frozen path reverted
        // awww to an old image on every startup even though Backdrop (state
        // file) was correct. Falls back to set-wallpaper.sh init when the
        // state file is empty or names a missing file.
        // Uses "restore" — not "set" — so set-wallpaper.sh only does the paint
        // step (ensure_daemon + awww img) and intentionally SKIPS writing to
        // the real state file, skipping after-wall.sh, and skipping hyprctl
        // reload.
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
