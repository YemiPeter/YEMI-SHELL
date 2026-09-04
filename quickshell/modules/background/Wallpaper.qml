import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.compositor
import "../../singletons" as QsSingletons

PanelWindow {
    id: root

    required property var modelData
    screen: root.modelData

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell:yWallpaper"
    exclusionMode: ExclusionMode.Ignore

    mask: Region { width: 0; height: 0 }

    readonly property bool active: QsSingletons.Flags.wallpaperUseMainWallpaper && !QsSingletons.Flags.backdropHideWallpaper
    readonly property string wallpaperPath: QsSingletons.WallpaperState.current
    readonly property string _wpPath: root.wallpaperPath || ""
    readonly property bool isGif: root._wpPath.toLowerCase().endsWith(".gif")

    readonly property bool animEnabled: QsSingletons.Flags.wallpaperEnableAnimation && root.active
    readonly property bool blurEnabled: QsSingletons.Flags.wallpaperEnableBlur && root.active
    readonly property int blurRadius: QsSingletons.Flags.wallpaperBlurRadius
    readonly property real dimAmount: root.active ? QsSingletons.Flags.wallpaperDim : 0

    visible: root.active

    Item {
        id: wallContainer
        anchors.fill: parent

        Image {
            anchors.fill: parent
            visible: !root.isGif
            source: root.wallpaperPath !== "" ? "file://" + root.wallpaperPath : ""
            fillMode: Image.PreserveAspectCrop
            // Decode at display size, not the wallpaper file's native res
            // (skill-audit roundup step 2).
            sourceSize: Qt.size(Math.max(1, Math.ceil(width)), Math.max(1, Math.ceil(height)))
            asynchronous: true
            smooth: true
        }

        AnimatedImage {
            anchors.fill: parent
            visible: root.isGif && root.animEnabled
            playing: visible
            source: root._wpPath !== "" ? (root._wpPath.startsWith("file://") ? root._wpPath : "file://" + root._wpPath) : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: wallContainer
        visible: root.blurEnabled || root.dimAmount > 0
        blurEnabled: root.blurEnabled && root.blurRadius > 0
        blur: root.blurRadius / 100.0
        blurMax: 64
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.dimAmount
        visible: root.dimAmount > 0
    }
}
