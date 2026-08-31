import QtQuick
import QtQuick.Effects
import "../../singletons" as QsSingletons
import "../../config" as QsConfig

/**
 * Frosted aurora glass background.
 *
 * Ported from iNiR's per-card aurora glass: a blurred copy of the live wallpaper
 * plus a translucent aurora tint, masked to `radius`. Drop it as the FIRST
 * child of a card so it sits behind the card's content.
 *
 * Layering contract: when a card is Glass-backed, the Glass IS the surface —
 * the host must not paint its own cardTop/cardBot fill over it (those tokens
 * are already aurora-transparentized, so stacking another fill double-dims).
 * Hosts that need a user-facing opacity feed it through `tintScale`, which
 * scales the tint's alpha once.
 *
 * Only paints when the Aurora theme is active (Appearance.auroraEverywhere);
 * in the default "yemi" style it is invisible and costs nothing visible.
 */
Rectangle {
    id: root

    color: "transparent"
    // No `clip` here: Rectangle clip cuts at the bounding rect, so the blurred
    // wallpaper would poke out as square corners past `radius`. The rounded
    // corners come from the MultiEffect mask below instead.
    radius: 12

    readonly property bool active: QsConfig.Appearance.auroraEverywhere
    visible: root.active

    /// Extra scale on the tint's alpha (e.g. Flags.pillOpacity), applied once.
    property real tintScale: 1.0

    readonly property color tintColor: {
        const c = QsConfig.Appearance.aurora.colSubSurface
        return Qt.rgba(c.r, c.g, c.b, c.a * root.tintScale)
    }

    // Live wallpaper, blurred. Sourced from the same WallpaperState the
    // Background layer draws, so the frost matches the user's wallpaper.
    Image {
        id: wp
        anchors.fill: parent
        source: root.active && QsSingletons.WallpaperState.current !== ""
            ? "file://" + QsSingletons.WallpaperState.current : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
    }

    // Mask source for the blur: an opaque white rounded rect rendered to a
    // texture. White is channel-agnostic (alpha, RGB all 1 inside, 0 outside),
    // so the mask shape is correct however MultiEffect samples it.
    Rectangle {
        id: maskRect
        anchors.fill: parent
        radius: root.radius
        color: "white"
        // Ensure the rect is rendered so the ShaderEffectSource can sample it.
        visible: true
    }

    ShaderEffectSource {
        id: maskSourceItem
        sourceItem: maskRect
        hideSource: true
        live: true
        // Disable smoothing to avoid a 1-2px semi-transparent fringe
        // when the mask is sampled by MultiEffect.
        smooth: false
    }

    MultiEffect {
        anchors.fill: parent
        source: wp
        visible: root.active
        blurEnabled: true
        blur: 0.6
        blurMax: 64
        saturation: 0.25
        maskEnabled: true
        maskSource: maskSourceItem
    }

    // Aurora tint — replaces the card's flat gradient in aurora mode.
    Rectangle {
        anchors.fill: parent
        color: root.tintColor
        radius: root.radius
    }
}
