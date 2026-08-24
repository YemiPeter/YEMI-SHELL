pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../modules/pill/lib/binds.js" as Binds

// ConflictKiller — resolves conflicting keybinds / settings.
// Shell by Yemi service. Two classes of conflict are handled:
//   1. Duplicate keybinds: the same chord bound to two actions in
//      $RICE_HOME/hypr/modules/binds.lua (parsed with the pill's Binds lib).
//   2. Shared-surface claims: modules register ownership of a finite resource
//      ("tray", "notifications", …). When two owners claim the same resource the
//      matching `_traysConflict` / `_notifsConflict` flag trips and the conflict
//      is surfaced so the UI can arbitrate via killDialogQmlPath.
// Convention: safe defaults, plain English,
// `_log()` debug gating, Notifications.send, and an IpcHandler.
Singleton {
    id: root

    // ── Paths ──────────────────────────────────────────────────────────────
    readonly property string bindsPath: {
        const rh = Quickshell.env("RICE_HOME")
        const base = rh && rh.length ? rh : (Quickshell.env("HOME") + "/.config")
        return base + "/hypr/modules/binds.lua"
    }

    readonly property string killDialogQmlPath: {
        const rh = Quickshell.env("RICE_HOME")
        const base = rh && rh.length ? rh : (Quickshell.env("HOME") + "/.config")
        return base + "/quickshell/modules/pill/ConflictKillDialog.qml"
    }

    // ── State ──────────────────────────────────────────────────────────────
    property bool ready: false

    // Duplicate keybind groups: [{ combo, count, lines:[int], labels:[str] }]
    property var keybindConflicts: []

    // Resource → list of owner ids that have claimed it.
    property var _claims: ({})

    readonly property bool _traysConflict: (_claims["tray"] || []).length > 1
    readonly property bool _notifsConflict: (_claims["notifications"] || []).length > 1

    // Aggregated, human-readable conflict list for the UI / IPC.
    property var conflicts: []

    property bool _notifiedKeybinds: false
    property bool _notifiedTray: false
    property bool _notifiedNotifs: false

    // ── Public API ─────────────────────────────────────────────────────────
    function load() {
        _rescan()
        _recompute()
        root.ready = true
        root.onReadyChanged()
        root._maybeHandleConflicts()
        _log("loaded", root.conflicts.length, "conflict(s)")
    }

    function onReadyChanged() {
        // Hook for consumers; placeholder matches the service's public shape.
    }

    /// Register `ownerId` as the owner of a shared `resource` (e.g. "tray").
    /// Returns true if the claim was new, false if already held by this owner.
    function claim(resource, ownerId) {
        if (!resource || !ownerId)
            return false
        const list = root._claims[resource] || []
        if (list.indexOf(ownerId) !== -1)
            return false
        const next = root._claims
        next[resource] = list.concat([ownerId])
        root._claims = next
        _recompute()
        root._maybeHandleConflicts()
        _log("claim", resource, "by", ownerId, "->", JSON.stringify(root._claims[resource]))
        return true
    }

    /// Release `ownerId`'s claim on `resource`.
    function release(resource, ownerId) {
        if (!resource || !ownerId)
            return
        const list = root._claims[resource] || []
        const idx = list.indexOf(ownerId)
        if (idx === -1)
            return
        const next = root._claims
        next[resource] = list.filter((id) => id !== ownerId)
        root._claims = next
        _recompute()
        _log("release", resource, "by", ownerId)
    }

    function registerTray(ownerId) { return root.claim("tray", ownerId) }
    function registerNotifs(ownerId) { return root.claim("notifications", ownerId) }
    function releaseTray(ownerId) { root.release("tray", ownerId) }
    function releaseNotifs(ownerId) { root.release("notifications", ownerId) }

    /// Force a re-read of the binds file.
    function scan() {
        _rescan()
        _recompute()
        root._maybeHandleConflicts()
        return JSON.stringify(root.conflicts)
    }

    function status() {
        return JSON.stringify({
            ready: root.ready,
            keybindConflicts: root.keybindConflicts.length,
            traysConflict: root._traysConflict,
            notifsConflict: root._notifsConflict,
            conflicts: root.conflicts
        })
    }

    // ── Internal ───────────────────────────────────────────────────────────
    function _log() {
        if (Quickshell.env("QS_DEBUG") === "1")
            console.log("[ConflictKiller]", arguments[0], arguments[1], arguments[2], arguments[3])
    }

    function _rescan() {
        const text = bindsFile.text()
        root.keybindConflicts = _scanKeybinds(text)
    }

    function _scanKeybinds(text) {
        if (!text || !text.length)
            return []
        const binds = Binds.parse(text)
        const groups = {}
        for (let i = 0; i < binds.length; i++) {
            const b = binds[i]
            const norm = (b.combo || "").toLowerCase().replace(/\s+/g, " ").trim()
            if (!norm)
                continue
            if (!groups[norm])
                groups[norm] = []
            groups[norm].push(b)
        }
        const out = []
        for (const k in groups) {
            const g = groups[k]
            if (g.length > 1) {
                out.push({
                    combo: g[0].combo,
                    count: g.length,
                    lines: g.map((x) => x.lineIndex),
                    labels: g.map((x) => x.label || x.name || x.dispatcher)
                })
            }
        }
        return out
    }

    function _recompute() {
        const list = []
        for (let i = 0; i < root.keybindConflicts.length; i++) {
            const k = root.keybindConflicts[i]
            list.push({
                type: "keybind",
                combo: k.combo,
                count: k.count,
                detail: k.combo + " bound " + k.count + "× (" + k.labels.join(", ") + ")"
            })
        }
        if (root._traysConflict) {
            list.push({
                type: "tray",
                owners: root._claims["tray"],
                detail: "Multiple owners of the system tray: " + root._claims["tray"].join(", ")
            })
        }
        if (root._notifsConflict) {
            list.push({
                type: "notifications",
                owners: root._claims["notifications"],
                detail: "Multiple owners of notifications: " + root._claims["notifications"].join(", ")
            })
        }
        root.conflicts = list
    }

    function _maybeHandleConflicts() {
        if (root.keybindConflicts.length > 0 && !root._notifiedKeybinds) {
            root._notifiedKeybinds = true
            const n = root.keybindConflicts.length
            Notifications.send({
                appName: "Quickshell",
                summary: n + " conflicting keybind" + (n === 1 ? "" : "s") + " detected",
                body: "Open the Keybinds surface to resolve duplicate chords.",
                icon: "dialog-warning-symbolic",
                urgency: NotificationUrgency.Normal,
                timeout: 8000
            })
        }
        if (root._traysConflict && !root._notifiedTray) {
            root._notifiedTray = true
            Notifications.send({
                appName: "Quickshell",
                summary: "Tray ownership conflict",
                body: "More than one surface owns the system tray.",
                icon: "dialog-warning-symbolic",
                urgency: NotificationUrgency.Low,
                timeout: 6000
            })
        }
        if (root._notifsConflict && !root._notifiedNotifs) {
            root._notifiedNotifs = true
            Notifications.send({
                appName: "Quickshell",
                summary: "Notification ownership conflict",
                body: "More than one surface owns notifications.",
                icon: "dialog-warning-symbolic",
                urgency: NotificationUrgency.Low,
                timeout: 6000
            })
        }
    }

    // ── Bindings / IO ──────────────────────────────────────────────────────
    FileView {
        id: bindsFile
        path: root.bindsPath
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: {
            root.keybindConflicts = root._scanKeybinds(bindsFile.text())
            root._recompute()
            root._maybeHandleConflicts()
        }
        onFileChanged: reload()
    }

    // ── IPC ────────────────────────────────────────────────────────────────
    IpcHandler {
        target: "conflict"
        function scan() { return root.scan() }
        function status() { return root.status() }
        function claim(resource, owner) { return root.claim(resource, owner) ? "claimed" : "already" }
        function release(resource, owner) { root.release(resource, owner); return "released" }
    }

    Component.onCompleted: root.load()
}
