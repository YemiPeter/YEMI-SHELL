// STATUS (parked, not abandoned):
// - Logic ported from iNiR, GlobalStates/waffle dead code removed — done
// - Compositor.dispatch() wiring for focus/close — verified working
// - Bad "Quickshell.Services" import — removed, confirmed unused
// - Config not imported — harmless, falls back to defaults
// - Connections.onToplevelsChanged — signal mismatch, list won't auto-refresh (low priority)
// - REAL BLOCKER: root is `Scope`, which has no visual surface at all.
//   Needs converting to PanelWindow, mirroring modules/osd/Wrapper.qml's setup.
//   That's the actual next step when this gets picked back up.
// Last checked: 2025-07

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

Scope {
    id: root
    property int panelWidth: 380
    property string searchText: ""
    // Animation and visibility control
    readonly property var altSwitcherOptions: Config.options?.altSwitcher ?? {}
    readonly property string altPreset: altSwitcherOptions.preset ?? "default"
    readonly property bool altNoVisualUi: altSwitcherOptions.noVisualUi ?? false
    readonly property bool effectiveNoVisualUi: altNoVisualUi && altPreset !== "skew"
    readonly property bool altMonochromeIcons: altSwitcherOptions.monochromeIcons ?? false
    readonly property bool altEnableAnimation: altSwitcherOptions.enableAnimation ?? true
    readonly property int altAnimationDurationMs: altSwitcherOptions.animationDurationMs ?? 200
    readonly property bool altUseMostRecent: altSwitcherOptions.useMostRecentFirst ?? true
    readonly property bool altEnableBlurGlass: altSwitcherOptions.enableBlurGlass ?? true
    readonly property real altBackgroundOpacity: altSwitcherOptions.backgroundOpacity ?? 0.9
    readonly property real altBlurAmount: altSwitcherOptions.blurAmount ?? 0.4
    readonly property int altScrimDim: altSwitcherOptions.scrimDim ?? 35
    readonly property string altPanelAlignment: altSwitcherOptions.panelAlignment ?? "right"
    readonly property bool altUseM3Layout: altSwitcherOptions.useM3Layout ?? false
    readonly property bool altCompactStyle: altSwitcherOptions.compactStyle ?? false
    readonly property bool altShowOverviewWhileSwitching: altSwitcherOptions.showOverviewWhileSwitching ?? false
    readonly property int altAutoHideDelayMs: altSwitcherOptions.autoHideDelayMs ?? 500

    // Step 3: local replacement for GlobalStates.altSwitcherOpen
    property bool altSwitcherOpen: false

    property bool animationsEnabled: root.effectiveEnableAnimation
    property real panelRightMargin: -panelWidth
    // Snapshot actual de ventanas ordenadas que se usa mientras el panel está abierto
    property var itemSnapshot: []
    // Cache de iconos resueltos para evitar lookups repetidos
    property var iconCache: ({})
    property var iconCacheKeys: []
    readonly property int maxIconCacheSize: 100
    property bool useM3Layout: root.altUseM3Layout
    property bool centerPanel: root.altPanelAlignment === "center"
    property bool compactStyle: root.altCompactStyle && !root.listStyle && !root.skewStyle
    property bool listStyle: altPreset === "list"
    property bool skewStyle: altPreset === "skew"
    property bool showOverviewWhileSwitching: root.altShowOverviewWhileSwitching
    property bool overviewOpenedByAltSwitcher: false
    // Pre-warm flag para evitar lag en primera apertura
    property bool _warmedUp: false
    // Slice geometry base values and responsive scaling
    readonly property int baseSkewSliceWidth: 135
    readonly property int baseSkewExpandedWidth: 924
    readonly property int baseSkewSliceHeight: 520
    readonly property int baseSkewOffset: 35
    readonly property int baseSkewSliceSpacing: -22
    readonly property int skewVisibleCount: 12

    readonly property real skewScale: Math.max(0.58, Math.min(1.0,
        (window.height - 120) / baseSkewSliceHeight,
        (window.width - 96) / baseSkewExpandedWidth
    ))

    readonly property int skewSliceWidth: Math.round(baseSkewSliceWidth * skewScale)
    readonly property int skewExpandedWidth: Math.round(baseSkewExpandedWidth * skewScale)
    readonly property int skewSliceHeight: Math.round(baseSkewSliceHeight * skewScale)
    readonly property int skewOffset: Math.round(baseSkewOffset * skewScale)
    readonly property int skewSliceSpacing: Math.round(baseSkewSliceSpacing * skewScale)
    readonly property int skewCardWidth: skewExpandedWidth + (skewVisibleCount - 1) * (skewSliceWidth + skewSliceSpacing)
    readonly property int skewCardHeight: skewSliceHeight + Math.round(40 * skewScale)
    readonly property int skewPanelWidth: skewCardWidth
    property bool skewCardVisible: false

    property bool _rapidNavigation: false
    property int _rapidNavSteps: 0

    Timer {
        id: skewRapidNavCooldown
        interval: 350
        onTriggered: {
            root._rapidNavigation = false
            root._rapidNavSteps = 0
        }
    }

    function _trackSkewNavStep(): void {
        _rapidNavSteps++
        if (_rapidNavSteps >= 3)
            _rapidNavigation = true
        skewRapidNavCooldown.restart()
    }
    
    readonly property int windowCount: itemSnapshot ? itemSnapshot.length : 0
    readonly property bool isHighLoad: windowCount > 15
    readonly property bool effectiveEnableBlurGlass: root.altEnableBlurGlass && !isHighLoad
    readonly property bool effectiveEnableAnimation: root.altEnableAnimation && !isHighLoad

    property bool quickSwitchDone: false
    property var noUiSnapshot: []
    property int noUiIndex: 0

    property var _pendingWindowsUpdate: null
    Timer {
        id: windowsUpdateDebounce
        interval: 50
        repeat: false
        onTriggered: {
            if (root._pendingWindowsUpdate) {
                root._pendingWindowsUpdate()
                root._pendingWindowsUpdate = null
            }
        }
    }

    Timer {
        id: quickSwitchResetTimer
        interval: 800
        repeat: false
        onTriggered: {
            if (!altSwitcherOpen) {
                root.quickSwitchDone = false
                root.noUiSnapshot = []
                root.noUiIndex = 0
            }
        }
    }

    function toTitleCase(name) {
        if (!name)
            return ""
        let s = name.replace(/[._-]+/g, " ")
        const parts = s.split(/\s+/)
        for (let i = 0; i < parts.length; i++) {
            const p = parts[i]
            if (!p)
                continue
            parts[i] = p.charAt(0).toUpperCase() + p.slice(1)
        }
        return parts.join(" ")
    }

    function getCachedIcon(appId, appName, title) {
        const key = appId || appName || title || ""
        if (iconCache[key] !== undefined) {
            const idx = iconCacheKeys.indexOf(key)
            if (idx >= 0) {
                iconCacheKeys.splice(idx, 1)
                iconCacheKeys.push(key)
            }
            return iconCache[key]
        }
        
        if (iconCacheKeys.length >= maxIconCacheSize) {
            const oldestKey = iconCacheKeys.shift()
            delete iconCache[oldestKey]
        }
        
        // TODO(yemi): decide whether to build icon lookup or skip icons for now
        const icon = ""
        iconCache[key] = icon
        iconCacheKeys.push(key)
        return icon
    }

    function buildItemsFrom(windows, workspaces, mruIds) {
        if (!windows || !windows.length)
            return []

        const items = []
        const itemsById = {}

        for (let i = 0; i < windows.length; i++) {
            const w = windows[i]
            const appId = w.app_id || ""
            let appName = appId
            if (appName && appName.indexOf(".") !== -1) {
                const parts = appName.split(".")
                appName = parts[parts.length - 1]
            }
            if (!appName && w.title)
                appName = w.title

            appName = toTitleCase(appName)
            const ws = workspaces[w.workspace_id]
            const wsIdx = ws && ws.idx !== undefined ? ws.idx : 0

            const item = {
                id: w.id,
                appId: appId,
                appName: appName,
                title: w.title || "",
                workspaceId: w.workspace_id,
                workspaceIdx: wsIdx,
                isFocused: w.is_focused ?? false,
                isFloating: w.is_floating ?? false,
                // TODO(yemi): decide whether to build icon lookup or skip icons for now
                icon: root.getCachedIcon(appId, appName, w.title)
            }
            items.push(item)
            itemsById[item.id] = item
        }

        items.sort(function (a, b) {
            const wa = workspaces[a.workspaceId]
            const wb = workspaces[b.workspaceId]
            const ia = wa ? wa.idx : 0
            const ib = wb ? wb.idx : 0
            if (ia !== ib)
                return ia - ib

            const an = (a.appName || a.title || "").toString()
            const bn = (b.appName || b.title || "").toString()
            const cmp = an.localeCompare(bn)
            if (cmp !== 0)
                return cmp

            return a.id - b.id
        })

        const useMostRecentFirst = root.altUseMostRecentFirst

        if (useMostRecentFirst && mruIds && mruIds.length > 0) {
            const ordered = []
            const used = {}

            for (let i = 0; i < mruIds.length; i++) {
                const id = mruIds[i]
                const it = itemsById[id]
                if (it) {
                    ordered.push(it)
                    used[id] = true
                }
            }

            for (let i = 0; i < items.length; i++) {
                const it = items[i]
                if (!used[it.id])
                    ordered.push(it)
            }

            return ordered
        }

        return items
    }

    property bool _rebuildPending: false
    
    function rebuildSnapshot() {
        if (_rebuildPending) return
        _rebuildPending = true
        
        Qt.callLater(function() {
            _rebuildPending = false
            // Compositor.toplevels is an object keyed by id; convert to array for buildItemsFrom
            const windows = Object.values(Compositor.toplevels || {})
            const workspaces = Compositor.workspaces || {}
            // TODO(yemi): Compositor.qml doesn't expose an equivalent of NiriService.mruWindowIds yet — needs to be added there first
            const mruIds = []
            itemSnapshot = buildItemsFrom(windows, workspaces, mruIds)
        })
    }

    function rebuildSnapshotSync() {
        const windows = Object.values(Compositor.toplevels || {})
        const workspaces = Compositor.workspaces || {}
        // TODO(yemi): Compositor.qml doesn't expose an equivalent of NiriService.mruWindowIds yet — needs to be added there first
        const mruIds = []
        itemSnapshot = buildItemsFrom(windows, workspaces, mruIds)
    }

    function rebuildNoUiSnapshotSync() {
        const windows = Object.values(Compositor.toplevels || {})
        const workspaces = Compositor.workspaces || {}
        // TODO(yemi): Compositor.qml doesn't expose an equivalent of NiriService.mruWindowIds yet — needs to be added there first
        const mruIds = []
        root.noUiSnapshot = buildItemsFrom(windows, workspaces, mruIds)
        root.noUiIndex = 0
    }
    
    function rebuildNoUiSnapshot() {
        if (_noUiRebuildPending) return
        _noUiRebuildPending = true
        
        Qt.callLater(function() {
            _noUiRebuildPending = false
            rebuildNoUiSnapshotSync()
        })
    }

    function focusNoUiIndex() {
        const len = root.noUiSnapshot?.length ?? 0
        if (len <= 0)
            return
        const idx = Math.max(0, Math.min(len - 1, root.noUiIndex))
        const id = root.noUiSnapshot[idx]?.id
        if (id !== undefined)
            // TODO(yemi): Compositor.qml doesn't expose an equivalent of NiriService.focusWindow yet — needs to be added there first
            Compositor.dispatch("focus-window --id " + id)
    }

    function ensureSnapshot() {
        if (!itemSnapshot || itemSnapshot.length === 0) {
            if (root.skewStyle)
                rebuildSnapshotSync()
            else
                rebuildSnapshot()
        }
    }

    function maybeOpenOverview() {
        if (Compositor.runningCompositor !== "niri")
            return
        if (!root.altShowOverviewWhileSwitching)
            return
        // TODO(yemi): Compositor.qml doesn't expose an equivalent of NiriService.inOverview yet — needs to be added there first
        // TODO(yemi): Compositor.qml doesn't expose an equivalent of NiriService.toggleOverview yet — needs to be added there first
        overviewOpenedByAltSwitcher = false
    }

    function maybeCloseOverview() {
        if (Compositor.runningCompositor !== "niri")
            return
        if (!root.altShowOverviewWhileSwitching)
            return
        // TODO(yemi): Compositor.qml doesn't expose an equivalent of NiriService.inOverview yet — needs to be added there first
        // TODO(yemi): Compositor.qml doesn't expose an equivalent of NiriService.toggleOverview yet — needs to be added there first
        overviewOpenedByAltSwitcher = false
    }

    function currentAnimDuration() {
        return root.altAnimationDurationMs
    }

    function showPanel() {
        if (root.skewStyle) {
            rebuildSnapshotSync()
            root.skewCardVisible = false
            if (listView.currentIndex < 0 || listView.currentIndex >= (itemSnapshot?.length ?? 0))
                listView.currentIndex = root.defaultSkewIndex()
            skewCardShowTimer.restart()
        } else {
            rebuildSnapshot()
        }
        if (Compositor.runningCompositor === "niri" && root.skewStyle)
            // TODO(yemi): Compositor.qml doesn't expose an equivalent of WindowPreviewService.captureForTaskView yet — needs to be added there first
            Qt.callLater(() => {})
        panelVisible = true
        if (animationsEnabled && !centerPanel && !compactStyle && !root.listStyle && !root.skewStyle) {
            const dur = currentAnimDuration()
            slideOutAnim.stop()
            root.panelRightMargin = -panelWidth
            slideInAnim.from = -panelWidth
            slideInAnim.to = 0
            slideInAnim.duration = dur
            slideInAnim.restart()
        } else {
            panelRightMargin = 0
        }
    }

    function hidePanel() {
        if (!panelVisible)
            return
        skewCardShowTimer.stop()
        root.skewCardVisible = false
        if (animationsEnabled && !centerPanel && !root.listStyle && !root.skewStyle) {
            const dur = currentAnimDuration()
            slideInAnim.stop()
            slideOutAnim.from = panelRightMargin
            slideOutAnim.to = -panelWidth
            slideOutAnim.duration = dur
            slideOutAnim.restart()
        } else {
            panelRightMargin = -panelWidth
            panelVisible = false
        }
    }

    function hasItems() {
        ensureSnapshot()
        return itemSnapshot && itemSnapshot.length > 0
    }

    function ensureOpen() {
        if (!altSwitcherOpen) {
            altSwitcherOpen = true
        }
    }

    function defaultSkewIndex() {
        const total = itemSnapshot?.length ?? 0
        if (total <= 0)
            return -1
        return total > 1 ? 1 : 0
    }

    function openSkewSwitcher() {
        autoHideTimer.stop()
        rebuildSnapshotSync()
        if ((itemSnapshot?.length ?? 0) === 0)
            return
        ensureOpen()
        listView.currentIndex = defaultSkewIndex()
    }

    function closeSelectedWindow(): void {
        if (!itemSnapshot || itemSnapshot.length === 0)
            return
        const idx = listView.currentIndex
        if (idx < 0 || idx >= itemSnapshot.length)
            return
        const win = itemSnapshot[idx]
        if (win?.id !== undefined)
            // TODO(yemi): Compositor.qml doesn't expose an equivalent of NiriService.closeWindow yet — needs to be added there first
            Compositor.dispatch("close-window --id " + win.id)
    }

    function confirmCurrentSelection() {
        root.activateCurrent()
        altSwitcherOpen = false
    }

    function nextItem() {
        if (root.skewStyle)
            root._trackSkewNavStep()
        ensureSnapshot()
        const total = itemSnapshot ? itemSnapshot.length : 0
        if (total === 0)
            return
        if (listView.currentIndex < 0)
            listView.currentIndex = 0
        else
            listView.currentIndex = (listView.currentIndex + 1) % total
        // TODO(yemi): this calls an iNiR helper function that doesn't exist in this project — listView.positionViewAtIndex
    }

    function previousItem() {
        if (root.skewStyle)
            root._trackSkewNavStep()
        ensureSnapshot()
        const total = itemSnapshot ? itemSnapshot.length : 0
        if (total === 0)
            return
        if (listView.currentIndex < 0)
            listView.currentIndex = total - 1
        else
            listView.currentIndex = (listView.currentIndex - 1 + total) % total
        // TODO(yemi): this calls an iNiR helper function that doesn't exist in this project — listView.positionViewAtIndex
    }

    function activateCurrent() {
        if (root.skewStyle) {
            const idx = listView.currentIndex
            if (idx >= 0 && idx < (itemSnapshot?.length ?? 0)) {
                const item = itemSnapshot[idx]
                if (item?.id !== undefined)
                    // TODO(yemi): Compositor.qml doesn't expose an equivalent of NiriService.focusWindow yet — needs to be added there first
                    Compositor.dispatch("focus-window --id " + item.id)
            }
            return
        }
        if (listView.currentItem && listView.currentItem.activate) {
            // TODO(yemi): this calls an iNiR helper function that doesn't exist in this project — listView.currentItem.activate
            listView.currentItem.activate()
        }
    }

    // Pre-warm: construir snapshot en background después de que el shell inicie
    // para evitar lag en la primera apertura
    Timer {
        id: warmUpTimer
        interval: 2000  // 2 segundos después del inicio
        running: !root._warmedUp && (Object.keys(Compositor.toplevels || {}).length > 0)
        onTriggered: {
            root.rebuildSnapshot()
            root._warmedUp = true
            // Limpiar snapshot después de warm-up (se reconstruye al abrir)
            Qt.callLater(function() {
                if (!altSwitcherOpen)
                    root.itemSnapshot = []
            })
        }
    }

    // Re-warm cuando cambian las ventanas (solo si no está abierto)
    Connections {
        target: Compositor
        enabled: root._warmedUp && !altSwitcherOpen
        function onToplevelsChanged() {
            const wins = Object.values(Compositor.toplevels || {})
            for (let i = 0; i < wins.length; i++) {
                const w = wins[i]
                const key = w.app_id || ""
                if (key && root.iconCache[key] === undefined) {
                    root.getCachedIcon(w.app_id, "", w.title)
                }
            }
        }
    }
    
    Timer {
        id: noUiSnapshotUpdateTimer
        interval: 3000
        repeat: true
        running: root.effectiveNoVisualUi && !altSwitcherOpen
        onTriggered: {
            const wins = Object.values(Compositor.toplevels || {})
            if (wins.length > 0) {
                Qt.callLater(function() {
                    const windows = Object.values(Compositor.toplevels || {})
                    const workspaces = Compositor.workspaces || {}
                    // TODO(yemi): Compositor.qml doesn't expose an equivalent of NiriService.mruWindowIds yet — needs to be added there first
                    const mruIds = []
                    root.noUiSnapshot = buildItemsFrom(windows, workspaces, mruIds)
                })
            }
        }
    }

    // Minimal visual layer - a plain box showing window titles with selected item highlighted
    Rectangle {
        id: altSwitcherPanel
        width: root.panelWidth
        height: Math.min(400, parent.height - 100)  // Max height to fit on screen
        x: root.centerPanel ? (parent.width - width) / 2 : parent.width + root.panelRightMargin
        y: (parent.height - height) / 2
        color: "#2d2d2d"
        opacity: root.altBackgroundOpacity
        radius: 12
        border.color: "#444"
        border.width: 1
        visible: altSwitcherOpen && !root.effectiveNoVisualUi && !root.skewStyle

        // Semi-transparent background overlay
        Rectangle {
            anchors.fill: parent.parent
            color: "#000000"
            opacity: 0.5 * (root.altScrimDim / 100)
            visible: altSwitcherOpen && !root.effectiveNoVisualUi && !root.skewStyle
            z: -1  // Behind the panel
        }

        ListView {
            id: listView
            anchors.fill: parent
            anchors.margins: 10
            model: root.itemSnapshot
            currentIndex: 0  // Default to first item
            
            delegate: Rectangle {
                width: listView.width - 20
                height: 40
                color: index === listView.currentIndex ? "#4a90e2" : "transparent"
                radius: 6
                
                Text {
                    anchors.centerIn: parent
                    text: modelData.title || modelData.appName || "Unknown Window"
                    color: index === listView.currentIndex ? "#ffffff" : "#cccccc"
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        listView.currentIndex = index
                        root.activateCurrent()
                        root.altSwitcherOpen = false
                    }
                }
            }
            
            highlight: Rectangle {
                color: "#4a90e2"
                radius: 6
            }
            
            focus: true
        }
        
        // Auto-hide timer
        Timer {
            id: autoHideTimer
            interval: root.altAutoHideDelayMs
            onTriggered: {
                if (root.altSwitcherOpen && !root.effectiveNoVisualUi) {
                    root.altSwitcherOpen = false
                }
            }
        }
        
        // Slide animations
        SequentialAnimation {
            id: slideInAnim
            PropertyAction { target: root; property: "panelRightMargin"; value: 0 }
        }
        
        SequentialAnimation {
            id: slideOutAnim
            PropertyAction { target: root; property: "panelRightMargin"; value: -root.panelWidth }
            onFinished: {
                root.panelVisible = false
            }
        }
        
        // Timer for skew card visibility
        Timer {
            id: skewCardShowTimer
            interval: 100
            onTriggered: {
                root.skewCardVisible = true
            }
        }
    }

    // Public API — called from shell.qml's IpcHandler via altSwitcherLoader.item
    function toggle(): void {
        if (root.skewStyle) {
            if (altSwitcherOpen)
                altSwitcherOpen = false
            else
                root.openSkewSwitcher()
            return
        }
        altSwitcherOpen = !altSwitcherOpen
        if (altSwitcherOpen)
            autoHideTimer.restart()
    }

    function open(): void {
        if (root.skewStyle) {
            root.openSkewSwitcher()
            return
        }
        ensureOpen()
        autoHideTimer.restart()
    }

    function close(): void {
        altSwitcherOpen = false
    }

    function next(): void {
        if (root.effectiveNoVisualUi) {
            autoHideTimer.stop()
            altSwitcherOpen = false
            const len = root.noUiSnapshot?.length ?? 0
            if (!root.quickSwitchDone || len === 0)
                root.rebuildNoUiSnapshotSync()
            const newLen = root.noUiSnapshot?.length ?? 0
            if (newLen === 0) return
            if (!root.quickSwitchDone) {
                root.quickSwitchDone = true
                root.noUiIndex = newLen > 1 ? 1 : 0
            } else {
                root.noUiIndex = (root.noUiIndex + 1) % newLen
            }
            root.focusNoUiIndex()
            quickSwitchResetTimer.restart()
            return
        }
        if (root.skewStyle) {
            if (!altSwitcherOpen) { root.openSkewSwitcher(); return }
            nextItem(); return
        }
        ensureOpen()
        nextItem()
        activateCurrent()
        autoHideTimer.restart()
    }

    function previous(): void {
        if (root.effectiveNoVisualUi) {
            autoHideTimer.stop()
            altSwitcherOpen = false
            const len = root.noUiSnapshot?.length ?? 0
            if (!root.quickSwitchDone || len === 0)
                root.rebuildNoUiSnapshotSync()
            const newLen = root.noUiSnapshot?.length ?? 0
            if (newLen === 0) return
            if (!root.quickSwitchDone) {
                root.quickSwitchDone = true
                root.noUiIndex = newLen > 1 ? (newLen - 1) : 0
            } else {
                root.noUiIndex = (root.noUiIndex - 1 + newLen) % newLen
            }
            root.focusNoUiIndex()
            quickSwitchResetTimer.restart()
            return
        }
        if (root.skewStyle) {
            if (!altSwitcherOpen) { root.openSkewSwitcher(); return }
            previousItem(); return
        }
        ensureOpen()
        previousItem()
        activateCurrent()
        autoHideTimer.restart()
    }
}