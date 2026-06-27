pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * cliphist bridge: keeps a warm in-memory snapshot of the clipboard history so
 * the clipboard surface opens instantly without shelling out on demand. A
 * wl-paste watcher fires on every clipboard change; after a short debounce the
 * thumbnail script regenerates missing image previews (and prunes stale ones),
 * then `cliphist list` is re-read into `entries`. Thumbnails are written before
 * the list lands so image delegates never bind to a not-yet-existing file. A
 * change arriving while the pipeline runs sets `pending` and replays once the
 * list lands, so no clipboard event is ever silently dropped; the watcher
 * respawns through a cooldown timer if wl-paste dies.
 *
 * Entries are plain objects: { id, preview, isImage, meta, label, sizeLabel,
 * thumb } where meta is cliphist's raw binary descriptor ("245 KiB png
 * 1920x1080"), label/sizeLabel its display split ("png 1920×1080" / "245 KiB")
 * and thumb the absolute path of the cached preview png (empty for text).
 */
Singleton {
    id: root

    property var entries: []
    readonly property int count: entries.length
    property bool pending: false

    // ADAPTED: ricelin → quickshell
    readonly property string thumbDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/quickshell/cliphist-thumbs/"
    readonly property string thumbScript: Quickshell.env("HOME") + "/.config/quickshell/scripts/cliphist-thumbs.sh"

    function refresh() {
        if (thumbProc.running || listProc.running || delProc.running || delQueue.length) {
            pending = true;
            return;
        }
        thumbProc.running = true;
    }

    function copy(entry) {
        if (!/^\d+$/.test(String(entry.id))) return;
        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "_", String(entry.id)]);
    }

    function wipe() {
        entries = [];
        wipeProc.running = true;
    }

    /**
     * Deletes are queued through a tracked process and any refresh is held
     * until the queue drains: a fire-and-forget delete racing an in-flight
     * `cliphist list` used to resurrect the removed entry from the stale
     * snapshot. The local prune stays optimistic so the row vanishes
     * immediately.
     */
    property var delQueue: []

    function remove(entry) {
        if (!entry || !entry.id) return;
        delQueue.push(entry);
        if (delProc.running) return;
        delProc.running = true;
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

    // --- List refresh ---
    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n");
                var out = [];
                for (var i = 0; i < lines.length; i++) {
                    if (!lines[i].trim()) continue;
                    var parts = lines[i].split("\t");
                    out.push({
                        id: parts[0] || "",
                        preview: parts[1] || "",
                        isImage: false,
                        meta: parts[2] || "",
                        label: "",
                        sizeLabel: "",
                        thumb: ""
                    });
                }
                root.entries = out;
                // Process any queued deletes
                if (root.delQueue.length > 0) {
                    var entry = root.delQueue.shift();
                    delByIdProc.command = ["cliphist", "del", String(entry.id)];
                    delByIdProc.running = true;
                } else {
                    thumbProc.running = false;
                }
                if (root.pending) {
                    root.pending = false;
                    root.refresh();
                }
            }
        }
        running: false
    }

    Process {
        id: delByIdProc
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.delQueue.length > 0) {
                    var entry = root.delQueue.shift();
                    delByIdProc.command = ["cliphist", "del", String(entry.id)];
                    delByIdProc.running = true;
                } else {
                    delProc.running = false;
                    root.refresh();
                }
            }
        }
    }

    Process {
        id: delProc
        command: ["cliphist", "wipe"]
        running: false
    }

    Process {
        id: wipeProc
        command: ["cliphist", "wipe"]
        running: false
    }

    // --- wl-paste watcher ---
    Timer {
        id: watchTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            watchProc.running = true;
        }
    }

    Process {
        id: watchProc
        command: ["wl-paste", "-t", "text", "-w", "echo"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    root.refresh();
            }
        }
    }

    Component.onCompleted: refresh()
}
