pragma Singleton

import Quickshell
import QtQuick 6.10
import "../services" as QsServices
import "../singletons" as QsSingletons
import "functions"
import "theme/moods"

Singleton {
    id: root

    // Directly expose appearance properties from Config
    readonly property var rounding: Config.appearance.rounding
    readonly property var spacing: Config.appearance.spacing
    readonly property var padding: Config.appearance.padding
    readonly property var font: Config.appearance.font
    readonly property var anim: Config.appearance.anim

    // === iNiR Animation Compatibility Layer ===
    // Ported (iNiR-derived) widgets reference Appearance.animation.<token>
    // with { duration, type, bezierCurve }. The rewritten yemishell schema
    // exposes durations/curves/easing instead, so map the named tokens here.
    readonly property bool animationsEnabled: true
    readonly property var animation: ({
        elementMoveFast: {
            duration: anim.durations.fast,
            type: Easing.BezierSpline,
            bezierCurve: anim.curves.emphasizedDecel
        },
        elementMove: {
            duration: anim.durations.normal,
            type: Easing.BezierSpline,
            bezierCurve: anim.curves.standardDecel
        },
        elementResize: {
            duration: anim.durations.normal,
            type: Easing.BezierSpline,
            bezierCurve: anim.curves.standard
        },
        elementMoveEnter: {
            duration: anim.durations.fast,
            type: Easing.BezierSpline,
            bezierCurve: anim.curves.standardDecel
        },
        elementMoveExit: {
            duration: anim.durations.fast,
            type: Easing.BezierSpline,
            bezierCurve: anim.curves.standardAccel
        },
        scroll: {
            duration: anim.durations.normal,
            type: Easing.BezierSpline,
            bezierCurve: anim.curves.standard
        },
        clickBounce: {
            duration: anim.durations.fast,
            type: Easing.OutBack,
            bezierCurve: anim.curves.emphasizedDecel
        }
    })

    readonly property var transparency: Config.appearance.transparency

    // === iNiR Compatibility Layer ===

    // 5a — Global UI scale factor used by Looks.scaledBar / Looks.dp
    readonly property real fontSizeScale: Config.options?.appearance?.typography?.sizeScale ?? 1.0

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

    // === iNiR theme bridge (Phase 1) — shared Appearance tokens for waffle ===
    // Mirrors iNiR's Appearance derivation, sourced from Dyn (Dominance M3 scheme)
    // so waffle renders the Yemi theme via the same single Appearance engine that
    // Pill uses. Reactive to wallpaper changes (Dyn.revision).

    // Resolve a snake_case Dyn active-scheme key, with a literal hex fallback so
    // waffle never sees undefined before Dyn finishes loading.
    function _dynColor(key, fallback) {
        QsSingletons.Dyn.revision
        const a = QsSingletons.Dyn.active
        return (a && a[key] !== undefined) ? a[key] : fallback
    }

    // --- Material 3 palette (read-only so MaterialThemeLoader cannot clobber) ---
    property QtObject m3colors: QtObject {
        readonly property bool darkmode: QsSingletons.Flags.systemMood !== "light"
        readonly property bool transparent: false
        readonly property color m3background: root._dynColor("surface", "#06070b")
        readonly property color m3onBackground: root._dynColor("on_surface", "#E3E6F0")
        readonly property color m3surface: root._dynColor("surface", "#06070b")
        readonly property color m3surfaceDim: "#05060a"
        readonly property color m3surfaceBright: "#141825"
        readonly property color m3surfaceContainerLowest: root._dynColor("surface_container_lowest", "#040508")
        readonly property color m3surfaceContainerLow: root._dynColor("surface_container_low", "#0B0E16")
        readonly property color m3surfaceContainer: root._dynColor("surface_container", "#111522")
        readonly property color m3surfaceContainerHigh: root._dynColor("surface_container_high", "#161B28")
        readonly property color m3surfaceContainerHighest: root._dynColor("surface_container_highest", "#1B2233")
        readonly property color m3onSurface: root._dynColor("on_surface", "#E3E6F0")
        readonly property color m3surfaceVariant: "#3D455A"
        readonly property color m3onSurfaceVariant: root._dynColor("on_surface_variant", "#C3CAD9")
        readonly property color m3inverseSurface: root._dynColor("inverse_surface", "#E3E6F0")
        readonly property color m3inverseOnSurface: root._dynColor("inverse_on_surface", "#151822")
        readonly property color m3outline: root._dynColor("outline", "#707894")
        readonly property color m3outlineVariant: root._dynColor("outline_variant", "#3D455A")
        readonly property color m3shadow: "#000000"
        readonly property color m3scrim: "#000000"
        readonly property color m3surfaceTint: "#1F6CFF"
        readonly property color m3primary: root._dynColor("primary", "#1F6CFF")
        readonly property color m3onPrimary: root._dynColor("on_primary", "#0A1020")
        readonly property color m3primaryContainer: root._dynColor("primary_container", "#12244A")
        readonly property color m3onPrimaryContainer: root._dynColor("on_primary_container", "#C7D4FF")
        readonly property color m3inversePrimary: "#8CACFF"
        readonly property color m3secondary: root._dynColor("secondary", "#9AA5C0")
        readonly property color m3onSecondary: root._dynColor("on_secondary", "#151925")
        readonly property color m3secondaryContainer: root._dynColor("secondary_container", "#242C40")
        readonly property color m3onSecondaryContainer: root._dynColor("on_secondary_container", "#D6DDF0")
        readonly property color m3tertiary: root._dynColor("tertiary", "#d1c3c6")
        readonly property color m3onTertiary: root._dynColor("on_tertiary", "#372e30")
        readonly property color m3tertiaryContainer: root._dynColor("tertiary_container", "#31292b")
        readonly property color m3onTertiaryContainer: root._dynColor("on_tertiary_container", "#c1b4b7")
        readonly property color m3error: root._dynColor("error", "#ffb4ab")
        readonly property color m3onError: root._dynColor("on_error", "#690005")
        readonly property color m3errorContainer: root._dynColor("error_container", "#93000a")
        readonly property color m3onErrorContainer: root._dynColor("on_error_container", "#ffdad6")
        readonly property color m3primaryFixed: "#e7e0e7"
        readonly property color m3primaryFixedDim: "#cbc4cb"
        readonly property color m3onPrimaryFixed: "#1d1b1f"
        readonly property color m3onPrimaryFixedVariant: "#49454b"
        readonly property color m3secondaryFixed: "#e6e1e4"
        readonly property color m3secondaryFixedDim: "#cac5c8"
        readonly property color m3onSecondaryFixed: "#1d1b1d"
        readonly property color m3onSecondaryFixedVariant: "#484648"
        readonly property color m3tertiaryFixed: "#eddfe1"
        readonly property color m3tertiaryFixedDim: "#d1c3c6"
        readonly property color m3onTertiaryFixed: "#211a1c"
        readonly property color m3onTertiaryFixedVariant: "#4e4447"
        readonly property color m3success: "#B5CCBA"
        readonly property color m3onSuccess: "#213528"
        readonly property color m3successContainer: "#374B3E"
        readonly property color m3onSuccessContainer: "#D1E9D6"
        readonly property color term0: "#EDE4E4"
        readonly property color term1: "#B52755"
        readonly property color term2: "#A97363"
        readonly property color term3: "#AF535D"
        readonly property color term4: "#A67F7C"
        readonly property color term5: "#B2416B"
        readonly property color term6: "#8D76AD"
        readonly property color term7: "#272022"
        readonly property color term8: "#0E0D0D"
        readonly property color term9: "#B52755"
        readonly property color term10: "#A97363"
        readonly property color term11: "#AF535D"
        readonly property color term12: "#A67F7C"
        readonly property color term13: "#B2416B"
        readonly property color term14: "#8D76AD"
        readonly property color term15: "#221A1A"
    }

    // --- Global style detection (centralized, reactive) ---
    readonly property string globalStyle: Config?.options?.appearance?.globalStyle ?? "material"
    readonly property bool inirEverywhere: globalStyle === "inir"
    readonly property bool angelEverywhere: globalStyle === "angel"
    readonly property bool auroraEverywhere: globalStyle === "aurora" || globalStyle === "angel"
    readonly property bool _auroraLightMode: auroraEverywhere && !(m3colors?.darkmode ?? true)

    // --- Wallpaper-derived (P1: no quantizer yet, so static) ---
    readonly property real wallpaperVibrancy: 0
    readonly property color wallpaperDominantColor: QsSingletons.Dyn.schemeValid ? QsSingletons.Dyn.primary : m3colors.m3primary
    readonly property real autoBackgroundTransparency: 0
    readonly property real autoContentTransparency: 0.9

    // --- Transparency (OFF by default in P1) ---
    readonly property bool _transparencyEnabled: Config?.options?.appearance?.transparency?.enable ?? false
    readonly property bool _transparencyAutomatic: Config?.options?.appearance?.transparency?.automatic ?? true
    property real backgroundTransparency: _transparencyEnabled
        ? (_transparencyAutomatic ? autoBackgroundTransparency : (Config?.options?.appearance?.transparency?.backgroundTransparency ?? 0))
        : 0
    property real contentTransparency: _transparencyEnabled
        ? (_transparencyAutomatic ? autoContentTransparency : (Config?.options?.appearance?.transparency?.contentTransparency ?? 0))
        : 0

    // --- Aurora glass palette (used when auroraEverywhere) ---
    property QtObject aurora: QtObject {
        readonly property real _lightFactor: root._auroraLightMode ? 0.75 : 1.0
        readonly property var _cfg: { Config.revision; return Config.options?.appearance?.aurora?.transparency ?? null }
        readonly property real overlayTransparentize: (_cfg?.overlay ?? 0.30) * _lightFactor
        readonly property real subSurfaceTransparentize: (_cfg?.subSurface ?? 0.42) * _lightFactor
        readonly property real popupTransparentize: (_cfg?.popup ?? 0.32) * _lightFactor
        readonly property real tooltipTransparentize: (_cfg?.tooltip ?? 0.28) * _lightFactor
        readonly property real layerTransparentize: (_cfg?.layer ?? 0.32) * _lightFactor
        readonly property color colOverlay: ColorUtils.transparentize(root.colors.colLayer0Base, overlayTransparentize)
        readonly property color colOverlayHover: ColorUtils.transparentize(
            ColorUtils.mix(root.colors.colLayer0Base, root.colors.colOnLayer0, 0.95), overlayTransparentize)
        readonly property color colSubSurface: ColorUtils.transparentize(root.colors.colLayer1Base, subSurfaceTransparentize)
        readonly property color colSubSurfaceHover: ColorUtils.transparentize(
            ColorUtils.mix(root.colors.colLayer1Base, root.colors.colOnLayer1, 0.92), subSurfaceTransparentize)
        readonly property color colSubSurfaceActive: ColorUtils.transparentize(
            ColorUtils.mix(root.colors.colLayer1Base, root.colors.colOnLayer1, 0.85), subSurfaceTransparentize)
        readonly property color colElevatedSurface: ColorUtils.transparentize(root.colors.colLayer2Base, subSurfaceTransparentize * 0.9)
        readonly property color colElevatedSurfaceHover: ColorUtils.transparentize(
            ColorUtils.mix(root.colors.colLayer2Base, root.colors.colOnLayer2, 0.92), subSurfaceTransparentize * 0.9)
        readonly property color colPopupSurface: ColorUtils.transparentize(root.colors.colLayer2Base, popupTransparentize)
        readonly property color colPopupSurfaceHover: ColorUtils.transparentize(
            ColorUtils.mix(root.colors.colLayer2Base, root.colors.colOnLayer2, 0.92), popupTransparentize)
        readonly property color colPopupSurfaceActive: ColorUtils.transparentize(
            ColorUtils.mix(root.colors.colLayer2Base, root.colors.colOnLayer2, 0.85), popupTransparentize)
        readonly property color colTooltipSurface: ColorUtils.transparentize(root.colors.colLayer3Base, tooltipTransparentize)
        readonly property color colTooltipBorder: ColorUtils.transparentize(
            ColorUtils.mix(root.colors.colLayer3Base, root.colors.colOnLayer3, 0.85), tooltipTransparentize * 0.8)
        readonly property color colDialogSurface: ColorUtils.transparentize(root.colors.colLayer3Base, popupTransparentize * 0.85)
        readonly property color colPopupBorder: ColorUtils.transparentize(root.colors.colOutline, 0.7)
        readonly property color colTextSecondary: ColorUtils.transparentize(root.colors.colOnLayer1, 0.3)
        readonly property real popupSurfaceTransparentize: popupTransparentize
    }

    // --- Angel neo-brutalism glass palette (used when angelEverywhere) ---
    property QtObject angel: QtObject {
        readonly property real blurIntensity: Config.options?.appearance?.angel?.blur?.intensity ?? 0.35
        readonly property real blurSaturation: Config.options?.appearance?.angel?.blur?.saturation ?? 0.20
        readonly property real overlayOpacity: Config.options?.appearance?.angel?.blur?.overlayOpacity ?? 0.45
        readonly property real noiseOpacity: Config.options?.appearance?.angel?.blur?.noiseOpacity ?? 0.15
        readonly property real vignetteStrength: Config.options?.appearance?.angel?.blur?.vignetteStrength ?? 0.4
        readonly property real _lightFactor: root._auroraLightMode ? 0.75 : 1.0
        readonly property real panelTransparentize: (Config.options?.appearance?.angel?.transparency?.panel ?? 0.28) * _lightFactor
        readonly property real cardTransparentize: (Config.options?.appearance?.angel?.transparency?.card ?? 0.40) * _lightFactor
        readonly property real popupTransparentize: (Config.options?.appearance?.angel?.transparency?.popup ?? 0.28) * _lightFactor
        readonly property real tooltipTransparentize: (Config.options?.appearance?.angel?.transparency?.tooltip ?? 0.25) * _lightFactor
        readonly property color colGlassPanel: ColorUtils.transparentize(root.colors.colLayer0Base, panelTransparentize)
        readonly property color colGlassCard: ColorUtils.transparentize(root.colors.colLayer1Base, cardTransparentize)
        readonly property color colGlassCardHover: ColorUtils.transparentize(
            ColorUtils.mix(root.colors.colLayer1Base, root.colors.colOnLayer1, 0.88), cardTransparentize)
        readonly property color colGlassCardActive: ColorUtils.transparentize(
            ColorUtils.mix(root.colors.colLayer1Base, root.colors.colOnLayer1, 0.78), cardTransparentize)
        readonly property color colGlassPopup: ColorUtils.transparentize(root.colors.colLayer2Base, popupTransparentize)
        readonly property color colGlassPopupHover: ColorUtils.transparentize(
            ColorUtils.mix(root.colors.colLayer2Base, root.colors.colOnLayer2, 0.88), popupTransparentize)
        readonly property color colGlassPopupActive: ColorUtils.transparentize(
            ColorUtils.mix(root.colors.colLayer2Base, root.colors.colOnLayer2, 0.78), popupTransparentize)
        readonly property color colGlassTooltip: ColorUtils.transparentize(root.colors.colLayer3Base, tooltipTransparentize)
        readonly property color colGlassDialog: ColorUtils.transparentize(root.colors.colLayer3Base, popupTransparentize * 0.85)
        readonly property color colGlassElevated: ColorUtils.transparentize(root.colors.colLayer2Base, cardTransparentize * 0.9)
        readonly property color colGlassElevatedHover: ColorUtils.transparentize(
            ColorUtils.mix(root.colors.colLayer2Base, root.colors.colOnLayer2, 0.92), cardTransparentize * 0.9)
        readonly property real colorStrength: Math.max(0.01, Config.options?.appearance?.angel?.colorStrength ?? 1.0)
        readonly property int escalonadoOffsetX: Config.options?.appearance?.angel?.escalonado?.offsetX ?? 2
        readonly property int escalonadoOffsetY: Config.options?.appearance?.angel?.escalonado?.offsetY ?? 2
        readonly property int escalonadoHoverOffsetX: Config.options?.appearance?.angel?.escalonado?.hoverOffsetX ?? 7
        readonly property int escalonadoHoverOffsetY: Config.options?.appearance?.angel?.escalonado?.hoverOffsetY ?? 7
        readonly property real escalonadoOpacity: Config.options?.appearance?.angel?.escalonado?.opacity ?? 0.40
        readonly property real escalonadoBorderOpacity: Config.options?.appearance?.angel?.escalonado?.borderOpacity ?? 0.60
        readonly property real escalonadoHoverOpacity: Config.options?.appearance?.angel?.escalonado?.hoverOpacity ?? 0.60
        readonly property color colEscalonado: ColorUtils.transparentize(root.m3colors.m3primary, Math.min(1, escalonadoOpacity / colorStrength))
        readonly property color colEscalonadoBorder: ColorUtils.transparentize(root.m3colors.m3primary, Math.min(1, escalonadoBorderOpacity / colorStrength))
        readonly property color colEscalonadoHover: ColorUtils.transparentize(root.m3colors.m3primary, Math.min(1, escalonadoHoverOpacity / colorStrength))
        readonly property int shadowOffsetX: Config.options?.appearance?.angel?.escalonadoShadow?.offsetX ?? 4
        readonly property int shadowOffsetY: Config.options?.appearance?.angel?.escalonadoShadow?.offsetY ?? 4
        readonly property int shadowHoverOffsetX: Config.options?.appearance?.angel?.escalonadoShadow?.hoverOffsetX ?? 10
        readonly property int shadowHoverOffsetY: Config.options?.appearance?.angel?.escalonadoShadow?.hoverOffsetY ?? 10
        readonly property real shadowOpacity: Config.options?.appearance?.angel?.escalonadoShadow?.opacity ?? 0.30
        readonly property real shadowBorderOpacity: Config.options?.appearance?.angel?.escalonadoShadow?.borderOpacity ?? 0.50
        readonly property real shadowHoverOpacity: Config.options?.appearance?.angel?.escalonadoShadow?.hoverOpacity ?? 0.50
        readonly property bool shadowGlass: Config.options?.appearance?.angel?.escalonadoShadow?.glass ?? true
        readonly property real shadowGlassBlur: Config.options?.appearance?.angel?.escalonadoShadow?.glassBlur ?? 0.15
        readonly property real shadowGlassOverlay: Config.options?.appearance?.angel?.escalonadoShadow?.glassOverlay ?? 0.50
        readonly property color colShadow: ColorUtils.transparentize(root.m3colors.m3primary, Math.min(1, shadowOpacity / colorStrength))
        readonly property color colShadowBorder: ColorUtils.transparentize(root.m3colors.m3primary, Math.min(1, shadowBorderOpacity / colorStrength))
        readonly property color colShadowHover: ColorUtils.transparentize(root.m3colors.m3primary, Math.min(1, shadowHoverOpacity / colorStrength))
        readonly property real borderWidth: Config.options?.appearance?.angel?.border?.width ?? 1.5
        readonly property int accentBarHeight: Config.options?.appearance?.angel?.border?.accentBarHeight ?? 0
        readonly property int accentBarWidth: Config.options?.appearance?.angel?.border?.accentBarWidth ?? 0
        readonly property real borderCoverage: Config.options?.appearance?.angel?.border?.coverage ?? 0.0
        readonly property color colAccentBar: root.m3colors.m3primary
        readonly property real borderOpacity: Config.options?.appearance?.angel?.border?.opacity ?? 0.0
        readonly property real borderHoverOpacity: Config.options?.appearance?.angel?.border?.hoverOpacity ?? 0.0
        readonly property real borderActiveOpacity: Config.options?.appearance?.angel?.border?.activeOpacity ?? 0.0
        readonly property color colBorder: ColorUtils.transparentize(root.m3colors.m3primary, Math.min(1, (0.99 - borderOpacity) / colorStrength))
        readonly property color colBorderHover: ColorUtils.transparentize(root.m3colors.m3primary, Math.min(1, (0.99 - borderHoverOpacity) / colorStrength))
        readonly property color colBorderActive: ColorUtils.transparentize(root.m3colors.m3primary, Math.min(1, (0.99 - borderActiveOpacity) / colorStrength))
        readonly property color colBorderSubtle: ColorUtils.transparentize(root.m3colors.m3outlineVariant, 0.82)
        readonly property int panelBorderWidth: Config.options?.appearance?.angel?.surface?.panelBorderWidth ?? 0
        readonly property int cardBorderWidth: Config.options?.appearance?.angel?.surface?.cardBorderWidth ?? 1
        readonly property real panelBorderOpacity: Config.options?.appearance?.angel?.surface?.panelBorderOpacity ?? 0.0
        readonly property real cardBorderOpacity: Config.options?.appearance?.angel?.surface?.cardBorderOpacity ?? 0.30
        readonly property color colPanelBorder: ColorUtils.transparentize(root.m3colors.m3primary, Math.min(1, (0.99 - panelBorderOpacity) / colorStrength))
        readonly property color colCardBorder: ColorUtils.transparentize(root.m3colors.m3primary, Math.min(1, (0.99 - cardBorderOpacity) / colorStrength))
        readonly property real insetGlowOpacity: Config.options?.appearance?.angel?.border?.insetGlowOpacity ?? 0.0
        readonly property color colInsetGlow: ColorUtils.transparentize(root.m3colors.m3primary, Math.min(1, (1.0 - insetGlowOpacity) / colorStrength))
        readonly property int insetGlowHeight: Config.options?.appearance?.angel?.border?.insetGlowHeight ?? 0
        readonly property real glowOpacity: Config.options?.appearance?.angel?.glow?.opacity ?? 0.80
        readonly property real glowStrongOpacity: Config.options?.appearance?.angel?.glow?.strongOpacity ?? 0.65
        readonly property color colGlow: ColorUtils.transparentize(root.m3colors.m3primary, Math.min(1, glowOpacity / colorStrength))
        readonly property color colGlowStrong: ColorUtils.transparentize(root.m3colors.m3primary, Math.min(1, glowStrongOpacity / colorStrength))
        readonly property color colText: root._auroraLightMode ? root.colors._inkPrimary : root.m3colors.m3onSurface
        readonly property color colTextSecondary: root._auroraLightMode ? root.colors._inkSecondary : root.m3colors.m3onSurfaceVariant
        readonly property color colTextMuted: ColorUtils.transparentize(
            root._auroraLightMode ? root.colors._inkMuted : root.m3colors.m3onSurfaceVariant, 0.3)
        readonly property color colTextDim: ColorUtils.transparentize(
            root._auroraLightMode ? root.colors._inkMuted : root.m3colors.m3outline, 0.1)
        readonly property color colPrimary: root.m3colors.m3primary
        readonly property color colPrimaryHover: ColorUtils.mix(root.m3colors.m3primary, root.m3colors.m3onPrimary, 0.3)
        readonly property color colOnPrimary: root.m3colors.m3onPrimary
        readonly property color colSecondary: root.m3colors.m3secondary
        readonly property color colTertiary: root.m3colors.m3tertiary
        readonly property int roundingSmall: Config.options?.appearance?.angel?.rounding?.small ?? 10
        readonly property int roundingNormal: Config.options?.appearance?.angel?.rounding?.normal ?? 15
        readonly property int roundingLarge: Config.options?.appearance?.angel?.rounding?.large ?? 25
    }

    // 5d — Semantic color tokens (m3-derived; shared by waffle AND Pill)
    property QtObject colors: QtObject {
        readonly property color _inkPrimary: "#2b2622"
        readonly property color _inkSecondary: "#5c534a"
        readonly property color _inkMuted: "#8a7f73"
        readonly property bool _needsHighContrast: auroraEverywhere && !root._auroraLightMode
        readonly property color _baseOnSurface: m3colors.m3onSurface
        readonly property color _baseOnSurfaceVariant: m3colors.m3onSurfaceVariant
        property color colSubtext: ColorUtils.readableSubtext(
            _needsHighContrast ? _baseOnSurface : (root._auroraLightMode ? _inkSecondary : m3colors.m3outline),
            colLayer1Base, 0.75)
        property color colLayer0Base: m3colors.transparent ? "transparent" : ColorUtils.mix(m3colors.m3background, m3colors.m3primary, Config?.options?.appearance?.extraBackgroundTint ? 0.99 : 1)
        property color colLayer0: ColorUtils.transparentize(colLayer0Base, root.backgroundTransparency)
        property color colOnLayer0: ColorUtils.ensureReadable(
            root._auroraLightMode ? _inkPrimary : _baseOnSurface, colLayer0Base, 4.5)
        property color colLayer0Hover: ColorUtils.transparentize(ColorUtils.mix(colLayer0, colOnLayer0, 0.9, root.contentTransparency))
        property color colLayer0Active: ColorUtils.transparentize(ColorUtils.mix(colLayer0, colOnLayer0, 0.8, root.contentTransparency))
        property color colLayer0Border: ColorUtils.mix(root.m3colors.m3outlineVariant, colLayer0, 0.4)
        property color colLayer1Base: m3colors.m3surfaceContainerLow
        property color colLayer1: auroraEverywhere ? ColorUtils.transparentize(m3colors.m3surfaceContainerLow, root.aurora.layerTransparentize) : ColorUtils.solveOverlayColor(colLayer0Base, colLayer1Base, 1 - root.contentTransparency)
        property color colOnLayer1: ColorUtils.ensureReadable(
            _needsHighContrast ? _baseOnSurface : (root._auroraLightMode ? _inkPrimary : _baseOnSurfaceVariant), colLayer1Base, 4.5)
        property color colOnLayer1Inactive: ColorUtils.readableSubtext(colOnLayer1, colLayer1Base, 0.55)
        property color colLayer1Hover: ColorUtils.transparentize(ColorUtils.mix(colLayer1, colOnLayer1, 0.92), root.contentTransparency)
        property color colLayer1Active: ColorUtils.transparentize(ColorUtils.mix(colLayer1, colOnLayer1, 0.85), root.contentTransparency)
        property color colLayer2Base: m3colors.m3surfaceContainer
        property color colLayer2: auroraEverywhere ? ColorUtils.transparentize(m3colors.m3surfaceContainer, root.aurora.layerTransparentize) : ColorUtils.solveOverlayColor(colLayer1Base, colLayer2Base, 1 - root.contentTransparency)
        property color colLayer2Hover: ColorUtils.solveOverlayColor(colLayer1Base, ColorUtils.mix(colLayer2Base, colOnLayer2, 0.90), 1 - root.contentTransparency)
        property color colLayer2Active: ColorUtils.solveOverlayColor(colLayer1Base, ColorUtils.mix(colLayer2Base, colOnLayer2, 0.80), 1 - root.contentTransparency)
        property color colLayer2Disabled: ColorUtils.solveOverlayColor(colLayer1Base, ColorUtils.mix(colLayer2Base, m3colors.m3background, 0.8), 1 - root.contentTransparency)
        property color colOnLayer2: ColorUtils.ensureReadable(
            _needsHighContrast ? _baseOnSurface : (root._auroraLightMode ? _inkPrimary : _baseOnSurface), colLayer2Base, 4.5)
        property color colOnLayer2Disabled: ColorUtils.readableSubtext(colOnLayer2, colLayer2Base, 0.4)
        property color colLayer3Base: m3colors.m3surfaceContainerHigh
        property color colLayer3: auroraEverywhere ? ColorUtils.transparentize(m3colors.m3surfaceContainerHigh, root.aurora.layerTransparentize) : ColorUtils.solveOverlayColor(colLayer2Base, colLayer3Base, 1 - root.contentTransparency)
        property color colLayer3Hover: ColorUtils.solveOverlayColor(colLayer2Base, ColorUtils.mix(colLayer3Base, colOnLayer3, 0.90), 1 - root.contentTransparency)
        property color colLayer3Active: ColorUtils.solveOverlayColor(colLayer2Base, ColorUtils.mix(colLayer3Base, colOnLayer3, 0.80), 1 - root.contentTransparency)
        property color colOnLayer3: ColorUtils.ensureReadable(
            _needsHighContrast ? _baseOnSurface : (root._auroraLightMode ? _inkPrimary : _baseOnSurface), colLayer3Base, 4.5)
        property color colLayer4Base: m3colors.m3surfaceContainerHighest
        property color colLayer4: ColorUtils.solveOverlayColor(colLayer3Base, colLayer4Base, 1 - root.contentTransparency)
        property color colLayer4Hover: ColorUtils.solveOverlayColor(colLayer3Base, ColorUtils.mix(colLayer4Base, colOnLayer4, 0.90), 1 - root.contentTransparency)
        property color colLayer4Active: ColorUtils.solveOverlayColor(colLayer3Base, ColorUtils.mix(colLayer4Base, colOnLayer4, 0.80), 1 - root.contentTransparency)
        property color colOnLayer4: ColorUtils.ensureReadable(
            root._auroraLightMode ? _inkPrimary : _baseOnSurface, colLayer4Base, 4.5)
        property color colPrimary: m3colors.m3primary
        property color colOnPrimary: m3colors.m3onPrimary
        property color colPrimaryHover: ColorUtils.mix(colors.colPrimary, colLayer1Hover, 0.87)
        property color colPrimaryActive: ColorUtils.mix(colors.colPrimary, colLayer1Active, 0.7)
        property color colPrimaryContainer: m3colors.m3primaryContainer
        property color colPrimaryContainerHover: ColorUtils.mix(colors.colPrimaryContainer, colors.colOnPrimaryContainer, 0.9)
        property color colPrimaryContainerActive: ColorUtils.mix(colors.colPrimaryContainer, colors.colOnPrimaryContainer, 0.8)
        property color colOnPrimaryContainer: m3colors.m3onPrimaryContainer
        property color colSecondary: m3colors.m3secondary
        property color colSecondaryHover: ColorUtils.mix(m3colors.m3secondary, colLayer1Hover, 0.85)
        property color colSecondaryActive: ColorUtils.mix(m3colors.m3secondary, colLayer1Active, 0.4)
        property color colOnSecondary: m3colors.m3onSecondary
        property color colSecondaryContainer: m3colors.m3secondaryContainer
        property color colSecondaryContainerHover: ColorUtils.mix(m3colors.m3secondaryContainer, m3colors.m3onSecondaryContainer, 0.90)
        property color colSecondaryContainerActive: ColorUtils.mix(m3colors.m3secondaryContainer, m3colors.m3onSecondaryContainer, 0.54)
        property color colOnSecondaryContainer: m3colors.m3onSecondaryContainer
        property color colTertiary: m3colors.m3tertiary
        property color colTertiaryHover: ColorUtils.mix(m3colors.m3tertiary, colLayer1Hover, 0.85)
        property color colTertiaryActive: ColorUtils.mix(m3colors.m3tertiary, colLayer1Active, 0.4)
        property color colTertiaryContainer: m3colors.m3tertiaryContainer
        property color colTertiaryContainerHover: ColorUtils.mix(m3colors.m3tertiaryContainer, m3colors.m3onTertiaryContainer, 0.90)
        property color colTertiaryContainerActive: ColorUtils.mix(m3colors.m3tertiaryContainer, colLayer1Active, 0.54)
        property color colOnTertiary: m3colors.m3onTertiary
        property color colOnTertiaryContainer: m3colors.m3onTertiaryContainer
        property color colBackgroundSurfaceContainer: ColorUtils.transparentize(m3colors.m3surfaceContainer, root.backgroundTransparency)
        property color colSurfaceContainerLow: ColorUtils.solveOverlayColor(m3colors.m3background, m3colors.m3surfaceContainerLow, 1 - root.contentTransparency)
        property color colSurfaceContainer: ColorUtils.solveOverlayColor(m3colors.m3surfaceContainerLow, m3colors.m3surfaceContainer, 1 - root.contentTransparency)
        property color colSurfaceContainerHigh: ColorUtils.solveOverlayColor(m3colors.m3surfaceContainer, m3colors.m3surfaceContainerHigh, 1 - root.contentTransparency)
        property color colSurfaceContainerHighest: ColorUtils.solveOverlayColor(m3colors.m3surfaceContainerHigh, m3colors.m3surfaceContainerHighest, 1 - root.contentTransparency)
        property color colSurfaceContainerHighestHover: ColorUtils.mix(m3colors.m3surfaceContainerHighest, m3colors.m3onSurface, 0.95)
        property color colSurfaceContainerHighestActive: ColorUtils.mix(m3colors.m3surfaceContainerHighest, m3colors.m3onSurface, 0.85)
        property color colOnSurface: m3colors.m3onSurface
        property color colOnSurfaceVariant: m3colors.m3onSurfaceVariant
        property color colTooltip: m3colors.m3inverseSurface
        property color colOnTooltip: m3colors.m3inverseOnSurface
        property color colScrim: ColorUtils.transparentize(m3colors.m3scrim, 0.5)
        property color colShadow: m3colors.transparent ? "transparent" : ColorUtils.transparentize(m3colors.m3shadow, 0.7)
        property color colOutline: _needsHighContrast ? ColorUtils.transparentize(m3colors.m3onSurface, 0.8) : m3colors.m3outline
        property color colOutlineVariant: _needsHighContrast ? ColorUtils.transparentize(m3colors.m3onSurface, 0.9) : m3colors.m3outlineVariant
        property color colError: m3colors.m3error
        property color colErrorHover: ColorUtils.mix(m3colors.m3error, colLayer1Hover, 0.85)
        property color colErrorActive: ColorUtils.mix(m3colors.m3error, colLayer1Active, 0.7)
        property color colOnError: m3colors.m3onError
        property color colErrorContainer: m3colors.m3errorContainer
        property color colErrorContainerHover: ColorUtils.mix(m3colors.m3errorContainer, m3colors.m3onErrorContainer, 0.90)
        property color colErrorContainerActive: ColorUtils.mix(m3colors.m3errorContainer, m3colors.m3onErrorContainer, 0.70)
        property color colOnErrorContainer: m3colors.m3onErrorContainer
        property color colBorderSubtle: ColorUtils.transparentize(m3colors.m3outlineVariant, 0.6)
    }

    // === Theme Adapter (Section 8) ===

    /// Resolve the active mood singleton (LightMood or DarkMood).
    readonly property var activeMood: QsSingletons.Flags.systemMood === "light" ? LightMood : DarkMood

    /// Whether the palette source is dynamic (wallpaper-derived) vs static.
    readonly property bool isDynamic: QsSingletons.Flags.paletteMode !== "static"

    /// Static mode + grayscale accent toggle (forces neutral gray accents).
    readonly property bool isGrayscaleStatic: !isDynamic && QsSingletons.Flags.staticGrayscaleAccents

    /// Raw Material 3 palette — always from Dyn (accent source even in static mode).
    readonly property var m3: QsSingletons.Dyn.active

    // --- Resolved Yemi compatibility tokens ---------------------------
    // Dynamic: wallpaper-derived via Dyn. Static: solid mood surfaces.
    // Text colors are run through ColorUtils.ensureReadable() for contrast.
    readonly property color yemiTileBg: QsSingletons.Dyn.schemeValid ? (isDynamic ? QsSingletons.Dyn.surface : activeMood.tileBg) : activeMood.tileBg
    readonly property color yemiCardTop: QsSingletons.Dyn.schemeValid ? (isDynamic ? QsSingletons.Dyn.surfaceContainerHigh : activeMood.cardTop) : activeMood.cardTop
    readonly property color yemiCardBot: QsSingletons.Dyn.schemeValid ? (isDynamic ? QsSingletons.Dyn.surfaceContainerLow : activeMood.cardBot) : activeMood.cardBot
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