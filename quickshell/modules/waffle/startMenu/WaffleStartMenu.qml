import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.services.deferred
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks

Scope {
    id: root

    readonly property bool allowMultiplePanels: Config.options?.waffles?.behavior?.allowMultiplePanels ?? false

    Connections {
        target: GlobalStates
        function onSearchOpenChanged() {
            if (GlobalStates.searchOpen) {
                if (!root.allowMultiplePanels) {
                    GlobalStates.waffleActionCenterOpen = false
                    GlobalStates.waffleNotificationCenterOpen = false
                }
                panelLoader.active = true
            }
        }
    }

    // Click-outside-to-close overlay
    LazyLoader {
        active: GlobalStates.searchOpen
        component: PanelWindow {
            anchors { top: true; bottom: true; left: true; right: true }
            WlrLayershell.namespace: "quickshell:wStartMenuBg"
            WlrLayershell.layer: WlrLayer.Top
            color: "transparent"
            MouseArea {
                anchors.fill: parent
                onClicked: GlobalStates.searchOpen = false
            }
        }
    }

    Loader {
        id: panelLoader
        active: GlobalStates.searchOpen
        sourceComponent: PanelWindow {
            id: panelWindow
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:wStartMenu"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            // Adaptive minimum size based on preset
            property string preset: Config.options.waffles?.startMenu?.sizePreset ?? "normal"
            property int minW: preset === "mini" ? 200 : preset === "compact" ? 280 : 360
            property int minH: preset === "mini" ? 200 : preset === "compact" ? 280 : 300

            // Lift the menu clear of the bar so the Start button (and the
            // full-screen outside-catcher) stays tappable — otherwise the
            // Overlay menu physically covers the button and a 2nd tap does
            // nothing. Offset by the scaled bar height on the bar's side.
            readonly property bool _barAtBottom: Config.options?.waffles?.bar?.bottom ?? true
            anchors {
                bottom: panelWindow._barAtBottom
                top: !panelWindow._barAtBottom
                left: Config.options?.waffles?.bar?.leftAlignApps ?? false
                bottomMargin: panelWindow._barAtBottom ? Looks.scaledBar(48, panelWindow.screen) : 0
                topMargin: panelWindow._barAtBottom ? 0 : Looks.scaledBar(48, panelWindow.screen)
            }

            implicitWidth: Math.max(minW, content.implicitWidth)
            implicitHeight: Math.max(minH, content.implicitHeight)

            Connections {
                target: GlobalStates
                function onSearchOpenChanged() {
                    if (!GlobalStates.searchOpen) content.close()
                }
            }

            StartMenuContent {
                id: content
                anchors.fill: parent
                focus: true
                onClosed: {
                    GlobalStates.searchOpen = false
                    panelLoader.active = false
                    LauncherSearch.query = ""
                }
            }
        }
    }

    IpcHandler {
        target: "search"
        function toggle(): void { GlobalStates.searchOpen = !GlobalStates.searchOpen }
        function close(): void { GlobalStates.searchOpen = false }
        function open(): void { GlobalStates.searchOpen = true }
    }
}
