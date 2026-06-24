import Quickshell
import QtQuick 6.10
import "../../../config" as QsConfig
import "../../../singletons" as QsSingletons
import "../../../components/effects"

// Modern fluid workspace indicator
Rectangle {
    id: root
    
    property int workspaceId: 1
    property bool isActive: false
    property bool isOccupied: false
    
    signal clicked()
    
    readonly property var config: QsConfig.Config
    
    // Dynamic sizing with fluid animation
    implicitWidth: {
        if (isActive) return 28  // Expanded pill for active
        if (isOccupied) return 10  // Larger dot for occupied
        return 6  // Minimal dot for empty
    }
    implicitHeight: {
        if (isActive) return 10
        return 6  // Consistent height for non-active
    }
    
    // Beautiful gradient-based colors
    color: {
        if (isActive) return QsSingletons.Theme.onGlow
        if (isOccupied) return Qt.rgba(QsSingletons.Theme.cream.r, QsSingletons.Theme.cream.g, QsSingletons.Theme.cream.b, 0.5)
        return Qt.rgba(QsSingletons.Theme.cream.r, QsSingletons.Theme.cream.g, QsSingletons.Theme.cream.b, 0.2)
    }
    
    border.width: 0
    radius: height / 2
    
    // Smooth material animations
    Behavior on implicitWidth {
        NumberAnimation {
            duration: Material3Anim.medium2
            easing.bezierCurve: Material3Anim.emphasizedDecelerate
        }
    }
    
    Behavior on implicitHeight {
        NumberAnimation {
            duration: Material3Anim.medium2
            easing.bezierCurve: Material3Anim.emphasizedDecelerate
        }
    }
    
    Behavior on color {
        ColorAnimation {
            duration: Material3Anim.short4
            easing.bezierCurve: Material3Anim.standard
        }
    }
    
    Behavior on opacity {
        NumberAnimation {
            duration: Material3Anim.short4
            easing.bezierCurve: Material3Anim.standard
        }
    }
    
    Behavior on scale {
        NumberAnimation {
            duration: Material3Anim.short2
            easing.bezierCurve: Material3Anim.standard
        }
    }
    
    // Inner glow for active workspace
    Rectangle {
        visible: isActive
        anchors.fill: parent
        anchors.margins: 1
        radius: parent.radius - 1
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.2)
        
        Behavior on opacity {
            NumberAnimation { 
                duration: Material3Anim.short3
                easing.bezierCurve: Material3Anim.standard
            }
        }
    }
    
    // Subtle glow pulse for active workspace
    Rectangle {
        visible: isActive
        anchors.centerIn: parent
        width: parent.width + 4
        height: parent.height + 4
        radius: (height) / 2
        color: "transparent"
        border.width: 2
        border.color: Qt.rgba(QsSingletons.Theme.onGlow.r, QsSingletons.Theme.onGlow.g, QsSingletons.Theme.onGlow.b, 0.15)
        
        SequentialAnimation on opacity {
            running: isActive
            loops: Animation.Infinite
            
            NumberAnimation { to: 0.3; duration: 1500; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.8; duration: 1500; easing.type: Easing.InOutSine }
        }
    }

    // Mouse interaction
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -4  // Larger hit area
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: root.clicked()
        
        onPressed: {
            root.scale = 0.85
        }
        
        onReleased: {
            root.scale = 1.0
        }
        
        onEntered: {
            if (!isActive) {
                root.scale = 1.2
            }
        }
        
        onExited: {
            root.scale = 1.0
        }
    }
    
    scale: 1.0
}
