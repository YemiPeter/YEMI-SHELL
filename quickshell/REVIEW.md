# Quickshell Settings Rewire — Review

## Summary

The `shell.qml` was already modernized (no stale `fullSettings` references). The task was to fix the remaining errors preventing the settings IPC handler and LazyLoader from working.

## Changes Made

### 1. `shell.qml` — Added missing imports (lines 1-3)
- Added `import qs` — makes `GlobalStates` singleton resolvable in the settings IPC handler (`GlobalStates.settingsOverlayOpen = !...`)
- Added `import qs.config` — makes `Config` singleton resolvable in both the IPC handler (`Config.options?.settingsUi?.overlayMode`) and the LazyLoader (`Config.ready`)

### 2. `config/Config.qml` — Added missing properties
- Added `readonly property bool ready: true` — required by the LazyLoader's `active` binding
- Added `readonly property var options` with `settingsUi: { overlayMode: false }` — required by the IPC handler and SettingsOverlay.qml

### 3. `modules/pill/Updates.qml` — Added missing import (line 2)
- Added `import Quickshell` — required for `Quickshell.env()` calls on lines 27-28

### 4. Pre-existing fixes (already in place)
- `services/qmldir` — removed 17 missing singleton entries
- `services/network` — symlink to `inir/network` created to resolve `qs.services.network` module

## Test Results

### Startup Log (`/tmp/qs3.log`)
- "Configuration Loaded" — success
- No `Config is not defined` errors
- No `GlobalStates is not defined` errors
- No `Quickshell is not defined` errors in Updates.qml
- No `Unable to assign [undefined] to bool` on LazyLoader

### Runtime Log (after `qs ipc call settings toggle`)
- No `referenceerror` patterns
- No `unavailable` module errors
- No `not defined` errors
- No `unable to assign` warnings

### IPC Call
- `qs ipc call settings toggle` — executed with no errors

### Script Verification
- `scripts/settings-window.sh` exists and is executable
- References `settings/settings.qml` which exists at `.config/quickshell/settings/settings.qml`

## Notes

- `overlayMode` is set to `false`, so the IPC handler launches `scripts/settings-window.sh` (external settings window) rather than the LazyLoader overlay (which stays `active: false`). This is the intended non-overlay mode behavior.
- To enable overlay mode, set `overlayMode: true` in `config/Config.qml` — the LazyLoader will then activate on `settings toggle`.
