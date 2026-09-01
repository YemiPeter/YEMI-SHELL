import QtQuick 6.10
import Quickshell
import "../../../config" as QsConfig
import "../../../singletons" as QsSingletons
import "../../../compositor" as QsCompositor

// Bare running-apps strip for the bar's left cluster — NOT a pill. No
// background, no border: open apps just stick their icon next to the
// workspace pill, dock-style. Click focuses the app (cycles through its
// windows if it has several); the focused app gets a small accent dot
// underneath. Hides entirely when nothing is running.
Item {
    id: root

    property var screen

    readonly property real s: screen ? (screen.height / 1080) * QsSingletons.Flags.uiScale : 1
    readonly property var compositor: QsCompositor.Compositor
    readonly property var theme: QsSingletons.Theme

    readonly property int iconSize: 26 * root.s
    readonly property int cellSize: 28 * root.s

    implicitWidth: leftPad + iconRow.implicitWidth
    implicitHeight: cellSize

    // Breathing room between this strip and the workspace pill to its left.
    readonly property int leftPad: 12 * root.s
    visible: root.appItems.length > 0

    property var _entryCache: ({})

    // One entry per running appId: { appId, icon, toplevels, focused }.
    // Same derivation approach as the pill Workspaces: direct property reads
    // so the binding re-evaluates on every open/close/focus change.
    readonly property var appItems: {
        void compositor.toplevels;
        void compositor.activeToplevel;

        var tls = compositor.toplevels || [];
        var active = compositor.activeToplevel;
        var isNiri = compositor.isNiri;

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
                    icon: iconFor(appId),
                    toplevels: [],
                    focused: false
                };
                order.push(appId);
            }
            map[appId].toplevels.push(tl);
            if (!map[appId].focused && isFocusedTl(tl, active, isNiri))
                map[appId].focused = true;
        }

        var out = [];
        for (var j = 0; j < order.length; j++)
            out.push(map[order[j]]);
        console.log("[AppIcons] tls=" + tls.length + " apps=" + out.length
                    + " sample=" + (tls.length ? JSON.stringify(appIdFor(tls[0])) : "none"));
        return out;
    }

    function appIdFor(tl): string {
        if (tl && typeof tl.appId === "string" && tl.appId) return tl.appId;
        if (tl && tl.wayland && typeof tl.wayland.appId === "string" && tl.wayland.appId) return tl.wayland.appId;
        if (tl && typeof tl.app_id === "string" && tl.app_id) return tl.app_id;
        if (tl && tl.clazz) return tl.clazz;
        if (tl && tl.lastIpcObject && tl.lastIpcObject.class) return tl.lastIpcObject.class;
        return "";
    }

    function isFocusedTl(tl, active, isNiri): bool {
        if (!tl || !active) return false;
        if (isNiri) {
            if (active.id != null && tl.id != null && String(active.id) === String(tl.id)) return true;
            return tl.is_focused === true || tl.is_active === true;
        }
        if (tl.activated === true) return true;
        if (active.address && tl.address && String(active.address) === String(tl.address)) return true;
        return false;
    }

    function iconFor(appId): string {
        if (appId in root._entryCache) return root._entryCache[appId];
        var hit = Quickshell.iconPath(appId, true);
        var apps = DesktopEntries.applications.values;
        var lower = appId.toLowerCase();
        for (var i = 0; i < apps.length; i++) {
            var e = apps[i];
            if (e && e.id && e.icon && e.id.toLowerCase() === lower) {
                hit = Quickshell.iconPath(e.icon, true);
                break;
            }
        }
        root._entryCache[appId] = hit;
        return hit;
    }

    // Click: focus this app's window. If the app is already focused and has
    // more windows, cycle to the next one.
    function focusApp(appItem): void {
        var tls = appItem ? appItem.toplevels : [];
        if (!tls || tls.length === 0) return;
        var isNiri = compositor.isNiri;
        var active = compositor.activeToplevel;
        var idx = -1;
        for (var i = 0; i < tls.length; i++) {
            if (isFocusedTl(tls[i], active, isNiri)) { idx = i; break; }
        }
        var target;
        if (idx >= 0 && tls.length > 1)
            target = tls[(idx + 1) % tls.length];
        else
            target = tls[Math.max(idx, 0)];
        activateTl(target);
    }

    function activateTl(tl): void {
        if (!tl) return;
        if (compositor.isNiri) {
            if (tl.id != null) compositor.dispatch("focus-window " + tl.id);
        } else if (compositor.isHyprland) {
            if (typeof tl.activate === "function") {
                tl.activate();
            } else {
                var addr = tl.address || (tl.wayland ? tl.wayland.address : "");
                if (!addr) return;
                if (addr.indexOf("0x") !== 0) addr = "0x" + addr;
                compositor.dispatch("focuswindow address:" + addr);
            }
        }
    }

    // ── UI: bare icon row, no pill chrome ─────────────────────────────
    Row {
        id: iconRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: root.leftPad
        spacing: 4 * root.s

        Repeater {
            model: root.appItems

            delegate: Item {
                id: cell
                required property var modelData
                readonly property var app: modelData

                width: root.cellSize
                height: root.cellSize

                // Hover highlight — a soft disc, since there is no pill chrome.
                Rectangle {
                    anchors.centerIn: parent
                    width: root.cellSize
                    height: root.cellSize
                    radius: width / 2
                    color: cellArea.containsMouse
                        ? Qt.rgba(root.theme.cream.r, root.theme.cream.g, root.theme.cream.b, 0.10)
                        : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                Image {
                    id: icon
                    anchors.centerIn: parent
                    width: root.iconSize
                    height: root.iconSize
                    sourceSize.width: Math.round(root.iconSize * 2)
                    sourceSize.height: Math.round(root.iconSize * 2)
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                    source: cell.app ? (cell.app.icon || "") : ""
                    visible: status === Image.Ready && source !== ""
                }

                // Neutral disc fallback while/if the icon can't be resolved.
                Rectangle {
                    anchors.centerIn: parent
                    width: root.iconSize * 0.6
                    height: root.iconSize * 0.6
                    radius: width / 2
                    color: Qt.rgba(root.theme.cream.r, root.theme.cream.g, root.theme.cream.b, 0.18)
                    visible: !icon.visible
                }

                // Focused-app indicator: small accent dot under the icon.
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 1
                    width: cell.app && cell.app.focused ? 8 * root.s : 0
                    height: 2 * root.s
                    radius: 1
                    color: root.theme.onGlow
                    visible: width > 0
                    Behavior on width { NumberAnimation { duration: 140 } }
                }

                MouseArea {
                    id: cellArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.focusApp(cell.app)
                }
            }
        }
    }
}

