pragma Singleton

import Quickshell
import QtQuick 6.10
import "../services" as QsServices
import "../singletons" as QsSingletons

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
        huge: font.typography?.displayLarge?.size ?? 57,
        normal: font.typography?.bodyLarge?.size ?? 16,
        smaller: font.typography?.bodyMedium?.size ?? 14,
        small: font.typography?.bodySmall?.size ?? 12,
        smallest: font.typography?.labelSmall?.size ?? 11
    })

    // 5b — Font family for numbers
    readonly property var fontFamily: ({
        numbers: font.family ?? "JetBrains Mono"
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
}
