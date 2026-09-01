pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.compositor
import "../common"
import "Singletons"

/**
 * BACKGROUND sub-surface: tunes the wallpaper backdrop that QuickShell draws on
 * its WlrLayer.Background window (see modules/background/Backdrop.qml). The
 * values persist through Flags (flags.json) so they survive a restart and are
 * shared across every surface. Reached from the settings index; morphs back on
 * the back chevron.
 */
SettingsSurface {
    id: root

    backSurface: "settings"
    property real maxSurfaceH: settings.implicitHeight
    implicitHeight: Math.min(settingsHeader.implicitHeight + innerColumn.implicitHeight, maxSurfaceH)
    rows: []

    /// Re-run the single-writer color pipeline (after-wall.sh) so a backdrop
    /// color-source change takes effect. after-wall.sh itself reads
    /// backdropThemeColors and swaps in the backdrop image when enabled.
    function regenColors() {
        colorRegen.exec(["sh", "-c",
            'sh "$HOME/.config/quickshell/scripts/after-wall.sh" "' + Flags.systemMood + '"'])
    }

    Process {
        id: colorRegen
        onExited: (code) => {
            if (Flags.debug) console.log("[Background] Color regen exited:", code)
        }
    }

    component Stepper: Row {
        id: step

        property real value: 0
        property string display: ""
        signal stepped(int dir)

        spacing: 6 * root.s

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 26 * root.s
            height: 26 * root.s
            radius: Motion.rSmall * root.s
            color: minusArea.containsMouse ? Theme.frameBg : Theme.tileBg
            border.width: 1
            border.color: Theme.border
            Behavior on color { ColorAnimation { duration: Motion.fast } }

            Text {
                anchors.centerIn: parent
                text: "−"
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 14 * root.s
                font.weight: Font.Bold
            }

            MouseArea {
                id: minusArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: step.stepped(-1)
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: 44 * root.s
            horizontalAlignment: Text.AlignHCenter
            text: step.display
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 12 * root.s
            font.weight: Font.DemiBold
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 26 * root.s
            height: 26 * root.s
            radius: Motion.rSmall * root.s
            color: plusArea.containsMouse ? Theme.frameBg : Theme.tileBg
            border.width: 1
            border.color: Theme.border
            Behavior on color { ColorAnimation { duration: Motion.fast } }

            Text {
                anchors.centerIn: parent
                text: "+"
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 14 * root.s
                font.weight: Font.Bold
            }

            MouseArea {
                id: plusArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: step.stepped(1)
            }
        }
    }

    component Group: Rectangle {
        id: g
        property string title: ""
        property bool collapsed: false
        default property alias content: bodyColumn.data

        width: parent ? parent.width : 0
        implicitHeight: cardBody.implicitHeight
        radius: Motion.rTile * root.s
        color: Theme.cardTop
        border.width: 1
        border.color: Theme.hairSoft
        clip: true

        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.mask: Rectangle {
                anchors.fill: parent
                radius: parent.parent.radius
                color: "white"
            }
            Glass {
                anchors.fill: parent
                radius: parent.parent.radius
                tintScale: 1.0
            }
        }

        readonly property real pad: 4 * root.s

        Column {
            id: cardBody
            width: parent.width - pad * 2
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: pad
            bottomPadding: pad
            spacing: 0

            Row {
                id: header
                width: cardBody.width
                height: 30 * root.s
                spacing: 6 * root.s

                GlyphIcon {
                    width: 14 * root.s
                    height: 14 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    name: "chevron-down"
                    rotation: g.collapsed ? -90 : 0
                    color: Theme.faint
                    stroke: 2.2

                    Behavior on rotation { NumberAnimation { duration: 150 } }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: g.title
                    color: Theme.faint
                    font.family: Theme.font
                    font.pixelSize: 8.5 * root.s
                    font.weight: Font.Bold
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 1.2 * root.s
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: g.collapsed = !g.collapsed
                }
            }

            Column {
                id: bodyColumn
                width: cardBody.width
                clip: true
                enabled: !g.collapsed
                opacity: g.collapsed ? 0 : 1
                height: g.collapsed ? 0 : implicitHeight

                Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 160 } }
            }
        }
    }

    component FieldRow: Item {
        id: frow
        property string label: ""
        property string caption: ""
        default property alias control: ctrl.data

        width: parent ? parent.width : 0
        height: 34 * root.s

        Column {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1 * root.s

            Text {
                text: frow.label
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 12.5 * root.s
                font.weight: Font.Medium
            }

            Text {
                visible: frow.caption.length > 0
                text: frow.caption
                color: Theme.faint
                font.family: Theme.font
                font.pixelSize: 9 * root.s
                font.weight: Font.Medium
            }
        }

        Item {
            id: ctrl
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: childrenRect.width
            height: childrenRect.height
        }
    }

    Column {
        id: content
        z: 100
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0
        height: root.height + root.mBottom * root.s
        clip: true

        SettingsHeader {
            id: settingsHeader
            s: root.s
            title: "BACKGROUND"
            showBack: true
        }

        Flickable {
            id: scroller
            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.max(0, root.height - settingsHeader.height)
            contentHeight: innerColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            onContentYChanged: {
                if (backdropGroup.y + backdropGroup.height < contentY && !backdropGroup.collapsed)
                    backdropGroup.collapsed = true
                if (parallaxGroup.y + parallaxGroup.height < contentY && !parallaxGroup.collapsed)
                    parallaxGroup.collapsed = true
            }

            Column {
                id: innerColumn
                width: parent.width
                spacing: 10 * root.s
                bottomPadding: 12 * root.s

            Group {
                title: "Wallpaper"
                collapsed: false

                FieldRow {
                    label: "Use Material wallpaper"
                    caption: "Adopt the same wallpaper set by the desktop"
                    LinkToggle {
                        s: root.s
                        on: Flags.wallpaperUseMainWallpaper
                        onToggled: Flags.wallpaperUseMainWallpaper = !Flags.wallpaperUseMainWallpaper
                    }
                }

                FieldRow {
                    label: "Enable animated wallpapers"
                    caption: "Play videos and GIFs as wallpaper"
                    LinkToggle {
                        s: root.s
                        on: Flags.wallpaperEnableAnimation
                        onToggled: Flags.wallpaperEnableAnimation = !Flags.wallpaperEnableAnimation
                    }
                }

                FieldRow {
                    label: "Enable blur"
                    caption: "Blur wallpaper when windows are open"
                    LinkToggle {
                        s: root.s
                        on: Flags.wallpaperEnableBlur
                        onToggled: Flags.wallpaperEnableBlur = !Flags.wallpaperEnableBlur
                    }
                }

                FieldRow {
                    label: "Blur radius"
                    caption: "Amount of blur applied to wallpaper"
                    visible: Flags.wallpaperEnableBlur
                    height: Flags.wallpaperEnableBlur ? 34 * root.s : 0
                    Stepper {
                        value: Flags.wallpaperBlurRadius
                        display: (Flags.wallpaperBlurRadius).toFixed(0) + "%"
                        onStepped: (dir) => {
                            var next = Math.max(0, Math.min(100, Math.round(Flags.wallpaperBlurRadius + dir * 5)));
                            if (next === Flags.wallpaperBlurRadius)
                                return;
                            Flags.wallpaperBlurRadius = next;
                        }
                    }
                }

                FieldRow {
                    label: "Dim overlay"
                    caption: "Darken the wallpaper"
                    Stepper {
                        value: Flags.wallpaperDim
                        display: (Flags.wallpaperDim * 100).toFixed(0) + "%"
                        onStepped: (dir) => {
                            var next = Math.max(0, Math.min(1, Math.round((Flags.wallpaperDim + dir * 0.05) * 100) / 100));
                            if (next === Flags.wallpaperDim)
                                return;
                            Flags.wallpaperDim = next;
                        }
                    }
                }
            }

            Group {
                id: backdropGroup
                title: "Backdrop"
                collapsed: false

                FieldRow {
                    label: "Backdrop layer"
                    caption: "Master switch for wallpaper effects"
                    LinkToggle {
                        s: root.s
                        on: Flags.backdropEnable
                        onToggled: Flags.backdropEnable = !Flags.backdropEnable
                    }
                }

                FieldRow {
                    label: "Double-paint (Hyprland)"
                    caption: "Force the QML wallpaper on top of awww so blur/saturation/contrast/parallax can apply"
                    visible: Flags.backdropEnable && Compositor.isHyprland
                    LinkToggle {
                        s: root.s
                        on: Flags.backdropDoublePaint
                        onToggled: Flags.backdropDoublePaint = !Flags.backdropDoublePaint
                    }
                }

                FieldRow {
                    label: "Hide main wallpaper"
                    caption: "Show the real desktop wallpaper; drop QuickShell's copy and effects blur"
                    visible: Flags.backdropEnable
                    LinkToggle {
                        s: root.s
                        on: Flags.backdropHideWallpaper
                        onToggled: Flags.backdropHideWallpaper = !Flags.backdropHideWallpaper
                    }
                }

                FieldRow {
                    label: "Animated wallpapers"
                    caption: "Play GIFs as wallpaper"
                    visible: Flags.backdropEnable
                    LinkToggle {
                        s: root.s
                        on: Flags.backdropEnableAnimation
                        onToggled: Flags.backdropEnableAnimation = !Flags.backdropEnableAnimation
                    }
                }

                FieldRow {
                    label: "Blur animated wallpapers"
                    caption: "Frost animated wallpapers"
                    visible: Flags.backdropEnable && Flags.backdropEnableAnimation
                    LinkToggle {
                        s: root.s
                        on: Flags.backdropEnableAnimatedBlur
                        onToggled: Flags.backdropEnableAnimatedBlur = !Flags.backdropEnableAnimatedBlur
                    }
                }

                FieldRow {
                    label: "Use separate wallpaper"
                    caption: "Different image for the backdrop"
                    visible: Flags.backdropEnable
                    LinkToggle {
                        s: root.s
                        on: !Flags.backdropUseMainWallpaper
                        onToggled: Flags.backdropUseMainWallpaper = !Flags.backdropUseMainWallpaper
                    }
                }

                FieldRow {
                    label: "Backdrop wallpaper"
                    caption: "Pick the separate image"
                    visible: Flags.backdropEnable && !Flags.backdropUseMainWallpaper
                    height: (Flags.backdropEnable && !Flags.backdropUseMainWallpaper) ? 34 * root.s : 0
                    Rectangle {
                        width: 64 * root.s
                        height: 24 * root.s
                        radius: Motion.rSmall * root.s
                        color: btArea.containsMouse ? Theme.frameBg : Theme.tileBg
                        border.width: 1
                        border.color: Theme.border
                        Text {
                            anchors.centerIn: parent
                            text: "Change"
                            color: Theme.cream
                            font.family: Theme.font
                            font.pixelSize: 11 * root.s
                        }
                        MouseArea {
                            id: btArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Flags.wallpaperSelectionTarget = "backdrop";
                                pill.requestSurface("wallpaper");
                            }
                        }
                    }
                }

                FieldRow {
                    label: "Theme from backdrop"
                    caption: "Derive shell colors from the backdrop image"
                    visible: Flags.backdropEnable && !Flags.backdropUseMainWallpaper
                    LinkToggle {
                        s: root.s
                        on: Flags.backdropThemeColors
                        onToggled: {
                            Flags.backdropThemeColors = !Flags.backdropThemeColors;
                            root.regenColors();
                        }
                    }
                }

                FieldRow {
                    label: "Effects"
                    caption: "Dim and vignette behind the UI"
                    visible: Flags.backdropEnable
                    LinkToggle {
                        s: root.s
                        on: Flags.backdropEffects
                        onToggled: Flags.backdropEffects = !Flags.backdropEffects
                    }
                }

                FieldRow {
                    label: "Dim"
                    caption: "How much the wallpaper darkens"
                    visible: Flags.backdropEnable && Flags.backdropEffects
                    height: (Flags.backdropEnable && Flags.backdropEffects) ? 34 * root.s : 0
                    Stepper {
                        value: Flags.backdropDim
                        display: (Flags.backdropDim * 100).toFixed(0) + "%"
                        onStepped: (dir) => {
                            var next = Math.max(0, Math.min(1, Math.round((Flags.backdropDim + dir * 0.05) * 100) / 100));
                            if (next === Flags.backdropDim)
                                return;
                            Flags.backdropDim = next;
                        }
                    }
                }

                FieldRow {
                    label: "Vignette"
                    caption: "Darken the screen edges"
                    visible: Flags.backdropEnable && Flags.backdropEffects
                    LinkToggle {
                        s: root.s
                        on: Flags.backdropVignetteEnable
                        onToggled: Flags.backdropVignetteEnable = !Flags.backdropVignetteEnable
                    }
                }

                FieldRow {
                    label: "Vignette intensity"
                    caption: "How dark the vignette is"
                    visible: Flags.backdropEnable && Flags.backdropEffects && Flags.backdropVignetteEnable
                    height: (Flags.backdropEnable && Flags.backdropEffects && Flags.backdropVignetteEnable) ? 34 * root.s : 0
                    Stepper {
                        value: Flags.backdropVignette
                        display: (Flags.backdropVignette * 100).toFixed(0) + "%"
                        onStepped: (dir) => {
                            var next = Math.max(0, Math.min(1, Math.round((Flags.backdropVignette + dir * 0.05) * 100) / 100));
                            if (next === Flags.backdropVignette)
                                return;
                            Flags.backdropVignette = next;
                        }
                    }
                }

                FieldRow {
                    label: "Vignette radius"
                    caption: "How far the darkening reaches"
                    visible: Flags.backdropEnable && Flags.backdropEffects && Flags.backdropVignetteEnable
                    height: (Flags.backdropEnable && Flags.backdropEffects && Flags.backdropVignetteEnable) ? 34 * root.s : 0
                    Stepper {
                        value: Flags.backdropVignetteRadius
                        display: (Flags.backdropVignetteRadius * 100).toFixed(0) + "%"
                        onStepped: (dir) => {
                            var next = Math.max(0.1, Math.min(1, Math.round((Flags.backdropVignetteRadius + dir * 0.05) * 100) / 100));
                            if (next === Flags.backdropVignetteRadius)
                                return;
                            Flags.backdropVignetteRadius = next;
                        }
                    }
                }
                }

                FieldRow {
                    label: "Blur"
                    caption: "Frost the wallpaper"
                    visible: Flags.backdropEnable
                    height: Flags.backdropEnable ? 34 * root.s : 0
                    enabled: !(Compositor.isHyprland && !Flags.backdropDoublePaint)
                    opacity: enabled ? 1 : 0.4
                    Stepper {
                        value: Flags.backdropBlurRadius
                        display: (Flags.backdropBlurRadius).toFixed(0) + "%"
                        onStepped: (dir) => {
                            var next = Math.max(0, Math.min(100, Math.round(Flags.backdropBlurRadius + dir * 5)));
                            if (next === Flags.backdropBlurRadius)
                                return;
                            Flags.backdropBlurRadius = next;
                        }
                    }
                }

                FieldRow {
                    label: "Saturation"
                    caption: "Color intensity (−100..100)"
                    visible: Flags.backdropEnable
                    height: Flags.backdropEnable ? 34 * root.s : 0
                    enabled: !(Compositor.isHyprland && !Flags.backdropDoublePaint)
                    opacity: enabled ? 1 : 0.4
                    Stepper {
                        value: Flags.backdropSaturation
                        display: (Flags.backdropSaturation).toFixed(0) + "%"
                        onStepped: (dir) => {
                            var next = Math.max(-100, Math.min(100, Math.round(Flags.backdropSaturation + dir * 10)));
                            if (next === Flags.backdropSaturation)
                                return;
                            Flags.backdropSaturation = next;
                        }
                    }
                }

                FieldRow {
                    label: "Contrast"
                    caption: "Light/dark separation (−100..100)"
                    visible: Flags.backdropEnable
                    height: Flags.backdropEnable ? 34 * root.s : 0
                    enabled: !(Compositor.isHyprland && !Flags.backdropDoublePaint)
                    opacity: enabled ? 1 : 0.4
                    Stepper {
                        value: Flags.backdropContrast
                        display: (Flags.backdropContrast).toFixed(0) + "%"
                        onStepped: (dir) => {
                            var next = Math.max(-100, Math.min(100, Math.round(Flags.backdropContrast + dir * 10)));
                            if (next === Flags.backdropContrast)
                                return;
                            Flags.backdropContrast = next;
                        }
                    }
                }

            Group {
                title: "Wallpaper transitions"
                collapsed: false

                readonly property var transitionTypes: ["none", "simple", "fade", "left", "right", "top", "bottom", "wipe", "wave", "grow", "center", "outer"]
                readonly property var transitionDirs: ["left", "right", "top", "bottom"]
                readonly property int transitionTypeIndex: Math.max(0, transitionTypes.indexOf(Flags.transitionType))
                readonly property int transitionDirIndex: Math.max(0, transitionDirs.indexOf(Flags.transitionDirection))
                readonly property bool isDirectional: ["wipe", "wave", "left", "right", "top", "bottom"].indexOf(Flags.transitionType) >= 0

                FieldRow {
                    label: "Enable transitions"
                    caption: "Animate wallpaper changes (Hyprland only)"
                    enabled: !Compositor.isNiri
                    opacity: enabled ? 1 : 0.4
                    LinkToggle {
                        s: root.s
                        on: Flags.transitionEnable
                        onToggled: Flags.transitionEnable = !Flags.transitionEnable
                    }
                }

                FieldRow {
                    label: "Transition style"
                    caption: transitionTypes[transitionTypeIndex]
                    visible: Flags.transitionEnable
                    height: Flags.transitionEnable ? 34 * root.s : 0
                    enabled: !Compositor.isNiri
                    opacity: enabled ? 1 : 0.4
                    Stepper {
                        value: transitionTypeIndex
                        display: transitionTypes[transitionTypeIndex]
                        onStepped: (dir) => {
                            var idx = transitionTypeIndex
                            var next = Math.max(0, Math.min(transitionTypes.length - 1, idx + dir))
                            Flags.transitionType = transitionTypes[next]
                        }
                    }
                }

                FieldRow {
                    label: "Transition direction"
                    caption: Flags.transitionDirection
                    visible: Flags.transitionEnable && isDirectional
                    height: (Flags.transitionEnable && isDirectional) ? 34 * root.s : 0
                    enabled: !Compositor.isNiri
                    opacity: enabled ? 1 : 0.4
                    Stepper {
                        value: transitionDirIndex
                        display: transitionDirs[transitionDirIndex]
                        onStepped: (dir) => {
                            var next = Math.max(0, Math.min(transitionDirs.length - 1, transitionDirIndex + dir))
                            Flags.transitionDirection = transitionDirs[next]
                        }
                    }
                }

                FieldRow {
                    label: "Transition duration"
                    caption: "How long the transition takes (ms, Hyprland only)"
                    visible: Flags.transitionEnable
                    height: Flags.transitionEnable ? 34 * root.s : 0
                    enabled: !Compositor.isNiri
                    opacity: enabled ? 1 : 0.4
                    Stepper {
                        value: Flags.transitionDuration
                        display: Flags.transitionDuration + " ms"
                        onStepped: (dir) => {
                            var next = Math.max(200, Math.min(3000, Flags.transitionDuration + dir * 100))
                            if (next === Flags.transitionDuration) return
                            Flags.transitionDuration = next
                        }
                    }
                }
            }

            Group {
                title: "Wallpapers folder"
                collapsed: false

                FieldRow {
                    label: "Wallpapers directory"
                    caption: "Folder containing wallpaper images"
                    TextField {
                        width: Math.max(180 * root.s, parent.width * 0.5)
                        height: 28 * root.s
                        font.pixelSize: 11 * root.s
                        color: Theme.cream
                        placeholderText: QsSingletons.Walls.wpDir
                        text: Flags.wallpapersDirectory || QsSingletons.Walls.wpDir
                        onEditingFinished: {
                            var val = text.trim()
                            Flags.wallpapersDirectory = val
                            Config.setNestedValue("wallpapers.directory", val)
                        }
                    }
                }
            }

            Group {
                title: "Shuffle wallpapers"
                collapsed: false

                FieldRow {
                    label: "Shuffle automatically"
                    caption: "Pick a random wallpaper from the folder periodically"
                    LinkToggle {
                        s: root.s
                        on: Flags.autoWallpaperEnable
                        onToggled: Flags.autoWallpaperEnable = !Flags.autoWallpaperEnable
                    }
                }

                FieldRow {
                    label: "Change every"
                    caption: "How often to pick a new wallpaper"
                    visible: Flags.autoWallpaperEnable
                    height: Flags.autoWallpaperEnable ? 34 * root.s : 0
                    Stepper {
                        value: Flags.autoWallpaperInterval
                        display: Flags.autoWallpaperInterval + " min"
                        onStepped: (dir) => {
                            var next = Math.max(1, Math.min(1440, Flags.autoWallpaperInterval + dir * 5))
                            if (next === Flags.autoWallpaperInterval) return
                            Flags.autoWallpaperInterval = next
                        }
                    }
                }

                FieldRow {
                    label: "Regenerate colors on shuffle"
                    caption: "Recompute theme colors from the new wallpaper"
                    visible: Flags.autoWallpaperEnable
                    LinkToggle {
                        s: root.s
                        on: Flags.autoWallpaperGenerateColors
                        onToggled: Flags.autoWallpaperGenerateColors = !Flags.autoWallpaperGenerateColors
                    }
                }

                FieldRow {
                    label: "Shuffle folder"
                    caption: "Leave empty to shuffle within the wallpapers directory"
                    visible: Flags.autoWallpaperEnable
                    TextField {
                        width: Math.max(180 * root.s, parent.width * 0.5)
                        height: 28 * root.s
                        font.pixelSize: 11 * root.s
                        color: Theme.cream
                        placeholderText: Translation.tr("Use current wallpapers folder")
                        text: Flags.autoWallpaperFolder
                        onEditingFinished: Flags.autoWallpaperFolder = text.trim()
                    }
                }
            }

            Group {
                id: parallaxGroup
                title: "Parallax"
                collapsed: false

                FieldRow {
                    label: "Parallax"
                    caption: "Slide the wallpaper between workspaces"
                    enabled: !(Compositor.isHyprland && !Flags.backdropDoublePaint)
                    opacity: enabled ? 1 : 0.4
                    LinkToggle {
                        s: root.s
                        on: Flags.parallaxEnable
                        onToggled: Flags.parallaxEnable = !Flags.parallaxEnable
                    }
                }

                FieldRow {
                    label: "Zoom"
                    caption: "How much the wallpaper scales to free edge pixels"
                    visible: Flags.parallaxEnable
                    height: Flags.parallaxEnable ? 34 * root.s : 0
                    enabled: !(Compositor.isHyprland && !Flags.backdropDoublePaint)
                    opacity: enabled ? 1 : 0.4
                    Stepper {
                        value: Flags.parallaxZoom
                        display: (Flags.parallaxZoom * 100).toFixed(0) + "%"
                        onStepped: (dir) => {
                            var next = Math.max(1.0, Math.min(1.2, Math.round((Flags.parallaxZoom + dir * 0.01) * 100) / 100));
                            if (next === Flags.parallaxZoom)
                                return;
                            Flags.parallaxZoom = next;
                        }
                    }
                }

                FieldRow {
                    label: "Strength"
                    caption: "How far it glides per workspace"
                    visible: Flags.parallaxEnable
                    height: Flags.parallaxEnable ? 34 * root.s : 0
                    enabled: !(Compositor.isHyprland && !Flags.backdropDoublePaint)
                    opacity: enabled ? 1 : 0.4
                    Stepper {
                        value: Flags.parallaxStrength
                        display: (Flags.parallaxStrength * 100).toFixed(0) + "%"
                        onStepped: (dir) => {
                            var next = Math.max(0, Math.min(1, Math.round((Flags.parallaxStrength + dir * 0.05) * 100) / 100));
                            if (next === Flags.parallaxStrength)
                                return;
                            Flags.parallaxStrength = next;
                        }
                    }
                }
            }

            }

            WheelScroller { flick: scroller }
        }
    }
}
