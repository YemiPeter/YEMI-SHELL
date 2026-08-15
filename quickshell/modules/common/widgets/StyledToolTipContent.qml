import qs.config
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    required property string text
    property bool shown: false
    property string position: "bottom" // "bottom", "top", "left", "right"
    property real horizontalPadding: 10
    property real verticalPadding: 5
    property alias font: tooltipTextObject.font
    implicitWidth: tooltipTextObject.implicitWidth + 2 * root.horizontalPadding
    implicitHeight: tooltipTextObject.implicitHeight + 2 * root.verticalPadding

    property bool isVisible: backgroundRectangle.implicitHeight > 0

    Rectangle {
        id: backgroundRectangle
        // Grow from the edge nearest to the anchor
        x: root.position === "left" ? root.implicitWidth - implicitWidth
         : root.position === "right" ? 0
         : (root.implicitWidth - implicitWidth) / 2
        y: root.position === "top" ? root.implicitHeight - implicitHeight
         : root.position === "bottom" ? 0
         : (root.implicitHeight - implicitHeight) / 2
        // ORIGINAL (iNiR, restore when theme bridge is built):
        // color: Appearance.angelEverywhere ? Appearance.angel.colGlassTooltip
        //      : Appearance.inirEverywhere ? Appearance.inir.colLayer2
        //      : Appearance.auroraEverywhere ? Appearance.aurora.colTooltipSurface
        //      : Appearance.colors.colLayer3
        color: false ? "#1e1e1e"
             : false ? "#1e1e1e"
             : true ? "#1e1e1e"
             : "#1e1e1e"
        // ORIGINAL (iNiR, restore when theme bridge is built):
        // radius: Appearance.angelEverywhere ? Appearance.angel.roundingSmall
        //      : Appearance.inirEverywhere ? Appearance.inir.roundingNormal
        //      : Appearance.rounding.verysmall
        radius: false ? 6
             : false ? 8
             : 4
        // ORIGINAL (iNiR, restore when theme bridge is built):
        // border.width: Appearance.angelEverywhere ? Appearance.angel.cardBorderWidth : 1
        border.width: 1
        // ORIGINAL (iNiR, restore when theme bridge is built):
        // border.color: Appearance.angelEverywhere ? Appearance.angel.colBorderSubtle
        //             : Appearance.inirEverywhere ? Appearance.inir.colBorder
        //             : Appearance.auroraEverywhere ? Appearance.aurora.colTooltipBorder
        //             : Appearance.colors.colLayer3Hover
        border.color: "#3a88f2"
        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.94
        transformOrigin: root.position === "top" ? Item.Bottom
                       : root.position === "left" ? Item.Right
                       : root.position === "right" ? Item.Left
                       : Item.Top
        implicitWidth: shown ? (tooltipTextObject.implicitWidth + 2 * root.horizontalPadding) : 0
        implicitHeight: shown ? (tooltipTextObject.implicitHeight + 2 * root.verticalPadding) : 0
        clip: true

        // ORIGINAL (iNiR, restore when theme bridge is built):
        // Behavior on opacity {
        //     enabled: Appearance.animationsEnabled
        //     NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
        // }
        Behavior on opacity {
            enabled: true
            NumberAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.34, 0.80, 0.34, 1.00, 1, 1] }
        }
        // ORIGINAL (iNiR, restore when theme bridge is built):
        // Behavior on scale {
        //     enabled: Appearance.animationsEnabled
        //     NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
        // }
        Behavior on scale {
            enabled: true
            NumberAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.34, 0.80, 0.34, 1.00, 1, 1] }
        }
        // ORIGINAL (iNiR, restore when theme bridge is built):
        // Behavior on implicitWidth {
        //     enabled: Appearance.animationsEnabled
        //     NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
        // }
        Behavior on implicitWidth {
            enabled: true
            NumberAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.34, 0.80, 0.34, 1.00, 1, 1] }
        }
        // ORIGINAL (iNiR, restore when theme bridge is built):
        // Behavior on implicitHeight {
        //     enabled: Appearance.animationsEnabled
        //     NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
        // }
        Behavior on implicitHeight {
            enabled: true
            NumberAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.34, 0.80, 0.34, 1.00, 1, 1] }
        }

        AngelPartialBorder {
            targetRadius: backgroundRectangle.radius
            coverage: 0.45
        }

        StyledText {
            id: tooltipTextObject
            anchors.centerIn: parent
            text: root.text
            // ORIGINAL (iNiR, restore when theme bridge is built):
            // font.pixelSize: Appearance.font.pixelSize.smaller
            font.pixelSize: 11
            font.hintingPreference: Font.PreferNoHinting // Prevent shaky text
            // ORIGINAL (iNiR, restore when theme bridge is built):
            // color: Appearance.angelEverywhere ? Appearance.angel.colText
            //     : Appearance.inirEverywhere ? Appearance.inir.colText
            //     : Appearance.colors.colOnLayer3
            color: false ? "#e6e6e6"
                : false ? "#e6e6e6"
                : "#e6e6e6"
            wrapMode: Text.Wrap
        }
    }   
}

