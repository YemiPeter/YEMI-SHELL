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
import "modules/waffle/actionCenter" as WaffleActionCenterModule
import "modules/waffle/notificationCenter" as WaffleNotificationCenterModule
import "modules/waffle/clipboard" as WaffleClipboardModule
import "modules/lock" as LockModule

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

    // Waffle Alt+Tab Switcher - handles the "waffleAltSwitcher" IPC target only
    // when panelFamily === "waffle".
    Loader {
        active: Config.ready && Config.options.panelFamily === "waffle"
        sourceComponent: WaffleAltSwitcherModule.WaffleAltSwitcher {}
    }

    // Waffle Action Center (SystemButton → GlobalStates.waffleActionCenterOpen;
    // self-managed PanelWindow + click-outside).
    WaffleActionCenterModule.WaffleActionCenter {}

    // Waffle Notification Center (TimeButton →
    // GlobalStates.waffleNotificationCenterOpen; self-managed PanelWindow).
    WaffleNotificationCenterModule.WaffleNotificationCenter {}

    // Waffle Clipboard - handles the "clipboard" IPC target only when
    // panelFamily === "waffle" (so it does not clash with the pill clipboard).
    Loader {
        active: Config.ready && Config.options.panelFamily === "waffle"
        sourceComponent: WaffleClipboardModule.WaffleClipboard {}
    }

    // Waffle Lock - WlSessionLock host that picks the waffle (or, on Hyprland,
    // Material) lock surface. Registers the global "lock" IPC target and is the
    // shell-side real lock screen for both families.
    LockModule.Lock {}
}
