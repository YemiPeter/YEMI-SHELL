import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Widgets
import "../../services" as QsServices
import "../../singletons" as QsSingletons
import "../../compositor" as QsCompositor
import "../pill/lib/setDeco.js" as SetDeco

/**
 * AltSwitcher — the Alt+Tab window overview.
 *
 * A full-screen overlay (niri + Hyprland) that shows every open window as a
 * frosted glass tile, navigable with Alt+Tab / Alt+Shift+Tab and focusable with
 * a click. The whole feature is gated by Flags.altSwitcherEnabled (toggle in
 * Appearance settings), mirroring iNiR's "button so it can be toggled on/off".
 *
 * Keyboard is NOT grabbed on purpose (beyond the overlay's own arrow/Enter/Esc
 * handling): navigation is driven by compositor keybinds that call
 * `qs ipc call altSwitcher next|previous` — niri Alt+Tab / Alt+Shift+Tab in
 * config.d/70-binds.kdl, Hyprland ALT/ALT SHIFT+Tab in hypr modules/binds.lua.
 * Tapping Tab cycles without a focus fight between the overlay and the
 * compositor. Mod+Tab is left to niri's own toggle-overview.
 *
 * Navigation follows focus recency (most recently used first, like iNiR's
 * "Most recently used first" default), so a fresh press lands on the window you
 * came from. Consecutive presses then walk the frozen snapshot one window at a
 * time (Alt+Tab forward, Alt+Shift+Tab backward) for walkHoldMs after the last
 * press, so cycling is a clean cycle at any pace — no reshuffling, no bouncing
 * between two windows. The walk ends when it goes idle, when focus moves to a
 * window the walk did not target, or on explicit dismissal.
 */
Scope {
    id: root

    // ── Tunables ──────────────────────────────────────────────────────────────
    readonly property real scrimDim: 0.35          // 0..1 darkness behind the glass
    // Frosted backdrop via compositor BackgroundEffect (ext-background-effect):
    // niri-only. Hyprland doesn't implement that protocol — its blur comes from
    // the `layerrule = blur on, match:namespace quickshell*` rules in
    // hyprland.conf, which already cover this overlay's layer namespace.
    readonly property bool blurGlass: compositor.isNiri
    readonly property int tileWidth: 224
    readonly property int tileHeight: 116
    readonly property int tileGap: 12

    // ── Theme tokens ─────────────────────────────────────────────────────────
    readonly property color cSurface: QsSingletons.Theme.cardBot
    readonly property color cPrimary: QsSingletons.Theme.onGlow
    readonly property color cText: QsSingletons.Theme.cream
    readonly property color cSubText: Qt.alpha(QsSingletons.Theme.cream, 0.6)
    readonly property color cBorder: Qt.alpha(QsSingletons.Theme.cream, 0.10)

    // ── Compositor data ───────────────────────────────────────────────────────
    readonly property var compositor: QsCompositor.Compositor
    readonly property bool isNiri: compositor.runningCompositor === "niri"
    readonly property bool isHyprland: compositor.runningCompositor === "hyprland"

    // ── Runtime state ──────────────────────────────────────────────────────────
    property bool open: false
    property int currentIndex: 0
    readonly property real s: QsSingletons.Flags.uiScale

    // Shared pointer baseline for the hover-select handlers (see the delegates).
    // lastPointer stores the last hover sample; pointerPrimed is false until the
    // first sample of each open has been consumed as that run's baseline. A layer
    // surface mapped under a parked cursor receives a synthesised enter/hover at
    // the pointer position — consuming it as the baseline means it can never
    // select a tile by itself; only a sample at a *different* position (a real
    // pointer move) drives the selection.
    property point lastPointer: Qt.point(0, 0)
    property bool pointerPrimed: false

    // ── Run snapshot (the walk) ────────────────────────────────────────────────
    // A "run" is one Alt+Tab walk: it starts on a fresh press, keeps its cursor
    // across consecutive presses, and ends when it goes idle (walkHoldMs), when
    // focus moves to a window the walk did not target, or on explicit dismissal
    // (Esc, click-away, toggle-off). Navigation always walks a FROZEN copy of
    // the window list taken at run start. The live list reorders on every focus
    // change (a focus event moves the focused window in the raw toplevel order,
    // and the MRU sort reorders by design), so navigating live indices lands on
    // shifted entries — the "switcher keeps going back to the same window" /
    // "windows just switch like a mix" symptoms. Re-snapshotting per tap has the
    // same flaw (fresh list = fresh index meaning); the frozen run is what keeps
    // the walk a stable cycle and the commit on the window you chose.
    property var runItems: []
    readonly property bool runActive: root.runItems.length > 0
    // The list every navigation path reads: the frozen run while one is active,
    // the live (MRU-ordered) list otherwise.
    readonly property var items: root.runActive ? root.runItems : root.windows

    // Keys this switcher focused itself (walker-initiated focus changes), with
    // an entry consumed by each matching focus event. Lets noteFocus() tell our
    // own steps — whose events can arrive late during fast tapping — apart from
    // the user focusing something else; the latter ends the walk, so the next
    // press is again a fresh MRU pick rather than a stale cycle.
    property var selfFocusKeys: []

    // How long after the last press the walk keeps its cursor. Every press
    // inside the window continues the cycle at whatever pace; only an idle gap
    // longer than this starts a fresh run (previous window). Raise to walk more
    // deliberately, lower for a stricter "release = session over" feel.
    readonly property int walkHoldMs: 6000

    // ── General-blur connection (Hyprland) ─────────────────────────────────────
    // The Look surface's blur toggle (decoration.lua blur.enabled) gates ALL
    // compositor blur, including this layer's layerrule frost. When it is off
    // the card goes solid so text stays readable; when on, the opacity setting
    // controls how much frosted desktop shows through. Niri has no Look surface
    // — the opacity setting applies directly and frost comes from
    // BackgroundEffect (already card-scoped).
    //
    // Read reactively rather than snapshotted on open: with watchChanges opted
    // in, Look's write (followed by its Hyprland reload) lands here on its own.
    // NOTE watchChanges defaults to false, so it must be set explicitly — and an
    // imperative reload()-then-text() read is NOT a substitute, because reload is
    // asynchronous and text() still holds the previous contents when read.
    readonly property string decoPath: Quickshell.env("RICE_HOME") + "/hypr/modules/decoration.lua"
    FileView {
        id: decoFile
        path: root.decoPath
        blockLoading: true
        watchChanges: true
        printErrors: false
    }
    readonly property bool generalBlurOn: SetDeco.getBlockField(decoFile.text(), "blur", "enabled") !== "false"
    // Belt and braces on top of the watch: reread when the overlay opens. The
    // binding above picks up the fresh contents whenever the async read lands, so
    // this costs nothing and covers a watch that misses an edit.
    // Reread the general-blur state when the overlay opens; the async read lands
    // in the reactive binding (see the general-blur connection block above).
    onOpenChanged: {
        if (root.open)
            decoFile.reload()
        // Each open re-primes the pointer baseline: the first hover sample of a
        // run only records where the parked cursor is, it never selects.
        root.pointerPrimed = false
    }
    readonly property real cardOpacity: !isHyprland || generalBlurOn
        ? QsSingletons.Flags.altSwitcherBackgroundOpacity : 1.0

    // ── Alignment (list layout only) ───────────────────────────────────────────
    readonly property bool alignRight: root.layoutList
        && QsSingletons.Flags.altSwitcherPanelAlignment === "right"
    // Gap kept between the right-aligned card and the screen edge.
    readonly property real alignMargin: 24 * root.s

    // ── Layout preset ─────────────────────────────────────────────────────────
    // Which visual design the overlay uses. All three live in this one file as
    // `visible:`-gated branches (iNiR does the same), so switching costs nothing
    // at runtime and no layout can affect another.
    //   "grid"    — the tile grid (original design)
    //   "list"    — narrow vertical rows, card sizes to content
    //   "compact" — icon-only horizontal strip
    readonly property string layout: {
        var v = QsSingletons.Flags.altSwitcherLayout;
        return (v === "list" || v === "compact") ? v : "grid";
    }
    readonly property bool layoutGrid: root.layout === "grid"
    readonly property bool layoutList: root.layout === "list"
    readonly property bool layoutCompact: root.layout === "compact"

    // Card box per layout. Grid keeps the big 82% panel; the two alternatives
    // hug their content so the switcher reads as a small floating box rather
    // than a screen-scale overlay.
    readonly property real cardW: root.layoutList ? Math.min(root.panelW * 0.55, 460 * root.s)
                                  : root.layoutCompact ? Math.min(Math.max(root.compactStripW + 36 * root.s, 320 * root.s), root.panelW * 0.9)
                                  : Math.min(root.panelW * 0.82, 960 * root.s)
    readonly property real cardH: root.layoutList ? Math.min(root.listContentH + 92 * root.s, root.panelH * 0.82)
                                  : root.layoutCompact ? 176 * root.s
                                  : Math.min(root.panelH * 0.82, 600 * root.s)
    property real panelW: 1920
    property real panelH: 1080
    // Row metrics for the list layout; strip width for compact.
    readonly property real listRowH: 52 * root.s
    readonly property real listContentH: root.count * root.listRowH + Math.max(root.count - 1, 0) * 6 * root.s
    readonly property real compactStripW: root.count * 56 * root.s + Math.max(root.count - 1, 0) * 10 * root.s

    // Advance-on-tap auto-hide (iNiR's mechanism — they have no release binds
    // either; the switcher hides `interval` ms after the LAST tap, which
    // naturally coincides with releasing Alt). Restarted by next()/previous()
    // when the flag is on; stopped by close(). Only the VISUAL hides here — the
    // walk itself survives so the next press continues the cycle (walkHoldMs).
    readonly property int advanceHideMs: 600
    Timer {
        id: advanceHideTimer
        interval: root.advanceHideMs
        repeat: false
        onTriggered: {
            if (root.open && root.advanceOnTap)
                root.hideOverlay()
        }
    }

    // Ends the walk when it goes idle (see walkHoldMs). Restarted on every
    // next()/previous() step; stopped by endRun().
    Timer {
        id: runHoldTimer
        interval: root.walkHoldMs
        repeat: false
        onTriggered: {
            if (QsSingletons.Flags.debug) console.log("[AltSwitcher] walk hold expired -> endRun")
            root.quickSwitchDone = false
            root.noUiIndex = 0
            root.endRun()
        }
    }

    // ── No-Visual-UI cycling (iNiR's "cycle windows only") ─────────────────────
    // When on, the overlay never opens: each tap walks a FROZEN snapshot of the
    // window list and focuses straight into it. The walk shares runHoldTimer
    // with the visual mode: taps at any pace keep cycling, and only an idle gap
    // longer than walkHoldMs starts over from the top of a fresh list.
    readonly property bool noVisualUi: QsSingletons.Flags.altSwitcherNoVisualUi
    // This mode has no UI left to commit a selection with, so every tap must
    // commit — it forces advance-on-tap on regardless of the user's toggle.
    readonly property bool advanceOnTap: QsSingletons.Flags.altSwitcherAdvanceOnTap || root.noVisualUi

    // ── Monochrome app icons (iNiR's "Tint app icons") ─────────────────────────
    // Colorises every app icon to the card's foreground so the switcher reads as
    // one flat surface instead of a wall of brand colours. Uses the same
    // MultiEffect colorisation as the bar's app icons (AppIcons.qml).
    readonly property bool monoIcons: QsSingletons.Flags.altSwitcherMonochromeIcons
    readonly property color iconTintColor: root.cPrimary

    property bool quickSwitchDone: false
    property int noUiIndex: 0

    // Toggling the mode mid-run invalidates the walk so the next tap is fresh.
    onNoVisualUiChanged: {
        root.quickSwitchDone = false
        root.noUiIndex = 0
        root.endRun()
        // Leaving the mode while the overlay happens to be up must not strand it.
        root.close()
    }

    // direction: +1 = forward (next), -1 = backward (previous). Mirrors iNiR's
    // next()/previous() no-UI branch: the first tap of a fresh walk lands on
    // index 1 (or last, going backward) because index 0 is the window you are
    // already on — true here because `windows` is ordered by focus recency
    // (MRU), so the second entry is the window you came from. The walk keeps
    // its cursor for walkHoldMs, so taps at any pace cycle cleanly instead of
    // restarting on the previous window. Walking live indices would re-index
    // the list under the walker and send it back to windows it already visited.
    function cycleNoUi(direction) {
        advanceHideTimer.stop()
        root.open = false
        if (!root.quickSwitchDone || root.runItems.length === 0) {
            // Fresh walk: snapshot the live order, then start one past the
            // current window (forward) or at the least recently used end
            // (backward).
            const total = root.startRun()
            if (total === 0)
                return
            root.quickSwitchDone = true
            root.noUiIndex = direction > 0
                ? (total > 1 ? 1 : 0)
                : (total > 1 ? total - 1 : 0)
        } else {
            root.noUiIndex = direction > 0
                ? (root.noUiIndex + 1) % root.runItems.length
                : (root.noUiIndex - 1 + root.runItems.length) % root.runItems.length
        }
        root.focusWindow(root.runItems[root.noUiIndex])
        runHoldTimer.restart()
    }

    // Live window list, ordered by focus recency — most recently used first.
    //
    // MRU-first is what makes the switcher's semantics work: index 0 is the
    // window you are on, so the first tap of a run targets the window you came
    // from (the classic Alt+Tab target) instead of a fixed slot in a static
    // list. iNiR ships the same default ("Most recently used first"). The order
    // comes from mruKeys (fed by compositor focus events); windows the events
    // have not seen yet fall back to the raw toplevel order — Hyprland keeps
    // the focused window last there, so later in raw ≈ more recently used —
    // and finally to the old (workspace idx, app name) grouping.
    //
    // Niri toplevels expose { id, app_id, title, workspace_id }; Hyprland
    // toplevels expose { address, title, workspace: { id }, lastIpcObject
    // { class, initialClass, ... } }. normalizeWindow() maps both shapes onto
    // one plain-JS row so sorting, the delegate and focusWindow never care
    // which compositor is running.
    readonly property var windows: (function () {
        const raw = compositor.toplevels || []
        const mapped = raw
            .map(function (w) { return root.normalizeWindow(w) })
            .filter(function (w) { return w !== null })
        // Fallback recency ranks (see the comment above): rank grows as the
        // window sits earlier in the raw list, so the last raw entry wins.
        const rawRank = {}
        for (let i = 0; i < mapped.length; i++)
            rawRank[mapped[i].key] = raw.length - i
        mapped.sort(function (a, b) {
            const ia = root.mruKeys.indexOf(a.key)
            const ib = root.mruKeys.indexOf(b.key)
            // Event-known windows keep their exact recency order; unknown ones
            // queue behind them, ranked by the raw-order fallback.
            const ka = ia >= 0 ? ia : 10000 + (rawRank[a.key] ?? 0)
            const kb = ib >= 0 ? ib : 10000 + (rawRank[b.key] ?? 0)
            if (ka !== kb)
                return ka - kb
            const wa = compositor.workspaces.find(function (w) { return w.id === a.wsId })
            const wb = compositor.workspaces.find(function (w) { return w.id === b.wsId })
            const ga = wa ? (wa.idx ?? wa.id ?? 0) : 0
            const gb = wb ? (wb.idx ?? wb.id ?? 0) : 0
            if (ga !== gb)
                return ga - gb
            return String(a.app).localeCompare(String(b.app))
        })
        return mapped
    })()

    function normalizeWindow(w) {
        if (!w)
            return null
        const ipc = w.lastIpcObject || {}
        return {
            // Stable identity for recency tracking: Hyprland addresses ("0x…"),
            // niri numeric ids — normalised (see focusKey) so both sources
            // always produce the same string for the same window.
            key: root.focusKey(w),
            // niri uses a numeric id; Hyprland uses the address string ("0x…").
            id: w.id ?? w.address ?? "",
            address: w.address ?? null,
            app: w.app_id ?? ipc.class ?? ipc.initialClass ?? w.appid ?? "",
            title: w.title ?? ipc.title ?? "",
            wsId: w.workspace_id ?? w.workspace?.id ?? ipc.workspace?.id ?? null
        }
    }

    // ── Focus recency (MRU) tracking ───────────────────────────────────────────
    // Window keys in focus order, most recent first. noteFocus() is driven by
    // the compositor's active-toplevel changes (see the Connections below).
    property var mruKeys: []

    function noteFocus(w) {
        if (!w)
            return
        const k = focusKey(w)
        if (!k)
            return
        // While a walk is live, a focus change the walk did not cause (the user
        // clicked or focused something else, possibly via another shortcut)
        // means the cycle is broken: end the run so the next press is a fresh
        // MRU pick instead of resuming a stale walk. Our own steps match either
        // the current cursor or the self-focus queue (their events can arrive
        // late during fast tapping).
        if (root.runActive) {
            if (k === root.walkTargetKey()) {
                if (QsSingletons.Flags.debug) console.log("[AltSwitcher] event matches walk target " + k)
            } else if (root.selfFocusKeys.indexOf(k) >= 0) {
                root.selfFocusKeys = root.selfFocusKeys.filter(function (x) { return x !== k })
                if (QsSingletons.Flags.debug) console.log("[AltSwitcher] event consumed self-focus " + k + " (left " + root.selfFocusKeys.length + ")")
            } else {
                if (QsSingletons.Flags.debug) console.log("[AltSwitcher] EXTERNAL focus " + k + " (target " + root.walkTargetKey() + ") -> endRun")
                root.endRun()
            }
        }
        if (QsSingletons.Flags.debug)
            console.log("[AltSwitcher][mru] focus " + k + " (list: " + root.mruKeys.length + ")")
        // Remove-then-unshift so refocusing a window that already sits deeper in
        // the list still moves it to the front.
        const next = []
        for (let i = 0; i < root.mruKeys.length; i++) {
            if (root.mruKeys[i] !== k)
                next.push(root.mruKeys[i])
        }
        next.unshift(k)
        root.mruKeys = next
    }

    // Key of the window the active walk currently points at (visual cursor or
    // no-UI cursor). Empty when no walk is live.
    function walkTargetKey() {
        if (!root.runActive)
            return ""
        const idx = root.noVisualUi ? root.noUiIndex : root.currentIndex
        const w = root.runItems[idx]
        return w ? w.key : ""
    }

    // Drop keys of windows that no longer exist so the list does not grow for
    // the whole session and stale entries cannot outrank live windows.
    function pruneMru() {
        if (root.mruKeys.length === 0)
            return
        const alive = {}
        for (let i = 0; i < root.windows.length; i++)
            alive[root.windows[i].key] = true
        const next = root.mruKeys.filter(function (k) { return alive[k] })
        if (next.length !== root.mruKeys.length)
            root.mruKeys = next
    }

    // Shared key normaliser. Hyprland addresses reach QML with or without the
    // "0x" prefix depending on the path (toplevels have needed both forms in
    // this shell's history — see focusWindow), so strip it and lowercase, or a
    // recency entry recorded from one source would never match a window row
    // built from another.
    function focusKey(w) {
        return String(w.address ?? w.id ?? "").toLowerCase().replace(/^0x/, "")
    }

    Connections {
        target: root.compositor
        function onActiveToplevelChanged() {
            if (QsSingletons.Flags.debug)
                console.log("[AltSwitcher][mru] active toplevel changed")
            root.noteFocus(root.compositor.activeToplevel)
        }
    }

    // Length of the list navigation reads (the frozen run while one is active,
    // the live MRU list otherwise — see the run-snapshot block).
    readonly property int count: root.items.length

    // High-load safety valve (ported from iNiR, L101). With a very crowded
    // window list the backdrop blur and the open/close fade cost more than they
    // add, so both are dropped rather than letting the switcher stutter.
    // NOTE: on Hyprland the frosted backdrop is compositor-side (the
    // `layerrule = blur` on our namespace in hyprland.conf), which QML cannot
    // switch per window-count; there the valve only drops the fade.
    readonly property bool isHighLoad: root.count > 15
    readonly property bool effectiveBlurGlass: root.blurGlass && !root.isHighLoad

    onWindowsChanged: {
        if (root.currentIndex >= root.count)
            root.currentIndex = Math.max(0, root.count - 1)
        root.pruneMru()
    }

    // ── Public API (driven by the altSwitcher IPC handler in shell.qml) ─────────
    function toggle() {
        if (!QsSingletons.Flags.altSwitcherEnabled)
            return
        if (root.open)
            root.close()
        else
            root.openSwitcher()
    }
    function open() { root.openSwitcher() }
    function openSwitcher() {
        if (!QsSingletons.Flags.altSwitcherEnabled)
            return
        // Instantiation itself is gated in shell.qml (niri + Hyprland); only
        // refuse on an unknown compositor so IPC stays a no-op there.
        if (!compositor.runningCompositor)
            return
        // A fresh run freezes the window order (see the run-snapshot block)
        // before the first advance: every navigation and the final commit read
        // this list instead of the live one, so focus events during the cycle
        // cannot reindex the walk. A run that is still inside its walkHoldMs
        // window keeps its snapshot and cursor — reopening the overlay is just
        // the visual coming back, not a new cycle.
        if (!root.runActive) {
            if (QsSingletons.Flags.debug) console.log("[AltSwitcher] openSwitcher: fresh walk")
            root.startRun()
            root.currentIndex = 0
        } else {
            if (QsSingletons.Flags.debug) console.log("[AltSwitcher] openSwitcher: continuing walk (cursor " + root.currentIndex + ")")
        }
        root.open = true
        cardHolder.forceActiveFocus()
    }

    /** Snapshot the live MRU-ordered list for a walk; returns its length. */
    function startRun() {
        root.runItems = root.windows.slice()
        root.selfFocusKeys = []
        if (QsSingletons.Flags.debug) console.log("[AltSwitcher] startRun snapshot: " + root.runItems.map(function (w) { return w.key }).join(","))
        return root.runItems.length
    }

    /** Drop the walk snapshot so the next press starts from the live order. */
    function endRun() {
        if (root.runItems.length > 0)
            if (QsSingletons.Flags.debug) console.log("[AltSwitcher] endRun — walk dropped (" + root.runItems.length + " items)")
        runHoldTimer.stop()
        if (root.runItems.length > 0)
            root.runItems = []
        if (root.selfFocusKeys.length > 0)
            root.selfFocusKeys = []
    }

    /** Hide the overlay without touching the walk (auto-hide / Alt release). */
    function hideOverlay() {
        if (QsSingletons.Flags.debug) console.log("[AltSwitcher] hideOverlay")
        advanceHideTimer.stop()
        root.open = false
    }

    /** Explicit dismissal (Esc, click-away, toggle-off, commit): overlay and
     *  walk both end — the next press starts a fresh MRU run. */
    function close() {
        root.hideOverlay()
        root.endRun()
    }
    function next() {
        // No-Visual-UI (cycle only): never draw the overlay — walk the frozen
        // snapshot and focus straight into it (iNiR's next() no-UI branch).
        if (root.noVisualUi) {
            root.cycleNoUi(1)
            return
        }
        const fresh = !root.open
        if (QsSingletons.Flags.debug) console.log("[AltSwitcher] next: fresh=" + fresh + " runActive=" + root.runActive + " cursor=" + root.currentIndex + " count=" + root.count)
        if (fresh)
            root.openSwitcher()
        if (root.count === 0)
            return
        // Classic mode (advance off) only opens on the first press — the
        // highlight rests on the current window until the next press.
        if (fresh && !root.advanceOnTap)
            return
        root.currentIndex = (root.currentIndex + 1) % root.count
        if (root.advanceOnTap) {
            // Advance-on-tap: every tap commits immediately — focus moves with
            // the highlight — and the walk keeps its cursor for walkHoldMs, so
            // taps at any pace step through the frozen list instead of
            // restarting on the previous window each time. A fresh walk starts
            // at index 0 (the window you are on), making the first step land on
            // the one you came from; a continuing walk steps from where it left
            // off (the overlay may have auto-hidden in between).
            if (QsSingletons.Flags.debug) {
                if (QsSingletons.Flags.debug) console.log("[AltSwitcher] step -> idx " + root.currentIndex + " " + root.items[root.currentIndex].key)
            }
            root.focusWindow(root.items[root.currentIndex])
            // Auto-hide: hides shortly after the last tap, which is what makes
            // releasing Alt feel like it closes itself. The walk survives the
            // hide (walkHoldMs) so the next press continues the cycle.
            advanceHideTimer.restart()
            runHoldTimer.restart()
        }
    }
    function previous() {
        // Mirror of next(): cycle-only mode never draws the overlay.
        if (root.noVisualUi) {
            root.cycleNoUi(-1)
            return
        }
        const fresh = !root.open
        if (fresh)
            root.openSwitcher()
        if (root.count === 0)
            return
        if (fresh && !root.advanceOnTap)
            return
        // Same walk as next(), one step backward. On a fresh walk the cursor is
        // index 0, so the wrap lands on the last entry — in MRU order the least
        // recently used window (iNiR's backward first tap).
        root.currentIndex = (root.currentIndex - 1 + root.count) % root.count
        if (root.advanceOnTap) {
            if (QsSingletons.Flags.debug) {
                if (QsSingletons.Flags.debug) console.log("[AltSwitcher] step <- idx " + root.currentIndex + " " + root.items[root.currentIndex].key)
            }
            root.focusWindow(root.items[root.currentIndex])
            advanceHideTimer.restart()
            runHoldTimer.restart()
        }
    }

    // ── Keyboard grid navigation (arrows + Enter/Esc) ──────────────────────────
    readonly property int _cols: Math.max(1, Math.floor((flow.width + root.tileGap * root.s) / (root.tileWidth * root.s + root.tileGap * root.s)))

    function moveLeft() {
        if (root.count === 0) return
        root.currentIndex = Math.max(0, root.currentIndex - 1)
    }
    function moveRight() {
        if (root.count === 0) return
        root.currentIndex = Math.min(root.count - 1, root.currentIndex + 1)
    }
    function moveUp() {
        if (root.count === 0) return
        root.currentIndex = Math.max(0, root.currentIndex - root._cols)
    }
    function moveDown() {
        if (root.count === 0) return
        root.currentIndex = Math.min(root.count - 1, root.currentIndex + root._cols)
    }

    function selectAndFocus(index) {
        if (index < 0 || index >= root.count)
            return
        const w = root.items[index]
        root.currentIndex = index
        focusWindow(w)
        root.close()
    }

/**
     * Resolve an icon path for a window's app id (Hyprland class / niri app_id).
     * Same lookup MinimizedTray and the bar's AppIcons use: match the app id to
     * a desktop-entry id first (the class often differs from the icon-theme
     * name), then fall back to a direct icon-theme lookup.
     */
    function iconForApp(appId) {
        if (!appId)
            return Quickshell.iconPath("application-x-executable", "application-x-executable")
        const cls = String(appId).toLowerCase()
        const apps = DesktopEntries.applications.values
        for (let i = 0; i < apps.length; i++) {
            const e = apps[i]
            if (e && e.id && e.id.toLowerCase() === cls && e.icon)
                return Quickshell.iconPath(e.icon, "application-x-executable")
        }
        return Quickshell.iconPath(appId, "application-x-executable")
    }
    function appLabel(appId) {
        if (!appId)
            return "Window"
        let s = String(appId).replace(/[._-]+/g, " ")
        const parts = s.split(/\s+/)
        for (let i = 0; i < parts.length; i++)
            if (parts[i])
                parts[i] = parts[i].charAt(0).toUpperCase() + parts[i].slice(1)
        return parts.join(" ")
    }

    function wsLabel(wsId) {
        const ws = compositor.workspaces.find(function (w) { return w.id === wsId })
        if (!ws)
            return ""
        return ws.name !== undefined && ws.name !== "" ? String(ws.name) : ("WS " + (ws.idx ?? ws.id ?? ""))
    }

    Process {
        id: focusProc
        command: ["niri", "msg", "action", "focus-window", "--id", "0"]
        onExited: (code) => {
            if (QsSingletons.Flags.debug)
                console.log("[AltSwitcher] focus-window exited", code)
        }
    }
    // Alt-release: when advance-on-tap is enabled, releasing Alt takes the
    // overlay down by itself (each tap already focused its window, so
    // re-focusing the current one is an idempotent safety net). The WALK is
    // deliberately left alive: releasing Alt between taps is part of a normal
    // walk, and the walk only ends after walkHoldMs of inactivity (or on an
    // explicit dismissal, where close() is called instead).
    function commitAndClose() {
        // Cycle-only mode never opens, so there is nothing to commit/hide.
        if (!root.open || !root.advanceOnTap)
            return
        if (root.count > 0 && root.currentIndex >= 0 && root.currentIndex < root.count)
            root.focusWindow(root.items[root.currentIndex])
        root.hideOverlay()
    }

    function focusWindow(w) {
        if (!w)
            return
        // Record the key so the focus-event handler can recognise this step as
        // walker-initiated even if the event arrives after the cursor has
        // already moved on (fast tapping). See noteFocus().
        const k = root.focusKey(w)
        if (k && root.selfFocusKeys.indexOf(k) < 0)
            root.selfFocusKeys = root.selfFocusKeys.concat([k])
        // Hyprland focuses by address through the unified dispatch path
        // (same convention as bar AppIcons). Niri uses its IPC action.
        if (root.isHyprland) {
            // Hyprland expects the full 0x-prefixed address (toplevels may
            // expose it without the prefix; the bare form is rejected with
            // "No such window found").
            let addr = String(w.address ?? "")
            if (addr.length > 0 && addr.indexOf("0x") !== 0)
                addr = "0x" + addr
            if (addr.length > 0)
                compositor.dispatch("focuswindow address:" + addr)
            return
        }
        focusProc.command = ["niri", "msg", "action", "focus-window", "--id", String(w.id)]
        focusProc.running = true
    }

    // ── Overlay ─────────────────────────────────────────────────────────────────
    PanelWindow {
        id: panel
        // Feed the live surface size to the root's card metrics (they are
        // declared on the root so all layouts can share them).
        onWidthChanged: root.panelW = width
        onHeightChanged: root.panelH = height
        Component.onCompleted: {
            root.panelW = width
            root.panelH = height
        }
        // Stays mapped until the fade drains so the close animation is visible.
        visible: root.open || cardHolder.opacity > 0.001
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:altSwitcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Frost the backdrop behind the card via the compositor (ext-background-effect),
        // NOT a MultiEffect on the card — blurring the card's own layer smears the text.
        // BackgroundEffect is an *attached* object (like WlrLayershell), not a child item.
        BackgroundEffect.blurRegion: root.effectiveBlurGlass ? blurRegion : null

        Region {
            id: blurRegion
            item: cardHolder
            radius: 20 * root.s
        }

        // Click-away to close. Invisible — there is deliberately NO full-screen
        // backdrop: the card is the only visible content, so the compositor's
        // blur (hyprland.conf layerrules on this namespace) frosts just the
        // card's pixels instead of the whole desktop.
        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }

        // Frosted-glass card. Zen fade: pure opacity, no transforms. Centered
        // normally; in the list layout the alignment setting can pin it to the
        // right edge instead so it never covers the centred window it describes.
        Item {
            id: cardHolder
            anchors.verticalCenter: parent.verticalCenter
            x: root.alignRight ? parent.width - width - root.alignMargin
                               : Math.round((parent.width - width) / 2)
            width: root.cardW
            height: root.cardH
            opacity: root.open ? 1 : 0
            Behavior on opacity {
                // High-load valve: skip the fade so the overlay unmaps the
                // instant it closes instead of holding a full-screen layer up
                // for another 140 ms.
                enabled: !root.isHighLoad
                NumberAnimation {
                    duration: root.open ? 300 : 140
                    easing.type: Easing.OutCubic
                }
            }
            focus: true
            Keys.onPressed: (event) => {
                if (!root.open)
                    return
                switch (event.key) {
                case Qt.Key_Left: root.moveLeft(); event.accepted = true; break
                case Qt.Key_Right: root.moveRight(); event.accepted = true; break
                case Qt.Key_Up: root.moveUp(); event.accepted = true; break
                case Qt.Key_Down: root.moveDown(); event.accepted = true; break
                case Qt.Key_Return:
                case Qt.Key_Enter: root.selectAndFocus(root.currentIndex); event.accepted = true; break
                case Qt.Key_Escape: root.close(); event.accepted = true; break
                }
            }

                Rectangle {
                    id: card
                        anchors.fill: parent
                        radius: 20
                        color: Qt.alpha(root.cSurface, root.cardOpacity)
                        border.color: root.cBorder
                        border.width: 1
                        clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18 * root.s
                    spacing: 14 * root.s

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12 * root.s

                        Text {
                            text: "Overview"
                            color: root.cText
                            font.family: QsSingletons.Theme.font
                            font.pixelSize: 16 * root.s
                            font.weight: Font.Bold
                        }
                        Text {
                            text: root.count + (root.count === 1 ? " window" : " windows")
                            color: root.cSubText
                            font.family: QsSingletons.Theme.font
                            font.pixelSize: 12 * root.s
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            visible: root.layoutGrid
                                text: "↑ ↓ ← → navigate · Enter focus · Esc close"
                            color: root.cSubText
                            font.family: QsSingletons.Theme.font
                            font.pixelSize: 11 * root.s
                        }
                        Rectangle {
                            width: 28 * root.s; height: 28 * root.s; radius: 14 * root.s
                            color: closeMA.containsMouse ? Qt.alpha(root.cPrimary, 0.18) : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: ""
                                font.family: "Material Design Icons"
                                color: root.cText
                                font.pixelSize: 16 * root.s
                            }
                            MouseArea {
                                id: closeMA
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.close()
                            }
                        }
                    }

                    // Window grid (preset: grid)
                    Flickable {
                        id: scroll
                        visible: root.layoutGrid
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: flow.width
                        contentHeight: flow.height
                        clip: true

                        Flow {
                            id: flow
                            width: scroll.width
                            spacing: root.tileGap * root.s

                            Repeater {
                                model: root.items
                                delegate: Rectangle {
                                    id: tile
                                    required property var modelData
                                    required property int index
                                    width: root.tileWidth * root.s
                                    height: root.tileHeight * root.s
                                    radius: 12 * root.s
                                    color: index === root.currentIndex
                                        ? Qt.alpha(root.cPrimary, 0.18)
                                        : Qt.alpha(root.cText, 0.05)
                                    border.width: 1
                                    border.color: index === root.currentIndex
                                        ? root.cPrimary
                                        : root.cBorder

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12 * root.s
                                        spacing: 10 * root.s

                                        // Accent rail for the selected tile
                                        Rectangle {
                                            Layout.preferredWidth: 3 * root.s
                                            Layout.fillHeight: true
                                            radius: 2 * root.s
                                            color: index === root.currentIndex ? root.cPrimary : "transparent"
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            spacing: 4 * root.s

                                            Text {
                                                Layout.fillWidth: true
                                                text: root.appLabel(modelData.app)
                                                color: root.cText
                                                font.family: QsSingletons.Theme.font
                                                font.pixelSize: 13 * root.s
                                                font.weight: Font.Bold
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.title || root.wsLabel(modelData.wsId)
                                                color: root.cSubText
                                                font.family: QsSingletons.Theme.font
                                                font.pixelSize: 11 * root.s
                                                elide: Text.ElideRight
                                                maximumLineCount: 2
                                                wrapMode: Text.Wrap
                                            }
                                            Item { Layout.fillHeight: true }
                                            Text {
                                                text: root.wsLabel(modelData.wsId)
                                                color: root.cPrimary
                                                font.family: QsSingletons.Theme.font
                                                font.pixelSize: 10 * root.s
                                                font.weight: Font.Bold
                                            }
                                        }
                                    }

                                    // Hover-select — but only after real pointer
                                    // movement. The first hover sample of a run
                                    // only primes the shared baseline (a layer
                                    // surface mapped under a parked cursor gets
                                    // a synthesised enter; it must not steal the
                                    // keyboard selection), and only a sample at
                                    // a new position sets the index. Same pattern
                                    // as Clipboard.qml's row hover.
                                    HoverHandler {
                                        onPointChanged: {
                                            if (!hovered)
                                                return
                                            var sp = point.scenePosition
                                            if (!root.pointerPrimed) {
                                                root.lastPointer = Qt.point(sp.x, sp.y)
                                                root.pointerPrimed = true
                                                return
                                            }
                                            if (sp.x !== root.lastPointer.x || sp.y !== root.lastPointer.y) {
                                                root.lastPointer = Qt.point(sp.x, sp.y)
                                                root.currentIndex = index
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: root.selectAndFocus(index)
                                    }
                                }
                            }
                        }
                    }

                    // Window list (preset: list) — one row per window, icon +
                    // name + title, card hugs the content height.
                    Flickable {
                        id: listScroll
                        visible: root.layoutList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: listCol.width
                        contentHeight: listCol.height
                        clip: true

                        Column {
                            id: listCol
                            width: listScroll.width
                            spacing: 6 * root.s

                            Repeater {
                                model: root.items
                                delegate: Rectangle {
                                    id: listRow
                                    required property var modelData
                                    required property int index
                                    width: listCol.width
                                    height: root.listRowH
                                    radius: 10 * root.s
                                    color: index === root.currentIndex
                                        ? Qt.alpha(root.cPrimary, 0.18)
                                        : (rowHover.hovered ? Qt.alpha(root.cText, 0.07) : "transparent")
                                    border.width: 1
                                    border.color: index === root.currentIndex ? root.cPrimary : "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12 * root.s
                                        anchors.rightMargin: 12 * root.s
                                        spacing: 12 * root.s

                                        Image {
                                            Layout.preferredWidth: 22 * root.s
                                            Layout.preferredHeight: 22 * root.s
                                            sourceSize.width: Math.round(44 * root.s)
                                            sourceSize.height: Math.round(44 * root.s)
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                            smooth: true
                                            source: root.iconForApp(listRow.modelData.app)
                                            // Monochrome mode: colorise the icon
                                            // to the card foreground (see the
                                            // monoIcons block above).
                                            layer.enabled: root.monoIcons
                                            layer.effect: MultiEffect {
                                                colorization: root.monoIcons ? 1.0 : 0.0
                                                colorizationColor: root.iconTintColor
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1 * root.s

                                            Text {
                                                Layout.fillWidth: true
                                                text: root.appLabel(listRow.modelData.app)
                                                color: root.cText
                                                font.family: QsSingletons.Theme.font
                                                font.pixelSize: 13 * root.s
                                                font.weight: Font.Bold
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                text: listRow.modelData.title || root.wsLabel(listRow.modelData.wsId)
                                                color: root.cSubText
                                                font.family: QsSingletons.Theme.font
                                                font.pixelSize: 11 * root.s
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Text {
                                            Layout.alignment: Qt.AlignVCenter
                                            text: root.wsLabel(listRow.modelData.wsId)
                                            color: root.cPrimary
                                            font.family: QsSingletons.Theme.font
                                            font.pixelSize: 10 * root.s
                                            font.weight: Font.Bold
                                        }
                                    }

                                    // Hover-select gated on real pointer movement
                                    // (see the grid tile's handler above): a
                                    // parked cursor can never yank the selection
                                    // off the keyboard walk.
                                    HoverHandler {
                                        id: rowHover
                                        onPointChanged: {
                                            if (!hovered)
                                                return
                                            var sp = point.scenePosition
                                            if (!root.pointerPrimed) {
                                                root.lastPointer = Qt.point(sp.x, sp.y)
                                                root.pointerPrimed = true
                                                return
                                            }
                                            if (sp.x !== root.lastPointer.x || sp.y !== root.lastPointer.y) {
                                                root.lastPointer = Qt.point(sp.x, sp.y)
                                                root.currentIndex = listRow.index
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: root.selectAndFocus(listRow.index)
                                    }
                                }
                            }
                        }
                    }

                    // Icon-only strip (preset: compact) — a horizontal run of app
                    // icons, centred; the card hugs the strip width.
                    Flickable {
                        id: stripScroll
                        visible: root.layoutCompact
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: Math.max(stripRow.width, width)
                        contentHeight: height
                        clip: true

                        Row {
                            id: stripRow
                            x: Math.max(0, (stripScroll.width - width) / 2)
                            y: Math.max(0, (stripScroll.height - height) / 2)
                            spacing: 10 * root.s

                            Repeater {
                                model: root.items
                                delegate: Rectangle {
                                    id: chip
                                    required property var modelData
                                    required property int index
                                    width: 48 * root.s
                                    height: 48 * root.s
                                    radius: 12 * root.s
                                    color: index === root.currentIndex
                                        ? Qt.alpha(root.cPrimary, 0.20)
                                        : Qt.alpha(root.cText, 0.06)
                                    border.width: 1
                                    border.color: index === root.currentIndex ? root.cPrimary : root.cBorder

                                    Image {
                                        anchors.centerIn: parent
                                        width: 26 * root.s
                                        height: 26 * root.s
                                        sourceSize.width: Math.round(52 * root.s)
                                        sourceSize.height: Math.round(52 * root.s)
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: true
                                        smooth: true
                                        source: root.iconForApp(chip.modelData.app)
                                        // Monochrome mode: see the monoIcons block.
                                        layer.enabled: root.monoIcons
                                        layer.effect: MultiEffect {
                                            colorization: root.monoIcons ? 1.0 : 0.0
                                            colorizationColor: root.iconTintColor
                                        }
                                    }

                                    // Hover-select gated on real pointer movement
                                    // (see the grid tile's handler above).
                                    HoverHandler {
                                        onPointChanged: {
                                            if (!hovered)
                                                return
                                            var sp = point.scenePosition
                                            if (!root.pointerPrimed) {
                                                root.lastPointer = Qt.point(sp.x, sp.y)
                                                root.pointerPrimed = true
                                                return
                                            }
                                            if (sp.x !== root.lastPointer.x || sp.y !== root.lastPointer.y) {
                                                root.lastPointer = Qt.point(sp.x, sp.y)
                                                root.currentIndex = chip.index
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: root.selectAndFocus(chip.index)
                                    }
                                }
                            }
                        }
                    }

                    // Empty state
                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        visible: root.count === 0
                        text: "No open windows"
                        color: root.cSubText
                        font.family: QsSingletons.Theme.font
                        font.pixelSize: 13 * root.s
                    }
                }
            }
        }
    }
}
