import QtQuick
import "Singletons"

/**
 * Clipboard history surface. Shows recent clipboard entries with thumbnails
 * for images. Click to copy back to clipboard.
 */
PillSurface {
    id: root
    mTop: 15
    mLeft: 17
    mRight: 17
    mBottom: 14

    property string query: ""

    readonly property var filtered: {
        if (!root.query || root.query.length === 0)
            return Cliphist.entries.slice(0, 20);
        const q = root.query.toLowerCase();
        return Cliphist.entries.filter(e =>
            (e.label || "").toLowerCase().includes(q) ||
            (e.meta || "").toLowerCase().includes(q)
        ).slice(0, 20);
    }

    implicitHeight: list.implicitHeight + 20 * s
    implicitWidth: 360 * s

    Column {
        id: col
        anchors.fill: parent
        anchors.topMargin: 12 * root.s
        anchors.leftMargin: 16 * root.s
        anchors.rightMargin: 16 * root.s
        anchors.bottomMargin: 12 * root.s
        spacing: 6 * root.s

        Text {
            text: "Clipboard"
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 14 * root.s
            font.weight: Font.DemiBold
        }

        ListView {
            id: list
            width: parent.width
            height: Math.min(280 * root.s, model.length * 44 * root.s)
            model: root.filtered
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            spacing: 2 * root.s

            delegate: Item {
                id: entryRow
                required property var modelData
                required property int index
                width: parent.width
                height: 40 * root.s

                Rectangle {
                    anchors.fill: parent
                    radius: 8 * root.s
                    color: entryArea.containsMouse ? Qt.alpha(Theme.cream, 0.06) : "transparent"
                    Behavior on color { ColorAnimation { duration: Motion.fast } }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 10 * root.s

                    Rectangle {
                        width: 24 * root.s
                        height: 24 * root.s
                        radius: 6 * root.s
                        color: Theme.tileBg
                        border.width: 1
                        border.color: Theme.border
                        visible: !modelData.isImage

                        Text {
                            anchors.centerIn: parent
                            text: "📋"
                            font.pixelSize: 12 * root.s
                        }
                    }

                    Image {
                        width: 24 * root.s
                        height: 24 * root.s
                        source: modelData.isImage ? modelData.preview : ""
                        fillMode: Image.PreserveAspectFit
                        visible: modelData.isImage
                    }

                    Text {
                        text: modelData.label || modelData.meta || "Clipboard entry"
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 12 * root.s
                        elide: Text.ElideRight
                        width: parent.width - 60 * root.s
                    }
                }

                MouseArea {
                    id: entryArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Cliphist.copy(modelData)
                }
            }
        }
    }
}
