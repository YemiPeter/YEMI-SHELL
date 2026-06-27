pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Wallpaper bridge: keeps a warm in-memory snapshot of the wallpaper directory
 * so the wallpaper strip opens instantly without shelling out on demand. A
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
 *
 * ADAPTED: Paths changed from ~/Ricelin/wallpapers to ~/Pictures/wallpapers
 * and scripts from .config/hypr/scripts to .config/quickshell/scripts.
 */
Singleton {
    id: root

    property var entries: []
    readonly property int count: entries.length
    property string current: ""
    property bool pending: false

    // ADAPTED: Ricelin-specific paths → quickshell paths
    readonly property string wpDir: Quickshell.env("HOME") + "/Pictures/wallpapers"
    readonly property string thumbDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/quickshell-wp-thumbs/"
    readonly property string thumbScript: Quickshell.env("HOME") + "/.config/quickshell/scripts/wallpaper-thumbs.sh"
    readonly property string setScript: Quickshell.env("HOME") + "/.config/quickshell/scripts/wallpaper.sh"
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

    function apply(path) {
        if (applyProc.running) {
            queuedApply = path;
            return;
        }
        applyProc.command = ["bash", root.setScript, "set", path];
        applyProc.running = true;
    }

    function random() {
        if (applyProc.running) {
            queuedApply = "random";
            return;
        }
        applyProc.command = ["bash", root.setScript, "random"];
        applyProc.running = true;
    }

    // --- Thumbnail generation ---
    Process {
        id: thumbProc
        command: ["bash", root.thumbScript]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                listProc.running = true;
            }
        }
    }

    // --- Directory listing ---
    Process {
        id: listProc
        command: ["find", root.wpDir, "-type", "f", "-printf", "%T@\t%p\n"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n");
                var out = [];
                for (var i = 0; i < lines.length; i++) {
                    if (!lines[i].trim()) continue;
                    var parts = lines[i].split("\t");
                    var mtime = parseFloat(parts[0]) || 0;
                    var path = parts[1] || "";
                    var name = path.split("/").pop();
                    var thumb = root.thumbDir + name + ".png";
                    out.push({ path: path, name: name, mtime: mtime, thumb: thumb });
                }
                out.sort(function(a, b) { return b.mtime - a.mtime; });
                root.entries = out;
                stateProc.running = true;
            }
        }
        running: false
    }

    // --- State file (current wallpaper) ---
    FileView {
        id: stateFileView
        path: root.stateFile
        blockLoading: true
        printErrors: false
    }

    Process {
        id: stateProc
        command: ["cat", root.stateFile]
        stdout: StdioCollector {
            onStreamFinished: {
                root.current = text.trim();
                if (root.pending) {
                    root.pending = false;
                    root.refresh();
                }
            }
        }
        running: false
    }

    Process {
        id: applyProc
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.queuedApply.length > 0) {
                    var next = root.queuedApply;
                    root.queuedApply = "";
                    if (next === "random") root.random();
                    else root.apply(next);
                } else {
                    root.refresh();
                }
            }
        }
    }

    Component.onCompleted: {
        refresh();
        root.current = stateFileView.text().trim();
    }
}
