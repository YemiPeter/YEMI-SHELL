import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../components/effects"
import "../common"
import "../../config" as QsConfig
import "../../singletons" as QsSingletons

Item {
    id: barPillRoot
    readonly property real s: QsSingletons.Flags.uiScale
    readonly property real pillAlpha: QsSingletons.Theme.pillAlpha
    readonly property color pillBg: QsSingletons.Theme.pillSurface
    readonly property color pillBorder: Qt.rgba(QsSingletons.Theme.cream.r, QsSingletons.Theme.cream.g, QsSingletons.Theme.cream.b, 0.10)
    readonly property color pillSeparator: Qt.rgba(QsSingletons.Theme.cream.r, QsSingletons.Theme.cream.g, QsSingletons.Theme.cream.b, 0.15)
    readonly property color highlightTop: Qt.rgba(1, 1, 1, 0.04)

    property real customHeight: 28 * s
    property real customRadius: 14 * s
    property real customSpacing: 6 * s
    property var barWindow
    property string screenName

    width: content.implicitWidth + 16 * s
    height: customHeight

    Rectangle {
        id: pillContainer
        anchors.fill: parent
        radius: customRadius
        color: QsSingletons.Theme.auroraActive ? "transparent" : pillBg
        border.width: 1
        border.color: pillBorder

        Glass {
            anchors.fill: parent
            radius: pillContainer.radius
            tintScale: pillAlpha
        }

        Behavior on width {
            NumberAnimation {
                duration: 250;
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 1 * s
            height: parent.height / 2
            radius: parent.radius - 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: highlightTop }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Row {
            id: content
            anchors.centerIn: parent
            spacing: customSpacing
        }
    }
}