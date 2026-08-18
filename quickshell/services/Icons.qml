pragma Singleton
import QtQuick

QtObject {
    id: root
    // Stubbed for waffle bar
    function get(name: string): string {
        return ""
    }
    readonly property string defaultIcon: ""
    function getWeatherIcon(wCode: string, isNight: bool): string { return "cloud" }
}