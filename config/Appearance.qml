pragma Singleton

import Quickshell
import QtQuick 6.10
import "../services" as QsServices

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

    // 5d — Semantic color tokens from Pywal
    readonly property var colors: ({
        colPrimary: QsServices.Pywal.primary,
        colOnPrimary: QsServices.Pywal.onPrimary ?? Qt.rgba(0, 0, 0, 0.9),
        colSecondary: QsServices.Pywal.secondary,
        colSecondaryContainer: QsServices.Pywal.secondaryContainer ?? Qt.darker(QsServices.Pywal.secondary, 1.3),
        colTertiary: QsServices.Pywal.tertiary ?? QsServices.Pywal.primary,
        colError: QsServices.Pywal.error ?? "#f38ba8",
        colSuccess: QsServices.Pywal.success ?? "#a6e3a1",
        colBackgroundSurfaceContainer: Qt.rgba(
            QsServices.Pywal.background.r,
            QsServices.Pywal.background.g,
            QsServices.Pywal.background.b, 0.55
        ),
        colLayer0: QsServices.Pywal.background,
        colLayer1: Qt.lighter(QsServices.Pywal.background, 1.15),
        colLayer2: Qt.lighter(QsServices.Pywal.background, 1.25),
        colLayer0Base: QsServices.Pywal.background,
        colLayer1Base: Qt.lighter(QsServices.Pywal.background, 1.15),
        colSubtext: Qt.rgba(
            QsServices.Pywal.foreground.r,
            QsServices.Pywal.foreground.g,
            QsServices.Pywal.foreground.b, 0.7
        ),
        colOnLayer1: QsServices.Pywal.foreground,
        colOutlineVariant: Qt.rgba(
            QsServices.Pywal.foreground.r,
            QsServices.Pywal.foreground.g,
            QsServices.Pywal.foreground.b, 0.08
        ),
        colLayer0Border: Qt.rgba(
            QsServices.Pywal.foreground.r,
            QsServices.Pywal.foreground.g,
            QsServices.Pywal.foreground.b, 0.08
        ),
        colLayer1Border: Qt.rgba(
            QsServices.Pywal.foreground.r,
            QsServices.Pywal.foreground.g,
            QsServices.Pywal.foreground.b, 0.12
        ),
        colScrim: Qt.rgba(0, 0, 0, 0.32),
        colLayer2Hover: Qt.rgba(
            QsServices.Pywal.foreground.r,
            QsServices.Pywal.foreground.g,
            QsServices.Pywal.foreground.b, 0.08
        ),
        colLayer1Hover: Qt.rgba(
            QsServices.Pywal.foreground.r,
            QsServices.Pywal.foreground.g,
            QsServices.Pywal.foreground.b, 0.12
        ),
        colPrimaryHover: Qt.lighter(QsServices.Pywal.primary, 1.15)
    })
}
