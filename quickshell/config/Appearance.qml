pragma Singleton

import Quickshell
import QtQuick 6.10
import "../services" as QsServices
import "../singletons" as QsSingletons
import qs.compositor
import "functions"
import "theme/moods"

Singleton {
    // Directly expose appearance properties from Config
    readonly property var rounding: Config.appearance.rounding
    readonly property var spacing: Config.appearance.spacing
    readonly property var padding: Config.appearance.padding
    readonly property var font: Config.appearance.font
    readonly property var anim: Config.appearance.anim
    readonly property var transparency: Config.appearance.transparency

    // === iNiR Compatibility Layer ===

    // 5a — Font pixel size scale
    readonly property var fontSize: ({
        huge: font.typography && font.typography.displayLarge ? font.typography.displayLarge.size : 57,
        normal: font.typography && font.typography.bodyLarge ? font.typography.bodyLarge.size : 16,
        smaller: font.typography && font.typography.bodyMedium ? font.typography.bodyMedium.size : 14,
        small: font.typography && font.typography.bodySmall ? font.typography.bodySmall.size : 12,
        smallest: font.typography && font.typography.labelSmall ? font.typography.labelSmall.size : 11
    })

    // 5b — Font family for numbers
    readonly property var fontFamily: ({
        numbers: font.family ? font.family : "JetBrains Mono"
    })

    // 5c — Effects enabled flag
    readonly property bool effectsEnabled: true

    // 5d — Semantic color tokens from Theme singleton
    readonly property var colors: ({
        colPrimary: QsSingletons.Theme.onGlow,
        colOnPrimary: Qt.rgba(0, 0, 0, 0.9),
        colSecondary: QsSingletons.Theme.verm,
        colSecondaryContainer: Qt.darker(QsSingletons.Theme.verm, 1.3),
        colTertiary: QsSingletons.Theme.verm,
        colError: QsSingletons.Theme.vermBurn,
        colSuccess: "#a6e3a1",
        colBackgroundSurfaceContainer: Qt.rgba(
            QsSingletons.Theme.cardBot.r,
            QsSingletons.Theme.cardBot.g,
            QsSingletons.Theme.cardBot.b, 0.55
        ),
        colLayer0: QsSingletons.Theme.cardBot,
        colLayer1: Qt.lighter(QsSingletons.Theme.cardBot, 1.15),
        colLayer2: Qt.lighter(QsSingletons.Theme.cardBot, 1.25),
        colLayer0Base: QsSingletons.Theme.cardBot,
        colLayer1Base: Qt.lighter(QsSingletons.Theme.cardBot, 1.15),
        colSubtext: Qt.rgba(
            QsSingletons.Theme.cream.r,
            QsSingletons.Theme.cream.g,
            QsSingletons.Theme.cream.b, 0.7
        ),
        colOnLayer1: QsSingletons.Theme.cream,
        colOutlineVariant: Qt.rgba(
            QsSingletons.Theme.cream.r,
            QsSingletons.Theme.cream.g,
            QsSingletons.Theme.cream.b, 0.08
        ),
        colLayer0Border: Qt.rgba(
            QsSingletons.Theme.cream.r,
            QsSingletons.Theme.cream.g,
            QsSingletons.Theme.cream.b, 0.08
        ),
        colLayer1Border: Qt.rgba(
            QsSingletons.Theme.cream.r,
            QsSingletons.Theme.cream.g,
            QsSingletons.Theme.cream.b, 0.12
        ),
        colScrim: Qt.rgba(0, 0, 0, 0.32),
        colLayer2Hover: Qt.rgba(
            QsSingletons.Theme.cream.r,
            QsSingletons.Theme.cream.g,
            QsSingletons.Theme.cream.b, 0.08
        ),
        colLayer1Hover: Qt.rgba(
            QsSingletons.Theme.cream.r,
            QsSingletons.Theme.cream.g,
            QsSingletons.Theme.cream.b, 0.12
        ),
        colPrimaryHover: Qt.lighter(QsSingletons.Theme.onGlow, 1.15)
    })

    // === Theme Adapter (Section 8) ===

    /// Resolve the active mood singleton (LightMood or DarkMood).
    readonly property var activeMood: QsSingletons.Flags.systemMood === "light" ? LightMood : DarkMood

    /// Whether the palette source is dynamic (wallpaper-derived) vs static.
    readonly property bool isDynamic: QsSingletons.Flags.paletteMode !== "static"

    /// Static mode + grayscale accent toggle (forces neutral gray accents).
    readonly property bool isGrayscaleStatic: !isDynamic && QsSingletons.Flags.staticGrayscaleAccents

    // --- Aurora glass style (ported from iNiR) ------------------------
    // When active, layer surfaces become translucent so the wallpaper shows
    // through (the "aurora" look). Driven by Flags.themeStyle === "aurora",
    // hard-gated to Hyprland: the Glass pipeline relies on Hyprland's layer
    // rendering, so a synced "aurora" themeStyle must never activate Glass on
    // Niri (or any unknown compositor) — there the pill stays fully solid.
    readonly property bool auroraEverywhere: QsSingletons.Flags.themeStyle === "aurora" && Compositor.isHyprland
    readonly property real _auroraLightFactor: auroraEverywhere && QsSingletons.Flags.systemMood !== "dark" ? 0.75 : 1.0

    readonly property var aurora: {
        const overlay = 0.30 * _auroraLightFactor;
        const subSurface = 0.42 * _auroraLightFactor;
        const popup = 0.32 * _auroraLightFactor;
        const tooltip = 0.28 * _auroraLightFactor;
        const layer = 0.32 * _auroraLightFactor;
        return {
            overlay: overlay,
            subSurface: subSurface,
            popup: popup,
            tooltip: tooltip,
            layer: layer,
            layerTransparentize: layer,
            colOverlay: ColorUtils.transparentize(yemiTileBgBase, overlay),
            colSubSurface: ColorUtils.transparentize(yemiCardTopBase, subSurface),
            colSubSurfaceHover: ColorUtils.transparentize(ColorUtils.mix(yemiCardTopBase, yemiCreamBase, 0.92), subSurface),
            colElevatedSurface: ColorUtils.transparentize(yemiCardBotBase, subSurface * 0.9),
            colElevatedSurfaceHover: ColorUtils.transparentize(ColorUtils.mix(yemiCardBotBase, yemiCreamBase, 0.92), subSurface * 0.9),
            colPopupSurface: ColorUtils.transparentize(yemiCardBotBase, popup),
            colPopupSurfaceHover: ColorUtils.transparentize(ColorUtils.mix(yemiCardBotBase, yemiCreamBase, 0.92), popup),
            colTooltipSurface: ColorUtils.transparentize(Qt.lighter(yemiCardBotBase, 1.15), tooltip),
            colTooltipBorder: ColorUtils.transparentize(ColorUtils.mix(Qt.lighter(yemiCardBotBase, 1.15), yemiCreamBase, 0.85), tooltip * 0.8),
            colDialogSurface: ColorUtils.transparentize(Qt.lighter(yemiCardBotBase, 1.15), popup * 0.85),
            colPopupBorder: ColorUtils.transparentize(yemiBorder, 0.7),
            colTextSecondary: ColorUtils.transparentize(yemiCreamBase, 0.3)
        };
    }

    /// Raw Material 3 palette — always from Dyn (accent source even in static mode).
    readonly property var m3: QsSingletons.Dyn.active

    // --- Resolved Yemi compatibility tokens ---------------------------
    // Dynamic: wallpaper-derived via Dyn. Static: solid mood surfaces.
    // Text colors are run through ColorUtils.ensureReadable() for contrast.
    readonly property color yemiTileBgBase: QsSingletons.Dyn.schemeValid ? (isDynamic ? QsSingletons.Dyn.surface : activeMood.tileBg) : activeMood.tileBg
    readonly property color yemiCardTopBase: QsSingletons.Dyn.schemeValid ? (isDynamic ? QsSingletons.Dyn.surfaceContainerHigh : activeMood.cardTop) : activeMood.cardTop
    readonly property color yemiCardBotBase: QsSingletons.Dyn.schemeValid ? (isDynamic ? QsSingletons.Dyn.surfaceContainerLow : activeMood.cardBot) : activeMood.cardBot
    // Aurora-independent text color so the aurora object can blend hovers without a cycle.
    readonly property color yemiCreamBase: QsSingletons.Dyn.schemeValid ? ColorUtils.ensureReadable(QsSingletons.Dyn.onSurface, yemiTileBgBase) : activeMood.cream

    // Aurora transparentizes the base surfaces so the wallpaper shows through.
    readonly property color yemiTileBg: auroraEverywhere ? ColorUtils.transparentize(yemiTileBgBase, aurora.layerTransparentize) : yemiTileBgBase
    readonly property color yemiCardTop: auroraEverywhere ? ColorUtils.transparentize(yemiCardTopBase, aurora.layerTransparentize) : yemiCardTopBase
    readonly property color yemiCardBot: auroraEverywhere ? ColorUtils.transparentize(yemiCardBotBase, aurora.layerTransparentize) : yemiCardBotBase
    readonly property color yemiCream: QsSingletons.Dyn.schemeValid ? ColorUtils.ensureReadable(QsSingletons.Dyn.onSurface, yemiTileBg) : activeMood.cream
    readonly property color yemiBright: QsSingletons.Dyn.schemeValid ? ColorUtils.ensureReadable(QsSingletons.Dyn.onSurface, yemiTileBg) : activeMood.bright
    readonly property color yemiSubtle: QsSingletons.Dyn.schemeValid ? ColorUtils.ensureReadable(QsSingletons.Dyn.onSurfaceVariant, yemiTileBg) : activeMood.subtle
    readonly property color yemiDim: QsSingletons.Dyn.schemeValid ? ColorUtils.ensureReadable(QsSingletons.Dyn.outline, yemiTileBg) : activeMood.dim
    readonly property color yemiFaint: QsSingletons.Dyn.schemeValid ? ColorUtils.ensureReadable(QsSingletons.Dyn.outlineVariant, yemiTileBg) : activeMood.faint
    readonly property color yemiBorder: QsSingletons.Dyn.outlineVariant
    readonly property color yemiPrimary: isGrayscaleStatic ? "#a0a0a0" : (isDynamic ? QsSingletons.Dyn.primary : QsSingletons.Dyn.primary)
    readonly property color yemiPrimaryContainer: isGrayscaleStatic ? "#505050" : (isDynamic ? QsSingletons.Dyn.primaryContainer : QsSingletons.Dyn.primaryContainer)

    // --- Flame string tokens (always #rrggbb) -------------------------
    // Read from yemiPrimary/yemiPrimaryContainer so the grayscale override
    // propagates to the flame canvas too.
    readonly property string flameInk: ColorUtils.colorToHex(yemiPrimary)
    readonly property string flameEmber: ColorUtils.colorToHex(yemiPrimaryContainer)
    readonly property string flameBurn: ColorUtils.colorToHex(yemiPrimaryContainer)
    readonly property string flameTip: ColorUtils.colorToHex(yemiPrimary)
}