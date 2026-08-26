pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Reactive current-wallpaper reader. Watches the same state file set-bg.sh
 * writes (~/.local/state/quickshell-wallpaper) and exposes the path as
 * `current`. Deliberately out of band of theme: it only reads, never triggers
 * pywal, after-wall.sh or any color reload. No settings, no flags.
 */
Singleton {
    id: root

    property string current: ""

    readonly property string stateFile: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell-wallpaper"

    FileView {
        id: file
        path: root.stateFile
        blockLoading: true
        watchChanges: true
        printErrors: false

        onLoaded: root.current = this.text().trim()
        onFileChanged: reload()
        onLoadFailed: function(error) {
            if (error === FileViewError.FileNotFound)
                root.current = ""
        }
    }
}
