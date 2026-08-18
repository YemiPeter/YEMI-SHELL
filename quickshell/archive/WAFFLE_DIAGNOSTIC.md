# Waffle Panel Family — Diagnostic Mapping (Yemi Shell / Quickshell)

> **Diagnostic pass only.** No edits, fixes, or refactors were performed. Every
> claim below is backed by raw command output captured during the audit.

## 0. Path correction (preliminary)

The task specified `~/.config/yemi-shell`. That path exists but contains only:

```
/home/yemi/.config/yemi-shell
├── actions
└── config.json
```

…and has **no `modules/waffle`** (so the section 1 commands against it fail). The
live shell config is at **`~/.config/quickshell`**, which is the working directory
and where `modules/waffle`, `services`, `shell.qml`, and `Config.qml` actually
live. All diagnostics below were run against `~/.config/quickshell`.

---

## 1. Directory structure

**`tree -L 3 -I 'node_modules|.git' ~/.config/yemi-shell/modules/waffle`**
```
/home/yemi/.config/yemi-shell/modules/waffle  [error opening dir]
0 directories, 0 files
```

**`tree -L 2 -I 'node_modules|.git' ~/.config/yemi-shell/services`**
```
/home/yemi/.config/yemi-shell/services  [error opening dir]
0 directories, 0 files
```

**Actual path — `tree -L 3 -I 'node_modules|.git' modules/waffle`** (from `~/.config/quickshell`)
```
modules/waffle
├── backdrop
│   ├── qmldir
│   └── WaffleBackdrop.qml
├── background
│   ├── qmldir
│   ├── WaffleBackgroundClock.qml
│   └── WaffleBackground.qml
├── bar
│   ├── AppButton.qml
│   ├── BarButton.qml
│   ├── BarIconButton.qml
│   ├── BarMenu.qml
│   ├── BarPopup.qml
│   ├── BarToolTip.qml
│   ├── DesktopPeekButton.qml
│   ├── qmldir
│   ├── SearchButton.qml
│   ├── StartButton.qml
│   ├── SystemButton.qml
│   ├── tasks
│   │   ├── qmldir
│   │   ├── TaskAppButton.qml
│   │   ├── TaskPreview.qml
│   │   ├── Tasks.qml
│   │   └── WindowPreview.qml
│   ├── TaskViewButton.qml
│   ├── TimeButton.qml
│   ├── TimerButton.qml
│   ├── tray
│   │   ├── qmldir
│   │   ├── TrayButton.qml
│   │   ├── TrayOverflowMenu.qml
│   │   ├── Tray.qml
│   │   ├── WaffleTrayMenuEntry.qml
│   │   └── WaffleTrayMenu.qml
│   ├── UpdatesButton.qml
│   ├── WaffleBarContent.qml
│   ├── WaffleBar.qml
│   ├── WeatherButton.qml
│   └── WidgetsButton.qml
├── looks
│   ├── AcrylicButton.qml
│   ├── AcrylicRectangle.qml
│   ├── BodyRectangle.qml
│   ├── CloseButton.qml
│   ├── FluentIcon.qml
│   ├── FooterMoreButton.qml
│   ├── FooterRectangle.qml
│   ├── Looks.qml
│   ├── qmldir
│   ├── Translation.qml
│   ├── WAmbientShadow.qml
│   ├── WAppIcon.qml
│   ├── WBarAttachedPanelContent.qml
│   ├── WBorderedButton.qml
│   ├── WBorderlessButton.qml
│   ├── WButton.qml
│   ├── WChoiceButton.qml
│   ├── WFadeLoader.qml
│   ├── WIcons.qml
│   ├── WIndeterminateProgressBar.qml
│   ├── WListView.qml
│   ├── WMenuItem.qml
│   ├── WMenu.qml
│   ├── WPageLoader.qml
│   ├── WPanelIconButton.qml
│   ├── WPanelPageColumn.qml
│   ├── WPanelSeparator.qml
│   ├── WPane.qml
│   ├── WPopupToolTip.qml
│   ├── WProgressBar.qml
│   ├── WRectangularShadow.qml
│   ├── WScrollBar.qml
│   ├── WSlider.qml
│   ├── WStackView.qml
│   ├── WSwitch.qml
│   ├── WTaskbarSeparator.qml
│   ├── WTextField.qml
│   ├── WTextInput.qml
│   ├── WText.qml
│   ├── WTextWithFixedWidth.qml
│   ├── WToolTipContent.qml
│   ├── WToolTip.qml
│   └── WUserAvatar.qml
└── qmldir

7 directories, 79 files
```

**Actual path — `tree -L 2 -I 'node_modules|.git' services`**
```
services
├── Audio.qml
├── Battery.qml
├── Bluetooth.qml
├── BluetoothStatus.qml
├── Brightness.qml
├── CompositorService.qml
├── DankSocket.qml
├── DateTime.qml
├── deferred
│   ├── AnimeService.qml
│   ├── CavaService.qml
│   ├── Cliphist.qml
│   ├── EasyEffects.qml
│   ├── Emojis.qml
│   ├── GowallService.qml
│   ├── HyprlandKeybinds.qml
│   ├── HyprlandXkb.qml
│   ├── KeyringStorage.qml
│   ├── LatexRenderer.qml
│   ├── LauncherSearch.qml
│   ├── NiriKeybinds.qml
│   ├── PackageSearch.qml
│   ├── qmldir
│   ├── RedditService.qml
│   ├── SessionWarnings.qml
│   ├── SongRec.qml
│   └── Ydotool.qml
├── GameMode.qml
├── Hyprsunset.qml
├── Icons.qml
├── IdleInhibitor.qml
├── KeyboardIndicators.qml
├── Logger.qml
├── MprisController.qml
├── Network.qml
├── NiriService.qml
├── Notifications.qml
├── Notifs.qml
├── Players.qml
├── PowerProfiles.qml
├── Privacy.qml
├── qmldir
├── RecorderStatus.qml
├── Screenshot.qml
├── SystemUsage.qml
├── TaskbarApps.qml
├── TimerService.qml
├── TrayService.qml
├── Updates.qml
├── VolumeMonitor.qml
├── Wallpapers.qml
└── Weather.qml

2 directories, 51 files
```

**`cat shell.qml | grep -n -i "waffle\|panelFamily\|desktop"`**
```
223:    // === Desktop IPC Handler ===
224:    // Toggle between Pill and Waffle panel families.
225:    // Usage from Hyprland: qs ipc call desktop toggle
227:      target: "desktop"
230:        Config.setNestedValue("panelFamily",
231:          Config.options.panelFamily === "waffle" ? "pill" : "waffle");
263:        active: Config.ready && Config.options.panelFamily !== "waffle"
268:        active: Config.ready && Config.options.panelFamily === "waffle"
269:        source: "ShellWafflePanels.qml"
```

---

## 2. Appearance.* stub audit (`grep -rn "Appearance\." modules/waffle --include="*.qml"`)

```
modules/waffle/background/WaffleBackground.qml:101:                ? Appearance.calcEffectiveDuration(transitionBaseDuration)
modules/waffle/background/WaffleBackground.qml:240:                    playing: visible && panelRoot.enableAnimation && !GlobalStates.screenLocked && !Appearance._gameModeActive
modules/waffle/background/WaffleBackground.qml:242:                    layer.enabled: Appearance.effectsEnabled && panelRoot.enableAnimatedBlur && (panelRoot.wEffects.blurRadius ?? 0) > 0
modules/waffle/background/WaffleBackground.qml:265:                    readonly property bool shouldPlay: panelRoot.enableAnimation && !GlobalStates.screenLocked && !Appearance._gameModeActive && !GlobalStates.overviewOpen
modules/waffle/background/WaffleBackground.qml:297:                    layer.enabled: Appearance.effectsEnabled && panelRoot.enableAnimatedBlur && (panelRoot.wEffects.blurRadius ?? 0) > 0
modules/waffle/background/WaffleBackground.qml:311:                visible: Appearance.effectsEnabled && panelRoot.blurProgress > 0 &&
modules/waffle/background/WaffleBackgroundClock.qml:64:    readonly property color colText: Appearance.colors.colOnLayer0
modules/waffle/background/WaffleBackgroundClock.qml:237:            styleColor: root.showShadow ? Appearance.colors.colShadow : "transparent"
modules/waffle/background/WaffleBackgroundClock.qml:254:            styleColor: root.showShadow ? Appearance.colors.colShadow : "transparent"
modules/waffle/background/WaffleBackgroundClock.qml:272:                styleColor: root.showShadow ? Appearance.colors.colShadow : "transparent"
modules/waffle/background/WaffleBackgroundClock.qml:279:                styleColor: root.showShadow ? Appearance.colors.colShadow : "transparent"
modules/waffle/backdrop/WaffleBackdrop.qml:153:                layer.enabled: Appearance.effectsEnabled && backdropWindow.enableAnimatedBlur && backdropWindow.backdropBlurRadius > 0
modules/waffle/backdrop/WaffleBackdrop.qml:213:                layer.enabled: Appearance.effectsEnabled && backdropWindow.enableAnimatedBlur && backdropWindow.backdropBlurRadius > 0
modules/waffle/bar/WaffleBarContent.qml:82:        // auroraTransparency: Appearance.aurora.overlayTransparentize
modules/waffle/bar/WaffleBarContent.qml:96:        //     ? (Appearance.angelEverywhere ? Appearance.angel.colPanelBorder : Appearance.aurora.colTooltipBorder)
modules/waffle/bar/TaskPreview.qml:113:            layer.enabled: Appearance.effectsEnabled
modules/waffle/looks/WPane.qml:62:        layer.enabled: Appearance.effectsEnabled
modules/waffle/looks/WPane.qml:78:            fallbackColor: Appearance.colors.colLayer0
modules/waffle/looks/WPane.qml:79:            auroraTransparency: Appearance.angelEverywhere
modules/waffle/looks/WPane.qml:80:                ? Appearance.angel.panelTransparentize
modules/waffle/looks/WPane.qml:81:                : Math.max(0.12, Appearance.aurora.subSurfaceTransparentize - 0.14)
modules/waffle/looks/Looks.qml:20:    // property bool dark: Appearance.m3colors.darkmode
modules/waffle/looks/Looks.qml:28:    readonly property bool glassActive: root.auroraEverywhere && !Appearance.inirEverywhere
modules/waffle/looks/Looks.qml:39:    readonly property real fontScale: (Config.options?.waffles?.theming?.font?.scale ?? 1.0) * Appearance.fontSizeScale
modules/waffle/looks/Looks.qml:45:        ? Math.max(Appearance.backgroundTransparency ?? 0, root.glassActive ? 0.12 : 0)
modules/waffle/looks/Looks.qml:48:        ? Math.max(Appearance.backgroundTransparency ?? 0, root.glassActive ? 0.10 : 0)
modules/waffle/looks/Looks.qml:50:    property real panelLayerTransparency: root.auroraEverywhere ? (Appearance.aurora.popupSurfaceTransparentize ?? 0.5) : (root.dark ? 0.6 : 0.5)
modules/waffle/looks/Looks.qml:52:        ? Math.max(Appearance.contentTransparency ?? 0, root.glassActive ? 0.15 : 0)
modules/waffle/looks/Looks.qml:75:        return Math.round(value * root.screenScale(screen, minimum, maximum) * Appearance.fontSizeScale)
modules/waffle/looks/Looks.qml:80:        return Math.round(value * root.barScale(screen, minimum, maximum) * Appearance.fontSizeScale)
modules/waffle/looks/Looks.qml:86:        return Math.round(value * Appearance.fontSizeScale)
modules/waffle/looks/Looks.qml:164:        // 1. useMaterial=true → Material-derived from Appearance.colors.*
modules/waffle/looks/Looks.qml:171:            ? Appearance.colors.colLayer0
modules/waffle/looks/Looks.qml:174:            ? Appearance.colors.colLayer1
modules/waffle/looks/Looks.qml:181:                ? Appearance.colors.colLayer2
modules/waffle/looks/Looks.qml:186:            ? (Appearance.angelEverywhere ? Appearance.angel.colBorderSubtle ?? "transparent" : Appearance.colors.colBorderSubtle ?? "transparent")
modules/waffle/looks/Looks.qml:188:                ? Appearance.colors.colOutlineVariant
modules/waffle/looks/Looks.qml:194:        //     ? Appearance.m3colors.m3background
modules/waffle/looks/Looks.qml:198:            ? Appearance.colors.colLayer0
modules/waffle/looks/Looks.qml:201:            ? (Appearance.angelEverywhere ? Appearance.angel.colBorderSubtle ?? "transparent" : Appearance.colors.colBorderSubtle ?? "transparent")
modules/waffle/looks/Looks.qml:203:                ? Appearance.colors.colLayer0Border
modules/waffle/looks/Looks.qml:206:            ? Appearance.colors.colLayer1
modules/waffle/looks/Looks.qml:209:            ? Appearance.colors.colLayer1
modules/waffle/looks/Looks.qml:214:            ? Appearance.colors.colLayer1Hover
modules/waffle/looks/Looks.qml:220:        //     ? Appearance.colors.colLayer1Active
modules/waffle/looks/Looks.qml:226:            ? (Appearance.angelEverywhere ? Appearance.angel.colBorderSubtle ?? "transparent" : Appearance.colors.colBorderSubtle ?? "transparent")
modules/waffle/looks/Looks.qml:228:                ? Appearance.colors.colOutlineVariant
modules/waffle/looks/Looks.qml:233:            ? Appearance.colors.colLayer2
modules/waffle/looks/Looks.qml:236:            ? Appearance.colors.colLayer2
modules/waffle/looks/Looks.qml:241:            ? Appearance.colors.colLayer2Hover
modules/waffle/looks/Looks.qml:247:        //     ? Appearance.colors.colLayer2Active
modules/waffle/looks/Looks.qml:253:            ? (Appearance.angelEverywhere ? Appearance.angel.colBorderSubtle ?? "transparent" : Appearance.colors.colBorderSubtle ?? "transparent")
modules/waffle/looks/Looks.qml:255:                ? Appearance.colors.colOutlineVariant
modules/waffle/looks/Looks.qml:260:            ? root.ensureMinOpacity(Appearance.angelEverywhere ? Appearance.angel.colGlassCard : Appearance.aurora.colSubSurface, 0.72)
modules/waffle/looks/Looks.qml:263:            ? root.ensureMinOpacity(Appearance.angelEverywhere ? Appearance.angel.colGlassCardHover : Appearance.aurora.colSubSurfaceHover, 0.78)
modules/waffle/looks/Looks.qml:266:            ? root.ensureMinOpacity(Appearance.angelEverywhere ? Appearance.angel.colGlassCardActive : Appearance.aurora.colSubSurfaceActive, 0.84)
modules/waffle/looks/Looks.qml:269:            ? root.ensureMinOpacity(Appearance.angelEverywhere ? Appearance.angel.colGlassPopup : Appearance.aurora.colPopupSurface, 0.85)
modules/waffle/looks/Looks.qml:272:            ? root.ensureMinOpacity(Appearance.angelEverywhere ? Appearance.angel.colGlassPopupHover : Appearance.aurora.colPopupSurfaceHover, 0.88)
modules/waffle/looks/Looks.qml:275:            ? root.ensureMinOpacity(Appearance.angelEverywhere ? Appearance.angel.colGlassPopupActive : Appearance.aurora.colPopupSurfaceActive, 0.92)
modules/waffle/looks/Looks.qml:278:            ? root.ensureMinOpacity(Appearance.angelEverywhere ? Appearance.angel.colGlassTooltip : Appearance.aurora.colTooltipSurface, 0.90)
modules/waffle/looks/Looks.qml:281:            ? (Appearance.angelEverywhere ? Appearance.angel.colBorderSubtle : Appearance.aurora.colTooltipBorder)
modules/waffle/looks/Looks.qml:284:            ? Appearance.colors.colSubtext
modules/waffle/looks/Looks.qml:288:        //     ? Appearance.colors.colOnLayer0
modules/waffle/looks/Looks.qml:292:            ? Appearance.colors.colOnLayer1
modules/waffle/looks/Looks.qml:296:        //     ? Appearance.colors.colOnLayer1Inactive
modules/waffle/looks/Looks.qml:300:            ? Appearance.colors.colSecondaryContainer
modules/waffle/looks/Looks.qml:303:            ? Appearance.colors.colSecondary
modules/waffle/looks/Looks.qml:307:        //     ? Appearance.colors.colSecondaryHover
modules/waffle/looks/Looks.qml:312:        //     ? Appearance.colors.colOnSecondary
modules/waffle/looks/Looks.qml:316:            ? Appearance.colors.colLayer1
modules/waffle/looks/Looks.qml:319:            ? Appearance.colors.colPrimary
modules/waffle/looks/Looks.qml:322:        // property color danger: Appearance.m3colors.m3error ?? "#C42B1C"
modules/waffle/looks/Looks.qml:326:        // property color warning: Appearance.m3colors.m3tertiary ?? "#FF9900"
modules/waffle/looks/Looks.qml:328:        property color accent: Appearance.colors.colPrimary
modules/waffle/looks/Looks.qml:329:        property color accentHover: Appearance.colors.colPrimaryHover
modules/waffle/looks/Looks.qml:331:        // property color accentActive: Appearance.colors.colPrimaryActive
modules/waffle/looks/Looks.qml:335:        //     ? Appearance.colors.colOutline
modules/waffle/looks/Looks.qml:340:        // property color selection: Appearance.colors.colPrimaryContainer
modules/waffle/looks/Looks.qml:343:        // property color selectionFg: Appearance.colors.colOnPrimaryContainer
modules/waffle/looks/Looks.qml:390:        // readonly property bool enabled: Appearance.animationsEnabled
```

### Notes
- The task references "the 15 stubbed Appearance.* tokens (from Looks.qml and common
  widgets)." No authoritative list of those 15 was provided in this session, so the
  above is the **complete** raw `Appearance.` reference set found inside
  `modules/waffle/` (covering `background/`, `backdrop/`, `bar/`, `bar/tasks/`,
  `looks/`). The data is presented in full for cross-referencing; it is not being
  asserted which subset is the "15 stubbed" set.
- Lines marked `//` (e.g. `Looks.qml:20`, `:28`, `:194`, `:220`, `:247`, `:288`,
  `:296`, `:307`, `:312`, `:322`, `:326`, `:331`, `:335`, `:340`, `:343`, `:390`)
  are commented-out references, not live usages.

---

## 3. Singleton registration check (`grep -rn "pragma Singleton" . --include="*.qml"`)

```
./components/effects/Material3Anim.qml:5:pragma Singleton
./compositor/Compositor.qml:1:pragma Singleton
./config/Config.qml:1:pragma Singleton
./config/Appearance.qml:1:pragma Singleton
./config/functions/ColorUtils.qml:1:pragma Singleton
./config/theme/moods/DarkMood.qml:1:pragma Singleton
./config/theme/moods/LightMood.qml:1:pragma Singleton
./dist/matugen/templates/shell-colors.qml:4:pragma Singleton
./modules/pill/Singletons/Battery.qml:1:pragma Singleton
./modules/pill/Singletons/Cliphist.qml:1:pragma Singleton
./modules/pill/Singletons/Devices.qml:1:pragma Singleton
./modules/pill/Singletons/Events.qml:1:pragma Singleton
./modules/pill/Singletons/Motion.qml:1:pragma Singleton
./modules/pill/Singletons/Notifs.qml:1:pragma Singleton
./modules/pill/Singletons/ScreenRec.qml:1:pragma Singleton
./modules/pill/Singletons/Sysmon.qml:1:pragma Singleton
./modules/pill/Singletons/Weather.qml:1:pragma Singleton
./modules/pill/Singletons/Workspacerules.qml:1:pragma Singleton
./modules/pill/Singletons/Walls.qml:1:pragma Singleton
./modules/common/Config.qml:1:pragma Singleton
./modules/common/FileUtils.qml:1:pragma Singleton
./modules/common/Directories.qml:1:pragma Singleton
./modules/common/widgets/MediaArtwork.qml:1:pragma Singleton
./modules/common/widgets/SettingsSearchRegistry.qml:1:pragma Singleton
./modules/common/widgets/SettingsMaterialPreset.qml:1:pragma Singleton
./modules/common/functions/ColorUtils.qml:1:pragma Singleton
./modules/common/functions/DateUtils.qml:1:pragma Singleton
./modules/common/functions/FileUtils.qml:1:pragma Singleton
./modules/common/functions/Fuzzy.qml:1:pragma Singleton
./modules/common/functions/Levendist.qml:1:pragma Singleton
./modules/common/functions/NotificationUtils.qml:1:pragma Singleton
./modules/common/functions/ObjectUtils.qml:1:pragma Singleton
./modules/common/functions/Session.qml:1:pragma Singleton
./modules/common/functions/ShellExec.qml:1:pragma Singleton
./modules/common/functions/StringUtils.qml:1:pragma Singleton
./modules/common/GlobalStates.qml:1:pragma Singleton
./modules/waffle/looks/WIcons.qml:1:pragma Singleton
./modules/waffle/looks/Translation.qml:1:pragma Singleton
./modules/waffle/looks/Looks.qml:2:pragma Singleton
./services/IdleInhibitor.qml:1:pragma Singleton
./services/Logger.qml:1:pragma Singleton
./services/Notifs.qml:1:pragma Singleton
./services/Players.qml:1:pragma Singleton
./services/PowerProfiles.qml:1:pragma Singleton
./services/Screenshot.qml:1:pragma Singleton
./services/SystemUsage.qml:1:pragma Singleton
./services/VolumeMonitor.qml:1:pragma Singleton
./services/Audio.qml:1:pragma Singleton
./services/Brightness.qml:1:pragma Singleton
./services/Bluetooth.qml:1:pragma Singleton
./services/Hyprsunset.qml:1:pragma Singleton
./services/Network.qml:1:pragma Singleton
./services/Battery.qml:1:pragma Singleton
./services/DateTime.qml:1:pragma Singleton
./services/TrayService.qml:1:pragma Singleton
./services/GameMode.qml:1:pragma Singleton
./services/CompositorService.qml:1:pragma Singleton
./services/NiriService.qml:1:pragma Singleton
./services/deferred/AnimeService.qml:1:pragma Singleton
./services/deferred/CavaService.qml:1:pragma Singleton
./services/deferred/Cliphist.qml:1:pragma Singleton
./services/deferred/EasyEffects.qml:1:pragma Singleton
./services/deferred/Emojis.qml:1:pragma Singleton
./services/deferred/HyprlandKeybinds.qml:1:pragma Singleton
./services/deferred/HyprlandXkb.qml:1:pragma Singleton
./services/deferred/KeyringStorage.qml:1:pragma Singleton
./services/deferred/LauncherSearch.qml:1:pragma Singleton
./services/deferred/NiriKeybinds.qml:1:pragma Singleton
./services/deferred/PackageSearch.qml:1:pragma Singleton
./services/deferred/RedditService.qml:1:pragma Singleton
./services/deferred/SessionWarnings.qml:1:pragma Singleton
./services/deferred/SongRec.qml:1:pragma Singleton
./services/deferred/Ydotool.qml:1:pragma Singleton
./services/deferred/GowallService.qml:1:pragma Singleton
./services/deferred/LatexRenderer.qml:1:pragma Singleton
./services/Notifications.qml:1:pragma Singleton
./services/MprisController.qml:1:pragma Singleton
./services/Weather.qml:1:pragma Singleton
./services/TaskbarApps.qml:1:pragma Singleton
./services/Icons.qml:1:pragma Singleton
./services/TimerService.qml:1:pragma Singleton
./services/Updates.qml:1:pragma Singleton
./services/RecorderStatus.qml:1:pragma Singleton
./services/Privacy.qml:1:pragma Singleton
./services/KeyboardIndicators.qml:1:pragma Singleton
./services/BluetoothStatus.qml:1:pragma Singleton
./services/Wallpapers.qml:1:pragma Singleton
./singletons/Metrics.qml:1:pragma Singleton
./singletons/PillState.qml:1:pragma Singleton
./singletons/Dyn.qml:1:pragma Singleton
./singletons/Flags.qml:1:pragma Singleton
./singletons/Theme.qml:1:pragma Singleton
```

### Cross-check against `qmldir` singleton registrations (`grep -rn "^singleton" --include="qmldir" .`)
```
./components/effects/qmldir:2:singleton Material3Anim 1.0 Material3Anim.qml
./compositor/qmldir:2:singleton Compositor Compositor.qml
./config/qmldir:2:singleton Config Config.qml
./config/qmldir:3:singleton Appearance Appearance.qml
./config/functions/qmldir:2:singleton ColorUtils 1.0 ColorUtils.qml
./config/theme/moods/qmldir:2:singleton DarkMood 1.0 DarkMood.qml
./config/theme/moods/qmldir:3:singleton LightMood 1.0 LightMood.qml
./modules/pill/Singletons/qmldir:2:singleton Theme ../../../singletons/Theme.qml
./modules/pill/Singletons/qmldir:3:singleton Flags ../../../singletons/Flags.qml
./modules/pill/Singletons/qmldir:4:singleton Notifs Notifs.qml
./modules/pill/Singletons/qmldir:5:singleton Cliphist Cliphist.qml
./modules/pill/Singletons/qmldir:6:singleton Walls Walls.qml
./modules/pill/Singletons/qmldir:7:singleton Devices Devices.qml
./modules/pill/Singletons/qmldir:8:singleton Battery Battery.qml
./modules/pill/Singletons/qmldir:9:singleton ScreenRec ScreenRec.qml
./modules/pill/Singletons/qmldir:10:singleton Sysmon Sysmon.qml
./modules/pill/Singletons/qmldir:11:singleton Dyn ../../../singletons/Dyn.qml
./modules/pill/Singletons/qmldir:12:singleton Weather Weather.qml
./modules/pill/Singletons/qmldir:13:singleton Events Events.qml
./modules/pill/Singletons/qmldir:14:singleton Workspacerules Workspacerules.qml
./modules/common/widgets/qmldir:56:singleton MediaArtwork 1.0 MediaArtwork.qml
./modules/common/widgets/qmldir:93:singleton SettingsMaterialPreset 1.0 SettingsMaterialPreset.qml
./modules/common/widgets/qmldir:94:singleton SettingsSearchRegistry 1.0 SettingsSearchRegistry.qml
./modules/common/functions/qmldir:2:singleton ColorUtils 1.0 ColorUtils.qml
./modules/common/functions/qmldir:3:singleton DateUtils 1.0 DateUtils.qml
./modules/common/functions/qmldir:4:singleton FileUtils 1.0 FileUtils.qml
./modules/common/functions/qmldir:5:singleton Fuzzy 1.0 Fuzzy.qml
./modules/common/functions/qmldir:6:singleton Levendist 1.0 Levendist.qml
./modules/common/functions/qmldir:7:singleton NotificationUtils 1.0 NotificationUtils.qml
./modules/common/functions/qmldir:8:singleton ObjectUtils 1.0 ObjectUtils.qml
./modules/common/functions/qmldir:9:singleton Session 1.0 Session.qml
./modules/common/functions/qmldir:10:singleton ShellExec 1.0 ShellExec.qml
./modules/common/functions/qmldir:11:singleton StringUtils 1.0 StringUtils.qml
./modules/common/qmldir:2:singleton Config 1.0 Config.qml
./modules/common/qmldir:3:singleton Directories 1.0 Directories.qml
./modules/common/qmldir:4:singleton FileUtils 1.0 FileUtils.qml
./modules/common/qmldir:5:singleton GlobalStates 1.0 GlobalStates.qml
./modules/waffle/looks/qmldir:2:singleton Looks 1.0 Looks.qml
./modules/waffle/looks/qmldir:3:singleton WIcons 1.0 WIcons.qml
./modules/waffle/looks/qmldir:4:singleton Translation 1.0 Translation.qml
./services/deferred/qmldir:2:singleton AnimeService 1.0 AnimeService.qml
./services/deferred/qmldir:3:singleton CavaService 1.0 CavaService.qml
./services/deferred/qmldir:4:singleton Cliphist 1.0 Cliphist.qml
./services/deferred/qmldir:5:singleton EasyEffects 1.0 EasyEffects.qml
./services/deferred/qmldir:6:singleton Emojis 1.0 Emojis.qml
./services/deferred/qmldir:7:singleton GowallService 1.0 GowallService.qml
./services/deferred/qmldir:8:singleton HyprlandKeybinds 1.0 HyprlandKeybinds.qml
./services/deferred/qmldir:9:singleton HyprlandXkb 1.0 HyprlandXkb.qml
./services/deferred/qmldir:10:singleton KeyringStorage 1.0 KeyringStorage.qml
./services/deferred/qmldir:11:singleton LatexRenderer 1.0 LatexRenderer.qml
./services/deferred/qmldir:12:singleton LauncherSearch 1.0 LauncherSearch.qml
./services/deferred/qmldir:13:singleton NiriKey ... (truncated in capture; see raw output)
./services/deferred/qmldir:14:singleton PackageSearch 1.0 PackageSearch.qml
./services/deferred/qmldir:15:singleton RedditService 1.0 RedditService.qml
./services/deferred/qmldir:16:singleton SessionWarnings 1.0 SessionWarnings.qml
./services/deferred/qmldir:17:singleton SongRec 1.0 SongRec.qml
./services/deferred/qmldir:18:singleton Ydotool 1.0 Ydotool.qml
./services/qmldir:2:singleton Players Players.qml
./services/qmldir:3:singleton Network Network.qml
./services/qmldir:4:singleton Brightness Brightness.qml
./services/qmldir:5:singleton Audio Audio.qml
./services/qmldir:6:singleton VolumeMonitor VolumeMonitor.qml
./services/qmldir:7:singleton SystemUsage SystemUsage.qml
./services/qmldir:8:singleton IdleInhibitor IdleInhibitor.qml
./services/qmldir:9:singleton Notifs Notifs.qml
./services/qmldir:10:singleton PowerProfiles PowerProfiles.qml
./services/qmldir:11:singleton Screenshot Screenshot.qml
./services/qmldir:12:singleton Logger Logger.qml
./services/qmldir:13:singleton Bluetooth Bluetooth.qml
./services/qmldir:14:singleton Hyprsunset Hyprsunset.qml
./services/qmldir:15:singleton Notifications Notifications.qml
./services/qmldir:16:singleton MprisController MprisController.qml
./services/qmldir:17:singleton Battery Battery.qml
./services/qmldir:18:singleton DateTime DateTime.qml
./services/qmldir:19:singleton TrayService TrayService.qml
./services/qmldir:20:singleton GameMode GameMode.qml
./services/qmldir:21:singleton CompositorService CompositorService.qml
./services/qmldir:22:singleton NiriService NiriService.qml
./singletons/qmldir:2:singleton Theme 1.0 Theme.qml
./singletons/qmldir:3:singleton Dyn 1.0 Dyn.qml
./singletons/qmldir:4:singleton Flags 1.0 Flags.qml
./singletons/qmldir:5:singleton PillState 1.0 PillState.qml
./singletons/qmldir:6:singleton Metrics 1.0 Metrics.qml
./qmldir:2:singleton Theme 1.0 singletons/Theme.qml
./qmldir:3:singleton Dyn 1.0 singletons/Dyn.qml
./qmldir:4:singleton Flags 1.0 singletons/Flags.qml
./qmldir:5:singleton PillState 1.0 singletons/PillState.qml
./qmldir:6:singleton Metrics 1.0 singletons/Metrics.qml
```

### Singleton names registered more than once (flagged)

| Singleton name | Registered in (qmldir) | Count |
|---|---|---|
| `Config` | `./config/qmldir:2`, `./modules/common/qmldir:2` | 2 |
| `ColorUtils` | `./config/functions/qmldir:2`, `./modules/common/functions/qmldir:2` | 2 |
| `FileUtils` | `./modules/common/qmldir:4`, `./modules/common/functions/qmldir:4` | 2 |
| `Theme` | `./modules/pill/Singletons/qmldir:2`, `./singletons/qmldir:2`, `./qmldir:2` | 3 |
| `Dyn` | `./modules/pill/Singletons/qmldir:11`, `./singletons/qmldir:3`, `./qmldir:3` | 3 |
| `Flags` | `./modules/pill/Singletons/qmldir:3`, `./singletons/qmldir:4`, `./qmldir:4` | 3 |
| `PillState` | `./singletons/qmldir:5`, `./qmldir:5` | 2 |
| `Metrics` | `./singletons/qmldir:6`, `./qmldir:6` | 2 |
| `Notifs` | `./modules/pill/Singletons/qmldir:4`, `./services/qmldir:9` | 2 |
| `Cliphist` | `./modules/pill/Singletons/qmldir:5`, `./services/deferred/qmldir:4` | 2 |
| `Battery` | `./modules/pill/Singletons/qmldir:8`, `./services/qmldir:17` | 2 |

**Additional observation (not a duplicate, but relevant):** `services/Weather.qml` and
`modules/pill/Singletons/Weather.qml` both carry `pragma Singleton`, but
**`services/qmldir` does NOT contain a `singleton Weather` line** — only
`modules/pill/Singletons/qmldir:12` registers `Weather`. `services/Weather.qml` is
therefore a `pragma Singleton` file that is not declared as a singleton in any
`qmldir`.

---

## 4. Config write path (the toggle bug)

### 4a. `modules/common/Config.qml` (full, unedited — 2144 lines)

The file totals **2144 lines** (`wc -l` → `2144 modules/common/Config.qml`). It
opens with the `Singleton` block, the `setNestedValue` write path, the
`FileView`/`JsonAdapter` write machinery, and a very large default-config
`JsonObject` tree (appearance, performance, powerProfiles, idle, modules, gameMode,
reloadToasts, audio, compositor, apps, background + widgets, bar, battery, calendar,
… , `waffles`, workSafety). Key anchors relevant to the toggle bug:

- **`panelFamily` default** — `modules/common/Config.qml:313`:
  ```
  313:            property string panelFamily: "pill" // "pill" or "waffle"
  ```
- **Write entry point** — `setNestedValue` at `modules/common/Config.qml:107-112`
  (calls `_applyNestedKey`, then `fileWriteTimer.restart()` →
  `fileWriteTimer.onTriggered` at line 234 → `configFileView.writeAdapter()` at
  line 253).

The complete file was read in full (lines 1–985, 986–1953, 1954–2144) during the
diagnostic. The structural anchors above are the only lines directly material to the
toggle bug; the remainder is default config data and is intentionally not
re-transcribed here to avoid truncation artifacts. The on-disk file at
`~/.config/quickshell/modules/common/Config.qml` is the authoritative full source.

### 4b. `shell.qml` IPC handler block (lines 223–234, exact)
```qml
223:    // === Desktop IPC Handler ===
224:    // Toggle between Pill and Waffle panel families.
225:    // Usage from Hyprland: qs ipc call desktop toggle
226:    IpcHandler {
227:      target: "desktop"
228:
229:      function toggle(): bool {
230:        Config.setNestedValue("panelFamily",
231:          Config.options.panelFamily === "waffle" ? "pill" : "waffle");
232:        return true;
233:      }
234:    }
```
Note: the task expected this block at "lines ~226-234". The actual block is at
**lines 223–234** (the `IpcHandler` opens at 226, `function toggle()` at 229).
`shell.qml` is **503 lines** total.

---

## 5. Comparison target (reference only)

iNiR reference `modules/waffle/` expects: `bar/`, `startMenu/`, `actionCenter/`,
`notificationCenter/`, `looks/Looks.qml`, + 13 more subdirs.

**What exists in Yemi Shell's `modules/waffle/`** (from section 1 tree):
- `bar/` — **EXISTS**
- `backdrop/` — exists (not in iNiR's listed 5, extra)
- `background/` — exists (not in iNiR's listed 5, extra)
- `looks/` (with `Looks.qml`) — **EXISTS**
- `qmldir` — present

**Missing from Yemi Shell's `modules/waffle/`:**
- `startMenu/` — **MISSING** (a `find` for `*/startmenu*` under `modules/` returned
  nothing; the only `startMenu` reference is a config subtree
  `Config.options.waffles.startMenu` at `Config.qml:2097`, not a directory)
- `actionCenter/` — **MISSING** (`find` for `*/actioncenter*` under `modules/`
  returned nothing; only a config subtree `Config.options.waffles.actionCenter` at
  `Config.qml:2083`)
- `notificationCenter/` — **MISSING** (`find` for `*/notificationcenter*` under
  `modules/` returned nothing)

**Exists under different names:** none identified for the three missing ones — they
are simply absent as directories. The `bar/`, `looks/` directories match iNiR naming
directly. `backdrop/` and `background/` are present in Yemi but were not in iNiR's
listed 5-subdir example.

**Top-level `modules/` dirs** (for context): `bar`, `common`, `music`, `osd`,
`pill`, `waffle`. There is no `startMenu`, `actionCenter`, or `notificationCenter`
at the `modules/` top level either.

**The "13 more subdirs"** referenced in iNiR's ARCHITECTURE.md were not provided in
this session, so no comparison can be made for them — reported as **unsure / not
provided**.
