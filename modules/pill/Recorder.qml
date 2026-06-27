import QtQuick
import Quickshell.Widgets
import "Singletons"

/**
 * Screen recorder surface. Source picker (screen/window), countdown, and
 * recording indicator.
 * STUB: Full gpu-screen-recorder + Pipewire integration pending.
 */
PillSurface {
    id: root
    mTop: 15
    mLeft: 17
    mRight: 17
    mBottom: 14

    property string screenName: ""

    implicitHeight: contentCol.implicitHeight + 24 * s
    implicitWidth: 384 * s

    Column {
        id: contentCol
        anchors.centerIn: parent
        spacing: 12 * root.s

        Text {
            text: "Screen Recorder"
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 16 * root.s
            font.weight: Font.DemiBold
        }

        Text {
            text: ScreenRec.recording ? "Recording..." : "Ready to record"
            color: ScreenRec.recording ? Theme.verm : Theme.dim
            font.family: Theme.font
            font.pixelSize: 12 * root.s
        }

        Row {
            spacing: 10 * root.s

            Rectangle {
                width: 100 * root.s
                height: 36 * root.s
                radius: 8 * root.s
                color: recScreenArea.containsMouse ? Qt.alpha(Theme.verm, 0.2) : Theme.tileBg
                border.width: 1
                border.color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "Screen"
                    color: Theme.cream
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                }

                MouseArea {
                    id: recScreenArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ScreenRec.prepareScreen(root.screenName)
                }
            }

            Rectangle {
                width: 100 * root.s
                height: 36 * root.s
                radius: 8 * root.s
                color: recWinArea.containsMouse ? Qt.alpha(Theme.verm, 0.2) : Theme.tileBg
                border.width: 1
                border.color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "Window"
                    color: Theme.cream
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                }

                MouseArea {
                    id: recWinArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ScreenRec.prepareWindow()
                }
            }
        }

        Text {
            visible: ScreenRec.recording
            text: "Countdown: " + ScreenRec.countdown
            color: Theme.flameGlow
            font.family: Theme.font
            font.pixelSize: 24 * root.s
            font.weight: Font.ExtraBold
        }
    }
}
