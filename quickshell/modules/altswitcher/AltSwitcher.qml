import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../pill/Singletons" // Motion (shared duration/curve tokens, reduceMotion)
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
 * Open/close is a Caelestia-style spring reveal (see the "Open/close motion"
 * section below): the scrim crossfades, the card pops from 85% scale with a
 * Material 3 expressive overshoot curve, and the tile grid cascades in with a
 * per-index stagger. reduceMotion turns it into a plain fade.
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
        // reveal flips and the Behavior below drives the whole spring — no
        // manual animation objects, so close→reopen interruptions blend.
        root.open = true
        cardHolder.forceActiveFocus()
    }
    function close(): void { root.open = false }
    function next(): void {
        if (!root.open) {
            root.openSwitcher()
            return
        }
        if (root.count > 0)
            root.currentIndex = (root.currentIndex + 1) % root.count
    }
    function previous(): void {
        if (!root.open) {
            root.openSwitcher()
            return
        }
        if (root.count > 0)
            root.currentIndex = (root.currentIndex - 1 + root.count) % root.count
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
    function focusWindow(w: var): void {
        if (!w)
            return
        // Hyprland focuses by address through the unified dispatch path
        // (same convention as bar AppIcons). Niri uses its IPC action.
        if (root.isHyprland) {
            if (w.address)
                compositor.dispatch("focuswindow address:" + String(w.address))
            return
        }
        focusProc.command = ["niri", "msg", "action", "focus-window", "--id", String(w.id)]
        focusProc.running = true
    }

    // ── Open/close motion ────────────────────────────────────────────────────────
    // Caelestia-style single-reveal driver (their modules/*/Wrapper.qml
    // `offsetScale` pattern): every animated property derives from one `reveal`
    // scalar (0 closed → 1 open), so a close interrupted by a reopen — or the
    // reverse — blends perfectly with zero animation juggling. The open curve
    // is Material 3's expressive default spatial spring (overshoot + settle,
    // same tokens caelestia's components/Anim.qml uses); close is deliberately
    // faster so rapid Alt+Tab never feels laggy. reduceMotion: Motion durations
    // drop to 40%, and the pose legs below collapse to a plain fade.
    readonly property real reveal: root.open ? 1 : 0
    Behavior on reveal {
        NumberAnimation {
            duration: root.open ? Motion.expressive : Motion.fast
            easing.type: root.open ? Motion.easeMorph : Motion.easeStandard
            easing.bezierCurve: Motion.springCurve
        }
    }

    // ── Overlay ─────────────────────────────────────────────────────────────────
    PanelWindow {
        id: panel
        // Stays mapped until the reveal fade drains, so the close animation is
        // visible; hides once everything is fully transparent.
        visible: root.reveal > 0.001
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

        // Dim everything behind the glass. Crossfades with the reveal driver.
        Rectangle {
            id: scrim
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, root.scrimDim)
            opacity: root.reveal
            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        // Centered frosted-glass card. Closed pose: 15% smaller and 18px low;
        // the reveal driver's spring curve pops it in with a visible
        // overshoot-settle. reduceMotion keeps the card at identity — a pure
        // fade. Explicit x/y centering (not anchors.centerIn) so the settle
        // offset can share the y binding.
        Item {
            id: cardHolder
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
                + (Motion.reduce ? 0 : (1 - root.reveal) * 18 * root.s)
            width: Math.min(parent.width * 0.82, 960)
            height: Math.min(parent.height * 0.82, 600)
            transformOrigin: Item.Center
            scale: Motion.reduce ? 1 : 0.85 + 0.15 * root.reveal
            opacity: root.reveal
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

                                    // Staggered grid reveal: each tile's opacity
                                    // and rise derive from the shared reveal
                                    // driver with an index-based delay, so the
                                    // grid cascades in during the open spring
                                    // and dissolves out on close. At rest
                                    // (reveal 0 or 1) every tile is fully
                                    // computed — no per-tile animation state.
                                    readonly property real delay: Math.min(0.55,
                                        Math.floor(index / Math.max(1, root._cols)) * 0.07
                                        + (index % Math.max(1, root._cols)) * 0.035)
                                    readonly property real t: root.reveal >= 1 ? 1
                                        : Math.max(0, Math.min(1,
                                            (root.reveal - delay) / Math.max(0.001, 1 - delay)))

                                    width: root.tileWidth * root.s
                                    height: root.tileHeight * root.s
                                    opacity: Motion.reduce ? root.reveal : t
                                    transform: Translate {
                                        y: (Motion.reduce ? (1 - root.reveal) : (1 - tile.t)) * 14 * root.s
                                    }
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
