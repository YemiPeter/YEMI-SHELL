import Quickshell
import QtQuick

Scope {
    id: root
    
    required property var matugen
    
    VolumeOSD {
        matugen: root.matugen
    }
    
    BrightnessOSD {
        matugen: root.matugen
    }
}