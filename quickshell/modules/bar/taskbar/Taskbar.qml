pragma ComponentBehavior: Bound

import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import "../../../config" as QsConfig
import "../../../compositor" as QsCompositor
import "../../../singletons" as QsSingletons

// Bar-embedded taskbar (running applications), ported from iNiR's BarTaskbar
// and adapted to YEMI-SHELL's Compositor singleton + Theme tokens.
// Renders as a pill matching the bar's other modules, showing every running app
// (grouped by appId) with active/running indicators and a hover preview that
// lists that app's windows. Rebuilds whenever the Compositor toplevel list
// changes (window open/close/focus), mirroring iNiR's rebuild-on-change.
Rectangle {
    id: root

    property var screen
    property var barWindow
    property var config: QsConfig.Config
    readonly property var compositor: QsCompositor.Compositor
    readonly property var theme: QsSingletons.Theme

    readonly property real s: screen && screen.height ? (screen.height / 1080) * QsSingletons.Flags.uiScale : 1
    readonly property var tbConfig: (config && config.bar && config.bar.taskbar) ? config.bar.taskbar : ({})
    readonly property real iconSize: (tbConfig.iconSize ?? 16) * root.s
    readonly property color pillBorderColor: Qt.rgba(theme.cream.r, theme.cream.g, theme.cream.b, 0.10)

    color: theme.pillSurface
    radius: 14 * root.s
    border.width: 1
    border.color: root.pillBorderColor
    height: 28 * root.s
    // Width is driven by the app row; hide when nothing is running.
    visible: root.appItems.length > 0

    Behavior on width {
        enabled: QsSingletons.Flags.reduceMotion === false
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    // Top highlight, matching the bar's pill style.
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

    // We need the row id declared before the width binding below.
    Row {
        id: appRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 8 * root.s
        anchors.right: parent.right
        anchors.rightMargin: 8 * root.s
        spacing: (root.tbConfig.spacing ?? 2) * root.s

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

    // Width follows the app row.
    width: appRow.implicitWidth + 16 * root.s

    // ─── App model (mirrors iNiR's running-app derivation) ────────────────
    property var _entryCache: ({})

    readonly property var appItems: {
        var tls = compositor.toplevels || [];
        var active = compositor.activeToplevel;

        var map = {};
        var order = [];
        for (var i = 0; i < tls.length; i++) {
            var tl = tls[i];
            if (!tl) continue;
            var appId = appIdFor(tl);
            if (!appId) continue;
            if (!map[appId]) {
                map[appId] = {
                    appId: appId,
                    name: nameFor(appId),
                    icon: iconFor(appId),
                    toplevels: [],
                    active: false,
                    key: appId
                };
                order.push(appId);
            }
            map[appId].toplevels.push(tl);
            if (!map[appId].active && isActiveTl(tl, active))
                map[appId].active = true;
        }

        // Focused app first (so it is never trimmed visually); stable order rest.
        var out = [];
        var activeIdx = -1;
        for (var j = 0; j < order.length; j++) {
            if (map[order[j]].active) { activeIdx = j; break; }
        }
        if (activeIdx >= 0) {
            out.push(map[order[activeIdx]]);
            for (var k = 0; k < order.length; k++)
                if (k !== activeIdx) out.push(map[order[k]]);
        } else {
            for (var m = 0; m < order.length; m++) out.push(map[order[m]]);
        }
        return out;
    }

    function appIdFor(tl: var): string {
        if (tl && typeof tl.appId === "string" && tl.appId) return tl.appId;
        if (tl && tl.wayland && typeof tl.wayland.appId === "string" && tl.wayland.appId) return tl.wayland.appId;
        if (tl && typeof tl.app_id === "string" && tl.app_id) return tl.app_id;
        if (tl && tl.clazz) return tl.clazz;
        if (tl && tl.lastIpcObject && tl.lastIpcObject.class) return tl.lastIpcObject.class;
        return "";
    }

    function isActiveTl(tl: var, active: var): bool {
        if (!tl || !active) return false;
        if (compositor.isNiri) {
            if (active.id != null && tl.id != null && String(active.id) === String(tl.id)) return true;
            return tl.is_focused === true || tl.is_active === true;
        }
        if (tl.activated === true) return true;
        if (active.address && tl.address && String(active.address) === String(tl.address)) return true;
        return false;
    }

    function desktopEntry(appId: string): var {
        if (appId in root._entryCache) return root._entryCache[appId];
        var apps = DesktopEntries.applications.values;
        var hit = null;
        for (var i = 0; i < apps.length; i++) {
            var e = apps[i];
            if (e && e.id && e.icon && e.id.toLowerCase() === appId.toLowerCase()) { hit = e; break; }
        }
        root._entryCache[appId] = hit;
        return hit;
    }

    function iconFor(appId: string): string {
        var e = root.desktopEntry(appId);
        if (e && e.icon) return Quickshell.iconPath(e.icon, true);
        return Quickshell.iconPath(appId, true);
    }

    function nameFor(appId: string): string {
        var e = root.desktopEntry(appId);
        if (e && e.name) return e.name;
        var s = String(appId).replace(/[-_.]/g, " ");
        return s.charAt(0).toUpperCase() + s.slice(1);
    }

    // ─── Hover preview (lazily loaded so a failure never breaks the bar) ──
    readonly property bool previewEnabled: (root.tbConfig.hoverPreview ?? true) === true

    Timer {
        id: previewCloseTimer
        interval: 180
        repeat: false
        onTriggered: root._closePreviewNow()
    }

    function showPreviewFor(appItem: var, button: Item): void {
        if (!root.previewEnabled) return
        previewCloseTimer.stop()
        if (!previewLoader.active) {
            previewLoader.active = true
        }
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
        asynchronous: false
        source: "TaskbarPreview.qml"
        onLoaded: {
            item.compositor = root.compositor
            item.theme = root.theme
            item.anchor.window = root.barWindow
        }
    }
}
