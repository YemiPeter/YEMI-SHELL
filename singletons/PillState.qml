pragma Singleton
import QtQuick

QtObject {
    property string openMon: ""
    property string openSurface: ""
    property string peekMon: ""
    property string pendingLinkView: "main"

    signal surfaceOpened(string mon, string surface)
    signal surfaceClosed()
    signal peekChanged(string mon)

    function toggleSurface(mon, surface) {
        console.log("[PillState] toggleSurface:", mon, surface, "| was:", openMon, openSurface)
        if (openMon === mon && openSurface === surface) {
            close();
            return;
        }
        openMon = mon;
        openSurface = surface;
        surfaceOpened(mon, surface);
    }
    
    function toggleLink(mon, view) {
      pendingLinkView = view;
      toggleSurface(mon, "link");
    }

    function close() {
        console.log("[PillState] close")
        openMon = "";
        openSurface = "";
        surfaceClosed();
    }

    function peek(mon) {
        console.log("[PillState] peek:", mon, "| was:", peekMon)
        peekMon = peekMon === mon ? "" : mon;
        peekChanged(mon);
    }
}
