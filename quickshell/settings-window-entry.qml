//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env INIR_STANDALONE_WINDOW=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Root-level entry point for the standalone settings window (scripts/settings-window.sh).
//
// quickshell -p resolves qs.* module imports relative to the directory
// containing the file passed to -p. Pointing -p directly at
// settings/settings.qml made quickshell treat settings/ as the config root,
// which broke `import qs.modules.common` and `import qs.services`.
//
// This file lives at the real config root so those qs.* modules resolve
// correctly. It then instantiates the actual settings UI from
// settings/settings.qml, which stays exactly where it is — so all of
// settings.qml's own relative paths (page components, Directories, etc.)
// keep resolving as they do in the in-shell overlay.
//
// settings/settings.qml is an ApplicationWindow, which is NOT an Item, so it
// cannot be loaded through a Loader. We create it detached as a top-level
// window via Qt.createComponent()/createObject(null) instead — the documented
// pattern for dynamically instantiating a stand-alone window.
//
// This fixes only the standalone launcher; SettingsOverlay.qml and the
// in-shell path are untouched.

import QtQuick

Item {
    id: root

    property var settingsWindow: null

    Component.onCompleted: {
        const component = Qt.createComponent("settings/settings.qml");
        if (component.status !== Component.Ready) {
            console.error("❌ Failed to load settings/settings.qml:",
                component.errorString());
            Qt.quit();
            return;
        }

        root.settingsWindow = component.createObject(null);
        if (!root.settingsWindow) {
            console.error("❌ Failed to instantiate settings window");
            Qt.quit();
        }
    }
}