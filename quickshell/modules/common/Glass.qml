import QtQuick
import QtQuick.Effects
import "../../singletons" as QsSingletons
import "../../config" as QsConfig

/**
 * Frosted aurora glass background.
 *
 * Ported from iNiR's per-card aurora glass: a blurred copy of the live wallpaper
 * plus a translucent aurora tint, clipped to `radius`. Drop it as the FIRST
 * child of a card so it sits behind the card's content.
 *
 * Only paints when the Aurora theme is active (Appearance.auroraEverywhere);
 * in the default "yemi" style it is invisible and costs nothing visible.
 */
Rectangle {
    id: root

    color: "transparent"
    clip: true
    radius: 12

    readonly property bool active: QsConfig.Appearance.auroraEverywhere
    visible: root.active

    // Live wallpaper, blurred. Sourced from the same WallpaperState the
    // Background layer draws, so the frost matches the user's wallpaper.
    Image {
        id: wp
        anchors.fill: parent
        source: QsSingletons.WallpaperState.current !== "" ? "file://" + QsSingletons.WallpaperState.current : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: wp
        visible: root.active
        blurEnabled: true
        blur: 0.6
        blurMax: 64
        saturation: 0.25
    }

    // Aurora tint — replaces the card's flat gradient in aurora mode.
    Rectangle {
        anchors.fill: parent
        color: QsConfig.Appearance.aurora.colSubSurface
        radius: root.radius
    }
}
