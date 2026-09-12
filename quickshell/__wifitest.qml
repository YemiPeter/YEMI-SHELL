import QtQuick
import Quickshell
import Quickshell.Wayland
import QtQuick.Effects
import "modules/pill" as PillDir

ShellRoot {
    PanelWindow {
        id: win
        anchors { top: true; left: true; right: true; bottom: true }
        margins.top: 7
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Region { id: pillRegion; x: 620; y: 0; width: 700; height: 110 }

        mask: pillRegion

        // Mimic the overlay: layered host + MultiEffect shadow (niri path)
        Item {
            id: host
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.45)
                shadowBlur: 1.0
                shadowVerticalOffset: 4
            }

            // simulate PillState.peekMon toggling at runtime
            property bool pinned: false
            Timer { interval: 3000; running: true; onTriggered: host.pinned = true }

            PillDir.Pill {
                id: pill
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                s: 0.9
                screenName: "eDP-1"
                forcePinned: host.pinned
                // Replicate the overlay's fullscreen state machinery
                states: [
                    State {
                        name: "fullscreen"
                        when: false
                        PropertyChanges { target: pill; opacity: 0 }
                    },
                    State {
                        name: "normal"
                        when: true
                        PropertyChanges { target: pill; opacity: 1 }
                    }
                ]
                transform: Translate {
                    y: 0
                    Behavior on y {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                }
                onRequestSurface: (name) => console.log("[WIFITEST] surface req", name)
                onRequestClose: console.log("[WIFITEST] close req")
            }
        }
    }
}
