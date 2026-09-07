import QtQuick
import "../../config" as QsConfig
import "../../singletons" as QsSingletons

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
 * No-wallpaper fallback (D4): when WallpaperState.current is empty there is
 * nothing behind us to frost, and the flat tint over the bare desktop reads
 * as a dead gray box. In that state the tint swaps to a vertical mood
 * gradient built from the Dyn palette (the Dominance Engine's colors carry
 * hardcoded fallbacks, so they are valid even with no wallpaper to sample).
 * Animated wallpapers need no handling here at all: Glass never samples
 * wallpaper pixels (post-5d64483 tint-only architecture), and GIF playback
 * lives entirely in modules/background/Backdrop.qml's AnimatedImage on Niri;
 * awww deliberately refuses GIFs on
 * Hyprland — see AwwwBackend.supportsMainWallpaper).
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

    /// True when no wallpaper is configured (empty state-file → the reactive
    /// WallpaperState FileView resolves to ""). Note this tracks the SYSTEM
    /// wallpaper state, not Backdrop's Niri test overrides
    /// (Flags.backdropWallpaperPath) — a deliberate simplification.
    readonly property bool wallpaperMissing: QsSingletons.WallpaperState.current === ""

    // Mood-gradient fallback colors (Feature 2 / D4). Built from existing Dyn
    // palette tokens — warm primaryContainer fading into surface tones — at
    // tintColor.a so tintScale keeps scaling the alpha exactly once. Dyn's
    // per-property hardcoded fallbacks guarantee valid colors even with the
    // Dominance Engine idle (which is exactly the no-wallpaper case).
    readonly property color moodTop: Qt.rgba(QsSingletons.Dyn.primaryContainer.r, QsSingletons.Dyn.primaryContainer.g, QsSingletons.Dyn.primaryContainer.b, root.tintColor.a)
    readonly property color moodMid: Qt.rgba(QsSingletons.Dyn.surfaceContainer.r, QsSingletons.Dyn.surfaceContainer.g, QsSingletons.Dyn.surfaceContainer.b, root.tintColor.a)
    readonly property color moodBottom: Qt.rgba(QsSingletons.Dyn.surfaceContainerLow.r, QsSingletons.Dyn.surfaceContainerLow.g, QsSingletons.Dyn.surfaceContainerLow.b, root.tintColor.a)

    // Aurora tint — the whole content of Glass now. Frost/blur comes from the
    // compositor layerrule behind us, so no readiness gate, no fade in, no
    // wallpaper file copy, no mask rect: the tint is fully present whenever
    // aurora is active and the card exists. With no wallpaper configured the
    // flat tint swaps to the mood gradient (a Gradient set on a Rectangle
    // takes precedence over color, so the states cannot stack).
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        gradient: root.wallpaperMissing ? moodGrad : null
        color: root.wallpaperMissing ? "transparent" : root.tintColor
    }

    Gradient {
        id: moodGrad
        orientation: Gradient.Vertical
        GradientStop { position: 0.0; color: root.moodTop }
        GradientStop { position: 0.55; color: root.moodMid }
        GradientStop { position: 1.0; color: root.moodBottom }
    }
}
