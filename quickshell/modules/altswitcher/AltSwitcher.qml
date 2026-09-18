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
    onOpenChanged: if (root.open) decoFile.reload()
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
    // either; the switcher closes `interval` ms after the LAST tap, which
    // naturally coincides with releasing Alt). Restarted by next()/previous()
    // when the flag is on; stopped by close()/commitAndClose().
    readonly property int advanceHideMs: 600
    Timer {
        id: advanceHideTimer
        interval: root.advanceHideMs
        repeat: false
        onTriggered: {
            if (root.open && root.advanceOnTap)
                root.close()
        }
    }

    // ── No-Visual-UI cycling (iNiR's "cycle windows only") ─────────────────────
    // When on, the overlay never opens: each tap walks a FROZEN snapshot of the
    // window list and focuses straight into it. quickSwitchResetTimer (iNiR's
    // 800 ms) ends the run when the taps stop, so the next tap starts over from
    // the top of the list instead of continuing the old walk.
    readonly property bool noVisualUi: QsSingletons.Flags.altSwitcherNoVisualUi
    // This mode has no UI left to commit a selection with, so every tap must
    // commit — it forces advance-on-tap on regardless of the user's toggle.
    readonly property bool advanceOnTap: QsSingletons.Flags.altSwitcherAdvanceOnTap || root.noVisualUi

    property bool quickSwitchDone: false
    property int noUiIndex: 0
    property var noUiSnapshot: []

    Timer {
        id: quickSwitchResetTimer
        interval: 800
        repeat: false
        onTriggered: {
            root.quickSwitchDone = false
            root.noUiSnapshot = []
            root.noUiIndex = 0
        }
    }

    // Toggling the mode mid-run invalidates the walk so the next tap is fresh.
    onNoVisualUiChanged: {
        quickSwitchResetTimer.stop()
        root.quickSwitchDone = false
        root.noUiSnapshot = []
        root.noUiIndex = 0
        // Leaving the mode while the overlay happens to be up must not strand it.
        root.close()
    }

    // direction: +1 = forward (next), -1 = backward (previous). Mirrors iNiR's
    // next()/previous() no-UI branch: the first tap of a run lands on index 1
    // (or last, going backward) because index 0 is the window you are already on.
    function cycleNoUi(direction: int): void {
        advanceHideTimer.stop()
        root.open = false
        if (!root.quickSwitchDone || root.noUiSnapshot.length === 0) {
            root.noUiSnapshot = root.windows.slice()
            root.noUiIndex = 0
        }
        const total = root.noUiSnapshot.length
        if (total === 0)
            return
        if (!root.quickSwitchDone) {
            root.quickSwitchDone = true
            root.noUiIndex = direction > 0
                ? (total > 1 ? 1 : 0)
                : (total > 1 ? total - 1 : 0)
        } else {
            root.noUiIndex = direction > 0
                ? (root.noUiIndex + 1) % total
                : (root.noUiIndex - 1 + total) % total
        }
        root.focusWindow(root.noUiSnapshot[root.noUiIndex])
        quickSwitchResetTimer.restart()
    }

    // Live, sorted window list (by workspace idx, then app name).
    //
    // Niri toplevels expose { id, app_id, title, workspace_id }; Hyprland
    // toplevels expose { address, title, workspace: { id }, lastIpcObject
    // { class, initialClass, ... } }. normalizeWindow() maps both shapes onto
    // one plain-JS row so sorting, the delegate and focusWindow never care
    // which compositor is running.
    readonly property var windows: (function () {
        const mapped = (compositor.toplevels || [])
            .map(function (w) { return root.normalizeWindow(w) })
            .filter(function (w) { return w !== null })
        mapped.sort(function (a, b) {
            const wa = compositor.workspaces.find(function (w) { return w.id === a.wsId })
            const wb = compositor.workspaces.find(function (w) { return w.id === b.wsId })
            const ia = wa ? (wa.idx ?? wa.id ?? 0) : 0
            const ib = wb ? (wb.idx ?? wb.id ?? 0) : 0
            if (ia !== ib)
                return ia - ib
            return String(a.app).localeCompare(String(b.app))
        })
        return mapped
    })()

    function normalizeWindow(w: var): var {
        if (!w)
            return null
        const ipc = w.lastIpcObject || {}
        return {
            // niri uses a numeric id; Hyprland uses the address string ("0x…").
            id: w.id ?? w.address ?? "",
            address: w.address ?? null,
            app: w.app_id ?? ipc.class ?? ipc.initialClass ?? w.appid ?? "",
            title: w.title ?? ipc.title ?? "",
            wsId: w.workspace_id ?? w.workspace?.id ?? ipc.workspace?.id ?? null
        }
    }

    readonly property int count: root.windows.length

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
    }

    // ── Public API (driven by the altSwitcher IPC handler in shell.qml) ─────────
    function toggle(): void {
        if (!QsSingletons.Flags.altSwitcherEnabled)
            return
        if (root.open)
            root.close()
        else
            root.openSwitcher()
    }
    function open(): void { root.openSwitcher() }
    function openSwitcher(): void {
        if (!QsSingletons.Flags.altSwitcherEnabled)
            return
        // Instantiation itself is gated in shell.qml (niri + Hyprland); only
        // refuse on an unknown compositor so IPC stays a no-op there.
        if (!compositor.runningCompositor)
            return
        root.currentIndex = 0
        root.open = true
        cardHolder.forceActiveFocus()
    }
    function close(): void {
        advanceHideTimer.stop()
        root.open = false
    }
    function next(): void {
        // No-Visual-UI (cycle only): never draw the overlay — walk the frozen
        // snapshot and focus straight into it (iNiR's next() no-UI branch).
        if (root.noVisualUi) {
            root.cycleNoUi(1)
            return
        }
        if (!root.open) {
            root.openSwitcher()
            // Advance-on-tap: the FIRST tap already switches (classic Alt+Tab
            // feel) — open, advance past the resting index, focus, arm hide.
            if (root.advanceOnTap && root.count > 0) {
                root.currentIndex = (root.currentIndex + 1) % root.count
                root.focusWindow(root.windows[root.currentIndex])
                advanceHideTimer.restart()
            }
            return
        }
        if (root.count > 0) {
            root.currentIndex = (root.currentIndex + 1) % root.count
            // Advance-on-tap: every tap commits immediately — focus moves with
            // the highlight. root.advanceOnTap also covers cycle-only mode,
            // which has no UI left to confirm a selection with.
            if (root.advanceOnTap) {
                root.focusWindow(root.windows[root.currentIndex])
                // Auto-hide: closes shortly after the last tap, which is what
                // makes releasing Alt feel like it closes itself.
                advanceHideTimer.restart()
            }
        }
    }
    function previous(): void {
        // Mirror of next(): cycle-only mode never draws the overlay.
        if (root.noVisualUi) {
            root.cycleNoUi(-1)
            return
        }
        if (!root.open) {
            root.openSwitcher()
            // Advance-on-tap: first tap walks BACKWARD from the end of the
            // list (count - 1), mirroring next()'s first-tap advance.
            if (root.advanceOnTap && root.count > 0) {
                root.currentIndex = root.count - 1
                root.focusWindow(root.windows[root.currentIndex])
                advanceHideTimer.restart()
            }
            return
        }
        if (root.count > 0) {
            root.currentIndex = (root.currentIndex - 1 + root.count) % root.count
            // Mirrors next(): each tap commits immediately when enabled.
            if (root.advanceOnTap) {
                root.focusWindow(root.windows[root.currentIndex])
                advanceHideTimer.restart()
            }
        }
    }

    // ── Keyboard grid navigation (arrows + Enter/Esc) ──────────────────────────
    readonly property int _cols: Math.max(1, Math.floor((flow.width + root.tileGap * root.s) / (root.tileWidth * root.s + root.tileGap * root.s)))

    function moveLeft(): void {
        if (root.count === 0) return
        root.currentIndex = Math.max(0, root.currentIndex - 1)
    }
    function moveRight(): void {
        if (root.count === 0) return
        root.currentIndex = Math.min(root.count - 1, root.currentIndex + 1)
    }
    function moveUp(): void {
        if (root.count === 0) return
        root.currentIndex = Math.max(0, root.currentIndex - root._cols)
    }
    function moveDown(): void {
        if (root.count === 0) return
        root.currentIndex = Math.min(root.count - 1, root.currentIndex + root._cols)
    }

    function selectAndFocus(index: int): void {
        if (index < 0 || index >= root.count)
            return
        const w = root.windows[index]
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
    function iconForApp(appId: string): string {
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
    function appLabel(appId: string): string {
        if (!appId)
            return "Window"
        let s = String(appId).replace(/[._-]+/g, " ")
        const parts = s.split(/\s+/)
        for (let i = 0; i < parts.length; i++)
            if (parts[i])
                parts[i] = parts[i].charAt(0).toUpperCase() + parts[i].slice(1)
        return parts.join(" ")
    }

    function wsLabel(wsId: var): string {
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
    // Alt-release commit: when advance-on-tap is enabled, releasing Alt
    // dismisses the switcher by itself (each tap already focused its window,
    // so re-focusing the current one on release is an idempotent safety net).
    // With the feature off this is a no-op — the classic Esc / click-away
    // dismissal stays untouched.
    function commitAndClose(): void {
        // Cycle-only mode never opens, so there is nothing to commit/close.
        if (!root.open || !root.advanceOnTap)
            return
        advanceHideTimer.stop()
        if (root.count > 0 && root.currentIndex >= 0 && root.currentIndex < root.count)
            root.focusWindow(root.windows[root.currentIndex])
        root.close()
    }

    function focusWindow(w: var): void {
        if (!w)
            return
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
                                model: root.windows
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

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onEntered: root.currentIndex = index
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
                                model: root.windows
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

                                    MouseArea {
                                        id: rowHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onEntered: root.currentIndex = listRow.index
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
                                model: root.windows
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
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onEntered: root.currentIndex = chip.index
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
