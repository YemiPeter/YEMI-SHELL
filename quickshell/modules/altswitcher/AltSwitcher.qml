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
 * A full-screen overlay (niri-only) that shows every open window as a frosted
 * glass tile, navigable with Alt+Tab / Alt+Shift+Tab and focusable with a click.
 * The whole feature is gated by Flags.altSwitcherEnabled (toggle in Appearance
 * settings), mirroring iNiR's "button so it can be toggled on/off".
 *
 * Keyboard is NOT grabbed here on purpose: navigation is driven by compositor
 * keybinds (niri Alt+Tab / Alt+Shift+Tab) that call `qs ipc call altSwitcher
 * next|previous`, so tapping Tab cycles without a focus fight between the
 * overlay and the compositor. Mod+Tab is left to niri's own toggle-overview.
 */
Scope {
    id: root

    // ── Tunables ──────────────────────────────────────────────────────────────
    readonly property real scrimDim: 0.35          // 0..1 darkness behind the glass
    readonly property bool blurGlass: true         // frosted backdrop via compositor BackgroundEffect
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

    // ── Runtime state ──────────────────────────────────────────────────────────
    property bool open: false
    property int currentIndex: 0
    readonly property real s: QsSingletons.Flags.uiScale

    // Live, sorted window list (by workspace idx, then app name).
    readonly property var windows: (function () {
        const raw = (compositor.toplevels || []).slice()
        raw.sort(function (a, b) {
            const wa = compositor.workspaces.find(function (w) { return w.id === a.workspace_id })
            const wb = compositor.workspaces.find(function (w) { return w.id === b.workspace_id })
            const ia = wa ? (wa.idx ?? 0) : 0
            const ib = wb ? (wb.idx ?? 0) : 0
            if (ia !== ib)
                return ia - ib
            return String(a.app_id || "").localeCompare(String(b.app_id || ""))
        })
        return raw
    })()

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
        if (!root.isNiri)
            return
        root.currentIndex = 0
        root.open = true
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
        focusProc.command = ["niri", "msg", "action", "focus-window", "--id", String(w.id)]
        focusProc.running = true
    }

    // ── Overlay ─────────────────────────────────────────────────────────────────
    PanelWindow {
        id: panel
        visible: root.open
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:altSwitcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
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
        }

        // Dim everything behind the glass.
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, root.scrimDim)
            visible: root.open
            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        // Centered frosted-glass card.
        Item {
            id: cardHolder
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.82, 960)
            height: Math.min(parent.height * 0.82, 600)

            Rectangle {
                id: card
                anchors.fill: parent
                radius: 20
                color: Qt.alpha(root.cSurface, 0.72)
                border.color: root.cBorder
                border.width: 1

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
                                text: "Alt+Tab next · Alt+Shift+Tab prev · click to focus"
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
                                                text: root.appLabel(modelData.app_id)
                                                color: root.cText
                                                font.family: QsSingletons.Theme.font
                                                font.pixelSize: 13 * root.s
                                                font.weight: Font.Bold
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.title || root.wsLabel(modelData.workspace_id)
                                                color: root.cSubText
                                                font.family: QsSingletons.Theme.font
                                                font.pixelSize: 11 * root.s
                                                elide: Text.ElideRight
                                                maximumLineCount: 2
                                                wrapMode: Text.Wrap
                                            }
                                            Item { Layout.fillHeight: true }
                                            Text {
                                                text: root.wsLabel(modelData.workspace_id)
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
