import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../singletons" as QsSingletons
import "../../config" as QsConfig

// ═══════════════════════════════════════════════════════════════════════════════
// AltSwitcher — ported from iNiR, stripped of iNiR-specific dependencies.
//
//   Uses CompositorService (the unified multi-compositor facade) for:
//     - mruWindowIds  → the MRU window list (Alt-Tab order)
//     - windows       → visual data (title, appId) for each MRU id
//     - focusWindow() → route focus to Hyprland or Niri
//     - closeWindow() → route close to Hyprland or Niri
//
//   Styling uses Yemi-Shell's Theme singleton (Theme.surface, Theme.primary…).
//   No iNiR config options, global switcher state, theme service, or NiriService.
// ═══════════════════════════════════════════════════════════════════════════════

Scope {
    id: root

    // === State ===
    property bool open: false
    property int currentIndex: 0
    property var itemSnapshot: []

    // === Build the MRU-ordered window list from CompositorService ===
    function buildItems() {
        const mru = QsSingletons.CompositorService.mruWindowIds || []
        const windows = QsSingletons.CompositorService.windows || []
        const byId = {}
        for (let i = 0; i < windows.length; i++) {
            const w = windows[i]
            if (w && w.id !== undefined)
                byId[w.id] = w
        }

        const items = []
        const used = {}
        // MRU order first
        for (let i = 0; i < mru.length; i++) {
            const id = mru[i]
            const w = byId[id]
            if (w) {
                items.push({
                    id: w.id,
                    appId: w.app_id || "",
                    title: w.title || "",
                    icon: w.icon || "",
                    isFocused: w.isFocused || false
                })
                used[id] = true
            }
        }
        // Any remaining windows not in MRU (fallback)
        for (let i = 0; i < windows.length; i++) {
            const w = windows[i]
            if (w && w.id !== undefined && !used[w.id]) {
                items.push({
                    id: w.id,
                    appId: w.app_id || "",
                    title: w.title || "",
                    icon: w.icon || "",
                    isFocused: w.isFocused || false
                })
            }
        }
        root.itemSnapshot = items
        if (root.currentIndex >= items.length)
            root.currentIndex = items.length > 0 ? items.length - 1 : 0
    }

    // === Alt-Tab cycling ===
    function nextItem() {
        if (itemSnapshot.length === 0) return
        // Clamp against a possibly-shrunk list (a window closed mid-cycle)
        if (currentIndex >= itemSnapshot.length)
            currentIndex = itemSnapshot.length - 1
        currentIndex = (currentIndex + 1) % itemSnapshot.length
    }

    function previousItem() {
        if (itemSnapshot.length === 0) return
        // Clamp against a possibly-shrunk list (a window closed mid-cycle)
        if (currentIndex >= itemSnapshot.length)
            currentIndex = itemSnapshot.length - 1
        currentIndex = (currentIndex - 1 + itemSnapshot.length) % itemSnapshot.length
    }

    // === Selection ===
    // select(id): focus the window and close the UI. MRU is pushed to the front
    // by CompositorService only when focus actually lands (successful select).
    function select(id) {
        if (id === undefined || id === null) return
        QsSingletons.CompositorService.focusWindow(id)
        root.close()
    }

    // hide(): cancel the switch and close the UI without focusing.
    function hide() {
        root.close()
    }

    function activateCurrent() {
        if (currentIndex >= 0 && currentIndex < itemSnapshot.length) {
            const item = itemSnapshot[currentIndex]
            if (item && item.id !== undefined)
                root.select(item.id)
        } else {
            root.close()
        }
    }

    function closeSelectedWindow() {
        if (currentIndex >= 0 && currentIndex < itemSnapshot.length) {
            const item = itemSnapshot[currentIndex]
            if (item && item.id !== undefined)
                QsSingletons.CompositorService.closeWindow(item.id)
        }
    }

    function open() {
        // No point opening a switcher when there is nothing to switch to.
        if (QsSingletons.CompositorService.windows.length < 2) return
        root.buildItems()
        if (itemSnapshot.length === 0) return
        // Start on the second item (first is the current window)
        currentIndex = itemSnapshot.length > 1 ? 1 : 0
        root.open = true
        window.visible = true
        altReleaseDetector.forceActiveFocus()
    }

    function close() {
        root.open = false
        window.visible = false
    }

    function toggle() {
        if (root.open) root.close()
        else root.open()
    }

    // === IPC Handler (master plan Section 3 trigger API) ===
    IpcHandler {
        target: "altSwitcher"

        // Canonical trigger methods
        function show(): void { root.open() }
        function next(): void {
            if (!root.open) root.open()
            else root.nextItem()
        }
        function prev(): void {
            if (!root.open) root.open()
            else root.previousItem()
        }
        function select(id: string): void { root.select(id) }
        function hide(): void { root.hide() }

        // Backward-compatible aliases (shell.qml wiring)
        function open(): void { root.open() }
        function close(): void { root.close() }
        function toggle(): void { root.toggle() }
        function previous(): void {
            if (!root.open) root.open()
            else root.previousItem()
        }
    }

    // === Fullscreen overlay window ===
    PanelWindow {
        id: window
        visible: false
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "quickshell:altSwitcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Scrim
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.35)
            visible: root.open
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }

        // Keyboard focus for Alt-Tab cycling
        FocusScope {
            id: altReleaseDetector
            anchors.fill: parent
            focus: root.open
            activeFocusOnTab: false

            Keys.onPressed: function (event) {
                if (!root.open) return
                if (event.key === Qt.Key_Escape) {
                    root.close()
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.activateCurrent()
                    event.accepted = true
                } else if (event.key === Qt.Key_Tab) {
                    if (event.modifiers & Qt.ShiftModifier)
                        root.previousItem()
                    else
                        root.nextItem()
                    event.accepted = true
                } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                    root.nextItem()
                    event.accepted = true
                } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                    root.previousItem()
                    event.accepted = true
                } else if (event.key === Qt.Key_C || event.key === Qt.Key_Delete) {
                    root.closeSelectedWindow()
                    event.accepted = true
                }
            }

            Keys.onReleased: function (event) {
                if (!root.open) return
                if (event.key === Qt.Key_Alt) {
                    root.activateCurrent()
                    event.accepted = true
                }
            }
        }

        // === Centered panel ===
        Rectangle {
            id: panel
            anchors.centerIn: parent
            width: 420
            implicitHeight: contentColumn.implicitHeight + 24
            radius: QsConfig.Appearance.rounding.large
            color: QsSingletons.Theme.tileBg
            border.width: 1
            border.color: QsSingletons.Theme.border
            visible: root.open

            ColumnLayout {
                id: contentColumn
                anchors.fill: parent
                anchors.margins: 12
                spacing: 4

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 8

                    Text {
                        text: "Switch windows"
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        color: QsSingletons.Theme.cream
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.itemSnapshot.length + " windows"
                        font.pixelSize: 12
                        color: QsSingletons.Theme.subtle
                    }
                }

                // Window list
                ListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(root.itemSnapshot.length, 8) * 52
                    clip: true
                    spacing: 2
                    model: root.itemSnapshot
                    currentIndex: root.currentIndex

                    delegate: Item {
                        required property var modelData
                        required property int index
                        width: listView.width
                        height: 50

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: index === listView.currentIndex
                                ? QsSingletons.Theme.verm
                                : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            // Left indicator dot
                            Rectangle {
                                Layout.alignment: Qt.AlignVCenter
                                width: 6
                                height: 6
                                radius: 3
                                color: index === listView.currentIndex
                                    ? QsSingletons.Theme.onGlow
                                    : "transparent"
                                visible: index === listView.currentIndex
                            }

                            // App icon (resolved from CompositorService.windows[].icon).
                            // Falls back to a generic themed icon when the app_id/icon is empty.
                            IconImage {
                                Layout.alignment: Qt.AlignVCenter
                                width: 28
                                height: 28
                                source: Quickshell.iconPath(modelData.icon, "preferences-system-windows")
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.appId || modelData.title || "Window"
                                    font.pixelSize: 14
                                    font.weight: index === listView.currentIndex ? Font.DemiBold : Font.Normal
                                    color: index === listView.currentIndex
                                        ? QsSingletons.Theme.onGlow
                                        : QsSingletons.Theme.cream
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.title
                                    visible: modelData.title && modelData.title !== modelData.appId
                                    font.pixelSize: 11
                                    color: index === listView.currentIndex
                                        ? QsSingletons.Theme.verm
                                        : QsSingletons.Theme.subtle
                                    elide: Text.ElideRight
                                }
                            }

                            // Focused badge
                            Rectangle {
                                Layout.alignment: Qt.AlignVCenter
                                visible: modelData.isFocused
                                width: focusText.implicitWidth + 10
                                height: 18
                                radius: 9
                                color: QsSingletons.Theme.verm

                                Text {
                                    id: focusText
                                    anchors.centerIn: parent
                                    text: "FOCUSED"
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    font.letterSpacing: 0.5
                                    color: QsSingletons.Theme.onGlow
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                listView.currentIndex = index
                                root.activateCurrent()
                            }
                        }
                    }
                }
            }
        }
    }

    // Rebuild when the MRU list changes while open
    Connections {
        target: QsSingletons.CompositorService
        function onMruWindowIdsChanged() {
            if (root.open)
                root.buildItems()
        }
    }
}