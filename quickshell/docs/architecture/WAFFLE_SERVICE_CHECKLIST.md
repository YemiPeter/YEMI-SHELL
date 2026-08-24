# Waffle → Pill iNiR Service Upgrade Checklist

Source of truth: `docs/architecture/WAFFLE_SERVICE_BLUEPRINT.md`
Legend: `[x]` done · `[ ]` pending · `[~]` skipped (redundant/covered) · Pill location = where it lives in this repo (if known).

Upgraded so far (commits on `pill-upgrade-inir-niri`):
- `Audio` + `Network` → `e3ab085`
- `Battery` + `Notifications` → `b1b3750`

---

## Core & System

- [x] **Audio** — `services/Audio.qml` — native PipeWire + wpctl fallback, per-app/device nodes, mic control, volume protection/ramping (commit `e3ab085`)
- [x] **Battery** — `modules/pill/Singletons/Battery.qml` — thresholds + `critical` + signals + charge-limit probe (commit `b1b3750`)
- [x] **Brightness** — `services/Brightness.qml` — per-screen `BrightnessMonitor` list + `getMonitorForScreen`, DDC/CI via `ddcutil detect`/`getvcp`/`setvcp` (safe if missing), `brightnessChanged` signal, `rawMaxBrightness` (root + per-monitor); laptop backlight (sysfs + `brightnessctl` + 500ms poll) preserved. Commit pending.
- [x] **Network** — `services/Network.qml` — native `Quickshell.Networking`, nmcli only for connect (commit `e3ab085`)
- [x] **Notifications** — `modules/pill/Singletons/Notifs.qml` — reconciled singleton, config timeouts + `toggleSilent`, Hyprland focus guarded (commit `b1b3750`)
- [x] **ResourceUsage** — `modules/pill/Singletons/Sysmon.qml` — history buffers (`cpuUsageHistory`/`memoryUsageHistory`/`swapUsageHistory`/`gpuUsageHistory`, capped `historyLength: 60`, reassignment-based updates), persistent-consumer model (`keepAlive`/`releaseKeepAlive`/`ensureRunning`/`stop` + `_persistentConsumers` + `autoStopTimer` with safe default `_autoStopDelayMs: 15000`), `kbToGbString` + KB totals `memoryTotal`/`memoryFree`/`swapTotal`. Existing sampling/timers preserved. Commit pending.
- [x] **SystemInfo** — `services/SystemInfo.qml` — static identity: distro (`distroName`/`distroId`/`distroIcon`/`logo` from `/etc/os-release`), user (`username`/`displayName` via `id`+`getent`), session (`desktopEnvironment`/`windowingSystem`), links (`homeUrl`/`documentationUrl`/`supportUrl`/`bugReportUrl`/`privacyPolicyUrl`), `refreshIdentity()`. Registered `singleton SystemInfo` in `services/qmldir`. Commit pending.
- [x] **Updates** — package update checks — `services/Updates.qml`: `available`/`count` via `checkupdates` (Arch/CachyOS), `updateAdvised` (>75)/`updateStronglyAdvised` (>200), periodic 120-min re-check. Thresholds/interval are safe defaults (no Config).
- [x] **ShellUpdates** — self-update of shell — already implemented by `modules/pill/Updates.qml` (git-based: check-update.sh + `git pull --ff-only` + `qs ipc call reload`)
- [x] **Privacy** — mic/screen-share detection — `services/Privacy.qml`: `micActive` (PipeWire link inspection), `screenSharing` stub (real detection in UI, matching Waffle). Registered `singleton Privacy` in `services/qmldir`.
- [x] **ScreenTime** — per-app screen-time tracking — `services/ScreenTime.qml`: Niri-only port (polls `niri msg -j windows`, attributes time to `app_id` + hourly buckets), persists per-day JSON under `~/.cache/quickshell/screenTime`, `enabled`/`pollIntervalSeconds` as safe defaults (no Config), drops `Directories`/`AppSearch`/`CompositorService`. Signals `dataChanged`/`rangeLoaded` retained.
- [x] **MemoryPressureService** — memory-pressure monitor — `services/MemoryPressureService.qml`: polls `/proc/self/maps` for `JSGCHeap` deleted/total mappings (5-min timer), notifies on `deletedMappingsThreshold` (300), `forceGc`/`restart`/`dismiss`/`reset`/`getStats` + `memory` IPC handlers (`collect`/`stats`/`restart`/`dismiss`/`reset`). `restart()` uses `qs ipc call reload`; Config→safe defaults; Translation→plain English; notifications via `Quickshell.Services.Notifications`.
- [~] **RecorderStatus** — screen recorder status — SKIPPED: redundant, fully covered by `modules/pill/Singletons/ScreenRec.qml` (pgrep gpu-screen-recorder) + `Recorder.qml`
- [ ] **WidgetPowerManager** — widget power/suspend helpers
- [x] **Events** — `modules/pill/Singletons/Events.qml` — calendar/event feed — already implemented (no port needed)
- [x] **TimerService** — timer / pomodoro — `services/TimerService.qml` + `Pill.qml` rest-clock hook: `timer` IPC (start/pause/reset/status), safe defaults (focusTime 1500/breakTime 300/longBreakTime 900/cyclesBeforeLongBreak 4), own 1s tick drives `countdownString`; rest clock swaps to countdown (Theme.vermLit, tabular nums) when running & not paused; real time kept in hover; finishes notify via `Quickshell.Services.Notifications`.
- [ ] **GlobalActions** — global action + hotkey registry
- [ ] **ConflictKiller** — resolve conflicting keybinds/settings
- [ ] **FirstRunExperience** — first-run onboarding
- [ ] **CustomWidgets** — shared custom widget library

## Power / Session / Input

- [ ] **GameMode** — game-mode detection + flags
- [ ] **Idle** — idle/inhibit screen-off/lock/suspend
- [ ] **PowerProfilePersistence** — persist power profile
- [ ] **KeyboardIndicators** — layout/Caps/Num-Lock indicators
- [ ] **Autostart** — autostart entries (systemd + .desktop)

## Compositor / Windowing

- [ ] **CompositorService** — `modules/pill/Singletons/`? — compositor dispatch (Hyprland/Niri)
- [ ] **NiriService** — Niri IPC
- [ ] **TrayService** — system tray aggregation
- [ ] **WindowPreviewService** — window thumbnail generation
- [ ] **MinimizedWindows** — minimized-window tracking
- [ ] **TaskbarApps** — taskbar pinned + open app model
- [ ] **HyprlandData** — Hyprland state (value type)

## Wallpaper / Theme

- [ ] **Wallpapers** — `modules/pill/Singletons/Walls.qml` — wallpaper management
- [ ] **WallpaperListener** — watch wallpaper change events
- [ ] **Wallhaven** — Wallhaven source
- [ ] **ThemeService** — iNiR theme service
- [ ] **MaterialThemeLoader** — Material You (m3colors)
- [ ] **CavaTheme** — Cava visualizer bridge
- [ ] **FontSyncService** — font sync
- [ ] **IconThemeService** — icon-theme management
- [ ] **AwwwBackend** — wallpaper transition backend
- [ ] **Hyprsunset** — night light control

## Media / Launcher

- [ ] **MprisController** — MPRIS media control
- [ ] **YtMusic** — YouTube Music control
- [ ] **AppCatalog** — package/store catalog
- [ ] **AppLauncher** — configurable launcher slots
- [ ] **AppSearch** — fuzzy desktop/app search

## AI / Cloud / Misc

- [ ] **Ai** — AI chat assistant
- [ ] **Booru** — booru image-board client
- [ ] **VoiceSearch** — voice search
- [ ] **Weather** — `modules/pill/Singletons/Weather.qml` — weather service
- [ ] **CalendarSync** — `.ics` sync
- [ ] **Notepad** — sticky notes
- [ ] **Todo** — todo list
- [ ] **Translation** — i18n / translation
- [ ] **DateTime** — clock/date formatting
- [ ] **DankSocket** — WebSocket helper
- [ ] **PolkitService** — polkit auth agent
- [ ] **PolkitServiceImpl** — polkit implementation
- [ ] **BooruResponseData** — booru response model

## Deferred (lazy / optional)

- [ ] **AnimeService**
- [ ] **CavaService**
- [ ] **Cliphist** — `modules/pill/Singletons/Cliphist.qml`
- [ ] **EasyEffects**
- [ ] **Emojis**
- [ ] **GowallService**
- [ ] **HyprlandKeybinds**
- [ ] **HyprlandXkb**
- [ ] **KeyringStorage**
- [ ] **LatexRenderer**
- [ ] **LauncherSearch**
- [ ] **NiriKeybinds**
- [ ] **PackageSearch**
- [ ] **RedditService**
- [ ] **SessionWarnings**
- [ ] **SongRec**
- [ ] **Ydotool**

## Submodules (ai/ + network/)

- [ ] **AiModel**
- [ ] **ApiStrategy**
- [ ] **AnthropicApiStrategy**
- [ ] **GeminiApiStrategy**
- [ ] **MistralApiStrategy**
- [ ] **OpenAiApiStrategy**
- [ ] **OpenAiResponseApiStrategy**
- [ ] **AiMessageData**
- [ ] **WifiAccessPoint**
