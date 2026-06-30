pragma Singleton
import QtQuick

QtObject {
    property string openMon: ""
    property string openSurface: ""

    function toggleSurface(mon, surface) {
        console.log("[PillState] toggleSurface:", mon, surface, "| was:", openMon, openSurface)
        if (openMon === mon && openSurface === surface) {
            close();
            return;
        }
        openMon = mon;
        openSurface = surface;
    }

    function close() {
        console.log("[PillState] close")
        openMon = "";
        openSurface = "";
    }
}
