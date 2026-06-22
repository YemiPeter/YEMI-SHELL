# AltSwitcher Component

## Component Overview

AltSwitcher is a window switcher component designed to replace traditional Alt+Tab functionality in the QuickShell desktop environment. It provides visual previews of running applications and allows users to cycle through them. The component supports multiple presentation styles including list, skew (card stack), and no-visual-ui modes. It integrates with the compositor abstraction layer to manage window focus and operations. Note that this component currently has known issues and is marked as "parked" pending conversion from Scope to PanelWindow root type.

## Project Structure and Dependencies

The AltSwitcher component is located at `/home/yemi/.config/quickshell/modules/altswitcher/AltSwitcher.qml`. It imports Qt Quick modules and Quickshell framework components:

- **Qt Quick modules**: QtQuick, QtQuick.Layouts, QtQuick.Controls for UI components
- **Quickshell framework**: Provides compositor integration and window management
- **Config module**: Optionally imports from `../../config` for user preferences

The component is intended to be loaded by shell.qml through an IpcHandler, though it is currently disabled due to architectural issues.

## Component Hierarchy and Role

AltSwitcher currently extends `Scope` which is a non-visual container. This is problematic as the component has visual content that needs to be rendered. The root type should be converted to `PanelWindow` for proper rendering. The component manages window snapshots, handles navigation between windows, and provides visual feedback during switching operations.

## Properties

| Property | Type | Default | Required | Description |
|----------|------|---------|----------|-------------|
| panelWidth | int | 380 | No | Width of the switcher panel in pixels |
| searchText | string | "" | No | Current search/filter text for window matching |
| altSwitcherOptions | var | Config.options?.altSwitcher ?? {} | No | Configuration options for the switcher |
| altPreset | string | "default" | No | Visual preset to use (list, skew, etc.) |
| altNoVisualUi | bool | false | No | Whether to operate without visual UI |
| effectiveNoVisualUi | bool | computed | No | Effective value considering other settings |
| altMonochromeIcons | bool | false | No | Whether to use monochrome icons |
| altEnableAnimation | bool | true | No | Whether animations are enabled |
| altAnimationDurationMs | int | 200 | No | Duration of animations in milliseconds |
| altUseMostRecent | bool | true | No | Whether to order windows by recent usage |
| altEnableBlurGlass | bool | true | No | Whether blur glass effect is enabled |
| altBackgroundOpacity | real | 0.9 | No | Opacity of the background |
| altBlurAmount | real | 0.4 | No | Amount of blur effect |
| altScrimDim | int | 35 | No | Darkness of background scrim |
| altPanelAlignment | string | "right" | No | Alignment of the panel (left, right, center) |
| altUseM3Layout | bool | false | No | Whether to use Material 3 layout |
| altCompactStyle | bool | false | No | Whether to use compact styling |
| altShowOverviewWhileSwitching | bool | false | No | Whether to show overview during switching |
| altAutoHideDelayMs | int | 500 | No | Delay before auto-hiding in ms |
| altSwitcherOpen | bool | false | No | Whether the switcher is currently open |
| animationsEnabled | bool | root.effectiveEnableAnimation | No | Whether animations are effectively enabled |
| panelRightMargin | real | -panelWidth | No | Right margin for panel positioning |
| itemSnapshot | var | [] | No | Snapshot of window items currently displayed |
| iconCache | var | ({}) | No | Cache of resolved icons |
| iconCacheKeys | var | [] | No | Ordered list of cache keys |
| maxIconCacheSize | int | 100 | No | Maximum size of icon cache |
| useM3Layout | bool | root.altUseM3Layout | No | Whether Material 3 layout is active |
| centerPanel | bool | root.altPanelAlignment === "center" | No | Whether panel is centered |
| compactStyle | bool | root.altCompactStyle && !root.listStyle && !root.skewStyle | No | Whether compact style is active |
| listStyle | bool | altPreset === "list" | No | Whether list style is active |
| skewStyle | bool | altPreset === "skew" | No | Whether skew style is active |
| showOverviewWhileSwitching | bool | root.altShowOverviewWhileSwitching | No | Whether overview is shown during switching |
| overviewOpenedByAltSwitcher | bool | false | No | Whether overview was opened by this component |
| _warmedUp | bool | false | No | Whether the component has been pre-warmed |
| baseSkewSliceWidth | int | 135 | No | Base width for skew slices |
| baseSkewExpandedWidth | int | 924 | No | Base expanded width for skew |
| baseSkewSliceHeight | int | 520 | No | Base height for skew slices |
| baseSkewOffset | int | 35 | No | Base offset for skew |
| baseSkewSliceSpacing | int | -22 | No | Base spacing for skew slices |
| skewVisibleCount | int | 12 | No | Number of visible items in skew view |
| skewScale | real | computed | No | Scale factor for skew view |
| skewSliceWidth | int | computed | No | Actual width of skew slices |
| skewExpandedWidth | int | computed | No | Actual expanded width for skew |
| skewSliceHeight | int | computed | No | Actual height of skew slices |
| skewOffset | int | computed | No | Actual offset for skew |
| skewSliceSpacing | int | computed | No | Actual spacing for skew slices |
| skewCardWidth | int | computed | No | Total width of skew card |
| skewCardHeight | int | computed | No | Total height of skew card |
| skewPanelWidth | int | computed | No | Width of the skew panel |
| skewCardVisible | bool | false | No | Whether the skew card is visible |
| _rapidNavigation | bool | false | No | Whether rapid navigation is active |
| _rapidNavSteps | int | 0 | No | Count of rapid navigation steps |
| windowCount | int | computed | No | Count of windows in snapshot |
| isHighLoad | bool | windowCount > 15 | No | Whether system load is high |
| effectiveEnableBlurGlass | bool | root.altEnableBlurGlass && !isHighLoad | No | Whether blur is effectively enabled |
| effectiveEnableAnimation | bool | root.altEnableAnimation && !isHighLoad | No | Whether animation is effectively enabled |
| quickSwitchDone | bool | false | No | Whether quick switching is complete |
| noUiSnapshot | var | [] | No | Snapshot for no-UI mode |
| noUiIndex | int | 0 | No | Current index in no-UI mode |
| _pendingWindowsUpdate | var | null | No | Pending window update function |

## Signals

This component does not declare custom signals but responds to timer events and compositor changes.

## Methods

#### toTitleCase(name) : string
Converts a name string to title case format. Parameters: `name` (input string).

#### getCachedIcon(appId, appName, title) : string
Retrieves an icon from cache or generates one. Parameters: `appId`, `appName`, `title`.

#### buildItemsFrom(windows, workspaces, mruIds) : array
Builds display items from window data. Parameters: `windows`, `workspaces`, `mruIds`.

#### rebuildSnapshot() : void
Rebuilds the window snapshot asynchronously.

#### rebuildSnapshotSync() : void
Rebuilds the window snapshot synchronously.

#### rebuildNoUiSnapshotSync() : void
Rebuilds the no-UI snapshot synchronously.

#### rebuildNoUiSnapshot() : void
Rebuilds the no-UI snapshot asynchronously.

#### focusNoUiIndex() : void
Focuses the window at the current no-UI index.

#### ensureSnapshot() : void
Ensures a window snapshot exists.

#### maybeOpenOverview() : void
Potentially opens the compositor overview if supported.

#### maybeCloseOverview() : void
Potentially closes the compositor overview if supported.

#### currentAnimDuration() : int
Returns the current animation duration.

#### showPanel() : void
Shows the switcher panel with appropriate animations.

#### hidePanel() : void
Hides the switcher panel with appropriate animations.

#### hasItems() : bool
Checks if there are any windows to display.

#### ensureOpen() : void
Ensures the switcher is in open state.

#### defaultSkewIndex() : int
Returns the default index for skew view.

#### openSkewSwitcher() : void
Opens the skew-style switcher.

#### closeSelectedWindow() : void
Closes the currently selected window.

#### confirmCurrentSelection() : void
Confirms the current selection and closes the switcher.

#### nextItem() : void
Moves selection to the next item.

#### previousItem() : void
Moves selection to the previous item.

#### activateCurrent() : void
Activates the currently selected window.

#### toggle() : void
Toggles the switcher visibility.

#### open() : void
Opens the switcher.

#### close() : void
Closes the switcher.

#### next() : void
Selects the next window in the list.

#### previous() : void
Selects the previous window in the list.

## Inter-Component Interactions

The AltSwitcher component interacts with:

- **Compositor layer** to retrieve window lists and perform window operations (focus, close)
- **Shell configuration** to read user preferences and settings
- **IPC handlers** in shell.qml to respond to keyboard shortcuts
- **Window management** systems to control focus and visibility

The component maintains its own state for window lists and user interaction, but relies on the compositor abstraction to perform actual window operations.

## Known Issues

This component currently has multiple critical issues that prevent it from functioning properly:

1. Root type is `Scope` (non-visual) with visual content as direct children
2. Not currently wired into the shell due to disabled loader
3. References to Config that may not be imported
4. Undeclared properties causing potential runtime errors
5. Various other bugs as identified in the project audit