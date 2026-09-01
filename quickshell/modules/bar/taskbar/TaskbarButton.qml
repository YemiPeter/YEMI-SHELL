pragma ComponentBehavior: Bound

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import "../../../config" as QsConfig
import "../../../compositor" as QsCompositor
import "../../../singletons" as QsSingletons

// A single running-app button for the bar taskbar. Adapted from iNiR's
// BarTaskbarButton: shows the app icon, an active/focus pill, and a running
// dot, and focuses/activates the app on click. Built on the Compositor
// singleton (no NiriService/AppSearch deps).
Item {
    id: btn

    required property var appItem
    required property var taskbar
    property int iconSize: 16

    readonly property var compositor: QsCompositor.Compositor
    readonly property var theme: QsSingletons.Theme
    readonly property bool active: btn.appItem ? !!btn.appItem.active : false
    readonly property int windowCount: btn.appItem && btn.appItem.toplevels ? btn.appItem.toplevels.length : 0

    signal hoverPreviewRequested()
    signal hoverPreviewDismissed()

    implicitWidth: btn.iconSize + 8
    implicitHeight: btn.iconSize + 8

    // Hover / press background
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 6
        color: area.containsMouse
            ? (area.pressed
                ? Qt.rgba(theme.cream.r, theme.cream.g, theme.cream.b, 0.16)
                : Qt.rgba(theme.cream.r, theme.cream.g, theme.cream.b, 0.10))
            : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    // App icon
    Image {
        id: icon
        anchors.centerIn: parent
        width: btn.iconSize
        height: btn.iconSize
        sourceSize.width: Math.round(btn.iconSize * 2)
        sourceSize.height: Math.round(btn.iconSize * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        source: btn.appItem ? (btn.appItem.icon || "") : ""
        visible: status === Image.Ready && source !== ""
    }

    // Fallback disc while/if the icon cannot be resolved
    Rectangle {
        anchors.centerIn: parent
        width: btn.iconSize * 0.6
        height: btn.iconSize * 0.6
        radius: width / 2
        color: Qt.rgba(theme.cream.r, theme.cream.g, theme.cream.b, 0.18)
        visible: !icon.visible
    }

    // Indicator: focused app -> accent pill, otherwise a dot when it has windows
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 1
        width: btn.active ? 8 : (btn.windowCount > 0 ? 3 : 0)
        height: btn.active ? 3 : 2
        radius: Math.min(width, height) / 2
        color: btn.active ? theme.onGlow : Qt.rgba(theme.cream.r, theme.cream.g, theme.cream.b, 0.35)
        visible: width > 0
        Behavior on width { NumberAnimation { duration: 140 } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: {
            if (containsMouse) btn.hoverPreviewRequested()
            else btn.hoverPreviewDismissed()
        }
        onClicked: {
            btn.focusApp()
            btn.hoverPreviewDismissed()
        }
    }

    // Click: focus the active window of this app, else its most recent window.
    function focusApp(): void {
        var tls = btn.appItem ? btn.appItem.toplevels : []
        if (!tls || tls.length === 0) return
        var target = null
        for (var i = 0; i < tls.length; i++) {
            if (btn.isActiveTl(tls[i])) { target = tls[i]; break }
        }
        if (!target) target = tls[tls.length - 1]
        if (target) btn.focusToplevel(target)
    }

    function isActiveTl(tl: var): bool {
        var a = compositor.activeToplevel
        if (!a || !tl) return false
        if (compositor.isNiri) {
            if (a.id != null && tl.id != null && String(a.id) === String(tl.id)) return true
            return tl.is_focused === true || tl.is_active === true
        }
        if (tl.activated === true) return true
        if (a.address && tl.address && String(a.address) === String(tl.address)) return true
        return false
    }

    function focusToplevel(tl: var): void {
        if (!tl) return
        if (compositor.isNiri) {
            if (tl.id != null) compositor.dispatch("focus-window " + tl.id)
        } else if (compositor.isHyprland) {
            if (typeof tl.activate === "function") {
                tl.activate()
            } else {
                var addr = tl.address || (tl.wayland ? tl.wayland.address : "")
                if (!addr) return
                if (addr.indexOf("0x") !== 0) addr = "0x" + addr
                compositor.dispatch("focuswindow address:" + addr)
            }
        }
    }
}
