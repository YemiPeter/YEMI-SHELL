# Audio Service Port — Compatibility Plan

## Step 1 — Current `services/Audio.qml` (read, 63 lines)
Singleton, only `Quickshell` / `Quickshell.Services.Pipewire` / `QtQuick`. Exposes: `sink`, `source`, `muted`, `volume`, `percentage`, `sourceMuted`, `sourceVolume`, `sourcePercentage`, and functions `setVolume`, `toggleMute`, `increaseVolume`, `decreaseVolume`, `setSourceVolume`, `toggleSourceMute`. No per-app/device lists, no mic detail, no protection, no wpctl.

## Step 2 — Files using the Audio service
- **`shell.qml`**: `QsServices.Audio.increaseVolume()`, `decreaseVolume()`, `toggleMute()`, `toggleSourceMute()`
- **`modules/.../VolumePopupWindow.qml`**: reads `audio.muted`, `audio.percentage`, `audio.sourceMuted`, `audio.sourcePercentage`; calls `audio.toggleMute()`, `audio.setVolume()`, `audio.toggleSourceMute()`, `audio.setSourceVolume()`
- **`Volume.qml`**: binds `audio: QsServices.Audio` but renders via `volumeMonitor` (no direct reads)
- **`Bar.qml`, `Launcher.qml`, `ScreenRec.qml`, `Recorder.qml`**: "Audio" references are unrelated (comments, category strings, local `Pipewire.defaultAudioSink` in `Recorder.qml`, local `AudioRow` component). Safe — not touching.

## Step 3 — Public API the UI depends on (must keep working)
- Properties: `muted`, `percentage`, `sourceMuted`, `sourcePercentage`, `sourceVolume`
- Functions: `setVolume(v)`, `toggleMute()`, `increaseVolume()`, `decreaseVolume()`, `setSourceVolume(v)`, `toggleSourceMute()`

## Step 4 — What will be KEPT from current Audio
- `pragma Singleton`, Singleton block, `id: root`
- Imports: `Quickshell`, `Quickshell.Services.Pipewire`, `QtQuick`
- Properties: `sink`, `source`, and all UI-read properties/functions listed above (kept name-for-name so no UI edit needed)

## Step 5 — What will be PORTED from whole-waffle Audio
- `ready` (bool); `rawSink`, `defaultSink`, `_pendingSink`
- `value` (=volume), `hardMaxValue: 2.0`
- `micMuted`, `micVolume`, `micBeingAccessed` (guarded)
- Lists: `outputAppNodes`, `inputAppNodes`, `outputDevices`, `inputDevices`
- `friendlyDeviceName`, `appNodeDisplayName`, `resolveControllableSink` (EasyEffects-aware), `correctType`, `appNodes`, `devices`, `setDefaultNode/setDefaultSink/setDefaultSource`
- Signal: `sinkProtectionTriggered(string reason)`
- Protection + ramp logic inside `setVolume` (satisfies feature #5)
- `incrementVolume`/`decrementVolume` (wpctl relative ±), wired also to `increaseVolume`/`decreaseVolume` names
- `toggleMicMute`, `_refreshMicState`, `_hardwareSourceId`
- wpctl `Process` blocks: `wpctlSetDefaultDevice`, `wpctlSetSinkVolume`, `wpctlIncrementSinkVolume`, `wpctlDecrementSinkVolume`, `wpctlSetMicMute`, `wpctlSetSourceVolume`, `_wpctlGetMicState`
- `PwObjectTracker`; `IpcHandler { target: "audio" }` (volumeUp/Down/mute/micMute)

## Step 6 — Dependencies REMOVED / REPLACED with safe defaults
| Reference dependency | Action |
|---|---|
| `import qs.modules.common` | **Remove** (absent) |
| `import qs.services.deferred` | **Remove** (absent) |
| `Config.options.sounds.theme` / `playSystemSound` | **Remove** `playSystemSound` + `audioTheme`; not in target features (avoids `Config` + `pw-play`) |
| `Config.options.audio.protection.*` | **Replace** with local constants: `volumeProtection: true`, `protectionMax: 0.99`, `protectionMaxIncrease: 0.10` |
| `Translation.tr(...)` | **Replace** with plain strings: `"Illegal increment"`, `"Exceeded max allowed"`, `"Unknown"` |
| `import Quickshell.Io` | **Add** (needed for `Process`/`StdioCollector`; already used in branch) |

## Step 7 — UI changes needed later (not now)
- None required — existing `VolumePopupWindow`/`shell.qml` calls all preserved.
- Future: build mixer UI from `outputAppNodes/inputAppNodes/outputDevices/inputDevices`; toast on `sinkProtectionTriggered`; `micBeingAccessed` indicator.

## Step 8 — Risks / possible compile/runtime errors
1. **`Pipewire.preferredDefaultAudioSink/Source`** — not used anywhere in branch yet; Quickshell-version dependent. Mitigation: wrap assignments in `try/catch` so a missing property degrades gracefully instead of crashing.
2. **`Pipewire.links` / `Pipewire.nodes`** — guard with `?? []` (e.g. `Pipewire.links?.values ?? []`) to avoid undefined access for `micBeingAccessed`.
3. **`IpcHandler`** — harmless if IPC disabled; keep.
4. Must run **`pkill -9 quickshell`** before editing (per rules).

## Step 9 — Acceptance-criteria check (post-edit)
- ✅ Compiles (no missing imports; `Quickshell.Io` added, `common`/`deferred`/`Config`/`Translation` removed)
- ✅ Existing volume control still works (`setVolume`/`toggleMute`/`increaseVolume`/`decreaseVolume`/`setSourceVolume`/`toggleSourceMute` kept)
- ✅ Richer data exposed: `outputAppNodes`, `inputAppNodes`, `outputDevices`, `inputDevices`, `micMuted`, `micVolume`, `micBeingAccessed`, `sinkProtectionTriggered`
- ✅ No whole-waffle dependency chain introduced

---
**Plan ready. Approve and I will make the surgical edit to `services/Audio.qml` (after `pkill -9 quickshell`).**
