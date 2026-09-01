pragma ComponentBehavior: Bound

import QtQuick 6.10
import Quickshell
import "../../../config" as QsConfig
import "../../../compositor" as QsCompositor
import "../../../singletons" as QsSingletons

// Bar-embedded running-apps taskbar. A minimal pill showing one icon per
// running application; click to focus, hover for a window list. Toggled by
// Flags.barTaskbar (false = workspace pill, true = this taskbar).
Rectangle {
    id: root

    property var screen
    property var barWindow

    readonly property var config: QsConfig.Config
    readonly property var compositor: QsCompositor.Compositor
    readonly property var theme: QsSingletons.Theme
    readonly property var flags: QsSingletons.Flags

    readonly property real s: screen && screen.height ? (screen.height / 1080) * flags.uiScale : 1
    readonly property real iconSize: 16 * root.s
    readonly property real pillH: 28 * root.s
    readonly property color pillBorder: Qt.rgba(theme.cream.r, theme.cream.g, theme.cream.b, 0.10)

    color: theme.pillSurface
    radius: 14 * root.s
    border.width: 1
    border.color: pillBorder
    height: pillH
    visible: root.appItems.length > 0

    Behavior on width {
        enabled: flags.reduceMotion === false
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    // Top highlight
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 1 * root.s
        height: parent.height / 2
        radius: parent.radius - 1
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.04) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // App icon row
    Row {
        id: appRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 8 * root.s
        anchors.right: parent.right
        anchors.rightMargin: 8 * root.s
        spacing: 4 * root.s

        Repeater {
            model: root.appItems

            delegate: TaskbarButton {
                required property var modelData
                appItem: modelData
                taskbar: root
                iconSize: root.iconSize
                onHoverPreviewRequested: root.showPreviewFor(appItem, this)
                onHoverPreviewDismissed: root.schedulePreviewClose()
            }
        }
    }

    width: appRow.implicitWidth + 16 * root.s

    // ─── App model ──────────────────────────────────────────────────────
    // One entry per running appId: { appId, name, icon, toplevels, active }
    property var _entryCache: ({})

    readonly property var appItems: {
        var tls = compositor.toplevels || []
        var active = compositor.activeToplevel
        var isNiri = compositor.isNiri

        var map = {}
        var order = []
        for (var i = 0; i < tls.length; i++) {
            var tl = tls[i]
            if (!tl) continue
            var appId = appIdFor(tl)
            if (!appId) continue
            if (!map[appId]) {
                map[appId] = {
                    appId: appId,
                    name: nameFor(appId),
                    icon: iconFor(appId),
                    toplevels: [],
                    active: false
                }
                order.push(appId)
            }
            map[appId].toplevels.push(tl)
            if (!map[appId].active && isActiveTl(tl, active, isNiri))
                map[appId].active = true
        }

        var out = []
        for (var j = 0; j < order.length; j++)
            out.push(map[order[j]])
        return out
    }

    function appIdFor(tl): string {
        if (tl && typeof tl.appId === "string" && tl.appId) return tl.appId
        if (tl && tl.wayland && typeof tl.wayland.appId === "string" && tl.wayland.appId) return tl.wayland.appId
        if (tl && typeof tl.app_id === "string" && tl.app_id) return tl.app_id
        if (tl && tl.clazz) return tl.clazz
        return ""
    }

    function isActiveTl(tl, active, isNiri): bool {
        if (!tl || !active) return false
        if (isNiri) {
            if (active.id != null && tl.id != null && String(active.id) === String(tl.id)) return true
            return tl.is_focused === true || tl.is_active === true
        }
        if (tl.activated === true) return true
        if (active.address && tl.address && String(active.address) === String(tl.address)) return true
        return false
    }

    function desktopEntry(appId): var {
        if (appId in root._entryCache) return root._entryCache[appId]
        var apps = DesktopEntries.applications.values
        var hit = null
        for (var i = 0; i < apps.length; i++) {
            var e = apps[i]
            if (e && e.id && e.icon && e.id.toLowerCase() === appId.toLowerCase()) { hit = e; break }
        }
        root._entryCache[appId] = hit
        return hit
    }

    function iconFor(appId): string {
        var e = root.desktopEntry(appId)
        if (e && e.icon) return Quickshell.iconPath(e.icon, true)
        return Quickshell.iconPath(appId, true)
    }

    function nameFor(appId): string {
        var e = root.desktopEntry(appId)
        if (e && e.name) return e.name
        var s = String(appId).replace(/[-_.]/g, " ")
        return s.charAt(0).toUpperCase() + s.slice(1)
    }

    // ─── Hover preview ───────────────────────────────────────────────────
    readonly property bool previewEnabled: (root.config.bar && root.config.bar.taskbar && root.config.bar.taskbar.hoverPreview) ?? true

    Timer {
        id: previewCloseTimer
        interval: 180
        repeat: false
        onTriggered: root._closePreviewNow()
    }

    function showPreviewFor(appItem, button): void {
        if (!root.previewEnabled) return
        previewCloseTimer.stop()
        if (!previewLoader.active)
            previewLoader.active = true
        previewLoader.item.show(appItem, button)
    }

    function schedulePreviewClose(): void {
        previewCloseTimer.restart()
    }

    function _closePreviewNow(): void {
        if (previewLoader.active && previewLoader.item)
            previewLoader.item.close()
    }

    Loader {
        id: previewLoader
        active: false
        source: "TaskbarPreview.qml"
        onLoaded: {
            item.compositor = root.compositor
            item.theme = root.theme
            item.anchor.window = root.barWindow
        }
    }
}
