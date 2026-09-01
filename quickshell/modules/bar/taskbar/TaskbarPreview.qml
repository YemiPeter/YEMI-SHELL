pragma ComponentBehavior: Bound

import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Wayland
import "../../../compositor" as QsCompositor
import "../../../singletons" as QsSingletons

// Hover preview for the bar taskbar: a small popup anchored under the
// hovered app button, listing that app's windows (icon + title). Click a
// row to focus that window. No live window capture — keeps it simple.
PopupWindow {
    id: popup

    property var compositor: QsCompositor.Compositor
    property var theme: QsSingletons.Theme
    property var appEntry: null
    property Item anchorItem: null

    readonly property var toplevels: appEntry && appEntry.toplevels ? appEntry.toplevels : []

    function close(): void { popup.visible = false }
    function open(): void { popup.visible = true }

    function show(appEntry, button): void {
        popup.appEntry = appEntry
        popup.anchorItem = button
        popup.anchor.updateAnchor()
        popup.open()
    }

    visible: false
    color: "transparent"
    implicitWidth: cardBody.implicitWidth + 16
    implicitHeight: cardBody.implicitHeight + 16

    // Close when the app loses all of its windows.
    Connections {
        target: popup.compositor
        function onToplevelsChanged() {
            if (!popup.visible || !popup.appEntry) return
            if ((popup.appEntry.toplevels ? popup.appEntry.toplevels.length : 0) === 0)
                popup.close()
        }
    }

    // Close shortly after the cursor leaves the popup.
    Timer {
        interval: 200
        running: popup.visible && !popupHover.containsMouse
        repeat: false
        onTriggered: popup.close()
    }

    anchor {
        adjustment: PopupAdjustment.Slide
        item: popup.anchorItem
        gravity: Edges.Bottom
        edges: Edges.Bottom
    }

    MouseArea {
        id: popupHover
        anchors.fill: parent
        hoverEnabled: true
    }

    // Content card
    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: 6
        radius: 12
        color: popup.theme ? popup.theme.cardBot : "#1a1a1a"
        border.width: 1
        border.color: popup.theme ? popup.theme.border : Qt.rgba(1, 1, 1, 0.1)

        ColumnLayout {
            id: cardBody
            anchors.fill: parent
            anchors.margins: 6
            spacing: 4

            Repeater {
                model: popup.toplevels

                delegate: Item {
                    required property var modelData
                    readonly property var tl: modelData
                    readonly property string tTitle: tl ? (tl.title || tl.title_name || "") : ""

                    implicitWidth: 210
                    implicitHeight: 40

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: tileArea.containsMouse
                            ? Qt.rgba(theme.cream.r, theme.cream.g, theme.cream.b, 0.12)
                            : Qt.rgba(theme.cream.r, theme.cream.g, theme.cream.b, 0.03)
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    Image {
                        id: windowIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20
                        height: 20
                        sourceSize.width: 40
                        sourceSize.height: 40
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                        source: popup.windowIcon(tl)
                        visible: status === Image.Ready && source !== ""
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 12
                        height: 12
                        radius: width / 2
                        color: Qt.rgba(theme.cream.r, theme.cream.g, theme.cream.b, 0.2)
                        visible: !windowIcon.visible
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 34
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: tTitle !== "" ? tTitle : (popup.appEntry ? popup.appEntry.name : "")
                        color: popup.theme ? popup.theme.cream : "#eeeeee"
                        font.pixelSize: 12
                        font.family: popup.theme ? popup.theme.font : "Inter"
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: tileArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            popup.focusToplevel(tl)
                            popup.close()
                        }
                    }
                }
            }
        }
    }

    function windowIcon(tl): string {
        var appId = popup.appIdForTl(tl)
        var e = popup.desktopEntry(appId)
        if (e && e.icon) return Quickshell.iconPath(e.icon, true)
        return appId ? Quickshell.iconPath(appId, true) : ""
    }

    function appIdForTl(tl): string {
        if (tl && typeof tl.appId === "string" && tl.appId) return tl.appId
        if (tl && tl.wayland && tl.wayland.appId) return tl.wayland.appId
        if (tl && typeof tl.app_id === "string" && tl.app_id) return tl.app_id
        if (tl && tl.clazz) return tl.clazz
        return popup.appEntry ? popup.appEntry.appId : ""
    }

    function desktopEntry(appId): var {
        if (!appId) return null
        var apps = DesktopEntries.applications.values
        for (var i = 0; i < apps.length; i++) {
            var e = apps[i]
            if (e && e.id && e.icon && e.id.toLowerCase() === appId.toLowerCase()) return e
        }
        return null
    }

    function focusToplevel(tl): void {
        if (!tl) return
        if (popup.compositor && popup.compositor.isNiri) {
            if (tl.id != null) popup.compositor.dispatch("focus-window " + tl.id)
        } else if (popup.compositor && popup.compositor.isHyprland) {
            if (typeof tl.activate === "function") {
                tl.activate()
            } else {
                var addr = tl.address || (tl.wayland ? tl.wayland.address : "")
                if (!addr) return
                if (addr.indexOf("0x") !== 0) addr = "0x" + addr
                popup.compositor.dispatch("focuswindow address:" + addr)
            }
        }
    }
}
