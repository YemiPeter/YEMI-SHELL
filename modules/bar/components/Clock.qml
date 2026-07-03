import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../../singletons" as QsSingletons

Item {
    id: root

    implicitWidth: clockLabel.implicitWidth + 16
    implicitHeight: 28

    Text {
        id: clockLabel
        anchors.centerIn: parent
        color: QsSingletons.Theme.dim
        font.pixelSize: 11
        font.bold: true
        font.family: "JetBrainsMono Nerd Font"
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: clockLabel.text = Qt.formatDateTime(new Date(), "hh:mm AP")
    }
}
