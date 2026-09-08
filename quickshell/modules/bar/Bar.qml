import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell
import "../../components/effects"
import "../common"
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../singletons" as QsSingletons
import qs.compositor

Item {
    id: root
    property var screen
    property var barWindow

    // Screen name for PillState toggle calls
    readonly property string screenName: root.screen ? root.screen.name : ""

    // Scale factor matching PillOverlay so bar spacing and center spacer align.
    readonly property real s: screen ? (screen.height / 1080) * QsSingletons.Flags.uiScale : 1

    readonly property var config: QsConfig.Config
    readonly property var appearance: QsConfig.AppearanceConfig
    /**
     * Side-pill alpha — read from the canonical single source (Theme.pillAlpha,
     * defined in Appearance.qml) so bar and pill can never drift: Niri always
     * solid, Hyprland via the Look → Pill opacity stepper. pillBg uses
     * Theme.pillSurface (cardBotBase @ pillAlpha, alpha applied exactly once).
     */
    readonly property real pillAlpha: QsSingletons.Theme.pillAlpha
    readonly property color pillBg: QsSingletons.Theme.pillSurface
    readonly property color pillBorder: Qt.rgba(QsSingletons.Theme.cream.r, QsSingletons.Theme.cream.g, QsSingletons.Theme.cream.b, 0.10)
    readonly property color pillSeparator: Qt.rgba(QsSingletons.Theme.cream.r, QsSingletons.Theme.cream.g, QsSingletons.Theme.cream.b, 0.15)

    readonly property color highlightTop: Qt.rgba(1, 1, 1, 0.04)
    // ═══════════════════════════════════════════════════════════════════════
    // MINIMAL AESTHETIC BAR
    // Clean, professional, beautiful - inspired by modern Linux rice
    // ═══════════════════════════════════════════════════════════════════════

    // Main bar container with floating effect
    Item {
        id: barContainer
        anchors.fill: parent
        anchors.topMargin: 1 * root.s
        anchors.leftMargin: 9 * root.s
        anchors.rightMargin: 9 * root.s
        anchors.bottomMargin: 1 * root.s

        // Drop shadow behind the whole strip so the floating bar reads as
        // lifted off the wallpaper (matches the popup shadow style).
        //
        // QML shadow is Niri-only (Compositor.qmlShadows): on Hyprland the
        // MultiEffect builds the shadow from the layer's alpha silhouette,
        // so every translucent surface in the strip (side pills, icons)
        // gets its own shadow halo, and the layerrule blur shows blurred
        // wallpaper through it OUTSIDE each pill's border. The compositor
        // blur already lifts the strip there.
        layer.enabled: QsSingletons.Flags.barShadow && Compositor.qmlShadows
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.45)
            shadowBlur: 1.0
            shadowVerticalOffset: 4
        }

        // ═══════════════════════════════════════════════════════════════
        // LEFT MODULE - Workspaces
        // ═══════════════════════════════════════════════════════════════
        Row {
            id: leftGroup
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8 * root.s

        Row {
            id: leftPills
            // Side-pill toggle (Flags.barLeftVisible): lets the user collapse
            // the left cluster for a single-pill layout. Opacity + width clip
            // so the bar strip itself stays put. The app-icons strip below is
            // a sibling of this Row so it is NOT hidden by this toggle.
            visible: QsSingletons.Flags.barLeftVisible
            opacity: QsSingletons.Flags.barLeftVisible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            spacing: 8 * root.s

            // Workspaces pill
            Loader {
                id: workspacesLoader
                asynchronous: false
                source: "components/BarPill.qml"
                Binding {
                    target: workspacesLoader.item
                    property: "customHeight"
                    value: 28 * root.s
                    when: workspacesLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }
                Binding {
                    target: workspacesLoader.item
                    property: "customRadius"
                    value: 14
                    when: workspacesLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }
                Binding {
                    target: workspacesLoader.item
                    property: "customSpacing"
                    value: 10 * root.s
                    when: workspacesLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }
                Binding {
                    target: workspacesLoader.item
                    property: "customDuration"
                    value: 350
                    when: workspacesLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }
                Binding {
                    target: workspacesLoader.item
                    property: "bezierCurve"
                    value: [0.34, 1.56, 0.64, 1]
                    when: workspacesLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }
                Binding {
                    target: workspacesLoader.item
                    property: "screen"
                    value: root.screen
                    when: workspacesLoader.status === Loader.Ready && root.screen !== undefined
                    restoreMode: Binding.RestoreBinding
                }
                Binding {
                    target: workspacesLoader.item
                    property: "barWindow"
                    value: root.barWindow
                    when: workspacesLoader.status === Loader.Ready && root.barWindow !== undefined
                    restoreMode: Binding.RestoreBinding
                }
            }
 
            // Running-apps strip — bare icons (no pill chrome) that sit next
            // to the workspace pill. Sibling of leftPills inside leftGroup so
            // hiding the pill doesn't hide the icons.
            Loader {
                id: appIconsLoader
                visible: QsSingletons.Flags.barAppIcons
                opacity: QsSingletons.Flags.barAppIcons ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                anchors.verticalCenter: parent.verticalCenter
                active: true
                source: "components/AppIcons.qml"
                Binding {
                    target: appIconsLoader.item
                    property: "barWindow"
                    value: root.barWindow
                    when: appIconsLoader.status === Loader.Ready && root.barWindow !== undefined
                    restoreMode: Binding.RestoreBinding
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════
        // CENTER MODULE - Spacer (pill now lives in PillOverlay.qml)
        // ═══════════════════════════════════════════════════════════════
        Item {
            id: centerContainer
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            // Scaled spacer matching the pill's rest dimensions in PillOverlay
            width: 160 * root.s
            height: 38 * root.s
        }

        // ═══════════════════════════════════════════════════════════════
        // RIGHT SIDE - Three Separate Pills
        // ═══════════════════════════════════════════════════════════════
        Row {
            id: rightPills
            // Side-pill toggle (Flags.barRightVisible) — mirrors leftPills.
            visible: QsSingletons.Flags.barRightVisible
            opacity: QsSingletons.Flags.barRightVisible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6 * root.s

            // ═══ PILL 1: Network + Bluetooth (Connectivity) ═══
            Loader {
                id: connectivityLoader
                asynchronous: false
                source: "components/BarPill.qml"
                Binding {
                    target: connectivityLoader.item
                    property: "customHeight"
                    value: 28 * root.s
                    when: connectivityLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }
                Binding {
                    target: connectivityLoader.item
                    property: "customRadius"
                    value: 14 * root.s
                    when: connectivityLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }
                Binding {
                    target: connectivityLoader.item
                    property: "customSpacing"
                    value: 4 * root.s
                    when: connectivityLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }
                Binding {
                    target: connectivityLoader.item
                    property: "customDuration"
                    value: 250
                    when: connectivityLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }
                Binding {
                    target: connectivityLoader.item
                    property: "barWindow"
                    value: root.barWindow
                    when: connectivityLoader.status === Loader.Ready && root.barWindow !== undefined
                    restoreMode: Binding.RestoreBinding
                }
                Binding {
                    target: connectivityLoader.item
                    property: "screenName"
                    value: root.screenName
                    when: connectivityLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }
                Binding {
                    target: connectivityLoader.item
                    property: "pillSeparator"
                    value: root.pillSeparator
                    when: connectivityLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }
            }
 
            // ═══ PILL 2: Brightness + Volume (Audio/Display) ═══
            Loader {
                id: audioLoader
                asynchronous: false
                source: "components/BarPill.qml"
                Binding {
                    target: audioLoader.item
                    property: "customHeight"
                    value: 28 * root.s
                    when: audioLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }
                Binding {
                    target: audioLoader.item
                    property: "customRadius"
                    value: 14 * root.s
                    when: audioLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }
                Binding {
                    target: audioLoader.item
                    property: "customSpacing"
                    value: 6 * root.s
                    when: audioLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }
                Binding {
                    target: audioLoader.item
                    property: "customDuration"
                    value: 250
                    when: audioLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }
                Binding {
                    target: audioLoader.item
                    property: "barWindow"
                    value: root.barWindow
                    when: audioLoader.status === Loader.Ready && root.barWindow !== undefined
                    restoreMode: Binding.RestoreBinding
                }
                Binding {
                    target: audioLoader.item
                    property: "screenName"
                    value: root.screenName
                    when: audioLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }
                Binding {
                    target: audioLoader.item
                    property: "pillSeparator"
                    value: root.pillSeparator
                    when: audioLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }
            }
 
            // ═══ PILL 3: Battery + Tray ═══
            Loader {
                id: powerLoader
                asynchronous: false
                source: "components/BarPill.qml"
                Binding {
                    target: powerLoader.item
                    property: "customHeight"
                    value: 28 * root.s
                    when: powerLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }
                Binding {
                    target: powerLoader.item
                    property: "customRadius"
                    value: 14 * root.s
                    when: powerLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }
                Binding {
                    target: powerLoader.item
                    property: "customSpacing"
                    value: 6 * root.s
                    when: powerLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }
                Binding {
                    target: powerLoader.item
                    property: "customDuration"
                    value: 250
                    when: powerLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }
                Binding {
                    target: powerLoader.item
                    property: "screenName"
                    value: root.screenName
                    when: powerLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }
                Binding {
                    target: powerLoader.item
                    property: "barWindow"
                    value: root.barWindow
                    when: powerLoader.status === Loader.Ready && root.barWindow !== undefined
                    restoreMode: Binding.RestoreBinding
                }
            }
        }
        }
    }
}