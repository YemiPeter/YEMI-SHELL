pragma Singleton
import Quickshell

Singleton {
    // Single source of truth for pill rest-height. This used to be hardcoded
    // separately in PillOverlay.qml (28) AND Pill.qml (38) — they drifted
    // apart and caused a vertical centering bug (pill sat 5px too low).
    // NEVER redeclare restH locally again. Read from here everywhere.
    readonly property real restHBase: 38
}
