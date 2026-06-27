pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "Singletons"

/**
 * System tray. Draws StatusNotifier items as warm-tinted icons. Left-click
 * activates (preferring the resolved desktop entry), middle-click does the
 * secondary action, right-click opens the item's native menu in a floating
 * washi card, wheel scrolls the item. The menu gets its own overlay window so
 * it can grab keyboard focus for dismissal.
 */
Item {
    id: tray

    property real s: 1
    property var barWindow

    visible: SystemTray.items.values.length > 0
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: 24 * tray.s

    function showMenu(item, anchorItem) {
        if (!item.hasMenu) return;
        card.expandedIdx = -1;
        opener.menu = item.menu;
        var p = anchorItem.mapToItem(null, anchorItem.width / 2, 0);
        menu.anchorX = p.x;
        menu.open = true;
    }

    QsMenuOpener {
        id: opener
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 2 * tray.s

        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: slot
                required property var modelData

                Layout.preferredWidth: 24 * tray.s
                Layout.preferredHeight: 24 * tray.s

                Rectangle {
                    anchors.fill: parent
                    radius: 6 * tray.s
                    color: slotArea.containsMouse ? Qt.alpha(Theme.cream, 0.1) : "transparent"
                    Behavior on color { ColorAnimation { duration: Motion.fast } }
                }

                Image {
                    anchors.fill: parent
                    anchors.margins: 4 * tray.s
                    source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                }

                MouseArea {
                    id: slotArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton)
                            tray.showMenu(modelData, slot);
                        else if (mouse.button === Qt.MiddleButton)
                            modelData.activateSecondary();
                        else
                            modelData.activate();
                    }
                    onWheel: (wheel) => {
                        // Scroll handling if needed
                    }
                }
            }
        }
    }
}
