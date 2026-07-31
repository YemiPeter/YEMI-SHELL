import QtQuick
import Quickshell
import "services" as QsServices
import "singletons" as QsSingletons
import "modules/pill" as Pill
import qs.services
import qs.config
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ShellRoot {
    id: root

    property string settingsPath: "settings/"
    property var pages: [
        "QuickConfig.qml",
        "GeneralConfig.qml",
        "BarConfig.qml",
        "BackgroundConfig.qml",
        "ThemesConfig.qml",
        "InterfaceConfig.qml",
        "ServicesConfig.qml",
        "ToolsConfig.qml",
        "ModulesConfig.qml",
        "AdvancedConfig.qml",
        "WaffleConfig.qml",
        "NiriConfig.qml",
        "DesktopWidgetsConfig.qml",
        "About.qml",
        "CheatsheetConfig.qml",
        "MonitorVisibilityConfig.qml",
        "ThemePresetCard.qml",
        "QuickWallpaperItem.qml",
        "ColorPickerRow.qml",
        "CustomThemeEditor.qml",
        "GowallWallpaperEditor.qml",
        "AngelStyleEditor.qml",
        "AuroraStyleEditor.qml",
        "BooruResponseData.qml"
    ]

    property int current: 0
    property int passed: 0
    property int failed: 0

    Component.onCompleted: {
        loadNext()
    }

    function loadNext() {
        if (current >= pages.length) {
            console.log("=== RESULTS ===")
            console.log("Passed: " + passed + "/" + pages.length)
            console.log("Failed: " + failed + "/" + pages.length)
            Qt.quit()
            return
        }

        var page = pages[current]
        console.log("Loading: " + page)

        try {
            var component = Qt.createComponent(settingsPath + page)
            if (component.status === Component.Ready) {
                console.log("PASS: " + page)
                passed++
            } else if (component.status === Component.Error) {
                console.log("FAIL: " + page + " - " + component.errorString())
                failed++
            } else {
                console.log("LOADING: " + page + " (status: " + component.status + ")")
                var timeout = 5000
                while (component.status !== Component.Ready && component.status !== Component.Error && timeout > 0) {
                    Qt.processEvents()
                    timeout -= 100
                }
                if (component.status === Component.Ready) {
                    console.log("PASS: " + page)
                    passed++
                } else {
                    console.log("FAIL: " + page + " - " + component.errorString())
                    failed++
                }
            }
        } catch (e) {
            console.log("FAIL: " + page + " - Exception: " + e)
            failed++
        }

        current++
        loadNext()
    }
}
