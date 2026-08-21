import QtQuick
import Quickshell
import qs.modules.common
import "modules/waffle/background" as WaffleBackgroundModule
import "modules/waffle/backdrop" as WaffleBackdropModule
import "modules/waffle/bar" as WaffleBarModule
import "modules/waffle/startMenu" as WaffleStartMenuModule
import "modules/waffle/widgets" as WaffleWidgetsModule
import "modules/waffle/taskview" as WaffleTaskViewModule
import "modules/waffle/altSwitcher" as WaffleAltSwitcherModule

// Waffle family stack — parsed ONLY when panelFamily === "waffle" because
// shell.qml loads this file via `LazyLoader { source: "ShellWafflePanels.qml" }`
// instead of an inline `Component`, so an inactive family is never compiled.
Item {
    // Waffle Background Panel (glass wallpaper layer)
    Loader {
        id: waffleBackgroundLoader
        sourceComponent: wBgPanel
        active: Config.ready && Config.options.panelFamily === "waffle" && (Config.options.enabledPanels ?? []).includes("wBackground")
    }

    // Waffle Backdrop Panel (fullscreen solid-color backdrop behind fullscreen windows)
    Loader {
        id: waffleBackdropLoader
        sourceComponent: wBackdropPanel
        active: Config.ready && Config.options.panelFamily === "waffle" && (Config.options.enabledPanels ?? []).includes("wBackdrop")
    }

    Component {
        id: wBgPanel
        WaffleBackgroundModule.WaffleBackground {}
    }

    Component {
        id: wBackdropPanel
        WaffleBackdropModule.WaffleBackdrop {}
    }

    // Waffle Bar (wBar) — only when panelFamily is "waffle" and wBar is enabled
    Loader {
        id: waffleBarLoader
        sourceComponent: wBarPanel
        active: Config.ready && Config.options.panelFamily === "waffle" && (Config.options.enabledPanels ?? []).includes("wBar")
    }

    Component {
        id: wBarPanel
        WaffleBarModule.WaffleBar {}
    }

    // Waffle Start Menu / Launcher (self-manages its PanelWindow on
    // GlobalStates.searchOpen; opened by the bar Start/Search buttons).
    WaffleStartMenuModule.WaffleStartMenu {}

    // Waffle Widgets surface (LEFT WeatherButton / RIGHT TimerButton →
    // GlobalStates.waffleWidgetsOpen; self-managed PanelWindow + click-outside).
    WaffleWidgetsModule.WaffleWidgets {}

    // Waffle Task View (CENTER TaskViewButton → GlobalStates.waffleTaskViewOpen;
    // self-managed PanelWindow with live window previews via WindowPreviewService).
    WaffleTaskViewModule.WaffleTaskView {}

    // Waffle Alt+Tab Switcher (self-managed overlay PanelWindows; opened via the
    // "waffleAltSwitcher" IPC target — wire Alt+Tab in the compositor keybinds).
    WaffleAltSwitcherModule.WaffleAltSwitcher {}
}