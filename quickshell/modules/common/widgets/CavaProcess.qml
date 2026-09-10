pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// Thin wrapper: subscribes/unsubscribes to CavaService on `active` and
// exposes the shared points list. Same external API as the iNiR original.
Item {
    id: root

    property bool active: false
    readonly property var points: CavaService.points

    onActiveChanged: {
        if (active) CavaService.subscribe()
        else CavaService.unsubscribe()
    }

    Component.onDestruction: {
        if (active) CavaService.unsubscribe()
    }
}
