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
    clip: true
    radius: 12

    readonly property bool active: QsConfig.Appearance.auroraEverywhere
    visible: root.active

    /// True once the wallpaper has decoded. The blur fades in over the tint
    /// when this flips, so activating aurora (or a wallpaper change) never
    /// flashes a tint-only card before the frost pops.
    readonly property bool frostReady: wp.status === Image.Ready

    /// Extra scale on the tint's alpha (e.g. Flags.pillOpacity), applied once.
    property real tintScale: 1.0

    // --- Screen geometry (iNiR GlassBackground contract) -------------------
    // The pill's overlay PanelWindow is fullscreen and edge-anchored, so
    // window-scene coordinates equal screen coordinates. This position is
    // computed by summing the ancestor x/y chain rather than mapToItem(null):
    // mapToItem is a Q_INVOKABLE and does NOT register binding dependencies,
    // so a mapToItem binding would go stale when the pill or a tooltip moves.
    // JS property reads ARE tracked, so this re-evaluates on any ancestor
    // move (pill morph, tooltip anchor, surface open).
    readonly property point screenPos: {
        let x = 0;
        let y = 0;
        let it = root;
        while (it) {
            x += it.x;
            y += it.y;
            it = it.parent;
        }
        return Qt.point(x, y);
    }

    /// Screen the hosting window sits on (uniform wallpaper geometry).
    readonly property real screenW: Screen.width
    readonly property real screenH: Screen.height

    readonly property color tintColor: {
        const c = QsConfig.Appearance.aurora.colSubSurface;
        return Qt.rgba(c.r, c.g, c.b, c.a * root.tintScale);
    }

    // Live wallpaper, blurred. Sourced from the same WallpaperState the
    // Background layer draws, so the frost matches the user's wallpaper.
    //
    // Position-aligned per iNiR's GlassBackground: the Image is SCREEN-sized
    // and offset by -screenPos, so the card shows exactly the wallpaper region
    // physically behind it (a true frosted window, not a centered crop).
    //
    // The screen-sized source is additionally oversized by `bleed` on every
    // side: the blur kernel (blur * blurMax ≈ 38px) has no pixels beyond the
    // item edge, so an exactly-screen-sized source would fade at the screen
    // borders (iNiR Backdrop.qml's documented "blur edge compensation").
    // Bleeding real wallpaper pixels past the screen edges keeps the blur
    // dense everywhere; the maskRect below crops the result back to the
    // rounded card.
    Image {
        id: wp
        readonly property real bleed: 64
        x: -root.screenPos.x - bleed
        y: -root.screenPos.y - bleed
        width: root.screenW + bleed * 2
        height: root.screenH + bleed * 2
        source: root.active && QsSingletons.WallpaperState.current !== ""
            ? "file://" + QsSingletons.WallpaperState.current : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(Math.max(1, Math.ceil(width)), Math.max(1, Math.ceil(height)))
        cache: true
        asynchronous: true
        smooth: true
        visible: false
    }

    // Rounded-rect mask for the blur. White inside the radius, transparent
    // outside, so it works whether the mask shader samples red or alpha.
    // root's rect clip only bounds the blur spill; the corners come from here
    // (clip: true alone crops to the bounding box, not the radius).
    Rectangle {
        id: maskRect
        anchors.fill: parent
        radius: root.radius
        color: "white"
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: wp
        visible: root.active && root.frostReady
        opacity: root.active && root.frostReady ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
        blurEnabled: true
        blur: 0.6
        blurMax: 64
        saturation: 0.25
        maskEnabled: true
        maskSource: maskRect
    }

    // Aurora tint — replaces the card's flat gradient in aurora mode.
    Rectangle {
        anchors.fill: parent
        color: root.tintColor
        radius: root.radius
    }
}
