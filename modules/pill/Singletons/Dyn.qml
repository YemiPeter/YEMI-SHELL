pragma Singleton
import QtQuick
import "../../../singletons" as QsSingletons

/**
 * Shim: re-exports the project-wide Dyn singleton so pill files
 * using `import "Singletons"` find `Dyn.primary` etc. without changes.
 * Do NOT add new properties here — add them in singletons/Dyn.qml.
 */
QtObject {
    id: root

    readonly property string surface: QsSingletons.Dyn.surface
    readonly property string surfaceContainer: QsSingletons.Dyn.surfaceContainer
    readonly property string surfaceContainerLow: QsSingletons.Dyn.surfaceContainerLow
    readonly property string surfaceContainerHigh: QsSingletons.Dyn.surfaceContainerHigh
    readonly property string surfaceContainerHighest: QsSingletons.Dyn.surfaceContainerHighest
    readonly property string primary: QsSingletons.Dyn.primary
    readonly property string primaryContainer: QsSingletons.Dyn.primaryContainer
    readonly property string onPrimaryContainer: QsSingletons.Dyn.onPrimaryContainer
    readonly property string outline: QsSingletons.Dyn.outline
    readonly property string outlineVariant: QsSingletons.Dyn.outlineVariant
    readonly property string cream: QsSingletons.Dyn.cream
    readonly property string bright: QsSingletons.Dyn.bright
    readonly property string subtle: QsSingletons.Dyn.subtle
    readonly property string dim: QsSingletons.Dyn.dim
    readonly property string faint: QsSingletons.Dyn.faint
    readonly property string iconDim: QsSingletons.Dyn.iconDim
    readonly property string tickRest: QsSingletons.Dyn.tickRest
}
