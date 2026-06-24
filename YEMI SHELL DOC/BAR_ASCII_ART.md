# QuickShell Top Bar - ASCII Art Representation

## Layout Overview

The QuickShell top bar features a clean, aesthetically pleasing design with a floating effect. It's organized into distinct sections with rounded pills containing system information and controls.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  [workspaces..] [media.....................] [conn] [audio] [pow] │
│  │ 1 │ 2 │ 3 │ │ [No media]                │ │📶│ │🔊│ │🔋│ │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Detailed Breakdown

### Left Side
```
┌──────────────────────┐
│     Workspaces       │
│                      │
│  [ 1 ][ 2 ][ 3 ]   │
│                      │
└──────────────────────┘
```

- **Workspaces Pill**: Shows active workspaces with rounded indicators

### Center Area
```
┌─────────────────────────────────────┐
│              Media Player           │
│                                     │
│        [No media - Now Playing]     │
│                                     │
└─────────────────────────────────────┘
```

- **Media Module**: Always visible, shows "No media" when nothing is playing, otherwise displays current playback information

### Right Side
```
┌──────────┬──────────┬─────────────────────────┐
│Connectivity│  Audio  │       Power           │
│           │         │                       │
│  [📶][📶]  │ [🔊][🔊] │ [⚠️][🔋][⚙️][ Tray ] │
│           │         │                       │
└──────────┴──────────┴─────────────────────────┘
```

- **Connectivity Pill**: Network and Bluetooth indicators
- **Audio Pill**: Volume and brightness controls
- **Power Pill**: Status indicators (Caffeine, DND), Battery, Control Center toggle, and System Tray

## Visual Style

The bar features:

- **Floating effect**: 1px margins on all sides creating a floating appearance
- **Rounded pills**: Each section is contained in a pill-shaped rectangle with 14px radius
- **Subtle highlights**: Top half has a subtle gradient for depth
- **Consistent sizing**: All pills are 28px in height
- **Pywal theming**: Uses dynamic colors from the pywal color scheme
  - Background: Semi-transparent with ~70% opacity
  - Borders: Thin borders with ~10% foreground color opacity
  - Highlights: Very subtle top gradient for depth

## Component Structure

```
[Workspaces] [Media Player] [Connectivity] [Audio] [Power Management]
     │           │               │          │          │
     ▼           ▼               ▼          ▼          ▼
Workspace   Media Info    Network/    Volume/   Battery/Status/
Indicators  Display       Bluetooth   Bright-   Control Center/
            Indicators    Indicators  ness      System Tray
```

The bar uses a modern, minimal aesthetic with smooth animations and transitions that respect the user's pywal color scheme for a cohesive desktop experience.