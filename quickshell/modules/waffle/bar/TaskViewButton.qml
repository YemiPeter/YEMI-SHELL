import QtQuick
import QtQuick.Layouts
import Quickshell
import org.kde.kirigami as Kirigami
import qs
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

AppButton {
    id: root

    iconName: (down && !checked) ? "task-view-pressed" : "task-view"
    pressedScale: checked ? 5/6 : 1
    separateLightDark: true

    checked: GlobalStates.waffleTaskViewOpen
    onClicked: {
        // Toggle the waffle TaskView panel directly (self-managed on
        // waffleTaskViewOpen; handles preview capture internally).
        GlobalStates.waffleTaskViewOpen = !GlobalStates.waffleTaskViewOpen
    }

    BarToolTip {
        extraVisibleCondition: root.shouldShowTooltip
        text: Translation.tr("Task View")
    }
}
