pragma Singleton
import QtQuick

QtObject {
    id: root
    // Stubbed for waffle substrate port
    readonly property string currentTime: new Date().toLocaleTimeString()
    readonly property string currentDate: new Date().toLocaleDateString()
}
