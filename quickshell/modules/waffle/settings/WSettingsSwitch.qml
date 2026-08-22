pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.waffle.looks

// Switch setting row - Windows 11 style
WSettingsRow {
    id: root
    
    property bool checked: false
    
    clickable: true
    onClicked: {
        console.log("[WSettingsSwitch] MouseArea onClicked - root.checked before:", root.checked);
        root.checked = !root.checked;
        console.log("[WSettingsSwitch] MouseArea onClicked - root.checked after:", root.checked);
    }
    
    control: Component {
        WSwitch {
            checked: root.checked
            onClicked: {
                console.log("[WSettingsSwitch] WSwitch onClicked - root.checked before:", root.checked);
                root.checked = !root.checked;
                console.log("[WSettingsSwitch] WSwitch onClicked - root.checked after:", root.checked);
            }
        }
    }
}
