pragma Singleton
import QtQuick

QtObject {
    id: root
    // Stubbed for waffle bar
    readonly property string temperature: "25°C"
    readonly property string condition: "Sunny"
    readonly property string icon: "weather-clear"
    readonly property bool isLoading: false
    readonly property string visibleCity: ""
    readonly property string weatherDescription: ""
    readonly property var data: ({})
    readonly property bool isNightNow: () => false
    
    function getData() {}
    function describeWeather(wCode: string): string { return "Sunny" }
    function showVisibleCity(): bool { return false }
}