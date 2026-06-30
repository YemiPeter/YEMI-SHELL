import Quickshell
import Quickshell.Wayland
import QtQuick 6.10
import "../../config" as QsConfig

Scope {
    readonly property var config: QsConfig.Config
    
    // Bluetooth popup window
    Loader {
        id: bluetoothPopupLoader
        source: "components/BluetoothPopupWindow.qml"
    
        property var bluetoothPopup: item
    }
    
    
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window
            
            property var modelData
            
            screen: modelData
            anchors {
                top: true
                left: true
                right: true
            }
            
            implicitHeight: config.bar.height
            color: "transparent"
            
            // Bar content
            Loader {
                id: barLoader
                anchors.fill: parent
                source: "Bar.qml"
                
                onStatusChanged: {
                    if (status === Loader.Ready) {
                        item.screen = Qt.binding(() => modelData)
                        item.barWindow = Qt.binding(() => window)
                        item.bluetoothPopup = Qt.binding(() => bluetoothPopupLoader.item)
                    }
                }
            }
        }
    }
}
