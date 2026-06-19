import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import Quickshell.Io
import "../../../components/effects"
import "../../../services" as QsServices

Rectangle {
    id: root

    required property var audio
    property var pywal

    readonly property var volumeMonitor: QsServices.VolumeMonitor
    readonly property bool isMuted: volumeMonitor.muted

    readonly property color surfaceColor: pywal ? Qt.lighter(pywal.background, 1.25) : "#2a2a3a"
    readonly property color textColor: pywal ? pywal.foreground : "#e6e6e6"
    readonly property color accentColor: pywal ? pywal.primary : "#a6e3a1"

    Layout.fillWidth: true
    Layout.preferredHeight: 48

    radius: 24
    color: surfaceColor

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: muteBtn
            Layout.preferredWidth: 48
            Layout.fillHeight: true
            radius: 24
            color: muteMouse.containsMouse
                ? Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.1)
                : "transparent"

            Text {
                anchors.centerIn: parent
                text: root.isMuted ? "󰝟" : (volumeMonitor.percentage > 66 ? "󰕾" : (volumeMonitor.percentage > 33 ? "󰖀" : "󰕿"))
                font.family: "Material Design Icons"
                font.pixelSize: 20
                color: root.isMuted ? root.accentColor : root.textColor
            }

            MouseArea {
                id: muteMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: toggleMuteProc.running = true
            }
        }

        Slider {
            id: slider
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: 12

            from: 0
            to: 100
            value: volumeMonitor.percentage
            live: true
            touchDragThreshold: 5

            onMoved: {
                volumeMonitor.percentage = Math.round(value)
                setVolumeProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.round(value) + "%"]
                setVolumeProc.running = true
            }

            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                implicitWidth: 200
                implicitHeight: 48
                radius: 24
                color: "transparent"

                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    radius: 24
                    color: root.accentColor
                    opacity: 0.2
                }
            }

            handle: Rectangle {
                visible: false
            }
        }

        Text {
            Layout.rightMargin: 16
            Layout.preferredWidth: 40
            text: volumeMonitor.percentage + "%"
            font.family: "Inter"
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: root.textColor
            horizontalAlignment: Text.AlignRight
        }
    }

    Process {
        id: setVolumeProc
    }

    Process {
        id: toggleMuteProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
    }
}
