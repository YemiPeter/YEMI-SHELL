# iNiR Waffle Panel Family Scope

Read-only discovery notes for iNiR's Waffle panel family, the Windows-desktop-style UI distinct from the `ii` overlay/pill family.

## Directory Discovery

Raw command output:

```text
$ find ~/iNiR/modules -maxdepth 2 -iname "*waffle*" -type d
/home/yemi/iNiR/modules/waffle

$ find ~/iNiR -maxdepth 2 -iname "*waffle*"
/home/yemi/iNiR/ShellWafflePanels.qml
/home/yemi/iNiR/modules/waffle
/home/yemi/iNiR/waffleSettings.qml
```

Main Waffle module:

```text
/home/yemi/iNiR/modules/waffle
```

Top-level Waffle wiring files:

```text
/home/yemi/iNiR/ShellWafflePanels.qml
/home/yemi/iNiR/waffleSettings.qml
```

## File And Line Count

Waffle module only:

```text
QML files: 179
Total lines: 34,375
```

This count is for:

```text
/home/yemi/iNiR/modules/waffle
```

It does not include top-level wiring files like `ShellWafflePanels.qml`, `waffleSettings.qml`, or shared iNiR services.

## Waffle QML File List

```text
/home/yemi/iNiR/modules/waffle/actionCenter/ActionCenterContent.qml
/home/yemi/iNiR/modules/waffle/actionCenter/ActionCenterContext.qml
/home/yemi/iNiR/modules/waffle/actionCenter/ExpandableChoiceButton.qml
/home/yemi/iNiR/modules/waffle/actionCenter/HeaderRow.qml
/home/yemi/iNiR/modules/waffle/actionCenter/MediaPaneContent.qml
/home/yemi/iNiR/modules/waffle/actionCenter/SectionText.qml
/home/yemi/iNiR/modules/waffle/actionCenter/ToggleItem.qml
/home/yemi/iNiR/modules/waffle/actionCenter/WaffleActionCenter.qml
/home/yemi/iNiR/modules/waffle/actionCenter/bluetooth/BluetoothControl.qml
/home/yemi/iNiR/modules/waffle/actionCenter/bluetooth/BluetoothDeviceItem.qml
/home/yemi/iNiR/modules/waffle/actionCenter/hotspot/HotspotControl.qml
/home/yemi/iNiR/modules/waffle/actionCenter/mainPage/MainPageBody.qml
/home/yemi/iNiR/modules/waffle/actionCenter/mainPage/MainPageBodySliders.qml
/home/yemi/iNiR/modules/waffle/actionCenter/mainPage/MainPageBodyToggles.qml
/home/yemi/iNiR/modules/waffle/actionCenter/mainPage/MainPageFooter.qml
/home/yemi/iNiR/modules/waffle/actionCenter/nightLight/NightLightControl.qml
/home/yemi/iNiR/modules/waffle/actionCenter/screenTime/ScreenTimePage.qml
/home/yemi/iNiR/modules/waffle/actionCenter/toggles/ActionCenterToggleButton.qml
/home/yemi/iNiR/modules/waffle/actionCenter/toggles/ActionCenterTogglesDelegateChooser.qml
/home/yemi/iNiR/modules/waffle/actionCenter/toggles/WNetworkToggle.qml
/home/yemi/iNiR/modules/waffle/actionCenter/volumeControl/VolumeControl.qml
/home/yemi/iNiR/modules/waffle/actionCenter/volumeControl/VolumeEntry.qml
/home/yemi/iNiR/modules/waffle/actionCenter/wifi/WWifiNetworkItem.qml
/home/yemi/iNiR/modules/waffle/actionCenter/wifi/WifiControl.qml
/home/yemi/iNiR/modules/waffle/altSwitcher/WaffleAltSwitcher.qml
/home/yemi/iNiR/modules/waffle/altSwitcher/WaffleAltSwitcherContent.qml
/home/yemi/iNiR/modules/waffle/altSwitcher/WaffleAltSwitcherThumbnail.qml
/home/yemi/iNiR/modules/waffle/altSwitcher/WaffleAltSwitcherTile.qml
/home/yemi/iNiR/modules/waffle/backdrop/WaffleBackdrop.qml
/home/yemi/iNiR/modules/waffle/background/WaffleBackground.qml
/home/yemi/iNiR/modules/waffle/background/WaffleBackgroundClock.qml
/home/yemi/iNiR/modules/waffle/bar/AppButton.qml
/home/yemi/iNiR/modules/waffle/bar/BarButton.qml
/home/yemi/iNiR/modules/waffle/bar/BarIconButton.qml
/home/yemi/iNiR/modules/waffle/bar/BarMenu.qml
/home/yemi/iNiR/modules/waffle/bar/BarPopup.qml
/home/yemi/iNiR/modules/waffle/bar/BarToolTip.qml
/home/yemi/iNiR/modules/waffle/bar/DesktopPeekButton.qml
/home/yemi/iNiR/modules/waffle/bar/SearchButton.qml
/home/yemi/iNiR/modules/waffle/bar/StartButton.qml
/home/yemi/iNiR/modules/waffle/bar/SystemButton.qml
/home/yemi/iNiR/modules/waffle/bar/TaskViewButton.qml
/home/yemi/iNiR/modules/waffle/bar/TimeButton.qml
/home/yemi/iNiR/modules/waffle/bar/TimerButton.qml
/home/yemi/iNiR/modules/waffle/bar/UpdatesButton.qml
/home/yemi/iNiR/modules/waffle/bar/WaffleBar.qml
/home/yemi/iNiR/modules/waffle/bar/WaffleBarContent.qml
/home/yemi/iNiR/modules/waffle/bar/WeatherButton.qml
/home/yemi/iNiR/modules/waffle/bar/WidgetsButton.qml
/home/yemi/iNiR/modules/waffle/bar/tasks/TaskAppButton.qml
/home/yemi/iNiR/modules/waffle/bar/tasks/TaskPreview.qml
/home/yemi/iNiR/modules/waffle/bar/tasks/Tasks.qml
/home/yemi/iNiR/modules/waffle/bar/tasks/WindowPreview.qml
/home/yemi/iNiR/modules/waffle/bar/tray/Tray.qml
/home/yemi/iNiR/modules/waffle/bar/tray/TrayButton.qml
/home/yemi/iNiR/modules/waffle/bar/tray/TrayOverflowMenu.qml
/home/yemi/iNiR/modules/waffle/bar/tray/WaffleTrayMenu.qml
/home/yemi/iNiR/modules/waffle/bar/tray/WaffleTrayMenuEntry.qml
/home/yemi/iNiR/modules/waffle/clipboard/WaffleClipboard.qml
/home/yemi/iNiR/modules/waffle/clipboard/WaffleClipboardContent.qml
/home/yemi/iNiR/modules/waffle/clipboard/WaffleClipboardItem.qml
/home/yemi/iNiR/modules/waffle/lock/WaffleLockSurface.qml
/home/yemi/iNiR/modules/waffle/lock/WaffleLockSurfaceSafe.qml
/home/yemi/iNiR/modules/waffle/looks/AcrylicButton.qml
/home/yemi/iNiR/modules/waffle/looks/AcrylicRectangle.qml
/home/yemi/iNiR/modules/waffle/looks/BodyRectangle.qml
/home/yemi/iNiR/modules/waffle/looks/CloseButton.qml
/home/yemi/iNiR/modules/waffle/looks/FluentIcon.qml
/home/yemi/iNiR/modules/waffle/looks/FooterMoreButton.qml
/home/yemi/iNiR/modules/waffle/looks/FooterRectangle.qml
/home/yemi/iNiR/modules/waffle/looks/Looks.qml
/home/yemi/iNiR/modules/waffle/looks/WAmbientShadow.qml
/home/yemi/iNiR/modules/waffle/looks/WAppIcon.qml
/home/yemi/iNiR/modules/waffle/looks/WBarAttachedPanelContent.qml
/home/yemi/iNiR/modules/waffle/looks/WBorderedButton.qml
/home/yemi/iNiR/modules/waffle/looks/WBorderlessButton.qml
/home/yemi/iNiR/modules/waffle/looks/WButton.qml
/home/yemi/iNiR/modules/waffle/looks/WChoiceButton.qml
/home/yemi/iNiR/modules/waffle/looks/WFadeLoader.qml
/home/yemi/iNiR/modules/waffle/looks/WIcons.qml
/home/yemi/iNiR/modules/waffle/looks/WIndeterminateProgressBar.qml
/home/yemi/iNiR/modules/waffle/looks/WListView.qml
/home/yemi/iNiR/modules/waffle/looks/WMenu.qml
/home/yemi/iNiR/modules/waffle/looks/WMenuItem.qml
/home/yemi/iNiR/modules/waffle/looks/WPageLoader.qml
/home/yemi/iNiR/modules/waffle/looks/WPane.qml
/home/yemi/iNiR/modules/waffle/looks/WPanelIconButton.qml
/home/yemi/iNiR/modules/waffle/looks/WPanelPageColumn.qml
/home/yemi/iNiR/modules/waffle/looks/WPanelSeparator.qml
/home/yemi/iNiR/modules/waffle/looks/WPopupToolTip.qml
/home/yemi/iNiR/modules/waffle/looks/WProgressBar.qml
/home/yemi/iNiR/modules/waffle/looks/WRectangularShadow.qml
/home/yemi/iNiR/modules/waffle/looks/WScrollBar.qml
/home/yemi/iNiR/modules/waffle/looks/WSlider.qml
/home/yemi/iNiR/modules/waffle/looks/WStackView.qml
/home/yemi/iNiR/modules/waffle/looks/WSwitch.qml
/home/yemi/iNiR/modules/waffle/looks/WTaskbarSeparator.qml
/home/yemi/iNiR/modules/waffle/looks/WText.qml
/home/yemi/iNiR/modules/waffle/looks/WTextField.qml
/home/yemi/iNiR/modules/waffle/looks/WTextInput.qml
/home/yemi/iNiR/modules/waffle/looks/WTextWithFixedWidth.qml
/home/yemi/iNiR/modules/waffle/looks/WToolTip.qml
/home/yemi/iNiR/modules/waffle/looks/WToolTipContent.qml
/home/yemi/iNiR/modules/waffle/looks/WUserAvatar.qml
/home/yemi/iNiR/modules/waffle/notificationCenter/CalendarWidget.qml
/home/yemi/iNiR/modules/waffle/notificationCenter/DateHeader.qml
/home/yemi/iNiR/modules/waffle/notificationCenter/FocusFooter.qml
/home/yemi/iNiR/modules/waffle/notificationCenter/NotificationCenterContent.qml
/home/yemi/iNiR/modules/waffle/notificationCenter/NotificationHeaderButton.qml
/home/yemi/iNiR/modules/waffle/notificationCenter/NotificationPaneContent.qml
/home/yemi/iNiR/modules/waffle/notificationCenter/SmallBorderedIconAndTextButton.qml
/home/yemi/iNiR/modules/waffle/notificationCenter/SmallBorderedIconButton.qml
/home/yemi/iNiR/modules/waffle/notificationCenter/WNotificationAppIcon.qml
/home/yemi/iNiR/modules/waffle/notificationCenter/WNotificationDismissAnim.qml
/home/yemi/iNiR/modules/waffle/notificationCenter/WNotificationGroup.qml
/home/yemi/iNiR/modules/waffle/notificationCenter/WSingleNotification.qml
/home/yemi/iNiR/modules/waffle/notificationCenter/WaffleNotificationCenter.qml
/home/yemi/iNiR/modules/waffle/notificationPopup/WNotificationGroup.qml
/home/yemi/iNiR/modules/waffle/notificationPopup/WNotificationItem.qml
/home/yemi/iNiR/modules/waffle/notificationPopup/WNotificationListView.qml
/home/yemi/iNiR/modules/waffle/notificationPopup/WaffleNotificationPopup.qml
/home/yemi/iNiR/modules/waffle/onScreenDisplay/BrightnessOSD.qml
/home/yemi/iNiR/modules/waffle/onScreenDisplay/KeyboardLayoutOSD.qml
/home/yemi/iNiR/modules/waffle/onScreenDisplay/MediaOSD.qml
/home/yemi/iNiR/modules/waffle/onScreenDisplay/OSDValue.qml
/home/yemi/iNiR/modules/waffle/onScreenDisplay/VolumeOSD.qml
/home/yemi/iNiR/modules/waffle/onScreenDisplay/WaffleOSD.qml
/home/yemi/iNiR/modules/waffle/polkit/WPolkitContent.qml
/home/yemi/iNiR/modules/waffle/polkit/WafflePolkit.qml
/home/yemi/iNiR/modules/waffle/regionSelector/WOptionsToolbar.qml
/home/yemi/iNiR/modules/waffle/sessionScreen/PowerButton.qml
/home/yemi/iNiR/modules/waffle/sessionScreen/SessionScreenContent.qml
/home/yemi/iNiR/modules/waffle/sessionScreen/WSessionScreenTextButton.qml
/home/yemi/iNiR/modules/waffle/sessionScreen/WaffleSessionScreen.qml
/home/yemi/iNiR/modules/waffle/settings/WKeybindRow.qml
/home/yemi/iNiR/modules/waffle/settings/WSettingsButton.qml
/home/yemi/iNiR/modules/waffle/settings/WSettingsCard.qml
/home/yemi/iNiR/modules/waffle/settings/WSettingsChoiceGroup.qml
/home/yemi/iNiR/modules/waffle/settings/WSettingsContent.qml
/home/yemi/iNiR/modules/waffle/settings/WSettingsDropdown.qml
/home/yemi/iNiR/modules/waffle/settings/WSettingsFontSelector.qml
/home/yemi/iNiR/modules/waffle/settings/WSettingsInfoBar.qml
/home/yemi/iNiR/modules/waffle/settings/WSettingsNavItem.qml
/home/yemi/iNiR/modules/waffle/settings/WSettingsPage.qml
/home/yemi/iNiR/modules/waffle/settings/WSettingsRow.qml
/home/yemi/iNiR/modules/waffle/settings/WSettingsSection.qml
/home/yemi/iNiR/modules/waffle/settings/WSettingsSlider.qml
/home/yemi/iNiR/modules/waffle/settings/WSettingsSpinBox.qml
/home/yemi/iNiR/modules/waffle/settings/WSettingsSwitch.qml
/home/yemi/iNiR/modules/waffle/settings/WSettingsTextField.qml
/home/yemi/iNiR/modules/waffle/settings/pages/WAboutPage.qml
/home/yemi/iNiR/modules/waffle/settings/pages/WBackgroundPage.qml
/home/yemi/iNiR/modules/waffle/settings/pages/WBarPage.qml
/home/yemi/iNiR/modules/waffle/settings/pages/WGeneralPage.qml
/home/yemi/iNiR/modules/waffle/settings/pages/WGowallPage.qml
/home/yemi/iNiR/modules/waffle/settings/pages/WInterfacePage.qml
/home/yemi/iNiR/modules/waffle/settings/pages/WModulesPage.qml
/home/yemi/iNiR/modules/waffle/settings/pages/WMonitorVisibilityPage.qml
/home/yemi/iNiR/modules/waffle/settings/pages/WQuickPage.qml
/home/yemi/iNiR/modules/waffle/settings/pages/WShortcutsPage.qml
/home/yemi/iNiR/modules/waffle/settings/pages/WThemesPage.qml
/home/yemi/iNiR/modules/waffle/settings/pages/WWaffleStylePage.qml
/home/yemi/iNiR/modules/waffle/startMenu/AllAppsContent.qml
/home/yemi/iNiR/modules/waffle/startMenu/SearchBar.qml
/home/yemi/iNiR/modules/waffle/startMenu/SearchEntryIcon.qml
/home/yemi/iNiR/modules/waffle/startMenu/SearchPageContent.qml
/home/yemi/iNiR/modules/waffle/startMenu/SearchResults.qml
/home/yemi/iNiR/modules/waffle/startMenu/StartMenuContent.qml
/home/yemi/iNiR/modules/waffle/startMenu/StartMenuContext.qml
/home/yemi/iNiR/modules/waffle/startMenu/StartPageContent.qml
/home/yemi/iNiR/modules/waffle/startMenu/TagStrip.qml
/home/yemi/iNiR/modules/waffle/startMenu/WSearchResultButton.qml
/home/yemi/iNiR/modules/waffle/startMenu/WaffleStartMenu.qml
/home/yemi/iNiR/modules/waffle/taskview/WaffleTaskView.qml
/home/yemi/iNiR/modules/waffle/taskview/WaffleTaskViewContent.qml
/home/yemi/iNiR/modules/waffle/taskview/WindowThumbnail.qml
/home/yemi/iNiR/modules/waffle/taskview/WorkspaceThumbnail.qml
/home/yemi/iNiR/modules/waffle/widgets/WaffleWidgets.qml
/home/yemi/iNiR/modules/waffle/widgets/WidgetsContent.qml
```

## Panel Family Switching

The switch is driven by:

```qml
Config.options.panelFamily
```

The default is declared in:

```text
/home/yemi/iNiR/modules/common/Config.qml
```

Relevant raw result:

```text
/home/yemi/iNiR/modules/common/Config.qml:399:            property string panelFamily: "ii" // "ii" or "waffle"
/home/yemi/iNiR/modules/common/Config.qml:400:            property bool familyTransitionAnimation: true // Show animated overlay when switching families
```

`/home/yemi/iNiR/shell.qml` defines two panel families:

```qml
property list<string> families: ["ii", "waffle"]
property var panelFamilies: ({
    "ii": [
        "iiBar", "iiBackground", "iiBackdrop", "iiBootGreeting", "iiCheatsheet", "iiControlPanel", "iiDock", "iiLock",
        "iiMediaControls", "iiNotificationPopup", "iiOnScreenDisplay", "iiOnScreenKeyboard",
        "iiOverlay", "iiOverview", "iiPolkit", "iiRegionSelector", "iiScreenCorners",
        "iiSessionScreen", "iiSidebarLeft", "iiSidebarRight", "iiTilingOverlay", "iiVerticalBar",
        "iiWallpaperSelector", "iiCoverflowSelector", "iiClipboard", "iiShellUpdate", "iiRecordingOsd"
    ],
    "waffle": [
        "wBar", "wBackground", "wBackdrop", "wStartMenu", "wActionCenter", "wNotificationCenter", "wNotificationPopup", "wOnScreenDisplay", "wWidgets", "wTaskView", "wLock", "wPolkit", "wSessionScreen",
        "iiBootGreeting", "iiCheatsheet", "iiOnScreenKeyboard", "iiOverlay", "iiOverview",
        "iiRegionSelector", "iiScreenCorners", "iiWallpaperSelector", "iiCoverflowSelector", "iiClipboard"
    ]
})
```

`shell.qml` lazy-loads only the active family:

```qml
LazyLoader {
    active: Config.ready && (Config.options?.panelFamily ?? "ii") !== "waffle"
    source: "ShellIiPanels.qml"
}

LazyLoader {
    active: Config.ready && (Config.options?.panelFamily ?? "ii") === "waffle"
    source: "ShellWafflePanels.qml"
}
```

Family switching is exposed via IPC:

```qml
IpcHandler {
    target: "panelFamily"
    function cycle(): void { root.cyclePanelFamily() }
    function set(family: string): void { root.setPanelFamily(family) }
}
```

With `familyTransitionAnimation` enabled, the switch is staged:

1. `shell.qml` stores `_pendingFamily`.
2. It sets `GlobalStates.familyTransitionDirection`.
3. It sets `GlobalStates.familyTransitionActive = true`.
4. `FamilyTransitionOverlay.qml` starts its animation.
5. `FamilyTransitionOverlay.qml` emits `exitComplete`.
6. `shell.qml` writes `Config.setNestedValue("panelFamily", _pendingFamily)`.
7. `shell.qml` calls `_ensureFamilyPanels(_pendingFamily)`.
8. `FamilyTransitionOverlay.qml` emits `enterComplete`.
9. `shell.qml` clears `GlobalStates.familyTransitionActive`.

The transition overlay is loaded in:

```text
/home/yemi/iNiR/shell.qml
```

Raw search result:

```text
$ grep -rn "FamilyTransitionOverlay" ~/iNiR --include="*.qml" | head -10
/home/yemi/iNiR/shell.qml:449:        source: "FamilyTransitionOverlay.qml"
```

## Waffle Panel Loader

`/home/yemi/iNiR/ShellWafflePanels.qml` imports and loads Waffle-specific modules:

```qml
import qs.modules.waffle.actionCenter
import qs.modules.waffle.altSwitcher as WaffleAltSwitcherModule
import qs.modules.waffle.background as WaffleBackgroundModule
import qs.modules.waffle.bar as WaffleBarModule
import qs.modules.waffle.clipboard as WaffleClipboardModule
import qs.modules.waffle.notificationCenter
import qs.modules.waffle.onScreenDisplay as WaffleOSDModule
import qs.modules.waffle.startMenu
import qs.modules.waffle.widgets
import qs.modules.waffle.backdrop as WaffleBackdropModule
import qs.modules.waffle.notificationPopup as WaffleNotificationPopupModule
import qs.modules.waffle.taskview as WaffleTaskViewModule
```

Immediate Waffle panels:

```qml
PanelLoader { identifier: "wBar"; component: WaffleBarModule.WaffleBar {} }
PanelLoader { identifier: "wBackground"; component: WaffleBackgroundModule.WaffleBackground {} }
PanelLoader { identifier: "wBackdrop"; extraCondition: Config.options?.waffles?.background?.backdrop?.enable ?? true; component: WaffleBackdropModule.WaffleBackdrop {} }
PanelLoader { identifier: "wNotificationPopup"; component: WaffleNotificationPopupModule.WaffleNotificationPopup {} }
PanelLoader { identifier: "wOnScreenDisplay"; component: WaffleOSDModule.WaffleOSD {} }
```

Deferred Waffle panels:

```qml
DeferredPanelLoader { identifier: "wStartMenu"; component: WaffleStartMenu {} }
DeferredPanelLoader { identifier: "wActionCenter"; component: WaffleActionCenter {} }
DeferredPanelLoader { identifier: "wNotificationCenter"; component: WaffleNotificationCenter {} }
DeferredPanelLoader { identifier: "wWidgets"; extraCondition: Config.options?.waffles?.modules?.widgets ?? true; component: WaffleWidgets {} }
DeferredPanelLoader { identifier: "wLock"; component: Lock {} }
DeferredPanelLoader { identifier: "wPolkit"; component: Polkit {} }
DeferredPanelLoader { identifier: "wSessionScreen"; component: SessionScreen {} }
DeferredPanelLoader { identifier: "wTaskView"; component: WaffleTaskViewModule.WaffleTaskView {} }
```

Shared modules loaded in Waffle mode:

```qml
DeferredPanelLoader { identifier: "iiBootGreeting"; component: BootGreeting {} }
DeferredPanelLoader { identifier: "iiCheatsheet"; component: Cheatsheet {} }
DeferredPanelLoader { identifier: "iiOnScreenKeyboard"; component: OnScreenKeyboard {} }
DeferredPanelLoader { identifier: "iiOverlay"; component: Overlay {} }
DeferredPanelLoader { identifier: "iiOverview"; component: Overview {} }
DeferredPanelLoader { identifier: "iiRegionSelector"; component: RegionSelector {} }
DeferredPanelLoader { identifier: "iiScreenCorners"; component: ScreenCorners {} }
DeferredPanelLoader { identifier: "iiWallpaperSelector"; component: WallpaperSelector {} }
DeferredPanelLoader { identifier: "iiCoverflowSelector"; component: WallpaperCoverflow {} }
DeferredPanelLoader { identifier: "iiClipboard"; extraCondition: Config.options?.panelFamily !== "waffle"; component: ClipboardModule.ClipboardPanel {} }
DeferredPanelLoader { identifier: "iiRecordingOsd"; component: RecordingOsd {} }
```

Waffle-only lazy loaders gated directly by `panelFamily === "waffle"`:

```qml
LazyLoader {
    loading: Config.ready && Config.options?.panelFamily === "waffle"
    activeAsync: Config.ready && GlobalStates.deferredPanelsReady && Config.options?.panelFamily === "waffle"
    component: WaffleClipboardModule.WaffleClipboard {}
}

LazyLoader {
    loading: Config.ready && Config.options?.panelFamily === "waffle"
    activeAsync: Config.ready && GlobalStates.deferredPanelsReady && Config.options?.panelFamily === "waffle"
    component: WaffleAltSwitcherModule.WaffleAltSwitcher {}
}
```

## IPC Targets

Raw Waffle-module target extraction:

```text
$ grep -RhoP 'target:\s*"\K[^"]+' ~/iNiR/modules/waffle 2>/dev/null | sort -u
clipboard
osd
search
session
taskview
wactionCenter
waffleAltSwitcher
wbar
wnotificationCenter
wwidgets
```

Waffle-specific targets from source:

```text
/home/yemi/iNiR/modules/waffle/actionCenter/WaffleActionCenter.qml: target "wactionCenter"
/home/yemi/iNiR/modules/waffle/altSwitcher/WaffleAltSwitcher.qml: target "waffleAltSwitcher"
/home/yemi/iNiR/modules/waffle/bar/WaffleBar.qml: target "wbar"
/home/yemi/iNiR/modules/waffle/notificationCenter/WaffleNotificationCenter.qml: target "wnotificationCenter"
/home/yemi/iNiR/modules/waffle/startMenu/WaffleStartMenu.qml: target "search"
/home/yemi/iNiR/modules/waffle/widgets/WaffleWidgets.qml: target "wwidgets"
```

Waffle-mode targets that are shared or generic:

```text
/home/yemi/iNiR/modules/waffle/clipboard/WaffleClipboard.qml: target "clipboard"
/home/yemi/iNiR/modules/waffle/onScreenDisplay/WaffleOSD.qml: target "osd"
/home/yemi/iNiR/modules/waffle/sessionScreen/WaffleSessionScreen.qml: target "session"
/home/yemi/iNiR/modules/waffle/taskview/WaffleTaskView.qml: target "taskview"
```

Related targets outside the Waffle directory:

```text
/home/yemi/iNiR/shell.qml: target "panelFamily"
/home/yemi/iNiR/modules/wallpaperSelector/WallpaperSelector.qml: target "wallpaperSelector"
/home/yemi/iNiR/services/WidgetPowerManager.qml: target "widgetpower"
```

Combined relevant target set:

```text
clipboard
coverflowSelector
osd
panelFamily
search
session
settings
taskview
wactionCenter
waffleAltSwitcher
wallpaperSelector
wbar
widgetpower
wnotificationCenter
wwidgets
```

## Service Dependencies

Raw `QsServices` check:

```text
$ grep -rl "QsServices\." ~/iNiR/modules/waffle | head -20
# no output

$ grep -Rho "QsServices\.[A-Za-z0-9_]*" ~/iNiR/modules/waffle 2>/dev/null | sort -u
# no output
```

Waffle does not use `QsServices.*` references. It imports iNiR services directly:

```text
import qs.services
import qs.services.deferred
import qs.services.network
```

Unique service/singleton names referenced in Waffle:

```text
AppLauncher
AppSearch
Audio
BluetoothStatus
Brightness
CalendarSync
Cliphist
Events
GlobalActions
GowallService
Hyprsunset
Idle
KeyboardIndicators
MprisController
Network
NiriService
Notifications
PolkitService
RecorderStatus
ScreenTime
ShellUpdates
SystemInfo
TaskbarApps
ThemeService
TrayService
Updates
Wallpapers
Weather
WindowPreviewService
```

Likely shared/general service dependencies:

```text
Audio
Brightness
Network
Notifications
MprisController
Weather
Updates
ShellUpdates
PolkitService
Wallpapers
ThemeService
AppLauncher
AppSearch
GlobalActions
SystemInfo
RecorderStatus
Hyprsunset
Idle
KeyboardIndicators
BluetoothStatus
Events
```

Waffle-specific or iNiR-specific dependencies that are not simple drop-ins for Yemi-shell:

```text
Config
GlobalStates
Looks
TaskbarApps
TrayService
NiriService
WindowPreviewService
ScreenTime
CalendarSync
Cliphist
WidgetPowerManager
GowallService
```

Yemi-shell already has partial conceptual equivalents for some areas:

```text
Audio
Brightness
Network
Notifications / Notifs
Mpris / Players
Weather
Config
Appearance
Niri compositor state
Wallpaper / Walls
Bluetooth
Power profiles
Screenshot
System usage
```

However, those are not API-compatible with iNiR's Waffle modules. Waffle expects iNiR's `qs.services`, `Config.options`, `GlobalStates`, `Looks`, and Niri/window-preview service shapes.

## Complexity Assessment

Waffle is not a standalone addable feature. It is a full alternate shell family.

It includes:

```text
Taskbar
Start menu
Action center
Notification center
Notification popups
On-screen display
Clipboard UI
Alt-tab switcher
Task view
Desktop background/backdrop
Widgets panel
Lock/session/polkit surfaces
Waffle-specific settings UI
Fluent/Windows-style component library
```

The architecture is integrated across:

```text
/home/yemi/iNiR/shell.qml
/home/yemi/iNiR/ShellWafflePanels.qml
/home/yemi/iNiR/FamilyTransitionOverlay.qml
/home/yemi/iNiR/modules/common/Config.qml
/home/yemi/iNiR/GlobalStates.qml
/home/yemi/iNiR/services/*
/home/yemi/iNiR/services/deferred/*
/home/yemi/iNiR/modules/waffle/*
```

Porting Waffle cleanly would require one of two approaches:

1. Recreate enough of iNiR's service/config/global-state API inside Yemi-shell for Waffle modules to run mostly unchanged.
2. Rewrite Waffle panels around Yemi-shell's current config, compositor, service, and IPC model.

The second approach is likely cleaner long term. The first approach is faster only if compatibility shims remain narrow, but the Waffle tree is large enough that the shim layer would probably expand quickly.

Bottom line: this is deep shell integration, not a small module copy.
