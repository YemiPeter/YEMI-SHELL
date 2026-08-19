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

    // Single fullscreen transparent Overlay window holding the menu. It is the
    // ONLY surface granted WlrKeyboardFocus.Exclusive, so on Hyprland (which
    // implements the exclusive seat/pointer grab) its internal MouseArea keeps
    // receiving pointer input while open — fixing tap-outside and tap-Start
    // close. iNiR only works because Niri does not implement this grab.
    Loader {
        id: panelLoader
        active: GlobalStates.searchOpen
        sourceComponent: PanelWindow {
            id: panelWindow
            anchors { top: true; bottom: true; left: true; right: true }
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:wStartMenu"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            // Full-screen click-catcher, behind the panel. A tap anywhere
            // outside the panel — including the bar's Start-button location —
            // lands here and closes the launcher.
            MouseArea {
                anchors.fill: parent
                z: 0
                onClicked: GlobalStates.searchOpen = false
            }

            StartMenuContent {
                id: content
                z: 1
                focus: true

                // Adaptive minimum size based on preset (mirrors pre-Option-B layout)
                readonly property string preset: Config.options.waffles?.startMenu?.sizePreset ?? "normal"
                readonly property int minW: preset === "mini" ? 200 : preset === "compact" ? 280 : 360
                readonly property int minH: preset === "mini" ? 200 : preset === "compact" ? 280 : 300
                width: Math.max(minW, implicitWidth)
                height: Math.max(minH, implicitHeight)

                readonly property bool _barAtBottom: Config.options?.waffles?.bar?.bottom ?? true
                readonly property bool _leftAlign: Config.options?.waffles?.bar?.leftAlignApps ?? false
                anchors {
                    horizontalCenter: !content._leftAlign ? parent.horizontalCenter : undefined
                    left: content._leftAlign ? parent.left : undefined
                    bottom: content._barAtBottom ? parent.bottom : undefined
                    top: !content._barAtBottom ? parent.top : undefined
                    bottomMargin: content._barAtBottom ? Looks.scaledBar(48, panelWindow.screen) : 0
                    topMargin: !content._barAtBottom ? Looks.scaledBar(48, panelWindow.screen) : 0
                }

                onClosed: {
                    GlobalStates.searchOpen = false
                    panelLoader.active = false
                    LauncherSearch.query = ""
                }
            }

            Connections {
                target: GlobalStates
                function onSearchOpenChanged() {
                    if (!GlobalStates.searchOpen) content.close()
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
