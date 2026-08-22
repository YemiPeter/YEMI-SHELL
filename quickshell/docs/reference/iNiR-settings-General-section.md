# iNiR Settings — "General" Section (2nd nav section) Map

> Source repo: `/home/yemi/iNiR` (read-only reference)
> Page entry: `settings.qml` → `pages[1]` → component `modules/settings/GeneralConfig.qml`
> Display name (translated): **"System"** — but it is the **General / System** settings page. It is the **2nd** item in the settings nav, after *Quick*.

```
settings.qml  (ApplicationWindow)
└─ pages[]  index 0 = Quick ............... (QuickConfig.qml)
             index 1 = System/General  --> modules/settings/GeneralConfig.qml   <-- THIS SECTION
             index 2 = Bar, 3 = Background, 4 = Themes, 5 = Panels, ...
```

---

## 1. ASCII Art — Section UI Tree

```
┌──────────────────────────────────────────────────────────────────────┐
│ GeneralConfig.qml  (ContentPage, settingsPageIndex: 1)                │
│                                                                      │
│ ┌─ SettingsCardSection [Audio]            (expanded)                  │
│ │   SettingsGroup                                                        │
│ │   ├─ SettingsSwitch      "Earbang protection"      → audio.protection.enable
│ │   ├─ SettingsDivider                                              │
│ │   └─ ConfigRow (enabled if protection)                             │
│ │      ├─ ConfigSpinBox  "Max allowed increase"  → audio.protection.maxAllowedIncrease
│ │      └─ ConfigSpinBox  "Volume limit"         → audio.protection.maxAllowed
│ │                                                                        │
│ ┌─ SettingsCardSection [Battery]        (collapsed)                  │
│ │   ├─ ConfigRow { Low warning , Critical warning }  → battery.low / .critical
│ │   ├─ SettingsDivider                                              │
│ │   ├─ ConfigRow { Automatic suspend switch , "at" spin } → battery.automaticSuspend / .suspend
│ │   ├─ SettingsDivider                                              │
│ │   ├─ ConfigRow { Full warning }                  → battery.full
│ │   ├─ SettingsDivider                                              │
│ │   ├─ ConfigRow (Battery.chargeLimitSupported)                     │
│ │   │   ├─ SettingsSwitch "Charge limit"        → battery.chargeLimit.enable
│ │   │   └─ ConfigSpinBox  "at" (adjustable)     → battery.chargeLimit.threshold
│ │   └─ StyledText  (live charge-limit status, depends on Battery)   │
│ │                                                                        │
│ ┌─ SettingsCardSection [Language]       (collapsed)                  │
│ │   ├─ ContentSubsection "Interface Language"                        │
│ │   │   └─ ConfigSelectionArray  → language.ui  (auto + all langs)   │
│ │   ├─ SettingsDivider                                              │
│ │   └─ ContentSubsection "Generate translation with Gemini"          │
│ │       └─ ConfigRow { MaterialTextArea (locale) , RippleButtonWithIcon "Generate" }
│ │           └─ Process translationProc → Directories.aiTranslationScriptPath
│ │                                                                        │
│ ┌─ SettingsCardSection [Policies]       (collapsed, hidden in easyMode)
│ │   └─ ConfigRow { ContentSubsection "AI"      → policies.ai         │
│ │               , ContentSubsection "Weeb"    → policies.weeb }       │
│ │                                                                        │
│ ┌─ SettingsCardSection [Sounds]         (collapsed)                  │
│ │   └─ ConfigRow uniform { Battery , Timer , Pomodoro , Notifications switches }
│ │        → sounds.battery / .timer / .pomodoro / .notifications      │
│ │                                                                        │
│ ┌─ SettingsCardSection [Time]           (collapsed)                  │
│ │   ├─ SettingsSwitch "Second precision"   → time.secondPrecision    │
│ │   ├─ SettingsDivider                                              │
│ │   ├─ ContentSubsection "Format" → ConfigSelectionArray → time.format
│ │   ├─ SettingsDivider                                              │
│ │   └─ ContentSubsection "Date formats"                             │
│ │       ├─ ContentSubsectionLabel "Long date format" + MaterialTextField → time.dateFormat
│ │       └─ ContentSubsectionLabel "Short date format"+ MaterialTextField → time.shortDateFormat
│ │                                                                        │
│ ┌─ SettingsCardSection [Keyboard]       (collapsed)                  │
│ │   └─ SettingsGroup (8 switches) → keyboardIndicators.*            │
│ │      showPopup, popup.layout, popup.caps, popup.num,               │
│ │      showPanel, panel.layout, panel.caps, panel.num               │
│ │                                                                        │
│ ┌─ SettingsCardSection [Window Management] (collapsed, hidden in easyMode)
│ │   └─ SettingsSwitch "Confirm before closing windows" → closeConfirm.enabled
│ │                                                                        │
│ ┌─ SettingsCardSection [Work safety]    (collapsed, hidden in easyMode)
│ │   ├─ SettingsSwitch "Hide clipboard images …"   → workSafety.enable.clipboard
│ │   ├─ SettingsDivider                                              │
│ │   └─ SettingsSwitch "Hide sussy/anime wallpapers" → workSafety.enable.wallpaper
│ │                                                                        │
│ ┌─ SettingsCardSection [Boot greeting]  (collapsed)                  │
│ │   ├─ SettingsSwitch "Show greeting on startup" → bootGreeting.enable
│ │   ├─ SettingsDivider                                              │
│ │   ├─ ConfigSpinBox "Auto-dismiss delay (ms)"   → bootGreeting.autoDismissDelay
│ │   ├─ SettingsDivider                                              │
│ │   └─ ConfigRow { Show weather , Show date switches } → bootGreeting.showWeather / .showDate
│ │                                                                        │
│ ┌─ SettingsCardSection [Lock screen]    (collapsed, LARGEST)         │
│ │   ├─ SettingsSwitch (Hyprland only) "Use Hyprlock" → lock.useHyprlock
│ │   ├─ SettingsSwitch "Launch on startup"            → lock.launchOnStartup
│ │   ├─ ContentSubsection "Security"                                │
│ │   │   ├─ SettingsSwitch "Require password to power off" → lock.security.requirePasswordToPower
│ │   │   └─ SettingsSwitch "Also unlock keyring"          → lock.security.unlockKeyring
│ │   ├─ ContentSubsection "Style: general"                          │
│ │   │   ├─ SettingsSwitch "Show notifications"            → lock.notifications.enable
│ │   │   ├─ SettingsSwitch (if enable) "Show notification body" → lock.notifications.showBody
│ │   │   ├─ ConfigSpinBox (if enable) "Max notifications shown" → lock.notifications.maxCount
│ │   │   ├─ ContentSubsection "Notification position" → ConfigSelectionArray → lock.notifications.position
│ │   │   ├─ ContentSubsection "Clock style"   → ConfigSelectionArray → lock.clock.style
│ │   │   ├─ ContentSubsection "Clock position" → ConfigSelectionArray → lock.clock.position
│ │   │   └─ ContentSubsection "Extras" (many switches) → lock.status.* / lock.dim.* / lock.centerClock / lock.showLockedText / lock.materialShapeChars / lock.enableAnimation
│ │   ├─ ContentSubsection "Widgets" → lock.widgets.weather / .media / .powerButtons / .hintText
│ │   └─ ContentSubsection "Style: Blurred"                          │
│ │       ├─ SettingsSwitch "Enable blur"           → lock.blur.enable
│ │       ├─ ConfigSpinBox  "Blur radius"           → lock.blur.radius
│ │       └─ ConfigSpinBox  "Extra wallpaper zoom"  → lock.blur.extraZoom
│ └─────────────────────────────────────────────────────────────────────┘
```

Sub-sections total: **11** (`SettingsCardSection`). Of these, **3 are hidden in easy mode** (`Policies`, `Window Management`, `Work safety` — all gated by `visible: !(Config.options?.settingsUi?.easyMode ?? false)`).

---

## 2. Files the Section "Contains" (local QML components used)

All 15 custom components are defined under **`modules/common/widgets/`**. Every reference below is the *defining* file, plus how many other `.qml` files in iNiR use it.

| # | Component (type) | Defining file | Referenced by (other files) |
|---|------------------|---------------|------------------------------|
| 1 | `ContentPage`            | `modules/common/widgets/ContentPage.qml`            | 18 |
| 2 | `SettingsCardSection`    | `modules/common/widgets/SettingsCardSection.qml`    | 19 |
| 3 | `SettingsGroup`          | `modules/common/widgets/SettingsGroup.qml`          | 18 |
| 4 | `SettingsSwitch`         | `modules/common/widgets/SettingsSwitch.qml`         | 12 |
| 5 | `StyledToolTip`          | `modules/common/widgets/StyledToolTip.qml`         | 127 |
| 6 | `SettingsDivider`        | `modules/common/widgets/SettingsDivider.qml`        | 5 |
| 7 | `ConfigRow`              | `modules/common/widgets/ConfigRow.qml`             | 11 |
| 8 | `ConfigSpinBox`          | `modules/common/widgets/ConfigSpinBox.qml`         | 13 |
| 9 | `StyledText`             | `modules/common/widgets/StyledText.qml`            | 250 |
|10 | `ContentSubsection`      | `modules/common/widgets/ContentSubsection.qml`      | 16 |
|11 | `ConfigSelectionArray`   | `modules/common/widgets/ConfigSelectionArray.qml`   | 18 |
|12 | `MaterialTextArea`       | `modules/common/widgets/MaterialTextArea.qml`       | 4 |
|13 | `RippleButtonWithIcon`   | `modules/common/widgets/RippleButtonWithIcon.qml`   | 10 |
|14 | `ContentSubsectionLabel` | `modules/common/widgets/ContentSubsectionLabel.qml` | 5 |
|15 | `MaterialTextField`      | `modules/common/widgets/MaterialTextField.qml`      | 15 |

**Built-in (non-local) types used:** `Process` (Quickshell.Io), `QtQuick`, `QtQuick.Layouts`, `QtQuick.Controls` (`MaterialTextArea`, `MaterialTextField` wrap `TextArea`/`TextField`), `Qt5Compat.GraphicalEffects`.

### Supporting singletons / services referenced (read, not defined here)

| Service | Defining file | Referenced by (other files) | Role in this section |
|---------|---------------|------------------------------|----------------------|
| `Config`            | `modules/common/Config.qml`            | 324 | `Config.options?.*` reads + `Config.setNestedValue(path, …)` writes |
| `Translation`       | `services/Translation.qml`             | 325 | `Translation.tr(...)`, `Translation.allAvailableLanguages` |
| `Battery`           | `services/Battery.qml`                 | 32  | `chargeLimitSupported/Adjustable/Active`, `currentChargeLimit` gates |
| `Directories`       | `modules/common/Directories.qml`       | 93  | `aiTranslationScriptPath`, `state` |
| `Appearance`        | `modules/common/Appearance.qml`        | 441 | `font.pixelSize.smaller`, `colors.colSubtext` |
| `CompositorService` | `services/CompositorService.qml`       | 79  | `isHyprland` gates the Hyprlock switch |

---

## 3. Where the Section's Config Keys Are Referenced (consumers)

Each row = files that **read** the key (besides `GeneralConfig.qml` itself). "Waffle mirror" notes the parallel waffle settings page `modules/waffle/settings/pages/WGeneralPage.qml`, which mirrors most of this section.

| Config key(s) written | Consumer files (outside GeneralConfig) | Notes |
|-----------------------|------------------------------------------|-------|
| `audio.protection.*` | `services/Audio.qml`, `welcome.qml`, `…/WGeneralPage.qml` | Volume limiter |
| `battery.low` / `battery.critical` / `battery.full` / `battery.automaticSuspend` / `battery.chargeLimit.*` | `services/Battery.qml`, `…/WGeneralPage.qml` | Battery service reads thresholds |
| `policies.ai` | `services/Ai.qml`, `modules/sidebarLeft/SidebarLeftContent.qml`, `modules/settings/InterfaceConfig.qml`, `welcome.qml` | AI feature gate |
| `policies.weeb` | `modules/sidebarLeft/SidebarLeftContent.qml`, `modules/wallpaperSelector/WallpaperSelectorContent.qml`, `modules/settings/QuickConfig.qml`, `modules/settings/InterfaceConfig.qml`, `welcome.qml` | Content gate |
| `language.ui` | `services/Translation.qml`, `…/WGeneralPage.qml` | Drives UI locale |
| `sounds.notifications` / `sounds.battery` / `sounds.timer` / `sounds.pomodoro` | `services/Notifications.qml`, `…/WGeneralPage.qml` | Sound toggles |
| `time.format` / `time.secondPrecision` / `time.dateFormat` / `time.shortDateFormat` | `services/DateTime.qml`, `modules/background/widgets/clock/ClockWidget.qml`, `…/WaffleBackgroundClock.qml` | Clock formatting |
| `keyboardIndicators.*` | `services/KeyboardIndicators.qml`, `…/WGeneralPage.qml` | Caps/Num/Lang popups & panel |
| `workSafety.enable.*` | `modules/background/Background.qml`, `modules/overview/SearchWidget.qml` | Blur/replace NSFW |
| `bootGreeting.*` | `modules/bootGreeting/BootGreeting.qml`, `shell.qml` | Startup greeting |
| `closeConfirm.enabled` | `modules/closeConfirm/CloseConfirm.qml`, `modules/settings/QuickConfig.qml`, `…/WGeneralPage.qml` | Confirm-on-close |
| `lock.*` | `modules/lock/Lock.qml`, `modules/lock/LockSurface.qml`, `modules/waffle/lock/WaffleLockSurface.qml`, `modules/waffle/lock/WaffleLockSurfaceSafe.qml`, `modules/background/Background.qml`, `modules/background/widgets/AbstractBackgroundWidget.qml`, `modules/background/widgets/clock/ClockWidget.qml`, `…/WaffleBackgroundClock.qml`, `…/WInterfacePage.qml` | Lock screen behavior (largest consumer group) |

---

## 4. ASCII Art — File / Dependency Map

```
                         settings.qml  (pages[1].component)
                                    │
                                    ▼
                    modules/settings/GeneralConfig.qml
                       (ContentPage, 977 lines)
            ┌───────────────┬───────────────┬───────────────┬───────────────┐
            ▼               ▼               ▼               ▼               ▼
   ┌────────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
   │ modules/common │ │ modules/common│ │  services/   │ │  services/   │ │ services/     │
   │ /widgets/*.qml │ │ /Config.qml  │ │ Translation  │ │ Battery.qml │ │ Compositor-   │
   │  (15 comps)    │ │  (Config)    │ │  .qml        │ │             │ │ Service.qml   │
   └───────┬────────┘ └──────┬───────┘ └──────┬───────┘ └──────┬───────┘ └──────┬─────────┘
           │                 │                │                │                │
   SettingsCardSection  Config.setNestedValue  Translation.tr   Battery.charge-  CompositorService
   SettingsGroup        Config.options?.…       allAvailable-    LimitSupported  .isHyprland
   SettingsSwitch       (324 refs)            Languages (325)    (32 refs)        (79 refs)
   SettingsDivider                                          Directories.aiTrans-
   ConfigRow             modules/common/                              lationScriptPath
   ConfigSpinBox         Directories.qml (93) ───────────────►  Process in GenCfg
   StyledText (250)
   ContentSubsection     modules/common/Appearance.qml (441)
   ConfigSelectionArray  ─► font.pixelSize.smaller, colors.colSubtext
   MaterialTextArea
   RippleButtonWithIcon
   ContentSubsectionLabel
   MaterialTextField

   CONSUMERS (read the keys written here):
   services/{Audio,Battery,Translation,Notifications,DateTime,KeyboardIndicators,Ai}.qml
   modules/{lock/*, background/*, overview/SearchWidget, sidebarLeft/*, bootGreeting/*,
            closeConfirm/*, wallpaperSelector/*}
   shell.qml  +  waffle mirror: modules/waffle/settings/pages/WGeneralPage.qml
```

---

## 5. Key Findings

1. **The "General" section is `GeneralConfig.qml`**, registered as the **2nd** settings page (`pages[1]`) in `settings.qml`, displayed with the translated title **"System"**.
2. It is a **single 977-line QML file** that composes **15 reusable widget components** — all defined in `modules/common/widgets/` — plus 6 singletons/services. No page-specific helper files of its own; everything it "contains" is shared, generic settings UI.
3. **Easy-mode gating:** `Policies`, `Window Management`, and `Work safety` sub-sections are hidden when `settingsUi.easyMode` is on. The Lock screen and most others always show.
4. **Waffle has a parallel page:** `modules/waffle/settings/pages/WGeneralPage.qml` mirrors most of this section (it appears as a consumer of nearly every key). So changes here propagate to waffle settings too.
5. **The `lock.*` key tree is the largest consumer group** — 10 files read lock settings, including both the Material lock (`modules/lock/*`) and the waffle lock surfaces (`modules/waffle/lock/*`).
6. **Hidden Hyprland-only control:** the "Use Hyprlock" switch is guarded by `CompositorService.isHyprland` — on the user's **Niri** setup this control is invisible (Hyprland path inert), which matches earlier findings that the Hyprlock branch in `Lock.qml` is unused under Niri.
7. **External process dependency:** the Language → "Generate translation with Gemini" button shells out via `Directories.aiTranslationScriptPath` (a `Process` spawned inside the page). Not a file in the section, but a runtime dependency.
8. **All 15 widgets and 6 services are heavily reused** elsewhere (StyledText alone: 250 files; Appearance: 441; Config: 324), so editing any of them affects the whole shell, not just settings.
