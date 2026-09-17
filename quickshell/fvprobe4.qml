import QtQuick
import Quickshell
import Quickshell.Io

// Which combination actually tracks external writes?
Item {
    id: root

    FileView { id: fA; path: "/home/yemi/.config/hypr/modules/decoration.lua"; blockLoading: true; watchChanges: true;  printErrors: false }
    FileView { id: fB; path: "/home/yemi/.config/hypr/modules/decoration.lua"; blockLoading: true; watchChanges: false; printErrors: false }
    FileView { id: fC; path: "/tmp/fv_target.lua"; blockLoading: true; watchChanges: true;  printErrors: false }
    FileView { id: fD; path: "/tmp/fv_target.lua"; blockLoading: true; watchChanges: false; printErrors: false }

    readonly property string tA: fA.text()
    readonly property string tB: fB.text()
    readonly property string tC: fC.text()
    readonly property string tD: fD.text()
    onTAChanged: console.log(">>> A (deco, watch=true)  CHANGED")
    onTBChanged: console.log(">>> B (deco, watch=false) CHANGED")
    onTCChanged: console.log(">>> C (/tmp, watch=true)  CHANGED")
    onTDChanged: console.log(">>> D (/tmp, watch=false) CHANGED")

    Component.onCompleted: console.log("loaded lens:", fA.text().length, fB.text().length, fC.text().length, fD.text().length)
}