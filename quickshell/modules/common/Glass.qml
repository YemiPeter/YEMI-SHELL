import QtQuick
import "../../config" as QsConfig

/**
 * Aurora glass tint overlay.
 *
 * Delivers the colored-tint visual identity of the aurora (Glass) theme.
 * Frost blur is PROVIDED BY THE COMPOSITOR, not inside QML:
 *   - Hyprland: layerrule = blur on the quickshell/pill/pill-tray namespaces
 *     blurs the live awww wallpaper pixels behind every translucent pixel of
 *     the layer surface. This Glass item draws only the tint on top of it.
 *   - Niri: the Background Backdrop layer owns the wallpaper re-paint, and
 *     Backdrop's own MultiEffect applies blur to that wallpaper copy BEFORE
 *     card windows sit on top; this Glass item is still just the tint.
 *
 * Historical note (D1 / 8819a34 / revert): this file used to self-blur via a
 * QtQuick.Effects.MultiEffect sourced from a re-loaded copy of the wallpaper
 * file. That copy was fed through WallpaperState.current which (diagnostic
 * confirmed) was stuck at "" forever (WallpaperState FileView blockLoading:true
 * with no matching reload() call). The self-blur never actually rendered.
 * Dropping the dead machinery means: no pointless Image decode attempt, no
 * 1/4-res layer texture, no saturation/bleed/mask code. The compositor is the
 * single source of truth for actual pixel blur. This Glass item = tint only.
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

    /// Extra scale on the tint's alpha (e.g. Flags.pillOpacity), applied once.
    property real tintScale: 1.0

    readonly property color tintColor: {
        const c = QsConfig.Appearance.aurora.colSubSurface;
        return Qt.rgba(c.r, c.g, c.b, c.a * root.tintScale);
    }

    // Aurora tint — the whole content of Glass now. Frost/blur comes from the
    // compositor layerrule behind us, so no readiness gate, no fade in, no
    // wallpaper file copy, no mask rect: the tint is fully present whenever
    // aurora is active and the card exists.
    Rectangle {
        anchors.fill: parent
        color: root.tintColor
        radius: root.radius
    }
}
