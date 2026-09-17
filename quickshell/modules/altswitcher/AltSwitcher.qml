import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../services" as QsServices
import "../../singletons" as QsSingletons
import "../../compositor" as QsCompositor

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
            console.log("[AltSwitcher] advanceHide fired, open =", root.open,
                        "flag =", QsSingletons.Flags.altSwitcherAdvanceOnTap)
            if (root.open && QsSingletons.Flags.altSwitcherAdvanceOnTap)
                root.close()
        }
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
        if (!root.open) {
            root.openSwitcher()
            // Advance-on-tap: the FIRST tap already switches (classic Alt+Tab
            // feel) — open, advance past the resting index, focus, arm hide.
            if (QsSingletons.Flags.altSwitcherAdvanceOnTap && root.count > 0) {
                root.currentIndex = (root.currentIndex + 1) % root.count
                root.focusWindow(root.windows[root.currentIndex])
                advanceHideTimer.restart()
            }
            return
                }
        if (root.count > 0) {
            root.currentIndex = (root.currentIndex + 1) % root.count
            // Advance-on-tap (iNiR behaviour, here toggleable): every tap
            // commits immediately — focus moves with the highlight.
            if (QsSingletons.Flags.altSwitcherAdvanceOnTap) {
                console.log("[AltSwitcher-debug] ELSE next() count=", root.count, "currentIndex=", root.currentIndex, "w.count=", root.windows.length, "addr=", root.windows[root.currentIndex]?.address)
                root.focusWindow(root.windows[root.currentIndex])
                // iNiR's auto-hide: closes shortly after the last tap, which
                // is what makes releasing Alt feel like it closes itself.
                advanceHideTimer.restart()
            }
        }
    }
    function previous(): void {
        if (!root.open) {
            root.openSwitcher()
            // Advance-on-tap: first tap walks BACKWARD from the end of the
            // list (count - 1), mirroring next()'s first-tap advance.
            if (QsSingletons.Flags.altSwitcherAdvanceOnTap && root.count > 0) {
                root.currentIndex = root.count - 1
                root.focusWindow(root.windows[root.currentIndex])
                advanceHideTimer.restart()
            }
            return
        }
        if (root.count > 0) {
            root.currentIndex = (root.currentIndex - 1 + root.count) % root.count
            // Mirrors next(): each tap commits immediately when enabled.
            if (QsSingletons.Flags.altSwitcherAdvanceOnTap) {
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
        if (!root.open || !QsSingletons.Flags.altSwitcherAdvanceOnTap)
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
        // Stays mapped until the fade drains so the close animation is visible.
        visible: root.open || scrim.opacity > 0.001 || cardHolder.opacity > 0.001
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
        BackgroundEffect.blurRegion: root.blurGlass ? blurRegion : null

        Region {
            id: blurRegion
            item: cardHolder
            radius: 20 * root.s
        }

        // Dim everything behind the glass. Zen fade: crossfades in over 300ms,
        // out over 140ms (faster close so rapid Alt+Tab never feels laggy).
        // Durations are local on purpose — no shared Motion changes.
        Rectangle {
            id: scrim
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, root.scrimDim)
            opacity: root.open ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: root.open ? 300 : 140
                    easing.type: Easing.OutCubic
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        // Centered frosted-glass card. Zen fade: pure opacity, no transforms.
        Item {
            id: cardHolder
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.82, 960)
            height: Math.min(parent.height * 0.82, 600)
            opacity: root.open ? 1 : 0
            Behavior on opacity {
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
                        color: Qt.alpha(root.cSurface, 0.72)
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

                    // Window grid
                    Flickable {
                        id: scroll
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
