import Quickshell
import QtQuick 6.10

QtObject {
    id: testLoader

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

    function runTests() {
        current = 0
        passed = 0
        failed = 0
        loadNext()
    }

    function loadNext() {
        if (current >= pages.length) {
            console.log("=== RESULTS ===")
            console.log("Passed: " + passed + "/" + pages.length)
            console.log("Failed: " + failed + "/" + pages.length)
            return
        }

        var page = pages[current]
        console.log("Loading: " + page)

        try {
            var component = Qt.createComponent("settings/" + page)
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
