# Service Blueprint — Shell by Yemi

> **Source of truth:** the shell's own service layer under `services/`
> (QML module `qs.services`) plus shared singletons in `singletons/`. UI
> surfaces live in `modules/` (pill, bar, …). This blueprint maps every
> reference service the shell provides or wraps, and the settings/panel
> surface, so features can be located and reused.

This blueprint maps **every** service the shell depends on, the full
settings UI, and the module/panel surface — so features can reuse the
right services.

---

## 1. Architecture Overview

- **UI surfaces** (`modules/`): the pill (launcher, mixer, calendar, clipboard,
  power, settings, keybinds, wallpaper, link, media, sysmon), the bar, the music
  panel, and the alt-tab switcher. They read/write config and bind to singletons.
- **Services** (`services/`, QML module `qs.services`) plus shared singletons
  (`singletons/`): Audio, Battery, Network, Notifications, TrayService,
  WindowPreviewService, CompositorService, NiriService, Wallpapers, ThemeService,
  GameMode, Idle, MprisController, and the ported services (ConflictKiller,
  FirstRunExperience, TimerService, MemoryPressureService).
- **Backends** reached over IPC / D-Bus / PulseAudio / files: Hyprland, Niri,
  PipeWire, NetworkManager, systemd, and the wallpaper engine.

---

## 2. Shell Module / Panel Map

| Module | Role |
|--------|------|
| `bar` | Main taskbar / status bar |
| `taskview` | Alt+Tab window switcher + window thumbnails |
| `actionCenter` | Quick settings / volume / brightness panel |
| `notificationCenter` | Notification history surface |
| `notificationPopup` | Transient notification popups |
| `startMenu` | App launcher menu |
| `widgets` | Desktop widgets panel |
| `background` | Desktop wallpaper surface |
| `backdrop` | Overview/backdrop surface |
| `lock` | Lock screen |
| `onScreenDisplay` | OSD (volume/brightness/media) |
| `clipboard` | Clipboard manager UI |
| `regionSelector` | Region/screenshot selector |
| `sessionScreen` | Session (logout/shutdown) screen |
| `altSwitcher` | Alt+Tab switcher surface |
| `polkit` | Polkit auth dialog |
| `looks` | Appearance/look derivation (aurora/angel) |
| `settings` | Settings app (see §4) |

---

## 3. Service Catalog (complete)

Every service in the shell's `services/` module plus shared singletons.
"compact API" lists representative `property` / `function` / `signal` members.

### 3.x Core & System

#### Audio

_PipeWire audio sink/source control: volume, default device, per-app nodes_

```qml
- property bool ready: sink
- readonly property PwNode rawSink: Pipewire
- property PwNode _pendingSink: null
- readonly property PwNode defaultSink: root
- property PwNode sink: root
- property PwNode source: Pipewire
- `function friendlyDeviceName(`
- `function appNodeDisplayName(`
- `function resolveControllableSink(`
- `function correctType(`
```

#### Battery

_Battery state, charge %, power state, low/critical thresholds_

```qml
- property bool available: UPower
- property var chargeState: UPower
- property bool isCharging: chargeState
- property bool isPluggedIn: isCharging
- property real percentage: UPower
- readonly property bool allowAutomaticSuspend: Config
- `function _log(`
- `function _detectChargeLimitPath(`
- `function _readChargeLimit(`
- `function _updateChargeLimitState(`
```

#### Brightness

_Display brightness control (ddcutil/backlight)_

```qml
- property var ddcMonitors
- readonly property list<BrightnessMonitor> monitors: Quickshell
- readonly property bool isDdc
- readonly property string busNum
- property int rawMaxBrightness: 100
- property real brightness
- `signal brightnessChanged(`
- `function getMonitorForScreen(`
- `function increaseBrightness(`
- `function decreaseBrightness(`
```

#### Network

_NetworkManager state: wifi/ethernet, connectivity, SSID_

```qml
- property bool wifi: true
- property bool ethernet: false
- property bool wifiEnabled: false
- property bool wifiScanning: false
- property bool wifiConnecting: connectProc
- property WifiAccessPoint wifiConnectTarget
- `function enableWifi(`
- `function toggleWifi(`
- `function rescanWifi(`
- `function connectToWifiNetwork(`
```

#### Notifications

_Notification daemon: timeouts, DND, popup position, history_

```qml
- property bool _initialized: false
- property var _discardingIds: new Set
- property Notification notification
- property list<var> actions: notification
- property bool popup: false
- property bool isTransient: notification
- `function _log(`
- `function notifToJSON(`
- `function notifToString(`
- `function toggleSilent(`
```

#### ResourceUsage

_CPU / RAM / disk / GPU usage sampling_

```qml
- property bool _runningRequested: false
- property bool _initRequested: false
- property int _persistentConsumers: 0
- readonly property int _autoStopDelayMs: Config
- property real memoryTotal: 0
- property real memoryFree: 0
- `function kbToGbString(`
- `function updateMemoryUsageHistory(`
- `function updateSwapUsageHistory(`
- `function updateCpuUsageHistory(`
```

#### SystemInfo

_OS + hardware info (kernel, cpu, mem, gpu)_

```qml
- property string distroName
- property string distroId
- property string distroIcon
- property string username
- property string displayName
- property string homeUrl
- `function refreshIdentity(`
```

#### Updates

_System package update checks_

```qml
- property bool available: false
- property int count: 0
- readonly property bool updateAdvised: available
- readonly property bool updateStronglyAdvised: available
- `function load(`
- `function refresh(`
- `function onReadyChanged(`
```

#### ShellUpdates

_Self-update of the shell itself_

```qml
- property bool hasUpdate: false
- property int commitsBehind: 0
- property string latestMessage
- property string localCommit
- property string remoteCommit
- property string currentBranch
- `function toggle(`
- `function open(`
- `function close(`
- `function check(`
```

#### Privacy

_Privacy/screen-share + recording detection_

```qml
- property bool micActive
- property bool screenSharing: false
```

#### ScreenTime

_Per-app screen-time tracking_

```qml
- readonly property bool enabled: Config
- property bool ready: false
- property var _todayData: null
- property string _currentAppId
- property string _currentAppName
- property real _lastTickTime: 0
- `signal dataChanged(`
- `signal rangeLoaded(`
- `function onConfigChanged(`
- `function _loadTodayFromFile(`
```

#### MemoryPressureService

_System memory-pressure monitor_

```qml
- readonly property bool enabled: Config
- readonly property int deletedMappingsThreshold: Config
- readonly property int checkIntervalMs: 300000
- property int currentDeletedMappings: 0
- property int currentTotalMappings: 0
- property bool notificationShown: false
- `function forceGc(`
- `function restart(`
- `function dismiss(`
- `function reset(`
```

#### RecorderStatus

_Screen recorder running status_

```qml
- property bool isRecording: false
- property real recordingStartTime: 0
- property int elapsedSeconds: 0
- `function refreshStatus(`
- `function scheduleQuickCheck(`
```

#### WidgetPowerManager

_Widget-level power/suspend helpers_

```qml
- readonly property bool widgetsActive
- readonly property bool reducedMode: _shouldPause
- readonly property bool enabled: Config
- readonly property bool pauseOnGameMode: Config
- readonly property bool pauseOnFullscreen: Config
- readonly property bool pauseWhenWindowsPresent: Config
- `function onWindowsChanged(`
- `function onWorkspacesChanged(`
- `function _updateState(`
- `function onActiveChanged(`
```

#### Events

_Calendar/event feed aggregation_

```qml
- property string filePath: Directories
- property var list
- property int nextId: 1
- `function _log(`
- `signal eventAdded(`
- `signal eventRemoved(`
- `signal eventUpdated(`
```

#### TimerService

_Timer / alarm service_

```qml
- property int focusTime: 1500
- property int breakTime: 300
- property int longBreakTime: 900
- property int cyclesBeforeLongBreak: 4
- property bool pomodoroRunning: Persistent
- property bool pomodoroPaused: Persistent
- `function _syncPomodoroConfig(`
- `function onConfigChanged(`
- `function onReadyChanged(`
- `function onReadyChanged(`
```

#### GlobalActions

_Global action + hotkey registry_

```qml
- readonly property var allActions: _rebuildActions
- readonly property list<string> categories
- readonly property var _systemActions
- readonly property var _appearanceActions
- readonly property var _toolActions
- readonly property var _mediaActions
- `function runLauncher(`
- `function fuzzyQuery(`
- `function runById(`
- `function listByCategory(`
```

#### ConflictKiller

_Resolves conflicting keybinds/settings_

```qml
- property string killDialogQmlPath: FileUtils
- property bool _traysConflict: false
- property bool _notifsConflict: false
- `function load(`
- `function onReadyChanged(`
- `function _maybeHandleConflicts(`
```

#### FirstRunExperience

_First-run onboarding flow_

```qml
- property string firstRunFilePath: FileUtils
- property string firstRunFileContent
- property string firstRunNotifSummary
- property string firstRunNotifBody
- property string defaultWallpaperPath
- property string welcomeQmlPath: FileUtils
- `function load(`
- `function enableNextTime(`
- `function disableNextTime(`
- `function handleFirstRun(`
```

#### CustomWidgets

_Shared custom widget component library_

```qml
- property list<var> widgets
- readonly property bool ready: _scanDone
- readonly property string widgetsDir
- property bool _scanDone: false
- property string widgetName
- property string _pascalName: widgetName
- `function onReadyChanged(`
- `function onCustomWidgetDataSyncedChanged(`
- `function reload(`
- `function _scan(`
```


### 3.x Power / Session / Input

#### GameMode

_Game-mode detection + behavior flags_

```qml
- property bool active: _manualActive
- readonly property bool autoDetect: Config
- property bool manuallyActivated: _manualActive
- readonly property bool autoActivated: _autoActive
- readonly property bool shouldHidePanels: false
- property bool hasAnyFullscreenWindow: false
- `function _log(`
- `function toggle(`
- `function activate(`
- `function deactivate(`
```

#### Idle

_Idle/inhibit: screen-off / lock / suspend timeouts_

```qml
- property bool inhibit: false
- readonly property int screenOffTimeout: Config
- readonly property int lockTimeout: Config
- readonly property int suspendTimeout: Config
- readonly property string launcherPath: Quickshell
- `function toggleInhibit(`
- `function _restartSwayidle(`
- `function _stopSwayidle(`
- `function _startSwayidle(`
```

#### PowerProfilePersistence

_Persists chosen power profile_

```qml
- property bool _initialized: false
- `function _profileToString(`
- `function _stringToProfile(`
- `function _applyPreferredProfile(`
- `function onReadyChanged(`
```

#### KeyboardIndicators

_Keyboard layout / Caps / Num-Lock indicators_

```qml
- property list<string> capsLockPaths
- property list<string> numLockPaths
- property var _capsLockStates
- property var _numLockStates
- property string _knownLayoutName
- property string _lockSource
- `function _log(`
- `function abbreviateLayoutCode(`
- `function refreshLedPaths(`
- `function _setCapsLockValue(`
```

#### Autostart

_Autostart entries (systemd + .desktop)_

```qml
- property bool hasRun: false
- property bool _systemdUnitsRefreshRequested: false
- readonly property bool globalEnabled: Config
- readonly property var entries
- property var systemdUnits
- property string desktopId
- `function _log(`
- `function load(`
- `function startFromConfig(`
- `function startEntry(`
```


### 3.x Compositor / Windowing

#### CompositorService

_Compositor dispatch abstraction (Hyprland/Niri)_

```qml
- property bool isHyprland: false
- property bool isNiri: false
- property bool isGnome: false
- property string compositor
- readonly property string hyprlandSignature: Quickshell
- readonly property string niriSocket: Quickshell
- `function scheduleSort(`
- `function scheduleRefresh(`
- `function setSortingConsumer(`
- `function onValuesChanged(`
```

#### NiriService

_Niri compositor IPC service_

```qml
- readonly property string socketPath: Quickshell
- property var workspaces
- property var allWorkspaces
- property int focusedWorkspaceIndex: 0
- property string focusedWorkspaceId
- property var currentOutputWorkspaces
- `signal configLoadFinished(`
- `function onActiveChanged(`
- `function fetchOutputs(`
- `function fetchKeyboardLayouts(`
```

#### TrayService

_System tray item aggregation_

```qml
- property bool _xembedProxyStartRequested: false
- property bool _xembedProxyCheckedOnce: false
- property bool smartTray: Config
- readonly property var problematicApps
- property var _pinnedItems: Config
- property list<var> itemsInUserList: SystemTray
- `function getProblematicAppInfo(`
- `function matchesApp(`
- `function smartActivate(`
- `function smartToggle(`
```

#### WindowPreviewService

_Window thumbnail / preview generation_

```qml
- readonly property string previewDir: FileUtils
- property var previewCache
- property bool initialized: false
- property bool capturing: false
- readonly property int previewValidityMs: 300000
- property double _lastCaptureEndTime: 0
- `function _log(`
- `function _saveClipboard(`
- `function _restoreClipboard(`
- `signal captureComplete(`
```

#### MinimizedWindows

_Minimized-window tracking_

```qml
- readonly property int minimizedWorkspaceIndex: 99
- property var minimizedWindows
- property list<int> minimizedIds
- `function isMinimized(`
- `function getMinimizedForApp(`
- `function countMinimizedForApp(`
- `function minimize(`
```

#### TaskbarApps

_Taskbar pinned + open app model_

```qml
- property list<var> apps
- `function togglePin(`
```

#### HyprlandData

_Hyprland state data (value type)_

```qml
- property var windowList
- property var addresses
- property var windowByAddress
- property var workspaces
- property var workspaceIds
- property var workspaceById
- `function updateWindowList(`
- `function updateLayers(`
- `function updateMonitors(`
- `function updateWorkspaces(`
```


### 3.x Wallpaper / Theme

#### Wallpapers

_Wallpaper management: set / list / per-monitor_

```qml
- readonly property bool _debugWallpaperUrls
- property bool _applyInProgress: false
- property string _queuedApplyPath
- property bool _queuedApplyDarkMode: Appearance
- property bool _queuedApplyNoSwitch: false
- readonly property string backendProvider
- `signal wallpaperBlurTransitionRequested(`
- `function currentThemingWallpaperPath(`
- `function isVideoFile(`
- `function getVideoFirstFramePath(`
```

#### WallpaperListener

_Watches wallpaper change events_

```qml
- readonly property bool multiMonitorEnabled: Config
- readonly property var wallpapersByMonitorRef: Config
- readonly property string globalWallpaperPath: Config
- readonly property bool globalAnimationEnabled: Config
- readonly property string globalFillMode: Config
- readonly property int screenCount: Quickshell
- `function _log(`
- `function isVideoPath(`
- `function isGifPath(`
- `function isAnimatedPath(`
```

#### Wallhaven

_Wallhaven wallpaper source_

```qml
- property Component wallhavenResponseComponent: BooruResponseData
- property string failMessage: Translation
- property var responses
- property int runningRequests: 0
- property string _lastTagSuggestionQuery
- property var _lastTagSuggestions
- `function _log(`
- `signal responseFinished(`
- `signal tagSuggestion(`
- `function _detailUrl(`
```

#### ThemeService

_shell theme service: palette + scheme source_

```qml
- property bool ready: false
- readonly property string currentTheme: Config
- readonly property bool isAutoTheme: currentTheme
- readonly property bool isStandaloneSettingsWindow
- readonly property bool defaultApplyExternal
- readonly property bool vesktopEnabled
- `function _log(`
- `function setTheme(`
- `function _triggerVesktopThemeGeneration(`
- `function applyCurrentTheme(`
```

#### MaterialThemeLoader

_Loads Material You theme (m3colors)_

```qml
- property string filePath: Directories
- property bool ready: false
- property bool _forceApply: false
- property bool _pendingExternalApply: false
- readonly property bool defaultApplyExternal
- readonly property bool isAutoTheme
- `function reapplyTheme(`
- `function colorToHex(`
- `function setDarkMode(`
- `function applySchemeVariant(`
```

#### CavaTheme

_Cava visualizer theme bridge_

```qml
- readonly property bool enabled: Config
- readonly property bool useCoverSource
- readonly property string coverSourceUrl
- readonly property string coverTitle: MprisController
- readonly property string coverArtist: MprisController
- readonly property string coverAlbum: MprisController
- `function _scheduleCoverRefresh(`
- `function _applyCoverTheme(`
- `function onTrackChanged(`
```

#### FontSyncService

_Synces fonts for Material/ii_

```qml
- readonly property string mainFont: Config
- readonly property real sizeScale: Config
- readonly property int fontSize: Math
- readonly property string gtkFontString
- readonly property bool syncEnabled: Config
- property bool _pendingSync: false
- `function _log(`
- `function _queueSync(`
- `function _doSync(`
- `function syncNow(`
```

#### IconThemeService

_Icon-theme management_

```qml
- property var availableThemes
- property string currentTheme
- property string dockTheme
- property bool _initialized: false
- property bool _restartQueued: false
- property string themeName
- `function _log(`
- `function smartIconName(`
- `function dockIconPath(`
- `function dockIconCandidates(`
```

#### AwwwBackend

_Wallpaper transition/animation backend_

```qml
- readonly property string provider
- readonly property bool enabled: true
- readonly property int transitionFps: Config
- readonly property int simpleStep: Config
- readonly property int spatialStep: Config
- readonly property int transitionDurationMs: Config
- `function supportsMainWallpaper(`
- `function supportsFillMode(`
- `function resizeModeForFillMode(`
- `function supportsVisibleMainWallpaper(`
```

#### Hyprsunset

_Hyprsunset (night light) control_

```qml
- property string from: Config
- property string to: Config
- property bool automatic: Config
- property int colorTemperature: Config
- property bool shouldBeOn
- property bool firstEvaluation: true
- `function inBetween(`
- `function reEvaluate(`
- `function ensureState(`
- `function load(`
```


### 3.x Media / Launcher

#### MprisController

_MPRIS media-player control_

```qml
- property list<MprisPlayer> players
- readonly property var displayPlayers: _filterYtMusicDuplicates
- property MprisPlayer trackedPlayer: null
- property bool _manualPlayerSelection: false
- property int _playbackStateVersion: 0
- property var _playerGrace
- `function _rebuildPlayerList(`
- `function _doRebuildPlayerList(`
- `function onReadyChanged(`
- `function _isInGracePeriod(`
```

#### YtMusic

_YouTube Music control_

```qml
- property bool _resumeRestored: false
- property real _targetPosition: 0
- property bool available: false
- property bool enabled: Config
- property bool searching: false
- property bool loading: false
- `function _persistResume(`
- `function _clearResume(`
- `function _log(`
- `function _isOurMpv(`
```

#### AppCatalog

_Package/store catalog (install/remove)_

```qml
- property list<var> catalog
- property var installedPackages
- property string selectedCategory
- property string searchQuery
- property bool loading: true
- property bool checkingInstalled: false
- `function _refreshInstalled(`
- `function _safeTerminal(`
- `function _runTerminalScript(`
- `function _getInstallTarget(`
```

#### AppLauncher

_Configurable launcher slots_

```qml
- property int _configRevision: 0
- readonly property var _slotDefinitions
- `function onConfigChanged(`
- `function slotDefinitions(`
- `function slotDefinition(`
- `function configuredCommand(`
```

#### AppSearch

_Fuzzy desktop/app search_

```qml
- property bool sloppySearch: Config
- property real scoreThreshold: 0
- property var substitutions
- property var regexSubstitutions
- property var _cachedList
- property var _cachedPreppedNames
- `function onValuesChanged(`
- `function _rebuildCache(`
- `function fuzzyQuery(`
- `function _decorateEntry(`
```


### 3.x AI / Cloud / Misc

#### Ai

_AI chat assistant (multi-provider)_

```qml
- property bool _initialized: false
- property var _lastInterfaceMessage: null
- property Component aiMessageComponent: AiMessageData
- property Component aiModelComponent: AiModel
- property Component geminiApiStrategy: GeminiApiStrategy
- property Component openaiApiStrategy: OpenAiApiStrategy
- `function _log(`
- `signal responseFinished(`
- `function ensureInitialized(`
- `function diagnose(`
```

#### Booru

_Booru image-board client_

```qml
- property Component booruResponseDataComponent: BooruResponseData
- property string failMessage: Translation
- property var responses
- property int runningRequests: 0
- property var defaultUserAgent: Config
- property var providerList: Object
- `function _log(`
- `signal tagSuggestion(`
- `signal responseFinished(`
- `function getWorkingImageSource(`
```

#### VoiceSearch

_Voice search_

```qml
- property int recordDuration: Config
- property string searchEngineUrl: Config
- readonly property bool recording: recordProc
- readonly property bool transcribing: transcribeProc
- readonly property bool running: recording
- property string lastTranscription
- `signal transcriptionReady(`
- `signal searchReady(`
- `function start(`
- `function onLoadedChanged(`
```

#### Weather

_Weather service_

```qml
- readonly property bool enabled: Config
- readonly property int fetchInterval
- readonly property bool useUSCS: Config
- readonly property bool hideLocation: Config
- readonly property string configCity: Config
- readonly property real configLat: Config
- `function redactedLogCity(`
- `function redactedLogLocationName(`
- `function redactedLogCoordinates(`
- `function isNightNow(`
```

#### CalendarSync

_Calendar (.ics) sync_

```qml
- readonly property bool enabled: Config
- readonly property var sources: Config
- readonly property int fetchIntervalMs
- property var events
- property var sourceStatuses
- property bool fetching: false
- `signal eventsUpdated(`
- `signal fetchStarted(`
- `signal fetchFinished(`
- `signal sourceError(`
```

#### Notepad

_Sticky notes_

```qml
- readonly property string tabsFilePath
- readonly property string legacyFilePath: Directories
- property int currentTab: 0
- property var tabs
- readonly property string text
- property bool _saving: false
- `function setTextValue(`
- `function setTabTitle(`
- `function addTab(`
- `function removeTab(`
```

#### Todo

_Todo list_

```qml
- property string filePath: Directories
- property string txtFilePath: Directories
- property var list
- property bool _suppressTxtWrite: false
- property bool _startupLock: true
- `function _log(`
- `function addItem(`
- `function addTask(`
- `function markDone(`
```

#### Translation

_i18n / translation_

```qml
- property var translations
- property var generatedTranslations
- property var availableLanguages
- property var availableGeneratedLanguages
- property var allAvailableLanguages
- property bool isScanning: scanLanguagesProcess
- `function tr(`
- `signal languagesScanned(`
- `function onReadyChanged(`
- `signal contentLoaded(`
```

#### DateTime

_Clock/date formatting + timezone_

```qml
- property var clock: SystemClock
- property string time: Qt
- property string timeDisplay
- property string shortDate: Qt
- property string date: Qt
- property string collapsedCalendarFormat: Qt
```

#### DankSocket

_WebSocket helper (value type)_

```qml
- property alias path: socket
- property alias parser: socket
- property bool connected: false
- property int reconnectBaseMs: 400
- property int reconnectMaxMs: 15000
- property int _reconnectAttempt: 0
- `signal connectionStateChanged(`
- `function send(`
- `function _scheduleReconnect(`
```

#### PolkitService

_Polkit auth agent_

```qml
- property var agent: impl
- property bool active: impl
- property var flow: impl
- property bool interactionAvailable: impl
- readonly property bool available: impl
- property var impl: null
- `function _log(`
- `function cancel(`
- `function submit(`
- `function _loadImpl(`
```

#### PolkitServiceImpl

_Polkit implementation (value type)_

```qml
- property alias agent: polkitAgent
- property alias active: polkitAgent
- property alias flow: polkitAgent
- property bool interactionAvailable: false
- `function cancel(`
- `function submit(`
- `function onAuthenticationFailed(`
```

#### BooruResponseData

_Booru API response model (value type)_

```qml
- property string provider
- property var tags
- property var page
- property var images
- property string message
```


### 3.x Deferred (lazy / optional)

#### AnimeService

_Anime tracking (deferred)_

_no public members extracted_

#### CavaService

_Cava audio visualizer (deferred)_

_no public members extracted_

#### Cliphist

_Clipboard history (deferred)_

_no public members extracted_

#### EasyEffects

_EasyEffects preset control (deferred)_

_no public members extracted_

#### Emojis

_Emoji picker data (deferred)_

_no public members extracted_

#### GowallService

_Gowall palette recolor (deferred)_

_no public members extracted_

#### HyprlandKeybinds

_Hyprland keybind mgmt (deferred)_

_no public members extracted_

#### HyprlandXkb

_Hyprland xkb layout (deferred)_

_no public members extracted_

#### KeyringStorage

_Secret keyring storage (deferred)_

_no public members extracted_

#### LatexRenderer

_LaTeX renderer (deferred)_

_no public members extracted_

#### LauncherSearch

_Launcher web search (deferred)_

_no public members extracted_

#### NiriKeybinds

_Niri keybind mgmt (deferred)_

_no public members extracted_

#### PackageSearch

_Package search (deferred)_

_no public members extracted_

#### RedditService

_Reddit feed (deferred)_

_no public members extracted_

#### SessionWarnings

_Session warnings (deferred)_

_no public members extracted_

#### SongRec

_Song recognition (deferred)_

_no public members extracted_

#### Ydotool

_Virtual input via ydotool (deferred)_

_no public members extracted_


### 3.x Submodules (ai/ + network/)

#### AiModel

_AI model descriptor (ai submodule)_

_no public members extracted_

#### ApiStrategy

_API strategy base (ai submodule)_

_no public members extracted_

#### AnthropicApiStrategy

_Anthropic provider strategy (ai submodule)_

_no public members extracted_

#### GeminiApiStrategy

_Gemini provider strategy (ai submodule)_

_no public members extracted_

#### MistralApiStrategy

_Mistral provider strategy (ai submodule)_

_no public members extracted_

#### OpenAiApiStrategy

_OpenAI provider strategy (ai submodule)_

_no public members extracted_

#### OpenAiResponseApiStrategy

_OpenAI Responses API strategy (ai submodule)_

_no public members extracted_

#### AiMessageData

_Chat message model (ai submodule)_

_no public members extracted_

#### WifiAccessPoint

_WiFi access-point model (network submodule)_

_no public members extracted_


---

## 4. Shell Settings UI → Service Map

The settings window (`modules/settings/SettingsWindow.qml`). Each setting below is backed by a shell service
(see §3 for the service's API). Format: **Page › Section › Setting**.


**Quick › Wallpaper & Colors**
- Dark mode
- Per-monitor wallpapers
- Colors only mode
- Color scheme
- Color strength
- Transparency

**Quick › Quick actions**
- Show reload notifications

**General › Audio**
- Volume protection
- Maximum volume
- Max increase per step

**General › Battery**
- Low battery warning
- Critical battery
- Full battery notification

**General › Time & Language**
- Show seconds
- Long date format
- Short date format
- Language

**General › Keyboard indicators**
- Keyboard popups
- Layout popup
- Caps Lock popup
- Num Lock popup
- Keyboard panel indicators
- Layout indicator
- Caps Lock indicator
- Num Lock indicator

**General › Window Management**
- Confirm before closing

**General › Sounds**
- Battery sounds
- Notification sounds

**General › Idle & Sleep**
- Screen off timeout
- Lock timeout
- Suspend timeout
- Lock before sleep

**General › Game Mode**
- Auto-detect fullscreen
- Disable animations
- Disable effects
- Disable Niri animations
- Disable Discover overlay
- Minimal mode
- Suppress notifications
- Hide reload toasts

**Taskbar › Position & Layout**
- Bottom position
- Left-align apps

**Taskbar › Icons**
- Tint app icons
- Tint tray icons

**Taskbar › Desktop Peek**
- Enable hover peek
- Hover delay

**Taskbar › Clock & Notifications**
- Show seconds
- Show unread count
- Activation watermark

**Background › Wallpaper**
- Use Material ii wallpaper
- Shell wallpaper
- Per-monitor wallpapers
- Hide when fullscreen
- Wallpaper scaling

**Background › Wallpaper Effects**
- Enable blur
- Blur radius
- Dim overlay
- Extra dim with windows

**Background › Wallpaper Transitions**
- Enable wallpaper transitions
- Transition style
- Transition direction
- Transition duration

**Background › Desktop Clock**
- Enable clock
- Placement
- Reset free position
- Clock style
- Time format
- Show seconds
- Show date
- Date style
- Color tone
- Animate time change
- Clock dim
- Time scale
- Date scale
- Show shadow
- Show lock status
- Clock font

**Background › Backdrop (Overview)**
- Enable backdrop
- Use separate wallpaper
- Backdrop wallpaper
- Derive theme colors from backdrop
- Hide main wallpaper
- Backdrop blur
- Backdrop dim
- Backdrop saturation
- Backdrop contrast
- Enable vignette
- Vignette intensity
- Vignette radius

**Themes › Color Theme**
- Color Theme

**Themes › Dark Mode**
- Appearance

**Themes › Color Scheme**
- Palette type

**Themes › Shell Typography**
- Font family
- Font scale

**Gowall › Source Image**
- Source image
- Use current wallpaper

**Gowall › Operation**
- Recolor
- Effects
- Invert
- Pixelate
- Upscale

**Gowall › Color Scheme Source**
- Built-in theme
- shell theme
- Custom palette

**Gowall › Output**
- Format

**Gowall › Extract Palette**
- Extract colors

**Interface › Notifications**
- Normal timeout
- Low priority timeout
- Critical timeout
- Ignore app timeout
- Popup position
- Do Not Disturb

**Interface › On-Screen Display**
- Media OSD
- OSD timeout

**Interface › Lock Screen**
- Enable blur
- Blur radius
- Center clock
- Show 'Locked' text

**Interface › Screen Corners**
- Fake rounded corners

**Modules › Panel Style**
- Panel family

**Modules › Material Modules in Shell**
- Left Sidebar
- Right Sidebar
- Dock
- Media Controls Overlay
- Screen Corners

**Modules › Shell Modules**
- Widgets Panel
- Desktop Backdrop

**Shell Style › Theming**
- Use Material colors

**Shell Style › Alt+Tab Switcher**
- Style
- Quick switch
- Most recent first
- Auto-hide
- Auto-hide delay

**Shell Style › Behavior**
- Allow multiple panels open
- Smoother menu animations

**Shell Style › Widgets Panel**
- Show date & time
- Show weather
- Show system info
- Show media controls
- Show quick actions

**Shell Style › Calendar**
- Force 2-char day names

**Monitors › Shell visibility**
- Primary monitor

**Monitors › Shell shell surfaces**
- Taskbar

**Monitors › Shared popups and widgets**
- Notification popups
- Desktop widgets
- OSD indicators

---

## 5. Theme Pipeline

- The shell themes itself with the **Dominance** engine: `singletons/Dyn.qml`
  reads `colors.json` (written by `after-wall.sh`) and exposes palette state to
  every surface via the `Theme` singleton.
- `Appearance.qml` / `AppearanceConfig.qml` expose the user-facing theme toggles
  (dark mode, palette, color scheme) consumed directly by the shell — there is no
  separate external appearance layer.
- To add a themed service, read `Theme`/`Dyn` state and re-emit on `Dyn`'s
  revision change rather than spinning up a second theme source.

---

## 6. How to reuse services

1. Pull needed services from §3 into `services/` (register in `services/qmldir`).
2. Map each setting (§4) to a shell config key; keep `qs.services.*` URIs.
3. For Niri, prefer `NiriService` + `CompositorService` over Hyprland-specific paths.
4. Theme via the Dominance/`Dyn` pipeline, not a separate theme source.
