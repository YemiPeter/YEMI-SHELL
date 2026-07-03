# Topbar Review Report

> **Date**: 2026-03-07
> **Scope**: `modules/bar/` — 14 QML files
> **Review types**: QML Code Review (qt-qml-review), UI Design Audit (qt-ui-design), Qt C++ Review (qt-cpp-review)

---

## Table of Contents

1. [QML Code Review](#1-qml-code-review)
   - [Lint Findings](#11-lint-findings)
   - [Deep Analysis Findings](#12-deep-analysis-findings)
   - [Investigation Targets](#13-investigation-targets)
   - [Summary](#14-summary)
2. [UI Design Audit](#2-ui-design-audit)
   - [Critical Findings](#21-critical)
   - [Warnings](#22-warnings)
   - [Opportunities](#23-opportunities)
   - [Summary](#24-summary)
3. [Qt C++ Review](#3-qt-c-review)
4. [Files Reviewed](#4-files-reviewed)

---

## 1. QML Code Review

**Scope**: files: `modules/bar/Bar.qml`, `modules/bar/BarWrapper.qml`, `modules/bar/components/Workspaces.qml`, `modules/bar/components/Workspace.qml`, `modules/bar/components/Network.qml`, `modules/bar/components/Bluetooth.qml`, `modules/bar/components/Brightness.qml`, `modules/bar/components/Volume.qml`, `modules/bar/components/Battery.qml`, `modules/bar/components/StatusIndicators.qml`, `modules/bar/components/SystemTray.qml`, `modules/bar/components/MediaPlayer.qml`, `modules/bar/components/Clock.qml`, `modules/bar/components/NotificationPopups.qml`

**Files reviewed**: 14
**Issues found**: 12 (4 from lint, 8 from deep analysis)
**qmllint**: not available (no system qmllint binary detected)

---

### 1.1 Lint findings

#### [L-001] IMP-4: Import ordering — Quickshell before QtQuick
- **File**: `modules/bar/Bar.qml:1`
- **Rule**: IMP-4 (Import ordering)
- **Finding**: `import Quickshell` (line 1) appears before `import QtQuick 6.10` (line 2), `import QtQuick.Layouts 6.10` (line 3), and `import QtQuick.Effects` (line 4). Convention requires Qt modules first, then third-party.
- **Mitigation**: Move `import Quickshell` after all `import QtQuick.*` lines.

#### [L-002] IMP-4: Import ordering — Quickshell before QtQuick
- **File**: `modules/bar/BarWrapper.qml:1`
- **Rule**: IMP-4 (Import ordering)
- **Finding**: `import Quickshell` (line 1) and `import Quickshell.Wayland` (line 2) appear before `import QtQuick 6.10` (line 3).
- **Mitigation**: Reorder to place `import QtQuick 6.10` first.

#### [L-003] IMP-4: Import ordering — Quickshell before QtQuick
- **File**: `modules/bar/components/Workspaces.qml:1`
- **Rule**: IMP-4 (Import ordering)
- **Finding**: `import Quickshell` (line 1) appears before `import QtQuick 6.10` (line 2) and `import QtQuick.Layouts 6.10` (line 3).
- **Mitigation**: Reorder to place `import QtQuick 6.10` first.

#### [L-004] IMP-4: Import ordering — Quickshell before QtQuick
- **File**: `modules/bar/components/NotificationPopups.qml:4`
- **Rule**: IMP-4 (Import ordering)
- **Finding**: `import Quickshell` (line 4) and `import Quickshell.Wayland` (line 5) appear after `import QtQuick.Effects` (line 3) but before local project imports. Quickshell imports should be grouped together after all QtQuick imports.
- **Mitigation**: Group Quickshell imports together: move lines 4-5 to appear after all `import QtQuick.*` lines and before local project imports.

---

### 1.2 Deep analysis findings

#### [D-001] STY-1: Root element missing `id: root`
- **File**: `modules/bar/BarWrapper.qml:6`
- **Category**: Performance & Quality
- **Confidence**: 100/100
- **Finding**: The root `Scope` element has no `id` at all. The only `id` in the file is `window` on the inner `PanelWindow` child. This breaks the project convention where all other root elements consistently use `id: root`.
- **Trace**: Compared against all other topbar files — every other root element uses `id: root` (Bar.qml, Workspace.qml, Network.qml, Bluetooth.qml, Brightness.qml, Volume.qml, Battery.qml, MediaPlayer.qml, Clock.qml, StatusIndicators.qml).
- **Mitigation**: Add `id: root` to the `Scope` element on line 6.

#### [D-002] PRF-1: Transparent Rectangle in delegate
- **File**: `modules/bar/components/SystemTray.qml:13`
- **Category**: Performance & Quality
- **Confidence**: 100/100
- **Finding**: The `Repeater` delegate is a `Rectangle` with `color: "transparent"` (line 17). This creates a scene graph geometry node even though nothing is rendered. The element is purely a layout/click container.
- **Trace**: The Rectangle has no visual fill — it only contains an `Image` and `MouseArea`. The `color: "transparent"` confirms no visual rendering is needed.
- **Mitigation**: Replace `Rectangle` with `Item` as the delegate root. `Item` generates no geometry node and is the correct choice for non-visual containers.

#### [D-003] BND-2: Imperative assignment destroys binding — `root.scale`
- **File**: `modules/bar/components/Workspace.qml:125`
- **Category**: Bindings & Properties
- **Confidence**: 100/100
- **Finding**: `onPressed` (line 125) sets `root.scale = 0.85` and `onReleased` (line 129) sets `root.scale = 1.0` imperatively. However, `scale: 1.0` is declared as a property binding on line 143. The imperative assignments in `onPressed`/`onReleased` permanently replace the binding with a static value. After the first press, the `scale` property is no longer reactive.
- **Trace**: Line 143: `scale: 1.0` is a binding. Lines 125-130: `onPressed { root.scale = 0.85 }` / `onReleased { root.scale = 1.0 }` are imperative assignments that destroy the binding. The `Behavior on scale` (lines 69-74) still animates transitions, but the binding itself is gone after first interaction.
- **Mitigation**: Remove the `scale: 1.0` binding on line 143. The imperative assignments in the MouseArea handlers will then work correctly as the sole source of truth for `scale`, and the `Behavior on scale` will continue to animate transitions.

#### [D-004] BND-2: Imperative assignment destroys binding — `clockLabel.text`
- **File**: `modules/bar/components/Clock.qml:26`
- **Category**: Bindings & Properties
- **Confidence**: 100/100
- **Finding**: The `Timer.onTriggered` handler (line 26) sets `clockLabel.text = Qt.formatDateTime(new Date(), "hh:mm AP")` imperatively. However, `clockLabel.text` is also set via a binding on line 14: `text: Qt.formatDateTime(new Date(), "hh:mm AP")`. The imperative assignment in `onTriggered` permanently replaces the binding with a static value. After the first timer tick, the text property is no longer reactive.
- **Trace**: Line 14: `text: Qt.formatDateTime(new Date(), "hh:mm AP")` is a binding. Line 26: `onTriggered: clockLabel.text = Qt.formatDateTime(new Date(), "hh:mm AP")` is an imperative assignment that destroys the binding on first tick.
- **Mitigation**: Remove the binding on line 14 and keep only the `onTriggered` handler. The binding cannot auto-update since `new Date()` is not a QML property, so the timer-driven approach is correct — but the binding must be removed to avoid the conflict.

#### [D-005] BND-2: Imperative assignment destroys binding — `titleText.x`
- **File**: `modules/bar/components/MediaPlayer.qml:35`
- **Category**: Bindings & Properties
- **Confidence**: 100/100
- **Finding**: The `onIsPlayingChanged` handler (line 33) sets `titleText.x = titleText.needsScroll ? 0 : (80 - titleText.implicitWidth) / 2` imperatively. However, `titleText.x` has a binding on line 195: `x: needsScroll ? 0 : (80 - implicitWidth) / 2`. The imperative assignment in `onIsPlayingChanged` permanently replaces the binding. After the first play/pause toggle, the x position is no longer reactive to text changes.
- **Trace**: Line 195: `x: needsScroll ? 0 : (80 - implicitWidth) / 2` is a binding. Line 35: `titleText.x = ...` is an imperative assignment that destroys the binding.
- **Mitigation**: Remove the imperative assignment in `onIsPlayingChanged` (line 35). The binding on line 195 already handles the non-scrolling case correctly. The marquee animation overrides `x` via `NumberAnimation` target, which is fine since animations do not destroy bindings.

#### [D-006] BND-2: Imperative assignment destroys binding — `progressAnim.running`
- **File**: `modules/bar/components/NotificationPopups.qml:431`
- **Category**: Bindings & Properties
- **Confidence**: 95/100
- **Finding**: Multiple signal handlers set `progressAnim.running = false` (line 431) and `progressAnim.running = true` (line 439) imperatively. However, `progressAnim` has a `running` property set via binding on line 395: `running: notifCard.isVisible && !notifCard.isHovered && !notifCard.isDragging`. The imperative assignments in `onEntered`/`onExited`/`onReleased` handlers permanently replace this binding.
- **Trace**: Line 395: `running: ...` is a binding. Lines 431, 439, 486, 538: `progressAnim.running = false/true` are imperative assignments that destroy the binding.
- **Mitigation**: Remove the `progressAnim.running = false/true` imperative assignments. The `onEntered` handler already sets `notifCard.isHovered = true` (line 429), which will cause the binding on line 395 to re-evaluate and stop the animation automatically. Let the binding react to state changes instead of setting `running` directly.

#### [D-007] PRF-2: `opacity: 0` without animation context
- **File**: `modules/bar/components/NotificationPopups.qml:407`
- **Category**: Performance & Quality
- **Confidence**: 90/100
- **Finding**: The `hoverLayer` Rectangle (line 402) has `opacity: notifCard.isHovered && !notifCard.isDragging ? 0.03 : 0` (line 407). The `0` value is the non-hovered default state, not a transition endpoint. The Rectangle still exists in the scene graph when invisible, incurring rendering overhead.
- **Trace**: Line 407: `opacity: ... ? 0.03 : 0` — the `0` branch is the non-hovered state. While a `Behavior on opacity` exists (line 409), the node is always present.
- **Mitigation**: Add `visible: notifCard.isHovered` to completely remove the node from the scene graph when not hovered, while keeping the `Behavior on opacity` for the fade-in transition.

#### [D-008] LDR-1: Loader.item access without status guard
- **File**: `modules/bar/components/StatusIndicators.qml:345`
- **Category**: Component Loading & Lifecycle
- **Confidence**: 95/100
- **Finding**: `statusIndicatorsLoader.item?.hasActiveIndicators` (line 345) uses optional chaining which prevents crashes, but the Loader has `asynchronous: true` (line 344), meaning `item` will be `null` until the component finishes loading asynchronously. The `visible` property will briefly be `false` (due to `?? false`), then snap to the correct value once loaded — causing a brief visual flicker on startup.
- **Trace**: Line 344: `asynchronous: true`. Line 345: `visible: item?.hasActiveIndicators ?? false`. The Loader's `item` is `null` until async loading completes.
- **Mitigation**: Either set `asynchronous: false` on the Loader, or add a `Loader.onStatusChanged` handler to set visibility only when `status === Loader.Ready`.

---

### 1.3 Investigation targets

#### [I-001] ORD-1: Attribute ordering — `scale` after child objects
- **File**: `modules/bar/components/Workspace.qml:143`
- **Category**: Performance & Quality
- **Confidence**: 75/100
- **Finding**: `scale: 1.0` is declared on line 143, after all child objects (MouseArea, inner Rectangles) and signal handlers (onClicked, onPressed, onReleased, onEntered, onExited). The QML attribute ordering convention places property assignments before child objects and signal handlers.
- **Unverified because**: The ordering convention is a style guideline, not a functional issue. The code works correctly regardless of order. The `scale` property may have been placed at the end intentionally as a "default" value.
- **How to verify**: Check if the project follows strict QML attribute ordering conventions. If so, move `scale: 1.0` to the property assignments section (after `radius: height / 2` on line 38).

---

### 1.4 Summary

| Category | Lint | Deep | Investigate | Total |
|----------|------|------|-------------|-------|
| Imports (IMP) | 4 | 0 | 0 | 4 |
| Style (STY) | 0 | 1 | 0 | 1 |
| Performance (PRF) | 0 | 2 | 0 | 2 |
| Bindings (BND) | 0 | 4 | 0 | 4 |
| Loading (LDR) | 0 | 1 | 0 | 1 |
| Ordering (ORD) | 0 | 0 | 1 | 1 |
| **Total** | **4** | **8** | **1** | **13** |

Findings below confidence 60 are suppressed entirely.

---

## 2. UI Design Audit

**Target platform**: Desktop Linux, Wayland (Quickshell)
**Screen shape**: Rectangle
**Resolution**: Variable (baseline 1080p with dynamic scaling via `screen.height / 1080`)
**Design system**: Custom Material Design 3-inspired system with theme tokens (`onGlow`, `cream`, `cardBot`, `cardTop`, `verm`, `vermBurn`) and Material3Anim timing constants
**Viewing distance**: Desktop ~60 cm
**Locale/Input**: English, keyboard + mouse/pointer

---

### 2.1 Critical

#### [CRITICAL-001] Typography: Body text far below 16 px minimum
- **File**: All bar component files
- **Category**: Typography
- **Severity**: **Critical** — Violates WCAG readability and the skill's §1.2 rule that body text minimum is 16 px at desktop viewing distance.
- **Finding**: All text in the topbar uses `font.pixelSize` values of 10–14 px:
  - Network.qml: `font.pixelSize: 10` (line 72), `font.pixelSize: 14` (line 43)
  - Bluetooth.qml: `font.pixelSize: 10` (line 72), `font.pixelSize: 14` (line 43)
  - Brightness.qml: `font.pixelSize: 10` (line 63), `font.pixelSize: 14` (line 39)
  - Volume.qml: `font.pixelSize: 10` (line 66), `font.pixelSize: 14` (line 42)
  - Battery.qml: `font.pixelSize: 11` (line 202), `font.pixelSize: 9` (line 184)
  - MediaPlayer.qml: `font.pixelSize: 10` (lines 60, 189), `font.pixelSize: 13-14` (lines 266, 319)
  - Clock.qml: `font.pixelSize: 11` (line 16)
  - StatusIndicators.qml: `font.pixelSize: 12` (line 54)
- **Impact**: Text at 10 px is approximately 7.5 pt — far below the 12 pt (16 px) minimum for comfortable desktop reading. Users with less-than-perfect vision or higher DPI displays will struggle. This also violates WCAG 2.2 SC 1.4.4 (Resize Text) since `font.pixelSize` does not respect OS font scaling.
- **Mitigation**: Use `font.pointSize` instead of `font.pixelSize` to respect OS DPI scaling, or derive sizes from a singleton driven by `Screen.pixelDensity`. At minimum, increase body text to 12–14 px for secondary labels and 16 px for primary information. The 10 px text in Network, Bluetooth, and MediaPlayer labels is too small for comfortable reading.

#### [CRITICAL-002] Colour: Colour used as sole carrier of state
- **File**: `modules/bar/components/Workspace.qml:31-35`
- **Category**: Colour / Accessibility
- **Severity**: **Critical** — Violates WCAG 2.2 and §2 (Accessibility): "Never rely on color alone to communicate state — always pair with shape, icon, or text."
- **Finding**: Workspace indicators use colour alone to distinguish state:
  - Active: `QsSingletons.Theme.onGlow` (a colour)
  - Occupied: `rgba(cream, 0.5)` (a colour)
  - Empty: `rgba(cream, 0.2)` (a colour)
  The only shape difference is size (28×10 active, 10×6 occupied, 6×6 empty), but the size difference alone may not be distinguishable to colour-blind users or at a glance.
- **Impact**: A user with deuteranopia (red-green colour blindness, ~8% of males) may not be able to distinguish active from occupied workspaces if `onGlow` and `cream` have similar luminance. The size difference helps but is subtle.
- **Mitigation**: Add a secondary visual cue — for example, the active workspace could have a filled dot vs. outlined dot, or an underline indicator. Alternatively, ensure the luminance contrast between `onGlow` and `cream` is at least 3:1 for the active vs. non-active states.

---

### 2.2 Warnings

#### [WARNING-001] Motion: Animation durations exceed 400 ms budget
- **File**: `modules/bar/components/Battery.qml:264`
- **Category**: Motion
- **Severity**: **Warning** — §1.1 states "Never exceed 500 ms for any UI animation — slower feels broken."
- **Finding**: The liquid fill animation in Battery.qml has `duration: 1500` (line 264) — 1.5 seconds for the fill animation when plugged in. This is 3× the maximum recommended duration.
- **Impact**: A 1.5-second animation feels sluggish and unresponsive. Users may perceive the system as slow or think the animation is stuck.
- **Mitigation**: Reduce the liquid fill animation to 300–400 ms. The Samsung-style expanded pill effect can still be visually impressive at a faster speed.

#### [WARNING-002] Motion: Animating geometry properties triggers layout
- **File**: Multiple files
- **Category**: Motion / Performance
- **Severity**: **Warning** — §1.1: "Animate only `transform` and `opacity` in QML — these are GPU-composited. Animating geometry (width, height, anchors) triggers layout recalculation and causes jank."
- **Finding**: Multiple `Behavior on width` animations exist throughout the bar:
  - `Bar.qml` lines 61, 135, 224, 313
  - `Battery.qml` lines 73, 259
  - `StatusIndicators.qml` lines 25, 46, 88
  - `NotificationPopups.qml` line 60
- **Impact**: Animating `width` forces the scene graph to recalculate the layout on every frame, which can cause jank, especially on lower-end hardware or when multiple animations run simultaneously.
- **Mitigation**: Where possible, use `scale` transforms instead of animating `width`. For the battery fill, consider using a `clip` mask with a scaled child rather than animating the rectangle's width directly.

#### [WARNING-003] Typography: No modular type scale, hardcoded pixel sizes
- **File**: All bar component files
- **Category**: Typography
- **Severity**: **Warning** — §1.2 recommends a modular type scale with role-based tokens.
- **Finding**: Font sizes are hardcoded as `font.pixelSize` values scattered across all components: 9, 10, 11, 12, 13, 14, 16 px. There is no central type scale singleton, no role-based naming, and no consistent ratio between sizes. The sizes appear arbitrary (10, 11, 12, 13, 14 — not following any modular scale).
- **Impact**: Inconsistent typography creates visual noise. Hardcoded `font.pixelSize` does not respect OS DPI scaling, making text potentially unreadable on high-DPI displays or for users who have increased their system font size.
- **Mitigation**: Create a `TypeScale` singleton (as described in §1.2) with role-based tokens (e.g., `TypeScale.caption`, `TypeScale.body`, `TypeScale.heading`). Use `font.pointSize` or derive from `Screen.pixelDensity` to respect OS scaling. Limit to 3–4 distinct sizes per screen.

#### [WARNING-004] Colour: No dark mode variant
- **File**: All bar component files
- **Category**: Colour
- **Severity**: **Warning** — §1.4: "Design for both light and dark themes from the start."
- **Finding**: The bar uses theme tokens from `QsSingletons.Theme` (which appears to support dynamic theming via Matugen), but the bar components hardcode alpha values and specific colour choices that may not adapt correctly to both light and dark themes. For example:
  - `pillBg: Qt.rgba(Theme.cardBot.r, ..., 0.7)` — the 0.7 alpha may look correct on dark but washed out on light
  - `pillBorder: Qt.rgba(Theme.cream.r, ..., 0.10)` — `cream` is likely a light colour, which works on dark backgrounds but would be invisible on light backgrounds
  - `color: Qt.rgba(1, 1, 1, 0.04)` (Bar.qml line 77) — hardcoded white highlight that assumes a dark background
- **Impact**: If the user switches to a light colour scheme, the bar may become unreadable — light text on light backgrounds, invisible borders, and misplaced highlights.
- **Mitigation**: Audit all hardcoded `Qt.rgba()` calls with white (1,1,1) or black (0,0,0) assumptions. Use theme tokens that adapt to both light and dark modes. The highlight effect (white gradient on top of pills) should use a token like `Theme.surfaceHighlight` rather than hardcoded white.

#### [WARNING-005] Keyboard: No keyboard navigation for bar controls
- **File**: All bar component files
- **Category**: Accessibility / Keyboard
- **Severity**: **Warning** — §1.3: "Full keyboard navigability is required."
- **Finding**: All interactive elements in the bar use `MouseArea` exclusively. There is no `KeyNavigation`, no `activeFocus` handling, and no keyboard-accessible alternatives for:
  - Workspace switching (click only)
  - Network/Bluetooth/Brightness/Volume/Battery popup toggles (click only)
  - Media playback controls (click only)
  - Status indicator toggles (click only)
- **Impact**: Users who rely on keyboard navigation (including many power users, users with motor disabilities, and users of tiling window managers) cannot interact with the bar without a mouse.
- **Mitigation**: Add `KeyNavigation.tab` / `KeyNavigation.backtab` chains between interactive elements. Add `Keys.onPressed` / `Keys.onReturnPressed` handlers to MouseArea-based controls. Ensure focus indicators are visible (e.g., a focus ring on the active control).

#### [WARNING-006] Motion: No reduced-motion preference support
- **File**: All bar component files
- **Category**: Motion / Accessibility
- **Severity**: **Warning** — §1.1: "Honour user preference for reduced motion."
- **Finding**: There is no project-level setting to disable or reduce animations. The bar has numerous animations (workspace transitions, battery fill, media player marquee, volume/brightness pulses, notification entrance/exit) with no gating mechanism.
- **Impact**: Users with vestibular disorders or who prefer reduced motion cannot disable animations. Qt 6.x has no built-in `prefers-reduced-motion` equivalent, so a project-level setting is required.
- **Mitigation**: Add a singleton property (e.g., `Flags.reducedMotion`) that gates all non-essential animations. Wrap animations in `enabled: !Flags.reducedMotion` and provide instant transitions when disabled.

---

### 2.3 Opportunities

#### [OPPORTUNITY-001] Typography: System font usage
- **File**: All bar component files
- **Category**: Typography
- **Severity**: **Opportunity** — §1.2: "System font first. Only introduce a custom font when there is a brand requirement."
- **Finding**: The bar uses "JetBrainsMono Nerd Font" (a monospace font) for all text — including labels, percentages, and media titles. Monospace fonts are designed for code and tabular data, not for reading body text. They have wider character spacing and can be less legible for continuous text at small sizes.
- **Impact**: While this is a deliberate aesthetic choice common in "riced" desktop environments, it reduces readability for longer text (e.g., network names, media titles, notification text). Monospace fonts at 10 px are particularly hard to read.
- **Mitigation**: Consider using a proportional font (e.g., the system UI font) for labels and body text, reserving the monospace font for data values (percentages, clock time) where tabular alignment is beneficial.

#### [OPPORTUNITY-002] Layout: Hit targets below recommended minimum
- **File**: `modules/bar/components/Workspace.qml:118`
- **Category**: Interaction
- **Severity**: **Opportunity** — §1.3 recommends minimum touch/click targets.
- **Finding**: Workspace indicators have `implicitWidth` as small as 6 px (empty workspace) and 10 px (occupied workspace). While the MouseArea uses `anchors.margins: -4` to expand the hit area, the visual indicator itself is very small. The effective hit area is approximately 14×14 px for empty workspaces.
- **Impact**: The 44 px recommended minimum click target (desktop) is not met. While the negative margins help, the small visual target makes it harder to aim at, especially for users with motor control difficulties or on high-DPI displays.
- **Mitigation**: Increase the minimum visual size of workspace indicators, or use a larger invisible hit area (e.g., a transparent `Item` with fixed 24×24 px size behind the small visual dot).

---

### 2.4 Summary

| Severity | Count | Key issues |
|----------|-------|------------|
| **Critical** | 2 | Typography too small (10 px body text), colour as sole state carrier |
| **Warning** | 5 | Animation durations exceed limits, geometry animation, no type scale, no dark mode adaptation, no keyboard navigation, no reduced-motion support |
| **Opportunity** | 2 | Monospace font for all text, small hit targets |
| **Total** | **9** | |

---

## 3. Qt C++ Review

**Not applicable** — the topbar is written entirely in QML. No C++ source files (`.cpp`, `.h`, `.hpp`) were found in the `modules/bar/` directory. The qt-cpp-review skill targets C++ code and was not triggered.

---

## 4. Files Reviewed

| # | File | Lines | Role |
|---|------|-------|------|
| 1 | `modules/bar/Bar.qml` | 394 | Main bar layout — left (workspaces), center (spacer), right (connectivity, audio, power pills) |
| 2 | `modules/bar/BarWrapper.qml` | 45 | PanelWindow wrapper — creates a bar per screen |
| 3 | `modules/bar/components/Workspaces.qml` | 50 | Workspace repeater — loads Workspace.qml for each workspace |
| 4 | `modules/bar/components/Workspace.qml` | 144 | Individual workspace indicator — animated dot/pill |
| 5 | `modules/bar/components/Network.qml` | 98 | WiFi status indicator with icon + SSID |
| 6 | `modules/bar/components/Bluetooth.qml` | 98 | Bluetooth status indicator with icon + device name |
| 7 | `modules/bar/components/Brightness.qml` | 137 | Brightness indicator with icon + percentage, wheel control |
| 8 | `modules/bar/components/Volume.qml` | 151 | Volume indicator with icon + percentage, wheel control |
| 9 | `modules/bar/components/Battery.qml` | 312 | Battery indicator with animated fill, charging animation |
| 10 | `modules/bar/components/StatusIndicators.qml` | 113 | Caffeine + DND status dots |
| 11 | `modules/bar/components/SystemTray.qml` | 41 | System tray icon repeater |
| 12 | `modules/bar/components/MediaPlayer.qml` | 422 | Compact music player with vinyl animation, controls, progress bar |
| 13 | `modules/bar/components/Clock.qml` | 28 | Simple clock display |
| 14 | `modules/bar/components/NotificationPopups.qml` | 846 | Material 3 notification popup window with swipe gestures |