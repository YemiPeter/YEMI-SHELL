pragma Singleton
import QtQuick
import qs.modules.common

QtObject {
    property string openMon: ""
    property string openSurface: ""
    property string peekMon: ""
    property string pendingLinkView: "main"

    signal surfaceOpened(string mon, string surface)
    signal surfaceClosed()
    signal peekChanged(string mon)

    function toggleSurface(mon, surface) {
        // Pill surfaces are only valid in the pill family. When the shell is in
        // the waffle family the bar/waffle stack is active and pill keybinds
        // must be inert (they would otherwise pop a pill over waffle).
        if (Config.options?.panelFamily === "waffle") return;
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
        openMon = "";
        openSurface = "";
        surfaceClosed();
    }

    function peek(mon) {
        if (Config.options?.panelFamily === "waffle") return;
        peekMon = peekMon === mon ? "" : mon;
        peekChanged(mon);
    }
}
