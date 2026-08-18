pragma Singleton
import QtQuick

QtObject {
    id: root
    // Stubbed for waffle bar
    readonly property bool capsLockVisible: false
    readonly property bool numLockVisible: false
    readonly property bool layoutVisible: false
    readonly property string capsFluentIcon: "keyboard-caps-lock"
    readonly property string numFluentIcon: "keyboard-num"
    readonly property string currentLayoutCodeInline: "EN"
    readonly property string currentLayoutName: "English"
}