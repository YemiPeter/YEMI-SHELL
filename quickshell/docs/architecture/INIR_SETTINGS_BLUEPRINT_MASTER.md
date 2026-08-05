# iNiR Settings System Master Blueprint

> Repository: `/home/yemi/iNiR`
> Discovered by: codebase archaeology
> Date: 2026-08-05

---

## Table of Contents

1. [Repository Overview](#1-repository-overview)
2. [Architecture Summary](#2-architecture-summary)
3. [Configuration File (`defaults/config.json`)](#3-configuration-files)
4. [Config Singleton (`modules/common/Config.qml`)](#4-config-singleton)
5. [Services System](#5-services-system)
6. [IPC Targets](#6-ipc-targets)
7. [Panel Families](#7-panel-families)
8. [Shell Entry Point (`shell.qml`)](#8-shell-entry-point)
9. [Module Import Patterns](#9-module-import-patterns)
10. [Config-to-Service Consumption](#10-config-to-service-consumption)

---

## 1. Repository Overview

### Repository Path

```
/home/yemi/iNiR
```

> Note: The repository is located at `/home/yemi/iNiR` (not `~/INIR` as initially referenced in some documents).

### Directory Structure

```
iNiR/
├── shell.qml                          # Shell entry point — Quickshell shim
├── ARCHITECTURE.md                    # Architecture documentation
├── defaults/
│   └── config.json                    # Default configuration (60 top-level sections)
├── modules/
│   ├── common/
│   │   ├── Config.qml                 # Config singleton (~2000+ lines)
│   │   └── GlobalStates.qml           # Global state management
│   ├── altSwitcher/
│   ├── background/
│   ├── bar/
│   ├── cheatsheet/
│   ├── clipboard/
│   ├── closeConfirm/
│   ├── controlPanel/
│   ├── ii/
│   │   └── overlay/
│   ├── lock/
│   ├── mediaControls/
│   ├── onScreenDisplay/
│   ├── onScreenKeyboard/
│   ├── overview/
│   ├── recordingOsd/
│   ├── regionSelector/
│   ├── sessionScreen/
│   ├── settings/
│   ├── sidebarLeft/
│   ├── sidebarRight/
│   ├── tilingOverlay/
│   ├── verticalBar/
│   ├── wallpaperSelector/
│   └── waffle/                        # Waffle (Fluent) panel family
│       ├── actionCenter/
│       ├── altSwitcher/
│       ├── bar/
│       ├── clipboard/
│       ├── notificationCenter/
│       ├── onScreenDisplay/
│       ├── sessionScreen/
│       ├── startMenu/
│       ├── taskview/
│       └── widgets/
├── services/
│   ├── qmldir                         # Service registry (50 services)
│   ├── Ai.qml
│   ├── AppCatalog.qml
│   ├── AppLauncher.qml
│   ├── AppSearch.qml
│   ├── Audio.qml
│   ├── Autostart.qml
│   ├── AwwwBackend.qml
│   ├── Battery.qml
│   ├── BluetoothStatus.qml
│   ├── Booru.qml
│   ├── Brightness.qml
│   ├── CalendarSync.qml
│   ├── CavaTheme.qml
│   ├── CompositorService.qml
│   ├── ConflictKiller.qml
│   ├── CustomWidgets.qml
│   ├── DateTime.qml
│   ├── Events.qml
│   ├── FirstRunExperience.qml
│   ├── FontSyncService.qml
│   ├── GameMode.qml
│   ├── GlobalActions.qml
│   ├── HyprlandData.qml
│   ├── Hyprsunset.qml
│   ├── IconThemeService.qml
│   ├── Idle.qml
│   ├── KeyboardIndicators.qml
│   ├── MaterialThemeLoader.qml
│   ├── MemoryPressureService.qml
│   ├── MinimizedWindows.qml
│   ├── MprisController.qml
│   ├── Network.qml
│   ├── NiriService.qml
│   ├── Notepad.qml
│   ├── Notifications.qml
│   ├── PolkitService.qml
│   ├── PowerProfilePersistence.qml
│   ├── Privacy.qml
│   ├── RecorderStatus.qml
│   ├── ResourceUsage.qml
│   ├── ScreenTime.qml
│   ├── ShellUpdates.qml
│   ├── SystemInfo.qml
│   ├── TaskbarApps.qml
│   ├── ThemeService.qml
│   ├── TimerService.qml
│   ├── Todo.qml
│   ├── Translation.qml
│   ├── TrayService.qml
│   ├── Updates.qml
│   ├── VoiceSearch.qml
│   ├── Wallhaven.qml
│   ├── WallpaperListener.qml
│   ├── Wallpapers.qml
│   ├── Weather.qml
│   ├── WidgetPowerManager.qml
│   ├── WindowPreviewService.qml
│   ├── YtMusic.qml
│   └── deferred/
│       ├── qmldir                     # Deferred service registry (20 services)
│       ├── AnimeService.qml
│       ├── CavaService.qml
│       ├── Cliphist.qml
│       ├── EasyEffects.qml
│       ├── Emojis.qml
│       ├── GowallService.qml
│       ├── HyprlandKeybinds.qml
│       ├── HyprlandXkb.qml
│       ├── KeyringStorage.qml
│       ├── LatexRenderer.qml
│       ├── LauncherSearch.qml
│       ├── NiriKeybinds.qml
│       ├── PackageSearch.qml
│       ├── RedditService.qml
│       ├── SessionWarnings.qml
│       ├── SongRec.qml
│       └── Ydotool.qml
├── services/
│   └── (also contains HyprlandData.qml, HyprlandService.qml, HyprlandXkb.qml directly — not in qmldir)
└── docs/
    └── IPC.md                         # IPC documentation
```

### Total Service Count

- **Services directory (eager-loaded)**: 50 services
- **Services/deferred directory**: 20 services
- **Total**: 74 service files
- **IPC Handlers**: 18 in service files + 22 in module files + 2 in shell.qml = 42 total IPC handler declarations

---

## 2. Architecture Summary

### Framework

- **Quickshell**: QML-based Linux shell framework (not Plasma)
- **Shell ID**: `inir` (declared in `shell.qml` via pragma)
- **QML Import Style**: `import qs.modules.common`, `import qs.services`, etc. (Quickshell's `qs.` prefix)

### Panel Families

- **`ii`** (Material style): Default panel family
- **`waffle`** (Fluent style): Alternative panel family
- Switching is handled dynamically via `Config.setNestedValue("enabledPanels", ...)` in `shell.qml`

### Configuration System

- **Default config**: `defaults/config.json` (60 top-level sections)
- **User config**: `~/.config/illogical-impulse/config.json` (overrides defaults)
- **Config singleton**: `modules/common/Config.qml` (~2000+ lines)
  - Key methods: `setNestedValue()`, `_writeMirrorToDisk()`
  - Provides `Config.options` object for runtime access to config values

### IPC System

- **IpcHandler**: Quickshell mechanism for CLI control via `inir` command
- **Target names**: String-based endpoints (e.g., `"ai"`, `"appCatalog"`, `"audio"`)
- IPC handlers exist in both service files and module files

---

## 3. Configuration File

### File: `defaults/config.json`

Contains **60 top-level sections**. Each section is a dictionary (dict) or scalar.

#### Complete Section Listing

| # | Section | Type | Description |
|---|---------|------|-------------|
| 1 | `ai` | dict | AI assistant settings (`extraModels`, `systemPrompt`, `tool`) |
| 2 | `altSwitcher` | dict | Alt+Tab switcher appearance (`preset`, `noVisualUi`, `animationDurationMs`, `backgroundOpacity`, `blurAmount`, `compactStyle`, `enableAnimation`, `enableBlurGlass`, `monochromeIcons`, `panelAlignment`, `scrimDim`, `showOverviewWhileSwitching`, `useMostRecentFirst`, `useM3Layout`, `autoHideDelayMs`) |
| 3 | `appearance` | dict | Theme and visual appearance. Sub-keys: `globalStyle`, `aurora`, `angelSubStyle`, `extraBackgroundTint`, `softenColors`, `fakeScreenRounding`, `recentThemes`, `favoriteThemes`, `globalStyleCornerStyles`, `themeSchedule`, `cava`, `palette`, `angel`, `transparency`, `wallpaperTheming`, `typography`, `shellScale`, `iconTheme`, `dockIconTheme`, `desaturation` |
| 4 | `apps` | dict | Application paths (`bluetooth`, `browser`, `discord`, `manageUser`, `network`, `networkEthernet`, `taskManager`, `terminal`, `volumeMixer`, `update`) |
| 5 | `audio` | dict | Audio protection settings (`protection`) |
| 6 | `compositor` | dict | Compositor settings (`autoExpandSingleTilingWindow`) |
| 7 | `background` | dict | Wallpaper and background. Sub-keys: `backdrop`, `enableAnimation`, `effects`, `hideWhenFullscreen`, `parallax`, `thumbnailPath`, `wallpaperPath`, `pan`, `autoWallpaper`, `backend`, `transition`, `widgets`, `multiMonitor`, `wallpapersByMonitor`, `hideUpscaleNotification` |
| 8 | `bar` | dict | Bar panel settings. Sub-keys: `activeWindow`, `autoHide`, `borderless`, `bottom`, `cornerStyle`, `customRounding`, `floatStyleShadow`, `height`, `indicators`, `modules`, `opacity`, `layout`, `resources`, `screenList`, `showBackground`, `showScrollHints`, `leftScrollAction`, `rightScrollAction`, `topLeftIcon`, `tray`, `utilButtons`, `verbose`, `vertical`, `weather`, `workspaces` |
| 9 | `battery` | dict | Battery thresholds (`automaticSuspend`, `critical`, `full`, `low`, `notifyFull`, `suspend`, `chargeLimit`) |
| 10 | `calendar` | dict | Calendar (`externalSync`, `showUpcoming`, `upcomingDays`) |
| 11 | `closeConfirm` | dict | Close confirmation (`enabled`) |
| 12 | `conflictKiller` | dict | Conflict killer (`autoKillNotificationDaemons`, `autoKillTray`) |
| 13 | `crosshair` | dict | Crosshair (`code`) |
| 14 | `display` | dict | Display (`primaryMonitor`) |
| 15 | `dock` | dict | Dock settings. Sub-keys: `enable`, `enableBlurGlass`, `height`, `hoverRegionHeight`, `hoverToReveal`, `ignoredAppRegexes`, `monochromeIcons`, `pinnedApps`, `pinnedOnStartup`, `screenList`, `showBackground`, `iconSize`, `separatePinnedFromRunning`, `enableDragReorder`, `style` |
| 16 | `controlPanel` | dict | Control panel UI (`keepLoaded`, `compactMode`, `showMediaSection`, `showWeatherSection`, `showWallpaperSection`, `showSystemSection`, `showSlidersSection`, `showQuickActionsSection`, `showWallpaperSchemeChips`) |
| 17 | `settingsUi` | dict | Settings overlay (`overlayMode`, `easyMode`, `overlayAppearance`) |
| 18 | `hacks` | dict | Developer hacks (`arbitraryRaceConditionDelay`) |
| 19 | `interactions` | dict | Interaction settings (`deadPixelWorkaround`, `scrolling`) |
| 20 | `language` | dict | Localization (`translator`, `ui`) |
| 21 | `light` | dict | Light/ambient settings (`antiFlashbang`, `night`) |
| 22 | `lock` | dict | Lock screen. Sub-keys: `blur`, `centerClock`, `clock`, `dim`, `launchOnStartup`, `materialShapeChars`, `enableAnimation`, `notifications`, `security`, `showLockedText`, `status`, `useHyprlock`, `widgets` |
| 23 | `media` | dict | Media controls (`filterDuplicatePlayers`, `screenList`) |
| 24 | `musicRecognition` | dict | Music recognition (`interval`, `timeout`) |
| 25 | `networking` | dict | Network (`userAgent`) |
| 26 | `notifications` | dict | Notification popup position & timeouts (`edgeMargin`, `maxPopupLifetime`, `position`, `screenList`, `timeout`, `timeoutCritical`, `timeoutLow`, `timeoutNormal`) |
| 27 | `osd` | dict | On-screen display (`mediaEnabled`, `screenList`, `timeout`) |
| 28 | `osk` | dict | On-screen keyboard (`layout`, `pinnedOnStartup`, `keepOnTop`) |
| 29 | `overlay` | dict | Overlay panel (`animationDurationMs`, `backgroundOpacity`, `clickthroughOpacity`, `darkenScreen`, `floatingImage`, `openingZoomAnimation`, `recorder`, `scrimAnimationDurationMs`, `scrimDim`) |
| 30 | `overview` | dict | Workspace overview. Sub-keys: `activeScreenOnly`, `allAppsGrid`, `allAppsGridMode`, `backgroundBlurEnable`, `backgroundBlurRadius`, `backgroundDim`, `bottomMargin`, `centerIcons`, `columns`, `enable`, `focusAnimationDurationMs`, `focusAnimationEnable`, `iconMaxSize`, `iconMinSize`, `keepOverviewOpenOnWindowClick`, `maxPanelWidthRatio`, `respectBar`, `rows`, `scale`, `scrimDim`, `scrollWorkspaceSteps`, `showWorkspaceNumbers`, `switchToWorkspaceOnOpen`, `switchWorkspaceIndex`, `topMargin`, `windowTileMargin`, `workspaceSpacing` |
| 31 | `performance` | dict | Performance (`lowPower`, `reduceAnimations`) |
| 32 | `policies` | dict | Policies (`ai`, `weeb`) |
| 33 | `regionSelector` | dict | Region selector (`circle`, `rect`, `targetRegions`, `annotation`) |
| 34 | `resources` | dict | Resource monitoring (`updateInterval`, `monitorGpu`) |
| 35 | `search` | dict | Search engine (`engineBaseUrl`, `excludedSites`, `imageSearch`, `nonAppResultDelay`, `prefix`, `sloppy`, `globalActions`) |
| 36 | `sidebar` | dict | Sidebar widgets. Sub-keys: `ai`, `booru`, `cornerOpen`, `keepRightSidebarLoaded`, `instantOpen`, `animationType`, `layout`, `quickSliders`, `quickToggles`, `right`, `screenTime`, `translator`, `tools`, `software`, `plugins`, `ytmusic`, `wallhaven`, `animeSchedule`, `reddit`, `widgets` |
| 37 | `sounds` | dict | Sound settings (`battery`, `notifications`, `pomodoro`, `theme`) |
| 38 | `time` | dict | Time format (`dateFormat`, `format`, `pomodoro`, `secondPrecision`, `shortDateFormat`) |
| 39 | `wallpaperSelector` | dict | Wallpaper selector (`selectionTarget`, `style`, `coverflowView`, `targetMonitor`, `useSystemFileDialog`, `animatePreview`) |
| 40 | `screenRecord` | dict | Screen recording. Sub-keys: `recordingOsd`, `showOsd`, `showNotifications`, `savePath`, `qualityPreset`, `videoCodec`, `audioCodec`, `accelerationMode`, `hardwareDevice`, `fps`, `videoBitrateKbps`, `audioBitrateKbps`, `audioSource`, `audioBackend`, `audioSampleRate`, `pixelFormat`, `preset`, `crf`, `vaapiFilter`, `enableFallback`, `discordCompress` |
| 41 | `windows` | dict | Window titlebars (`centerTitle`, `showTitlebar`) |
| 42 | `workSafety` | dict | Work safety (`enable`, `triggerCondition`) |
| 43 | `idle` | dict | Idle actions (`screenOffTimeout`, `lockTimeout`, `suspendTimeout`, `lockBeforeSleep`) |
| 44 | `gameMode` | dict | Game mode. Sub-keys: `autoDetect`, `disableAnimations`, `disableEffects`, `disableNiriAnimations`, `disableReloadToasts`, `disableDiscoverOverlay`, `suppressNotifications`, `checkInterval`, `minimalMode`, `niriWindowListUpdateIntervalMs`, `niriWindowListUpdateIntervalMsGameMode` |
| 45 | `hotspot` | dict | Hotspot connection (`ssid`, `password`, `band`) |
| 46 | `keyboardIndicators` | dict | Keyboard indicator UI (`showPopup`, `showPanel`, `popup`, `panel`) |
| 47 | `reloadToasts` | dict | Reload toast settings (`enable`) |
| 48 | `modules` | dict | Panel module toggles. Sub-keys: `bar`, `background`, `cheatsheet`, `crosshair`, `dock`, `lock`, `mediaControls`, `notificationPopup`, `onScreenDisplay`, `onScreenKeyboard`, `overview`, `overlay`, `polkit`, `regionSelector`, `reloadPopup`, `screenCorners`, `sessionScreen`, `sidebarLeft`, `sidebarRight`, `verticalBar`, `wallpaperSelector` |
| 49 | `tray` | dict | System tray (`monochromeIcons`, `showItemId`, `invertPinnedItems`, `pinnedItems`, `filterPassive`) |
| 50 | `shellUpdates` | dict | Shell update checker (`enabled`, `checkIntervalMinutes`, `dismissedCommit`, `lastNotifiedCommit`, `openTerminalOnUpdate`) |
| 51 | `updates` | dict | System updates (`checkInterval`, `adviseUpdateThreshold`, `stronglyAdviseUpdateThreshold`) |
| 52 | `bootGreeting` | dict | Boot greeting (`enable`, `autoDismissDelay`, `showWeather`, `showDate`) |
| 53 | `welcomeWizard` | dict | Welcome wizard (`completed`, `skipped`) |
| 54 | `waffles` | dict | Waffle (Fluent) family settings. Sub-keys: `settings`, `modules`, `tweaks`, `altSwitcher`, `notifications`, `background`, `bar`, `actionCenter`, `calendar`, `theming`, `behavior`, `startMenu`, `widgetsPanel`, `workspaceNames`, `taskView` |
| 55 | `familyTransitionAnimation` | bool | Controls family transition animation (`true` by default) |
| 56 | `panelFamily` | str | Active panel family (`"ii"` by default) |
| 57 | `enabledPanels` | list | List of enabled panel names (25 panels for `ii` family by default) |
| 58 | `knownPanels` | list | Known panel names (empty by default) |
| 59 | `powerProfiles` | dict | Power profiles (`restoreOnStart`, `preferredProfile`) |
| 60 | `voiceSearch` | dict | Voice search settings (`duration`) |

### Default `enabledPanels` (ii family)

```
iiBar, iiBackground, iiBackdrop, iiCheatsheet, iiControlPanel, iiDock, iiLock,
iiMediaControls, iiNotificationPopup, iiOnScreenDisplay, iiOnScreenKeyboard,
iiOverlay, iiOverview, iiPolkit, iiRegionSelector, iiScreenCorners,
iiSessionScreen, iiSidebarLeft, iiSidebarRight, iiTilingOverlay, iiVerticalBar,
iiWallpaperSelector, iiCoverflowSelector, iiClipboard, iiShellUpdate
```

### Default `panelFamily`

```
"ii"
```

---

## 4. Config Singleton

### File: `modules/common/Config.qml`

- **Size**: ~2000+ lines
- **Singleton pattern**: Registered as `Config` in `modules/common/qmldir`
- **Purpose**: Centralized configuration management with read/write support

#### Key Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `setNestedValue` | `function setNestedValue(key: string, value: var)` | Sets a nested configuration value by dot-path key (e.g., `"panelFamily"`, `"themeSchedule.enabled"`) |
| `_writeMirrorToDisk` | `function _writeMirrorToDisk()` | Writes the in-memory config mirror back to disk (`~/.config/illogical-impulse/config.json`) |
| `applyConfig` | (assumed) | Applies configuration changes to running services |

#### Access Pattern

Services and modules access configuration via:

```qml
Config.options?.<sectionKey>
// or
Config.options?.<sectionKey>?.<subKey>
```

The optional chaining (`?.`) is used consistently to handle missing config sections gracefully.

---

## 5. Services System

### Service Directories

1. **`services/`** — Eager-loaded singletons (50 services)
2. **`services/deferred/`** — Lazy-loaded/conditionally-loaded services (20 services)

### Service qmldir Registry (`services/qmldir`)

All 50 eager services are registered as singletons:

```
singleton Ai
singleton AppCatalog
singleton AppLauncher
singleton AppSearch
singleton Audio
singleton Autostart
singleton AwwwBackend
singleton Battery
singleton BluetoothStatus
singleton Booru
singleton Brightness
singleton CalendarSync
singleton CavaTheme
singleton CompositorService
singleton ConflictKiller
singleton CustomWidgets
singleton DateTime
singleton Events
singleton FirstRunExperience
singleton FontSyncService
singleton GameMode
singleton GlobalActions
singleton Hyprsunset
singleton IconThemeService
singleton Idle
singleton KeyboardIndicators
singleton MaterialThemeLoader
singleton MemoryPressureService
singleton MinimizedWindows
singleton MprisController
singleton Network
singleton NiriService
singleton Notepad
singleton Notifications
singleton PolkitService
singleton PowerProfilePersistence
singleton Privacy
singleton RecorderStatus
singleton ResourceUsage
singleton ScreenTime
singleton ShellUpdates
singleton SystemInfo
singleton TaskbarApps
singleton ThemeService
singleton TimerService
singleton Todo
singleton Translation
singleton TrayService
singleton Updates
singleton VoiceSearch
singleton Wallhaven
singleton WallpaperListener
singleton Wallpapers
singleton Weather
singleton WidgetPowerManager
singleton WindowPreviewService
singleton YtMusic
```

### Deferred Service qmldir Registry (`services/deferred/qmldir`)

20 deferred services:

```
singleton AnimeService
singleton CavaService
singleton Cliphist
singleton EasyEffects
singleton Emojis
singleton GowallService
singleton HyprlandKeybinds
singleton HyprlandXkb
singleton KeyringStorage
singleton LatexRenderer
singleton LauncherSearch
singleton NiriKeybinds
singleton PackageSearch
singleton RedditService
singleton SessionWarnings
singleton SongRec
singleton Ydotool
```

**Note**: The deferred qmldir lists 17 singletons but there are 20 `.qml` files in the `deferred/` directory. A few services (like `KeyringStorage`) may be registered differently or imported directly rather than via qmldir.

---

## 6. IPC Targets

### IPC Documentation

- **File**: `docs/IPC.md`
- **Invocation**: `inir ipc <target> <method> [args]`
- **Mechanism**: Quickshell's `IpcHandler` component with string-based `target` property

### 18 Confirmed IPC Targets from Service Files

Each IPC target is backed by an `IpcHandler` declaration in its corresponding service file:

| # | IPC Target | Service File | Type |
|---|------------|--------------|------|
| 1 | `ai` | `services/Ai.qml` | Eager |
| 2 | `appCatalog` | `services/AppCatalog.qml` | Eager |
| 3 | `audio` | `services/Audio.qml` | Eager |
| 4 | `brightness` | `services/Brightness.qml` | Eager |
| 5 | `cliphistService` | `services/deferred/Cliphist.qml` | Deferred |
| 6 | `customWidgets` | `services/CustomWidgets.qml` | Eager |
| 7 | `gamemode` | `services/GameMode.qml` | Eager |
| 8 | `globalActions` | `services/GlobalActions.qml` | Eager |
| 9 | `keyboard` | `services/KeyboardIndicators.qml` | Eager (target name differs from file name) |
| 10 | `memory` | `services/MemoryPressureService.qml` | Eager |
| 11 | `minimize` | `services/MinimizedWindows.qml` | Eager |
| 12 | `mpris` | `services/MprisController.qml` | Eager |
| 13 | `notifications` | `services/Notifications.qml` | Eager |
| 14 | `packageSearch` | `services/deferred/PackageSearch.qml` | Deferred |
| 15 | `shellUpdate` | `services/ShellUpdates.qml` | Eager |
| 16 | `voiceSearch` | `services/VoiceSearch.qml` | Eager |
| 17 | `widgetpower` | `services/WidgetPowerManager.qml` | Eager |
| 18 | `ytmusic` | `services/YtMusic.qml` | Eager |

### IPC Handlers in Module Files

Additional `IpcHandler` declarations exist in module files (panels, overlays, etc.):

- `GlobalStates.qml` — 1 IPC handler
- `modules/altSwitcher/AltSwitcher.qml` — 1 IPC handler
- `modules/background/Background.qml` — 1 IPC handler
- `modules/bar/Bar.qml` — 1 IPC handler
- `modules/cheatsheet/Cheatsheet.qml` — 1 IPC handler
- `modules/clipboard/ClipboardPanel.qml` — 1 IPC handler
- `modules/closeConfirm/CloseConfirm.qml` — 1 IPC handler
- `modules/controlPanel/ControlPanel.qml` — 1 IPC handler
- `modules/ii/overlay/Overlay.qml` — 1 IPC handler
- `modules/lock/Lock.qml` — 1 IPC handler
- `modules/mediaControls/MediaControls.qml` — 1 IPC handler
- `modules/onScreenDisplay/OnScreenDisplay.qml` — 1 IPC handler
- `modules/onScreenKeyboard/OnScreenKeyboard.qml` — 1 IPC handler
- `modules/overview/Overview.qml` — 1 IPC handler
- `modules/recordingOsd/RecordingOsd.qml` — 1 IPC handler
- `modules/regionSelector/RegionSelector.qml` — 1 IPC handler
- `modules/sessionScreen/SessionScreen.qml` — 1 IPC handler
- `modules/settings/SettingsOverlay.qml` — 1 IPC handler
- `modules/sidebarLeft/SidebarLeft.qml` — 1 IPC handler
- `modules/sidebarRight/SidebarRight.qml` — 1 IPC handler
- `modules/tilingOverlay/TilingOverlay.qml` — 1 IPC handler
- `modules/verticalBar/VerticalBar.qml` — 1 IPC handler
- `modules/waffle/actionCenter/WaffleActionCenter.qml` — 1 IPC handler
- `modules/waffle/altSwitcher/WaffleAltSwitcher.qml` — 1 IPC handler
- `modules/waffle/bar/WaffleBar.qml` — 1 IPC handler
- `modules/waffle/clipboard/WaffleClipboard.qml` — 1 IPC handler
- `modules/waffle/notificationCenter/WaffleNotificationCenter.qml` — 1 IPC handler
- `modules/waffle/onScreenDisplay/WaffleOSD.qml` — 1 IPC handler
- `modules/waffle/sessionScreen/WaffleSessionScreen.qml` — 1 IPC handler
- `modules/waffle/startMenu/WaffleStartMenu.qml` — 1 IPC handler
- `modules/waffle/taskview/WaffleTaskView.qml` — 1 IPC handler
- `modules/waffle/widgets/WaffleWidgets.qml` — 1 IPC handler
- `modules/wallpaperSelector/WallpaperCoverflow.qml` — 1 IPC handler
- `modules/wallpaperSelector/WallpaperSelector.qml` — 1 IPC handler
- `shell.qml` — 2 IPC handlers (lines 290 and 456)

---

## 7. Panel Families

### Definition Location

`shell.qml` line ~347 defines `panelFamilies` as a JavaScript object mapping family names to arrays of panel component names.

### Family: `ii` (Material / Default)

26 panels (25 in `enabledPanels` + `iiBootGreeting` in the family definition):

```
iiBar, iiBackground, iiBackdrop, iiBootGreeting, iiCheatsheet, iiControlPanel,
iiDock, iiLock, iiMediaControls, iiNotificationPopup, iiOnScreenDisplay,
iiOnScreenKeyboard, iiOverlay, iiOverview, iiPolkit, iiRegionSelector,
iiScreenCorners, iiSessionScreen, iiSidebarLeft, iiSidebarRight,
iiTilingOverlay, iiVerticalBar, iiWallpaperSelector, iiCoverflowSelector,
iiClipboard, iiShellUpdate, iiRecordingOsd
```

### Family: `waffle` (Fluent)

18 + shared panels:

```
wBar, wBackground, wBackdrop, wStartMenu, wActionCenter, wNotificationCenter,
wNotificationPopup, wOnScreenDisplay, wWidgets, wTaskView, wLock, wPolkit,
wSessionScreen
```

Plus shared modules also loaded with waffle:

```
iiBootGreeting, iiCheatsheet, iiOnScreenKeyboard, iiOverlay, iiOverview,
iiRegionSelector, iiScreenCorners, iiWallpaperSelector, iiCoverflowSelector,
iiClipboard
```

> Comment in `shell.qml` notes: `wAltSwitcher` is always loaded when `waffle` is active (not in the panel list), and `iiAltSwitcher` acts as an IPC router redirecting to `wAltSwitcher` when waffle is active.

### Families List

```qml
property list<string> families: ["ii", "waffle"]
```

---

## 8. Shell Entry Point

### File: `shell.qml`

### Pragmas

```
//@ pragma UseQApplication
//@ pragma ShellId inir
//-@ pragma EnableQtWebEngineQuick
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QT_LOGGING_RULES=quickshell.dbus.properties=false
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma DefaultEnv QS_DROP_EXPENSIVE_FONTS=1
//-@ pragma Env QTWEBENGINE_CHROMIUM_FLAGS=--disable-features=ThirdPartyCookieBlocking,StorageAccessAPI
```

### Imports

```qml
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.altSwitcher
import qs.modules.closeConfirm
import qs.modules.settings
import qs.services
```

### Panel Family Switch Logic

```qml
// Line ~206: When switching families
Config.setNestedValue("enabledPanels", root.panelFamilies[family])

// Line ~228: Merging family panels
const basePanels = root.panelFamilies[family] ?? [];
const currentPanels = Config.options?.enabledPanels ?? []

// Line ~368: Ensure family panels are loaded
function _ensureFamilyPanels(family: string): void {
    const basePanels = root.panelFamilies[family] ?? []
    const currentPanels = Config.options?.enabledPanels ?? []
    // ... merge logic
}
```

### IPC Handlers in shell.qml

- **Line 290**: First `IpcHandler` (likely `shellUpdate` or panel-related)
- **Line 456**: Second `IpcHandler` (likely `globalActions` or shell-level control)

---

## 9. Module Import Patterns

### Common Imports

All modules and services follow these import conventions:

```qml
import QtQuick
import QtQuick.Controls
import Quickshell
import qs.modules.common     // Config, GlobalStates
import qs.services           // All eager services
import qs.services.deferred  // Deferred services (when needed)
```

### Panel Module Structure

- **`ii` panels**: Located at `modules/ii/` (e.g., `modules/ii/overlay/Overlay.qml`)
- **`waffle` panels**: Located at `modules/waffle/` (e.g., `modules/waffle/bar/WaffleBar.qml`)
- **Shared panels**: Some `ii` panels are reused by `waffle` (see `panelFamilies` definition)

### Service Import

Services are imported via:

```qml
import qs.services
```

This gives access to all 50 singletons defined in `services/qmldir`.

### Deferred Services Import

Deferred services are accessed via their file path or separate import:

```qml
// Either direct path import or via qmldir
import qs.services.deferred
```

---

## 10. Config-to-Service Consumption

### Summary

Services consume configuration via `Config.options?.<sectionKey>` pattern. The following top-level config keys are consumed by services:

```
ai, appearance, apps, audio, autostart, background, bar, battery,
calendar, compositor, conflictKiller, dock, enabledPanels, gameMode,
hacks, idle, keyboardIndicators, language, light, media, modules,
musicRecognition, networking, notifications, osd, osk, overlay,
overview, performance, policies, powerProfiles, resources, search,
shellUpdates, sidebar, sounds, time, tray, updates, voiceSearch,
wallpaperSelector
```

### Direct Config-to-Service Mappings (Partial)

| Service File | Config Key(s) Consumed |
|---|---|
| `Ai.qml` | `Config.options?.ai`, `Config.options?.appearance` |
| `AppCatalog.qml` | `Config.options?.apps` |
| `Audio.qml` | `Config.options?.audio` |
| `Autostart.qml` | `Config.options?.apps` |
| `Battery.qml` | `Config.options?.battery` |
| `Brightness.qml` | `Config.options?.light`, `Config.options?.appearance` |
| `CalendarSync.qml` | `Config.options?.calendar` |
| `CompositorService.qml` | `Config.options?.compositor`, `Config.options?.display` |
| `ConflictKiller.qml` | `Config.options?.conflictKiller` |
| `CustomWidgets.qml` | `Config.options?.apps` |
| `DateTime.qml` | `Config.options?.time` |
| `GameMode.qml` | `Config.options?.gameMode` |
| `GlobalActions.qml` | `Config.options?.apps`, `Config.options?.search` |
| `Hyprsunset.qml` | `Config.options?.light?.night` |
| `Idle.qml` | `Config.options?.idle` |
| `KeyboardIndicators.qml` | `Config.options?.keyboardIndicators` |
| `MemoryPressureService.qml` | `Config.options?.resources` |
| `Notifications.qml` | `Config.options?.notifications`, `Config.options?.apps` |
| `PolkitService.qml` | `Config.options?.apps` |
| `PowerProfilePersistence.qml` | `Config.options?.powerProfiles` |
| `RecorderStatus.qml` | `Config.options?.screenRecord` |
| `ResourceUsage.qml` | `Config.options?.resources` |
| `ShellUpdates.qml` | `Config.options?.shellUpdates` |
| `TaskbarApps.qml` | `Config.options?.apps` |
| `ThemeService.qml` | `Config.options?.appearance` |
| `TrayService.qml` | `Config.options?.tray` |
| `Updates.qml` | `Config.options?.updates` |
| `VoiceSearch.qml` | `Config.options?.voiceSearch` |
| `WallpaperListener.qml` | `Config.options?.background`, `Config.options?.wallpaperSelector` |
| `Weather.qml` | `Config.options?.apps` |
| `WidgetPowerManager.qml` | `Config.options?.modules` |
| `WindowPreviewService.qml` | `Config.options?.overview`, `Config.options?.compositor` |
| `YtMusic.qml` | `Config.options?.sidebar` |

### Module Config Consumption (Partial)

Panel and module components also consume config keys:

| Module File | Config Keys Consumed |
|---|---|
| `modules/background/Background.qml` | `appearance`, `background` |
| `modules/bar/Bar.qml` | `bar`, `appearance` |
| `modules/altSwitcher/AltSwitcher.qml` | `altSwitcher`, `appearance` |
| `modules/dock/Dock.qml` | `dock`, `appearance` |
| `modules/lock/Lock.qml` | `lock`, `appearance` |
| `modules/overview/Overview.qml` | `overview`, `appearance` |
| `modules/sidebarLeft/SidebarLeft.qml` | `sidebar`, `appearance` |
| `modules/settings/SettingsOverlay.qml` | All config sections (settings UI) |
| `modules/waffle/bar/WaffleBar.qml` | `waffles.bar`, `waffles.settings` |
| `modules/waffle/startMenu/WaffleStartMenu.qml` | `waffles.startMenu` |

### setNestedValue Usage (Config Writes)

Services and modules write config values via `Config.setNestedValue()`:

| File | Key Written |
|---|---|
| `shell.qml` (line 206) | `enabledPanels` |
| `shell.qml` (line 374) | `enabledPanels` |
| `services/Autostart.qml` | `apps.*` |
| `services/TrayService.qml` | `tray.*` |
| `services/ThemeService.qml` | `appearance.*` |
| `services/PowerProfilePersistence.qml` | `powerProfiles.*` |
| `services/ShellUpdates.qml` | `shellUpdates.*` |

---

## Appendix: File Locations

| Resource | Path |
|---|---|
| Repository root | `/home/yemi/iNiR/` |
| Shell entry point | `/home/yemi/iNiR/shell.qml` |
| Default config | `/home/yemi/iNiR/defaults/config.json` |
| User config (runtime) | `~/.config/illogical-impulse/config.json` |
| Config singleton | `/home/yemi/iNiR/modules/common/Config.qml` |
| Global states | `/home/yemi/iNiR/GlobalStates.qml` |
| Service registry | `/home/yemi/iNiR/services/qmldir` |
| Deferred service registry | `/home/yemi/iNiR/services/deferred/qmldir` |
| IPC documentation | `/home/yemi/iNiR/docs/IPC.md` |
| Architecture docs | `/home/yemi/iNiR/ARCHITECTURE.md` |
| ii panels | `/home/yemi/iNiR/modules/ii/` |
| Waffle panels | `/home/yemi/iNiR/modules/waffle/` |
| Shared modules | `/home/yemi/iNiR/modules/` |
| Common modules | `/home/yemi/iNiR/modules/common/` |

---

*Blueprint generated by codebase archaeology of the iNiR repository.*
