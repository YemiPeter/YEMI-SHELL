import QtQuick
import qs.config
import qs.modules.common
import qs.modules.common.functions

// Angel partial border — elegant half-borders with gradient fade to transparent.
// Creates an asymmetric frame: top-left corner flowing right + down.
// Bottom-right corner flowing left + up. Each edge fades elegantly at its end.
//
// Usage: place INSIDE the target container as a child, after the background.
//   Rectangle {
//       id: card
//       AngelPartialBorder { targetRadius: card.radius }
//   }
//
Item {
    id: root
    anchors.fill: parent

    property bool hovered: false
    property real targetRadius: 0
    // ORIGINAL (iNiR, restore when theme bridge is built):
    // property real coverage: Appearance.angel.borderCoverage
    // property real borderWidth: Appearance.angel.borderWidth
    // property color borderColor: hovered ? Appearance.angel.colBorderHover : Appearance.angel.colBorder
    property real coverage: 0.7
    property real borderWidth: 1
    property color borderColor: hovered ? "#4a98f7" : "#3a88f2"

    // ORIGINAL (iNiR, restore when theme bridge is built):
    // visible: Appearance.angelEverywhere
    visible: true

    // Top edge — from left, fades to transparent at right end
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        width: parent.width * root.coverage
        height: root.borderWidth
        radius: root.targetRadius > 0 ? root.targetRadius : 0

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: root.borderColor }
            GradientStop { position: 0.7; color: root.borderColor }
            GradientStop { position: 1.0; color: "transparent" }
        }

        // ORIGINAL (iNiR, restore when theme bridge is built):
        // Behavior on width {
        //     enabled: Appearance.animationsEnabled
        //     NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        // }
        Behavior on width {
            enabled: true
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
    }

    // Left edge — from top, fades to transparent at bottom end
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        width: root.borderWidth
        height: parent.height * root.coverage
        radius: root.targetRadius > 0 ? root.targetRadius : 0

        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: root.borderColor }
            GradientStop { position: 0.7; color: root.borderColor }
            GradientStop { position: 1.0; color: "transparent" }
        }

        // ORIGINAL (iNiR, restore when theme bridge is built):
        // Behavior on height {
        //     enabled: Appearance.animationsEnabled
        //     NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        // }
        Behavior on height {
            enabled: true
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
    }

    // Bottom edge — from right, fades to transparent at left end
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: parent.width * root.coverage
        height: root.borderWidth
        radius: root.targetRadius > 0 ? root.targetRadius : 0

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.3; color: root.borderColor }
            GradientStop { position: 1.0; color: root.borderColor }
        }

        // ORIGINAL (iNiR, restore when theme bridge is built):
        // Behavior on width {
        //     enabled: Appearance.animationsEnabled
        //     NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        // }
        Behavior on width {
            enabled: true
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
    }

    // Right edge — from bottom, fades to transparent at top end
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: root.borderWidth
        height: parent.height * root.coverage
        radius: root.targetRadius > 0 ? root.targetRadius : 0

        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.3; color: root.borderColor }
            GradientStop { position: 1.0; color: root.borderColor }
        }

        // ORIGINAL (iNiR, restore when theme bridge is built):
        // Behavior on height {
        //     enabled: Appearance.animationsEnabled
        //     NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        // }
        Behavior on height {
            enabled: true
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
    }
}
