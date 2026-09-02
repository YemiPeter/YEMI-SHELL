import QtQuick
import qs.compositor
import "../../singletons" as QsSingletons

// Niri-only workspace parallax math for Backdrop.qml's wallContainer.
//
// This component is instantiated through a Loader that is only active when
// Compositor.isNiri, so on Hyprland none of the parallax math, the workspace
// lookups, or the Behavior animator below ever exist.
Item {
    id: root

    // The PanelWindow's screen, injected by Backdrop.qml (a plain Item has no
    // `screen` of its own).
    required property var monitorScreen

    readonly property bool parallaxOn: QsSingletons.Flags.parallaxEnable
    readonly property real parallaxScale: root.parallaxOn ? QsSingletons.Flags.parallaxZoom : 1.0
    readonly property int wsId: {
        const m = Compositor.monitorFor(root.monitorScreen)
        return (m && m.activeWorkspace) ? m.activeWorkspace.id : 1
    }
    readonly property real maxShift: root.parallaxScale > 1
        ? (root.parallaxScale - 1) / 2 * 0.9 * root.width
        : 0
    readonly property real parallaxStep: root.maxShift * QsSingletons.Flags.parallaxStrength
    readonly property real shift: root.parallaxOn ? Math.min(
        Math.max((root.wsId - 1) * root.parallaxStep, 0),
        root.maxShift
    ) : 0

    // Animated offset applied to the wall container. The Behavior lives here
    // (not on wallContainer) so the animator object only exists while this
    // component is loaded — i.e. on Niri only. Not readonly: `Behavior on`
    // requires a writable property, and the binding is never written to
    // imperatively so it survives.
    property real containerX: -root.shift
    Behavior on containerX { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    // TEMP DEBUG — remove before commit
    Component.onCompleted: console.log("[BackdropParallax] onCompleted width=" + root.width + " wsId=" + root.wsId + " shift=" + root.shift)
    onWsIdChanged: console.log("[BackdropParallax] wsId=" + root.wsId + " shift=" + root.shift)
    onWidthChanged: console.log("[BackdropParallax] width=" + root.width)
    onShiftChanged: console.log("[BackdropParallax] shift=" + root.shift)

    anchors.fill: parent
}
