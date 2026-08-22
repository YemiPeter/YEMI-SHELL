pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.waffle.settings
import qs.modules.waffle.looks

WSettingsCard {
    title: Translation.tr("Audio")
    icon: "speaker-2-filled"

    WSettingsSwitch {
        label: Translation.tr("Volume protection")
        icon: "speaker-mute"
        description: Translation.tr("Limit volume to prevent hearing damage")
        checked: Config.options?.audio?.protection?.enable ?? false
        onCheckedChanged: Config.setNestedValue("audio.protection.enable", checked)
    }
    WSettingsSpinBox {
        visible: Config.options?.audio?.protection?.enable ?? false
        label: Translation.tr("Maximum volume")
        icon: "speaker-1"
        suffix: "%"
        from: 50; to: 150; stepSize: 5
        value: Config.options?.audio?.protection?.maxAllowed ?? 99
        onValueChanged: Config.setNestedValue("audio.protection.maxAllowed", value)
    }
    WSettingsSpinBox {
        visible: Config.options?.audio?.protection?.enable ?? false
        label: Translation.tr("Max increase per step")
        icon: "speaker-1"
        description: Translation.tr("Maximum volume increase per key press")
        suffix: "%"
        from: 1; to: 20; stepSize: 1
        value: Config.options?.audio?.protection?.maxAllowedIncrease ?? 10
        onValueChanged: Config.setNestedValue("audio.protection.maxAllowedIncrease", value)
    }
}
