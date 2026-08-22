pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.services

/**
 * Keyboard indicator state for the Waffle bar / panels.
 *
 * Layout: sourced from NiriService (Niri).
 * Lock keys (CapsLock / NumLock): polled from /sys/class/leds/ brightness files.
 *
 * Config-driven via General → Keyboard Indicators:
 *   keyboardIndicators.showPopup   — global toggle for all popups
 *   keyboardIndicators.popup.{layout,caps,num}
 *   keyboardIndicators.showPanel   — global toggle for bar/taskbar indicators
 *   keyboardIndicators.panel.{layout,caps,num}
 */
Singleton {
    id: root

    // --- Config reads (General → Keyboard Indicators) ---
    readonly property bool showPopup: Config.options?.keyboardIndicators?.showPopup ?? true
    readonly property bool showPanel: Config.options?.keyboardIndicators?.showPanel ?? true
    readonly property bool popupLayout: Config.options?.keyboardIndicators?.popup?.layout ?? true
    readonly property bool popupCaps: Config.options?.keyboardIndicators?.popup?.caps ?? true
    readonly property bool popupNum: Config.options?.keyboardIndicators?.popup?.num ?? false
    readonly property bool panelLayout: Config.options?.keyboardIndicators?.panel?.layout ?? true
    readonly property bool panelCaps: Config.options?.keyboardIndicators?.panel?.caps ?? true
    readonly property bool panelNum: Config.options?.keyboardIndicators?.panel?.num ?? false

    // --- Layout tracking ---
    property string currentLayoutName: ""
    readonly property string currentLayoutCodeInline: {
        const name = root.currentLayoutName;
        if (!name) return "??";
        return name.length >= 2 ? name.slice(0, 2).toUpperCase() : name.toUpperCase();
    }
    readonly property string currentLayoutLabel: root.currentLayoutName || Translation.tr("Unknown")

    // --- Lock-key state (CapsLock / NumLock) ---
    property bool capsLock: false
    property bool numLock: false

    // --- Effective visibility (config gate + value presence) ---
    readonly property bool capsLockVisible: root.showPanel && root.panelCaps
    readonly property bool layoutVisible: root.showPanel && root.panelLayout && root.currentLayoutName !== ""
    readonly property bool numLockVisible: root.showPanel && root.panelNum

    // Icon tokens for bar rendering
    readonly property string capsFluentIcon: "keyboard-caps-lock"
    readonly property string numFluentIcon: "keyboard-num"

    // ---- Layout source: Niri via NiriService ----
    Connections {
        target: NiriService
        enabled: CompositorService.isNiri

        function onKeyboardLayoutNamesChanged() { root._syncLayout() }
        function onCurrentKeyboardLayoutIndexChanged() { root._syncLayout() }
    }

    function _syncLayout(): void {
        if (CompositorService.isNiri && typeof NiriService !== "undefined") {
            const name = NiriService.getCurrentKeyboardLayoutName()
            currentLayoutName = name || ""
        }
    }

    // ---- Lock-key polling via sysfs ----
    Timer {
        id: lockPollTimer
        interval: 1000
        repeat: true
        running: CompositorService.isNiri || CompositorService.isHyprland
        onTriggered: root._pollLockKeys()
    }

    function _pollLockKeys(): void {
        capsReadProc.running = true
        numReadProc.running = true
    }

    Process {
        id: capsReadProc
        command: ["/usr/bin/cat", "/sys/class/leds/input2::capslock/brightness"]
        stdout: StdioCollector {
            id: capsCollector
            onStreamFinished: { root.capsLock = capsCollector.text.trim() === "1" }
        }
        onErrorOccurred: capsReadProc2.running = true
    }
    Process {
        id: capsReadProc2
        command: ["/usr/bin/cat", "/sys/class/leds/input3::capslock/brightness"]
        stdout: StdioCollector {
            id: capsCollector2
            onStreamFinished: { root.capsLock = capsCollector2.text.trim() === "1" }
        }
        onErrorOccurred: { root.capsLock = false }
    }
    Process {
        id: numReadProc
        command: ["/usr/bin/cat", "/sys/class/leds/input2::numlock/brightness"]
        stdout: StdioCollector {
            id: numCollector
            onStreamFinished: { root.numLock = numCollector.text.trim() === "1" }
        }
        onErrorOccurred: numReadProc2.running = true
    }
    Process {
        id: numReadProc2
        command: ["/usr/bin/cat", "/sys/class/leds/input3::numlock/brightness"]
        stdout: StdioCollector {
            id: numCollector2
            onStreamFinished: { root.numLock = numCollector2.text.trim() === "1" }
        }
        onErrorOccurred: { root.numLock = false }
    }

    Component.onCompleted: {
        root._syncLayout();
        root._pollLockKeys();
    }
}
