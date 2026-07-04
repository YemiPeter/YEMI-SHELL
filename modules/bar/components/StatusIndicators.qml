import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import "../../../singletons" as QsSingletons
import "../../../config" as QsConfig

// Status Indicators - Keep Awake and DND dots in the bar
Item {
    id: root
    
    
    readonly property bool keepAwakeActive: QsSingletons.Flags.keepAwake
    readonly property bool dndActive: QsSingletons.Flags.dnd
    readonly property bool hasActiveIndicators: keepAwakeActive || dndActive
    
    implicitWidth: hasActiveIndicators ? indicatorRow.implicitWidth : 0
    implicitHeight: 28
    
    visible: hasActiveIndicators
    opacity: hasActiveIndicators ? 1 : 0
    
    Behavior on implicitWidth {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    Behavior on opacity {
        NumberAnimation { duration: 150 }
    }
    
    Row {
        id: indicatorRow
        anchors.centerIn: parent
        spacing: 6
        
        // Caffeine indicator (coffee icon)
        Rectangle {
            id: caffeineIndicator
            width: keepAwakeActive ? 22 : 0
            height: 22
            radius: 11
            color: Qt.rgba(QsSingletons.Theme.onGlow.r, QsSingletons.Theme.onGlow.g, QsSingletons.Theme.onGlow.b, 0.2)
            visible: keepAwakeActive
            
            Behavior on width {
                NumberAnimation { duration: 200; easing.bezierCurve: [0.34, 1.56, 0.64, 1] }
            }
            
            Text {
                anchors.centerIn: parent
                text: "󰛊"  // Coffee icon
                font.family: "Material Design Icons"
                font.pixelSize: 12
                color: QsSingletons.Theme.onGlow
            }
            
            // Subtle pulse animation when active
            SequentialAnimation on opacity {
                running: keepAwakeActive
                loops: Animation.Infinite
                paused: !visible
                NumberAnimation { to: 0.7; duration: 1500; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 1500; easing.type: Easing.InOutSine }
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                
                onClicked: QsSingletons.Flags.keepAwake = !QsSingletons.Flags.keepAwake
            }
        }
        
        // DND indicator (bell off icon)
        Rectangle {
            id: dndIndicator
            width: dndActive ? 22 : 0
            height: 22
            radius: 11
            color: Qt.rgba(QsSingletons.Theme.verm.r, QsSingletons.Theme.verm.g, QsSingletons.Theme.verm.b, 0.2)
            visible: dndActive
            
            Behavior on width {
                NumberAnimation { duration: 200; easing.bezierCurve: [0.34, 1.56, 0.64, 1] }
            }
            
            Text {
                anchors.centerIn: parent
                text: "󰂛"  // Bell off icon
                font.family: "Material Design Icons"
                font.pixelSize: 12
                color: QsSingletons.Theme.verm
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                
                onClicked: QsSingletons.Flags.dnd = !QsSingletons.Flags.dnd
            }
        }
    }
}
