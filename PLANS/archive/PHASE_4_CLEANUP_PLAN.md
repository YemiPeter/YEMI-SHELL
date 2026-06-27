# Phase 4 Cleanup Pass — Implementation Plan

> **Status: EXECUTED (2026-06-27).** Steps 1-2 (qmldir cleanups) were already done before this plan was written. Step 3 (Hyprland abstraction) is in progress — compositor signals added, 5 file rewrites pending. This plan's content is now tracked in `QUICKSHELL_MASTER_PLAN.md` Phase 4B section.

## Current State (verified via grep/read_file)

### 1. Flags.qml Duplication
- `singletons/Flags.qml` — **already merged** (25 properties, FileView persistence, paletteMode default "dynamic", uiFont default "")
- `modules/pill/Singletons/Flags.qml` — **file does not exist** (already deleted)
- `modules/pill/Singletons/qmldir` line 2 — **still references** `singleton Flags Flags.qml` → **must remove this line**

### 2. Theme.qml + Dyn.qml Duplication
- `modules/pill/Singletons/Theme.qml` — **file does not exist**
- `modules/pill/Singletons/Dyn.qml` — **file does not exist**
- `modules/pill/Singletons/qmldir` lines 4-5 — **still reference** `singleton Theme Theme.qml` and `singleton Dyn Dyn.qml` → **must remove these lines**

### 3. Service Stubs
- `services/Mpris.qml`, `services/Pipewire.qml`, `services/SystemTray.qml`, `services/Notifications.qml` — **files do not exist**
- `services/qmldir` lines 16-19 — **still reference** all four → **must remove these lines**
- Pill files already import real services directly (confirmed via grep)

### 4. Hyprland Direct Coupling — 5 Files
- `compositor/` abstraction exists and is functional (`Compositor.qml` → `Hyprland.qml` | `Niri.qml`)
- 5 files still import `Quickshell.Hyprland` directly

### 5. Bar.qml Center Pill
- Already confirmed: `Bar.qml` line 120-126 loads `Pill.Pill` correctly

## Implementation Steps

### Step 1: Clean up `modules/pill/Singletons/qmldir`
Remove lines referencing Flags, Theme, Dyn (lines 2, 4, 5) since those files don't exist and the project-wide singletons are used instead.

### Step 2: Clean up `services/qmldir`
Remove lines 16-19 referencing Mpris, Pipewire, SystemTray, Notifications stubs.

### Step 3: Rewrite 5 Hyprland-coupled files to use Compositor abstraction

#### 3a. `modules/pill/Singletons/Workspacerules.qml`
- Replace `import Quickshell.Hyprland` with `import "../../compositor"`
- Replace `Hyprland` references with `Compositor`
- Replace `Hyprland.onRawEvent` with `Compositor` equivalent
- Keep `hyprctl` process call (it's compositor-specific and the abstraction doesn't wrap this)
- Add `// TODO: Niri parity` comment

#### 3b. `modules/pill/Workspaces.qml`
- Replace `import Quickshell.Hyprland` with `import "../compositor"` (relative to modules/)
- Replace `Hyprland.workspaces` → `Compositor.workspaces`
- Replace `Hyprland.monitors` → `Compositor.monitors`
- Replace `Hyprland.dispatch(...)` → `Compositor.dispatch(...)`

#### 3c. `modules/pill/MinimizedTray.qml`
- Replace `import Quickshell.Hyprland` with `import "../compositor"`
- Replace `Hyprland.toplevels` → `Compositor.toplevels`
- Replace `Hyprland.dispatch(...)` → `Compositor.dispatch(...)`

#### 3d. `modules/pill/Osd.qml`
- Replace `import Quickshell.Hyprland` with `import "../compositor"`
- Replace `Hyprland.monitors` → `Compositor.monitors`

#### 3e. `modules/pill/Power.qml`
- Replace `import Quickshell.Hyprland` with `import "../compositor"`
- Replace `Hyprland.dispatch(...)` → `Compositor.dispatch(...)`

### Step 4: Verification
- Run greps to confirm no remaining references to old paths
- Report results

## Files to Modify
| File | Change |
|------|--------|
| `modules/pill/Singletons/qmldir` | Remove lines 2, 4, 5 |
| `services/qmldir` | Remove lines 16-19 |
| `modules/pill/Singletons/Workspacerules.qml` | Rewrite imports + Hyprland refs → Compositor |
| `modules/pill/Workspaces.qml` | Rewrite imports + Hyprland refs → Compositor |
| `modules/pill/MinimizedTray.qml` | Rewrite imports + Hyprland refs → Compositor |
| `modules/pill/Osd.qml` | Rewrite imports + Hyprland refs → Compositor |
| `modules/pill/Power.qml` | Rewrite imports + Hyprland refs → Compositor |

## Verification Commands
```bash
# After Step 1
grep -n "Flags\|Theme\|Dyn" modules/pill/Singletons/qmldir

# After Step 2
grep -n "Mpris\|Pipewire\|SystemTray\|Notifications" services/qmldir

# After Step 3
grep -rn "Quickshell\.Hyprland" modules/pill/

# Bar.qml confirmation
grep -n "Pill" modules/bar/Bar.qml
```
