pragma Singleton
import QtQuick

QtObject {
    // paletteMode: "dynamic" → use Dyn's wallpaper-driven values
    // paletteMode: "static"  → use Theme.qml's fallback hex values
    property string paletteMode: "dynamic"

    // Font family override; empty string means "use system default"
    property string uiFont: ""
}