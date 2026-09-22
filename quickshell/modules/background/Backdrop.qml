import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.compositor
import "../common/widgets"
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

    // Niri-only workspace parallax, loaded through a Loader so Hyprland never
    // evaluates parallax math or holds a Behavior animator object. The loaded
    // component owns shift/parallaxScale and the x-animation; see
    // BackdropParallax.qml.
    readonly property bool parallaxActive: parallaxLoader.active && parallaxLoader.item !== null

    readonly property real dim: (QsSingletons.Flags.backdropEnable && QsSingletons.Flags.backdropEffects) ? QsSingletons.Flags.backdropDim : 0
    readonly property real vignette: (QsSingletons.Flags.backdropEnable && QsSingletons.Flags.backdropEffects && QsSingletons.Flags.backdropVignetteEnable) ? QsSingletons.Flags.backdropVignette : 0
    readonly property real vr: QsSingletons.Flags.backdropVignetteRadius
    readonly property real vignetteInner: 1.0 - root.vr

    readonly property string effectiveWallpaper: (!QsSingletons.Flags.backdropUseMainWallpaper && QsSingletons.Flags.backdropWallpaperPath !== "") ? QsSingletons.Flags.backdropWallpaperPath : QsSingletons.WallpaperState.current
    readonly property string _wpPath: root.effectiveWallpaper || ""
    readonly property bool isGif: root._wpPath.toLowerCase().endsWith(".gif")
    readonly property bool isVideo: {
        const lower = root._wpPath.toLowerCase();
        return lower.endsWith(".mp4") || lower.endsWith(".webm") || lower.endsWith(".mkv")
            || lower.endsWith(".avi") || lower.endsWith(".mov");
    }
    readonly property bool isAnimated: root.isGif || root.isVideo

    // When the mpvpaper engine flag is on, animated picks (video AND gif) are
    // owned by mpvpaper: mpv hardware-decodes in its own process on a
    // layer-shell background surface, outside quickshell's render loop. The
    // QML layers below hide entirely in that case — nothing here can render a
    // video, and QML's AnimatedImage was the GIF lag source (CPU frame decode
    // inside the shell process). With the engine off, GIFs fall back to the
    // QML AnimatedImage path below; videos have no QML fallback.
    readonly property bool mpvpaperOwns: QsSingletons.Flags.wallpaperVideoEngine && root.isAnimated

    // Whether the QML-rendered image is actually shown.
    // Niri: QML *is* the wallpaper, always show it — except animated picks
    // owned by mpvpaper, which render on their own layer surface.
    // Hyprland: awww paints the real wallpaper; the QML backdrop is Niri-only
    // and does not render here, so the image layer is never shown.
    readonly property bool showImageLayer: Compositor.isNiri
                                           && !QsSingletons.Flags.backdropHideWallpaper
                                           && !root.mpvpaperOwns

    // Niri-only backdrop layer. On Hyprland, awww owns the wallpaper and the
    // QML overlay must not run (no parallax, no crossfader, no effects).
    visible: QsSingletons.Flags.backdropEnable && Compositor.isNiri

    Loader {
        id: parallaxLoader
        anchors.fill: parent
        active: Compositor.isNiri
        sourceComponent: BackdropParallax {
            monitorScreen: root.screen
        }
    }

    Item {
        id: wallContainer
        anchors {
            fill: parent
            margins: -64
        }
        // Driven by BackdropParallax when loaded (Niri); identity otherwise.
        // The ternary short-circuits, so parallaxLoader.item is never
        // dereferenced while it is null (loader inactive).
        x: root.parallaxActive ? parallaxLoader.item.containerX : 0
        scale: root.parallaxActive ? parallaxLoader.item.parallaxScale : 1.0
        transformOrigin: Item.Center

        WallpaperCrossfader {
            id: wall
            anchors.fill: parent
            visible: root.showImageLayer && !root.isGif
            source: root.effectiveWallpaper !== "" ? (root.effectiveWallpaper.startsWith("file://") ? root.effectiveWallpaper : "file://" + root.effectiveWallpaper) : ""
            fillMode: Image.PreserveAspectCrop
        }

        AnimatedImage {
            id: gifWallpaper
            anchors.fill: parent
            visible: root.showImageLayer && root.isGif
            playing: root.showImageLayer && root.isGif && QsSingletons.Flags.backdropEnableAnimation
            source: root._wpPath !== "" ? (root._wpPath.startsWith("file://") ? root._wpPath : "file://" + root._wpPath) : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
        }
    }

    MultiEffect {
        id: wallFx
        anchors.fill: wallContainer
        source: root.isGif ? wallContainer : wall
        // Effects apply to the QML-rendered backdrop, which is Niri-only; an
        // explicit gate here stops blur/saturation/contrast bindings from
        // evaluating at all when the layer itself is off (Hyprland).
        visible: QsSingletons.Flags.backdropEnable && Compositor.isNiri

    // The WallpaperState singleton's `current` change isn't always picked up by
    // the readonly-property binding chain in time (singleton change signals
    // across files can be flaky). Listen explicitly and forward the new path
    // to the crossfader so the QML transition kicks in.
    Connections {
        target: QsSingletons.WallpaperState
        function onCurrentChanged() {
            const path = root.effectiveWallpaper
            wall.source = path !== "" ? (path.startsWith("file://") ? path : "file://" + path) : ""
        }
    }
    Connections {
        target: QsSingletons.Flags
        function onBackdropWallpaperPathChanged() {
            const path = root.effectiveWallpaper
            wall.source = path !== "" ? (path.startsWith("file://") ? path : "file://" + path) : ""
        }
        function onBackdropUseMainWallpaperChanged() {
            const path = root.effectiveWallpaper
            wall.source = path !== "" ? (path.startsWith("file://") ? path : "file://" + path) : ""
        }
    }
        // Blur must not arm until the crossfader has decoded at least one
        // frame: a MultiEffect with blurEnabled over a not-yet-decoded Image
        // renders the source as a solid color frame (the Niri startup race).
        // hasLoadedOnce is a latch set on the crossfader's first successful
        // decode and never reset — not `ready`, which stays true while a NEW
        // wallpaper decodes and would re-trigger the same race on every
        // wallpaper change.
        blurEnabled: QsSingletons.Flags.backdropBlurRadius > 0
                     && wall.hasLoadedOnce
                     && (!root.isGif || QsSingletons.Flags.backdropEnableAnimatedBlur)
        blur: QsSingletons.Flags.backdropBlurRadius / 100.0
        blurMax: 64
        saturation: QsSingletons.Flags.backdropSaturation / 100.0
        contrast: QsSingletons.Flags.backdropContrast / 100.0
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.dim
        visible: root.dim > 0
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
