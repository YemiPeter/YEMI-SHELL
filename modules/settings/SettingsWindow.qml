import QtQuick 6.10
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: settingsWindow
    
    width: 800
    height: 600
    title: "Settings"
    visible: false  // Start hidden, will be toggled by IPC
    
    // Property to track visibility state
    property bool isOpen: false
    
    // Function to toggle the window
    function toggle() {
        visible = !visible
        isOpen = visible
        if (visible) {
            // Bring to front when opened
            raise()
            requestActivate()
        }
    }
    
    // Basic UI content
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        
        Text {
            text: "QuickShell Settings"
            font.pointSize: 18
            Layout.alignment: Qt.AlignHCenter
        }
        
        Text {
            text: "Configuration options will be available here"
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
        }
        
        Item {
            Layout.fillHeight: true
        }
    }
}