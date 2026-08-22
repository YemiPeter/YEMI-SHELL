pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.services

/**
 * Close-confirmation gate.
 *
 * Wraps NiriService.closeWindow() so that when
 * Config.options.closeConfirm.enabled is true, the user gets a
 * "Close window?" prompt before the window is actually closed.
 *
 * Callers (bar buttons, taskview, thumbnails) should call
 * CloseConfirm.requestClose(windowId) instead of NiriService.closeWindow()
 * directly.
 */
Singleton {
    id: root

    readonly property bool enabled: Config.options?.closeConfirm?.enabled ?? false

    property int _pendingWindowId: -1

    function requestClose(windowId): void {
        if (!root.enabled) {
            NiriService.closeWindow(windowId)
            return
        }

        root._pendingWindowId = windowId
        confirmProc.running = true
    }

    Process {
        id: confirmProc
        command: [
            "/usr/bin/zenity",
            "--question",
            "--text", "Close this window?",
            "--ok-label", "Close",
            "--cancel-label", "Cancel",
            "--width", "300"
        ]
        onExited: (code, status) => {
            if (code === 0 && root._pendingWindowId !== -1) {
                NiriService.closeWindow(root._pendingWindowId)
            }
            root._pendingWindowId = -1
        }
    }
}
