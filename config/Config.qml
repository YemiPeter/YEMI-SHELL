pragma Singleton

import Quickshell

Singleton {
    readonly property BarConfig bar: BarConfig {}
    readonly property AppearanceConfig appearance: AppearanceConfig {}
    
    // Notification configuration
    readonly property var notifications: ({
        popupWidth: 340,
        maxVisible: 5,
        timeout: 7000,
        spacing: 8,
        margin: 8
    })
    
    // Popup configuration
    readonly property var popups: ({
        width: 280,
        minHeight: 100,
        maxHeight: 400,
        hoverDelay: 300,
        margin: 6
    })

    // Dashboard visibility toggles (for Overview Dashboard compatibility)
    readonly property var dashboard: ({
        enable: false,
        showToggles: true,
        showMedia: true,
        showVolume: true,
        showWeather: false,    // requires Weather.qml service
        showSystem: true
    })
}
