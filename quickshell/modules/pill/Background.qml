pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
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

    component Group: Column {
        id: g
        property string title: ""
        property bool collapsed: false
        default property alias content: bodyColumn.data

        spacing: 0
        width: parent ? parent.width : 0

        Row {
            id: header
            width: g.width
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
            width: g.width
            clip: true
            enabled: !g.collapsed
            opacity: g.collapsed ? 0 : 1
            height: g.collapsed ? 0 : implicitHeight

            Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 160 } }
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

            Rectangle {
                width: parent.width
                height: 1 * root.s
                color: Theme.hairSoft
            }

            Group {
                title: "Parallax"
                collapsed: false

                FieldRow {
                    label: "Parallax"
                    caption: "Slide the wallpaper between workspaces"
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
