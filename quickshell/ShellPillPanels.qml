import QtQuick
import Quickshell
import qs.modules.common
import "modules/pill" as Pill

// Pill family stack — parsed ONLY when panelFamily !== "waffle" because
// shell.qml loads this file via `LazyLoader { source: "ShellPillPanels.qml" }`
// instead of an inline `Component`, so an inactive family is never compiled.
Item {
    id: root

    // Reference to the bar window (set when BarWrapper loads, passed to pill overlays)
    property var barWindow: null

    // Bar (only when the Pill family is active)
    Loader {
        id: barLoader
        source: "modules/bar/BarWrapper.qml"
        active: Config.ready && Config.options.panelFamily !== "waffle"
        onLoaded: root.barWindow = item
    }

    // Pill overlay windows (one per screen) — only loaded when the Pill family is active
    Loader {
        active: Config.ready && Config.options.panelFamily !== "waffle"
        sourceComponent: pillOverlayComponent
    }

    Component {
        id: pillOverlayComponent
        Variants {
            model: Quickshell.screens
            Pill.PillOverlay {
                modelData: modelData
                barWindow: root.barWindow
            }
        }
    }
}