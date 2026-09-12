import QtQuick
import Quickshell
import QtQuick.Shapes
import QtQuick.Effects
import "modules/pill" as PillDir
import "singletons" as QsSingletons

ShellRoot {
    PanelWindow {
        id: win
        anchors { top: true; right: true }
        margins.top: 10
        margins.right: 10
        implicitWidth: 360
        implicitHeight: 360
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: QsSingletons.Theme.pillSurface
            border.color: "#ffffff"
            border.width: 1
        }

        // Replicate the pill body: layered item + MultiEffect shadow
        Item {
            id: layeredHost
            anchors.centerIn: parent
            width: 340
            height: 200
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.45)
                shadowBlur: 1.0
                shadowVerticalOffset: 4
            }

            Rectangle {
                anchors.fill: parent
                color: QsSingletons.Theme.pillSurface
                radius: 100
            }

            Item {
                id: wifiIconLayered
                anchors.centerIn: parent
                width: 17
                height: 17

                PillDir.WifiGlyph {
                    anchors.centerIn: parent
                    s: 1
                    level: 0.68
                    on: true
                }
            }

            PillDir.WifiGlyph {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                s: 8
                level: 0.68
                on: true
            }
        }

        Component.onCompleted: {
            console.log("THEME iconDim =", QsSingletons.Theme.iconDim);
            console.log("THEME pillSurface =", QsSingletons.Theme.pillSurface);
            console.log("THEME subtle =", QsSingletons.Theme.subtle);
            console.log("THEME faint =", QsSingletons.Theme.faint);
        }

        Item {
            id: wifiIcon
            anchors.centerIn: parent
            width: 17
            height: 17

            PillDir.WifiGlyph {
                anchors.centerIn: parent
                s: 1
                level: 0.68
                on: true
            }
        }

        PillDir.WifiGlyph {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            s: 8
            level: 0.68
            on: true
        }
    }
}
