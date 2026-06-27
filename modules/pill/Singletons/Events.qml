pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Local calendar events, persisted as a plain JSON array beside the session
 * flags (~/.local/state/quickshell/events.json). The in-memory `events` is the
 * source of truth: add/remove mutate it and write the file, which is read back
 * only at startup. The file is deliberately NOT watched — re-reading our own
 * write races the FileView's cached text and dropped the just-added event (it
 * flashed in, then vanished until the next write). The file holds an array
 * of { id, date, endDate, time, endTime, text } with date/endDate as "YYYY-MM-DD".
 * endDate is "" for a single-day entry, otherwise the last day a multi-day span
 * covers. time and endTime may be "" for an all-day or open-ended entry. Because
 * the keys are zero-padded "YYYY-MM-DD", a plain string compare orders and spans
 * dates correctly, so coverage tests need no Date parsing.
 *
 * A bare array is simpler than a JsonAdapter for a growing list: read the text,
 * JSON.parse, mutate the array, JSON.stringify back through setText. Every parse
 * is guarded so a truncated or corrupt file never throws and never wipes the
 * singleton — a bad read just leaves the last good `events` in place.
 *
 * Ids come from a monotonic counter seeded past the highest id already on disk,
 * never Date.now() or Math.random() (both throw in this engine), so every add is
 * uniquely addressable for remove() even within the same minute.
 */
Singleton {
    id: root

    // ADAPTED: ricelin → quickshell
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell"

    property var events: []
    property int nextId: 1

    /**
     * Re-read the file text into `events` and advance the id counter past every
     * id present, so a freshly added event can never collide with one loaded
     * from disk. A FileNotFound or malformed body is treated as an empty list.
     */
    function reloadEvents() {
        var arr = [];
        try {
            var t = file.text();
            if (t && t.trim().length > 0) {
                var parsed = JSON.parse(t);
                if (Array.isArray(parsed))
                    arr = parsed;
            }
        } catch (e) {
            arr = [];
        }
        var maxId = 0;
        for (var i = 0; i < arr.length; i++) {
            var n = Number(arr[i].id);
            if (n > maxId) maxId = n;
        }
        root.nextId = maxId + 1;
        root.events = arr;
    }

    function filePath() { return stateDir + "/events.json"; }

    function add(date, endDate, time, endTime, text) {
        var ev = { id: String(nextId), date: date, endDate: endDate || "", time: time || "", endTime: endTime || "", text: text };
        events.push(ev);
        nextId++;
        writeEvents();
    }

    function remove(id) {
        for (var i = events.length - 1; i >= 0; i--)
            if (events[i].id === String(id)) events.splice(i, 1);
        writeEvents();
    }

    function writeEvents() {
        file.setText(JSON.stringify(events));
    }

    FileView {
        id: file
        path: root.filePath()
        blockLoading: true
        printErrors: false
    }

    Component.onCompleted: reloadEvents()
}
