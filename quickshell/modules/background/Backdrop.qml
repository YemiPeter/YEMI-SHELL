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
    WlrLayershell.namespace: "quickshell:yBackdrop"
    exclusionMode: ExclusionMode.Ignore

    mask: Region { width: 0; height: 0 }

    readonly property bool parallaxOn: QsSingletons.Flags.parallaxEnable
    readonly property real parallaxScale: root.parallaxOn ? QsSingletons.Flags.parallaxZoom : 1.0
    readonly property int wsId: {
        const m = Compositor.monitorFor(root.screen)
        return (m && m.activeWorkspace) ? m.activeWorkspace.id : 1
    }
    readonly property real maxShift: root.parallaxScale > 1
        ? (root.parallaxScale - 1) / 2 * 0.9 * root.width
        : 0
    readonly property real parallaxStep: root.maxShift * QsSingletons.Flags.parallaxStrength
    readonly property real shift: root.parallaxOn ? Math.min(
        Math.max((root.wsId - 1) * root.parallaxStep, 0),
        root.maxShift
    ) : 0

    readonly property real dim: (QsSingletons.Flags.backdropEnable && QsSingletons.Flags.backdropEffects) ? QsSingletons.Flags.backdropDim : 0
    readonly property real vignette: (QsSingletons.Flags.backdropEnable && QsSingletons.Flags.backdropEffects && QsSingletons.Flags.backdropVignetteEnable) ? QsSingletons.Flags.backdropVignette : 0
    readonly property real vr: QsSingletons.Flags.backdropVignetteRadius
    readonly property real vignetteInner: 1.0 - root.vr

    readonly property bool globalAnimationEnabled: QsSingletons.Flags.wallpaperEnableAnimation
    readonly property bool globalBlurEnabled: QsSingletons.Flags.wallpaperEnableBlur
    readonly property int globalBlurRadius: QsSingletons.Flags.wallpaperBlurRadius
    readonly property real globalDim: QsSingletons.Flags.wallpaperDim
    readonly property real effectiveBlur: Math.min(1.0, ((QsSingletons.Flags.backdropBlurRadius + (root.globalBlurEnabled ? root.globalBlurRadius : 0)) / 100.0))
    readonly property real effectiveDim: Math.min(1.0, root.dim + root.globalDim)

    readonly property bool wallpaperActive: QsSingletons.Flags.wallpaperUseMainWallpaper
    readonly property bool hideWhenFullscreen: QsSingletons.Flags.wallpaperHideWhenFullscreen

    readonly property string effectiveWallpaper: (!QsSingletons.Flags.backdropUseMainWallpaper && QsSingletons.Flags.backdropWallpaperPath !== "") ? QsSingletons.Flags.backdropWallpaperPath : QsSingletons.WallpaperState.current
    readonly property string _wpPath: root.effectiveWallpaper || ""
    readonly property bool isGif: root._wpPath.toLowerCase().endsWith(".gif")

    Item {
        id: wallContainer
        anchors.fill: parent
        x: -root.shift
        scale: root.parallaxScale
        transformOrigin: Transform.Center
        visible: root.wallpaperActive

        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        Image {
            id: wall
            anchors.fill: parent
            visible: !root.isGif
            source: root.effectiveWallpaper !== "" ? "file://" + root.effectiveWallpaper : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
        }

        AnimatedImage {
            id: gifWallpaper
            anchors.fill: parent
            visible: root.isGif
            playing: root.isGif && QsSingletons.Flags.backdropEnableAnimation && root.globalAnimationEnabled
            source: root._wpPath !== "" ? (root._wpPath.startsWith("file://") ? root._wpPath : "file://" + root._wpPath) : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
        }
    }

    MultiEffect {
        id: wallFx
        anchors.fill: wallContainer
        source: wallContainer
        visible: QsSingletons.Flags.backdropEnable && root.wallpaperActive
        blurEnabled: root.effectiveBlur > 0
        blur: root.effectiveBlur
        blurMax: 64
        saturation: QsSingletons.Flags.backdropSaturation / 100.0
        contrast: QsSingletons.Flags.backdropContrast / 100.0
    }

    MultiEffect {
        id: wallFx
        anchors.fill: wallContainer
        source: wallContainer
        visible: QsSingletons.Flags.backdropEnable
        blurEnabled: root.effectiveBlur > 0
        blur: root.effectiveBlur
        blurMax: 64
        saturation: QsSingletons.Flags.backdropSaturation / 100.0
        contrast: QsSingletons.Flags.backdropContrast / 100.0
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.effectiveDim
        visible: root.effectiveDim > 0
    }

    Item {
        anchors.fill: parent
        visible: root.vignette > 0

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, root.vignette) }
                GradientStop { position: root.vignetteInner; color: "transparent" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: root.vr; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, root.vignette) }
            }
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, root.vignette) }
                GradientStop { position: root.vignetteInner; color: "transparent" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: root.vr; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, root.vignette) }
            }
        }
    }
}
