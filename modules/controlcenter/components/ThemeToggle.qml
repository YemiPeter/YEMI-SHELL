import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Io
import "../../../components/effects"

Rectangle {
    id: root

    property color activeColor: "#a6e3a1"
    property color surfaceColor: Qt.rgba(1, 1, 1, 0.15)
    property color textColor: "#e6e6e6"

    // Three states: "auto", "dark", "light"
    property string colorMode: "dark"

    Layout.fillWidth: true
    Layout.preferredHeight: 64

    radius: 32
    color: colorMode !== "dark" ? activeColor : surfaceColor

    Behavior on color {
        ColorAnimation {
            duration: Material3Anim.medium2
            easing.bezierCurve: Material3Anim.standard
        }
    }

    scale: themeMouse.pressed ? 0.96 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: Material3Anim.short2
            easing.bezierCurve: Material3Anim.standard
        }
    }

    // Read current mode on startup
    Component.onCompleted: readModeProc.running = true

    Process {
        id: readModeProc
        command: ["bash", "-c", "cat ~/.config/quickshell/state/colormode 2>/dev/null || echo dark"]
        stdout: SplitParser {
            onRead: data => {
                var mode = data.trim().toLowerCase()
                if (mode === "auto" || mode === "dark" || mode === "light") {
                    root.colorMode = mode
                }
            }
        }
    }

    Process {
        id: toggleProc
        command: ["bash", "/home/yemipeter/.config/quickshell/scripts/toggle-colormode.sh"]
        onExited: readModeProc.running = true
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.08)
        opacity: themeMouse.containsMouse && !themeMouse.pressed ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Material3Anim.short2 }
        }
    }

    MouseArea {
        id: themeMouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: toggleProc.running = true
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Rectangle {
            width: 40
            height: 40
            radius: 20
            color: root.colorMode === "light"
                ? Qt.rgba(1, 1, 1, 0.25)
                : root.colorMode === "auto"
                    ? Qt.rgba(root.activeColor.r, root.activeColor.g, root.activeColor.b, 0.2)
                    : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.12)

            Text {
                anchors.centerIn: parent
                text: root.colorMode === "auto" ? "󰖫"
                     : root.colorMode === "light" ? "󰖨"
                     : "󰖔"
                font.family: "Material Design Icons"
                font.pixelSize: 22
                color: root.colorMode === "light"
                    ? Qt.darker(root.activeColor, 1.5)
                    : root.textColor
            }
        }

        ColumnLayout {
            spacing: 1
            Text {
                text: root.colorMode === "auto" ? "Auto"
                     : root.colorMode === "light" ? "Light"
                     : "Dark"
                font.family: "Inter"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: root.colorMode === "light"
                    ? Qt.darker(root.activeColor, 1.8)
                    : root.textColor
            }
            Text {
                text: "Color mode"
                font.family: "Inter"
                font.pixelSize: 12
                color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.6)
            }
        }
    }
}
