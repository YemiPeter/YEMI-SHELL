pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Networking
import "Singletons"
import "../common"
import "../../singletons" as QsSingletons
import qs.services as QsServices
import qs.compositor

/**
 * The pill body. One element carries every state. Width/height driven by `state`
 * (rest, hover/pinned, mixer, calendar) with a no-overshoot easing so surfaces
 * grow out of the pill in place. Surfaces are stacked absolutely and cross-fade.
 *
 * Hover comes from a passive HoverHandler, pin from a passive TapHandler, so
 * neither swallows pointer events from the surfaces stacked above: workspace
 * dots, the clock target, tray icons and the mixer faders get their own clicks
 * and drags.
 */
Item {
    id: pill


    property real s: 1
    property string screenName: ""
    property var barWindow
    property string surface: ""

    // Floating drop shadow behind the pill body so the center pill reads as
    // lifted off the wallpaper, matching the bar strip's shadow.
    //
    // Niri-only by design: on Hyprland the layerrule blur is composited
    // behind every translucent pixel of this fullscreen overlay, so the
    // shadow's pixels would show blurred wallpaper as a halo outside the
    // pill's border — and the compositor blur already lifts the pill there.
    // A Hyprland-native shadow (compositor drop_shadow or a dedicated
    // shadow surface) is handled separately from this QML effect.
    layer.enabled: QsSingletons.Flags.barShadow && Compositor.qmlShadows
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.45)
        shadowBlur: 1.0
        shadowVerticalOffset: 4
    }

    property bool hovered: false
    property bool pinned: false
    property bool forcePinned: false

    readonly property bool held: pinned || forcePinned
    readonly property bool mixerOpen: surface === "mixer"
    readonly property bool calendarOpen: surface === "calendar"
    readonly property bool launcherOpen: surface === "launcher"
    readonly property bool clipboardOpen: surface === "clipboard"
    readonly property bool wallpaperOpen: surface === "wallpaper"
    readonly property bool powerOpen: surface === "power"
    readonly property bool mediaOpen: surface === "media"
    readonly property bool linkOpen: surface === "link"
    readonly property bool linkBtOpen: surface === "bluetooth"
    readonly property bool batteryOpen: surface === "battery"
    readonly property bool settingsOpen: surface === "settings"
    readonly property bool keybindsOpen: surface === "keybinds"
    readonly property bool recorderOpen: surface === "recorder"
    readonly property bool sysmonOpen: surface === "sysmon"
    readonly property bool appearanceOpen: surface === "appearance"
    readonly property bool updatesOpen: surface === "updates"
    readonly property bool displayOpen: surface === "display"
    readonly property bool inputOpen: surface === "input"
    readonly property bool lookOpen: surface === "look"
    readonly property bool idlelockOpen: surface === "idlelock"
    readonly property bool fontpickerOpen: surface === "fontpicker"
    readonly property bool barPillsOpen: surface === "barpills"
    readonly property bool backgroundOpen: surface === "background"
    readonly property bool settingsLike: settingsOpen || appearanceOpen || updatesOpen || barPillsOpen

    /**
     * Loader-gated surfaces stay instantiated through their close fade via
     * this single grace slot: `closingGraceSurface` holds the name of the
     * surface that closed (or was switched away from) most recently, for one
     * morph duration. PillSurface's opacity fade-out animates over
     * Motion.morph, so deactivating a Loader the frame `open` flips false
     * would cut the fade mid-animation; a gated surface's `active` reads
     * `pill.<x>Open || pill.closingGraceSurface === "<x>"`. Only one surface
     * can be open at a time, so one slot suffices.
     */
    property string closingGraceSurface: ""
    property string lastSurface: ""
    Timer {
        id: closingGraceTimer
        // +50 ms so the fade-out's final frame isn't raced by the expiry.
        interval: Motion.morph + 50
        onTriggered: pill.closingGraceSurface = ""
    }
    onSurfaceChanged: {
        const prev = lastSurface;
        if (surface.length > 0) {
            lastSurface = surface;
            // Direct sub-surface switch (settings -> keybinds): surfaceOpen
            // never flips, so hand the outgoing surface the grace slot here.
            if (prev.length > 0 && prev !== surface) {
                closingGraceSurface = prev;
                closingGraceTimer.restart();
            }
        }
    }
    /**
     * Actually PLAYING right now — not merely a registered MPRIS endpoint.
     * Browsers (Firefox/Chromium) expose an MPRIS player permanently and
     * paused players stay registered, which made the right-edge media bud sit
     * on the pill with or without music. The bud gates on this (NOT on
     * Mpris.players.values.length, which is always true with a browser open).
     * Mirrors Media.qml's active-player pick (p.isPlaying, and the same
     * skwd-music exclusion) so the bud never advertises a surface that would
     * show "Nothing playing".
     */
    readonly property bool mediaPlaying: Mpris.players.values.some(function(p) {
        return p && p.identity !== "skwd-music" && p.isPlaying;
    })

    /**
     * Subview the link surface should land on when next opened. The wifi glance
     * sets "wifi" to drill straight to the network list; the inbox glance and
     * toast set "main". Reset once the surface closes so IPC opens land on main.
     */
    property string linkInitialView: QsSingletons.PillState.pendingLinkView
    
    /**
     * Subview the bluetooth surface should land on. Always "bt" — the bar
     * bluetooth pill opens straight to the device list.
     */
    property string linkBtInitialView: "bt"

    readonly property var netDevices: (typeof Networking !== "undefined" && Networking && Networking.devices) ? Networking.devices.values : []
    readonly property var wifiDev: netDevices.find(function(d) { return d && d.type === DeviceType.Wifi }) || null
    readonly property bool wifiOn: (typeof Networking !== "undefined" && Networking) ? Networking.wifiEnabled : false
    readonly property var wifiNets: (wifiDev && wifiDev.networks) ? wifiDev.networks.values : []
    readonly property var wifiActive: wifiNets.find(function(n) { return n && n.connected }) || null
    readonly property real wifiLevel: (wifiActive && wifiActive.signalStrength) || 0
    readonly property bool surfaceOpen: surface.length > 0
    property bool hoverLatch: false
    readonly property bool expanded: surfaceOpen || held || hoverLatch
    readonly property bool toastActive: Notifs.popups.length > 0
    readonly property bool osdActive: osd.flashing

    /**
     * Quick-record overlays belong only to the focused monitor the keybind
     * targeted, so a single chooser and a single countdown toast appear. The
     * standalone chooser is suppressed while the morphing recorder surface owns the
     * pill; the countdown toast yields to the surface too (the surface shows its
     * own in-bar countdown there).
     */
    readonly property bool quickHere: ScreenRec.quickMon === screenName
    readonly property bool quickChoosing: quickHere && ScreenRec.quickChoosing && !surfaceOpen
    readonly property bool quickCounting: quickHere && ScreenRec.counting && !recorderOpen

    readonly property real restW: 160 * s
    readonly property real restH: QsSingletons.Metrics.restHBase * s
    readonly property real hoverPad: 20 * s
    readonly property real hoverW: hoverRow.implicitWidth + 2 * hoverPad
    readonly property real hoverH: 58 * s
    readonly property real mixerW: 93 * Math.max(4, mixer?.faderCount ?? 4) * s
    readonly property real mixerH: 214 * s
    readonly property real calendarW: (calendar && calendar.implicitWidth > 0 ? calendar.implicitWidth : 282 * s) + 36 * s
    readonly property real calendarH: (calendar?.implicitHeight ?? 0) + 32 * s
    readonly property real launcherW: 360 * s
    readonly property real launcherH: 332 * s
    readonly property real clipboardW: 360 * s
    readonly property real clipboardH: 332 * s
    readonly property real wallpaperW: 720 * s
    readonly property real wallpaperH: 172 * s
    readonly property real powerW: (power && power.contentWidth > 0 ? power.contentWidth : 330 * s) + 34 * s
    readonly property real powerH: 150 * s
    readonly property real mediaW: 390 * s
    readonly property real mediaH: 150 * s
    readonly property real batteryW: 316 * s
    readonly property real settingsW: 392 * s
    readonly property real keybindsW: 460 * s
    readonly property real recorderW: 384 * s
    readonly property real sysmonW: 392 * s
    readonly property real appearanceW: 392 * s
    readonly property real updatesW: 360 * s
    readonly property real displayW: 392 * s
    readonly property real inputW: 392 * s
    readonly property real lookW: 392 * s
    readonly property real idlelockW: 392 * s
    readonly property real fontpickerW: 360 * s
    readonly property real barPillsW: 392 * s
    readonly property real backgroundW: 392 * s
    readonly property real toastW: 342 * s
    readonly property real quickChooseW: 344 * s
    readonly property real quickChooseH: 76 * s
    readonly property real quickCountW: 150 * s
    readonly property real quickCountH: 64 * s
    readonly property real restCorner: 18 * s
    readonly property real openCorner: 22 * s

    /**
     * Single source of truth for every morphing surface, keyed by its `surface`
     * string. Each entry owns the surface's target size (a thunk so the geometry
     * it reads registers as a live dep of targetSize) and the surface item Ame
     * anchors to while it is open (null = Ame falls back to the pill's own hover
     * or wake anchor). `mode`, `targetSize` and `ameSurface` all derive from this,
     * so adding a surface is one entry here plus its child item — no parallel
     * ternary chains to keep in lockstep.
     */
    readonly property var surfaces: ({
        calendar:  { size: () => Qt.size(calendarW, calendarH), ame: calendar },
        launcher:  { size: () => Qt.size(launcherW, launcherH), ame: launcher },
        clipboard: { size: () => Qt.size(clipboardW, clipboardH), ame: clip },
        wallpaper: { size: () => Qt.size(wallpaperW, wallpaperH), ame: null },
        power:     { size: () => Qt.size(powerW, powerH), ame: power },
        media:     { size: () => Qt.size(mediaW, mediaH), ame: media },
        mixer: { size: () => Qt.size(mixerW, mixerH), ame: mixer },
        link: { size: () => Qt.size(link?.desiredW ?? 330 * s, (link?.implicitHeight ?? 0) + 26 * s), ame: link },
        bluetooth: { size: () => Qt.size(linkBt?.desiredW ?? 286 * s, (linkBt?.implicitHeight ?? 0) + 26 * s), ame: linkBt },
        battery: { size: () => Qt.size(batteryW, (battery?.implicitHeight ?? 0) + 36 * s), ame: battery },
        settings:  { size: () => Qt.size(settingsW, (settings?.implicitHeight ?? 0) + 29 * s), ame: settings },
        keybinds:  { size: () => Qt.size(keybindsW, (keybindsLoader.item?.implicitHeight ?? 0) + 29 * s), ame: keybindsLoader.item ?? null },
        recorder:  { size: () => Qt.size(recorderW, (recorderLoader.item?.implicitHeight ?? 0) + 33 * s), ame: recorderLoader.item ?? null },
        sysmon:    { size: () => Qt.size(sysmonW, (sysmonLoader.item?.implicitHeight ?? 0) + 33 * s), ame: sysmonLoader.item ?? null },
        appearance: { size: () => Qt.size(appearanceW, (appearanceLoader.item?.implicitHeight ?? 0) + 29 * s), ame: appearanceLoader.item ?? null },
        updates:    { size: () => Qt.size(updatesW, (updatesLoader.item?.implicitHeight ?? 0) + 29 * s), ame: updatesLoader.item ?? null },
        display:    { size: () => Qt.size(displayW, (displayLoader.item?.implicitHeight ?? 0) + 29 * s), ame: displayLoader.item ?? null },
        input:      { size: () => Qt.size(inputW, (inputLoader.item?.implicitHeight ?? 0) + 29 * s), ame: inputLoader.item ?? null },
        look:       Compositor.isHyprland
            ? { size: () => Qt.size(lookW, (lookLoader.item?.implicitHeight ?? 0) + 29 * s), ame: lookLoader.item ?? null }
            : undefined,
        idlelock:   { size: () => Qt.size(idlelockW, (idlelockLoader.item?.implicitHeight ?? 0) + 29 * s), ame: idlelockLoader.item ?? null },
        fontpicker: { size: () => Qt.size(fontpickerW, (fontpickerLoader.item?.implicitHeight ?? 0) + 29 * s), ame: fontpickerLoader.item ?? null },
        barpills:  { size: () => Qt.size(barPillsW, (barPillsLoader.item?.implicitHeight ?? 0) + 29 * s), ame: barPillsLoader.item ?? null },
        background: { size: () => Qt.size(backgroundW, (backgroundLoader.item?.implicitHeight ?? 0) + 29 * s), ame: backgroundLoader.item ?? null }
    })

    readonly property string mode: surfaceOpen && surfaces[surface] !== undefined ? surface
        : (quickChoosing ? "quickChoose"
        : (quickCounting ? "quickCount"
        : (osdActive && !held ? "osd"
        : (toastActive && !held ? "toast"
        : (expanded ? "hover" : "rest")))))

    signal requestSurface(string name)
    signal requestClose()
    
    Component.onCompleted: {
    }

    /**
     * Forward an arrow-key nudge to the open mixer's targeted fader. Returns true
     * when the mixer is open and a fader consumed the step.
     */
    function mixerStep(deltaPct) {
        return pill.mixerOpen ? (mixer?.stepFocused(deltaPct) ?? false) : false;
    }

    /**
     * Move the open mixer's keyboard focus across the fader row; `dir` is +1
     * (right) or -1 (left). No-op unless the mixer is open.
     */
    function mixerFocusMove(dir) {
        if (pill.mixerOpen)
            mixer?.moveFocus(dir);
    }

    /**
     * Forward an arrow-key nudge to the open recorder's focused audio fader.
     * Returns true when the recorder is open and a revealed fader consumed it.
     */
    function recorderStep(deltaPct) {
        return pill.recorderOpen ? (recorderLoader.item?.stepFocused(deltaPct) ?? false) : false;
    }

    /**
     * Resolve which settings-family surface owns keyboard row navigation right
     * now: the category index or one of its morphing sub-surfaces. Returns null
     * when none of them is open.
     */
    function rowNavSurface() {
        if (pill.settingsOpen)
            return settings;
        if (pill.appearanceOpen)
            return appearanceLoader.item ?? null;
        if (pill.barPillsOpen)
            return barPillsLoader.item ?? null;
        return null;
    }

    /**
     * Move the focused settings row by `dir` (+1 down, -1 up), carrying the soul
     * seam. Returns true when a settings-family surface is open and consumed it.
     */
    function settingsMove(dir) {
        var nav = pill.rowNavSurface();
        if (!nav)
            return false;
        nav.kbMove(dir);
        return true;
    }

    /**
     * Step the focused settings row's control: a segmented choice cycles by
     * `dir`, a toggle is set on (dir > 0) or off. Returns true when consumed.
     */
    function settingsAdjust(dir) {
        var nav = pill.rowNavSurface();
        if (!nav)
            return false;
        nav.kbAdjust(dir);
        return true;
    }

    /**
     * Activate the focused settings row: a toggle flips, a nav row opens its
     * sub-surface. Returns true when a settings-family surface is open.
     */
    function settingsActivate() {
        var nav = pill.rowNavSurface();
        if (!nav)
            return false;
        nav.kbActivate();
        return true;
    }

    /**
     * Slide the open keybinds list's focused row by `dir` (+1 down, -1 up),
     * carrying the soul seam. No-op unless the keybinds surface is open.
     */
    function keybindsMove(dir) {
        if (pill.keybindsOpen)
            keybindsLoader.item?.move(dir);
    }

    /**
     * Enter on the open keybinds surface: arm chord capture on the focused row.
     * No-op unless the keybinds surface is open.
     */
    function keybindsActivate() {
        if (pill.keybindsOpen)
            keybindsLoader.item?.activate();
    }

    readonly property bool keybindsListening: pill.keybindsOpen && (keybindsLoader.item?.listening ?? false)

    /**
     * A tile was picked in the standalone quick-record chooser. Screen with several
     * monitors flips to the inline sub-choice; otherwise each source kicks off its
     * resolver (which counts down once the target is ready) and the chooser closes.
     */
    function quickChooseSource(kind) {
        if (kind === "screen") {
            if (ScreenRec.monitors.length > 1) {
                ScreenRec.quickScreenChoosing = true;
                return;
            }
            ScreenRec.prepareScreen(pill.screenName);
        } else if (kind === "window") {
            ScreenRec.prepareWindow();
        }
        ScreenRec.quickChoosing = false;
        ScreenRec.quickScreenChoosing = false;
    }

    function quickPickMonitor(name) {
        ScreenRec.quickChoosing = false;
        ScreenRec.quickScreenChoosing = false;
        ScreenRec.prepareScreen(name);
    }

    /**
     * Pop the open link surface one subview back. Returns true when the step was
     * consumed, false when the surface is already at its root (or not open) and
     * Escape should close the surface instead.
     */
    function linkBack() {
        return pill.linkOpen ? (link?.back() ?? false) : false;
    }

    /**
     * Step the open surface back one level when its header bar is clicked: a
     * settings sub-surface returns to the index, the font picker to appearance,
     * a keybinds form to its list, and any other surface dismisses to the hover
     * pill. Empty space in the body never triggers this.
     */
    function surfaceBack() {
        if (pill.keybindsOpen) {
            if (keybindsLoader.item?.formOpen)
                keybindsLoader.item?.closeForm();
            else
                pill.requestSurface("settings");
            return;
        }
        if (pill.fontpickerOpen) {
            pill.requestSurface("appearance");
            return;
        }
        if (pill.barPillsOpen) {
            pill.requestSurface("appearance");
            return;
        }
        if (pill.appearanceOpen || pill.updatesOpen || pill.displayOpen || pill.inputOpen || pill.lookOpen || pill.idlelockOpen) {
            pill.requestSurface("settings");
            return;
        }
        pill.requestClose();
    }

    /**
     * Pop the open keybinds editor form back to the bind list. Returns true when a
     * form was open and dismissed, false otherwise so Escape closes the surface.
     */
    function keybindsBack() {
        if (pill.keybindsOpen && keybindsLoader.item?.formOpen) {
            keybindsLoader.item?.closeForm();
            return true;
        }
        return false;
    }

    /**
     * Slide the open wallpaper strip's focus by `dir` thumbs; +1 is right (older)
     * and -1 is left (newer). No-op unless the wallpaper surface is open.
     */
    function wallpaperMove(dir) {
        if (pill.wallpaperOpen)
            wallLoader.item?.move(dir);
    }

    /**
     * Apply the wallpaper strip's focused thumb through wallpaper.sh. The
     * surface stays open so the pick can be iterated. No-op unless the
     * wallpaper surface is open.
     */
    function wallpaperActivate() {
        if (pill.wallpaperOpen)
            wallLoader.item?.activate();
    }

    readonly property bool wallpaperSearching: pill.wallpaperOpen && (wallLoader.item?.searching ?? false)

    /**
     * Route the first printable keystroke over the open wallpaper strip into a
     * DuckDuckGo search seeded with that character. No-op unless the wallpaper
     * surface is open.
     */
    function wallpaperType(ch) {
        if (pill.wallpaperOpen)
            wallLoader.item?.startSearch(ch);
    }

    /**
     * Slide the open power surface's keyboard focus by `dir` tiles; +1 is right
     * and -1 is left. No-op unless the power surface is open.
     */
    function powerMove(dir) {
        if (pill.powerOpen)
            power?.move(dir);
    }

    /**
     * Enter pressed on the open power surface's focused tile: fires a safe tile
     * at once, latches a destructive tile's heat hold. Returns true when a tile
     * consumed the key. No-op (false) unless the power surface is open.
     */
    function powerPress() {
        return pill.powerOpen ? (power?.pressFocused() ?? false) : false;
    }

    /**
     * Enter released on the open power surface: drains an unfinished destructive
     * hold so a key let go before the fill completes never confirms.
     */
    function powerRelease() {
        if (pill.powerOpen)
            power?.releaseFocused();
    }

    onSurfaceOpenChanged: {
        if (surfaceOpen) {
            pinned = false;
            if (quickHere && ScreenRec.quickChoosing) {
                ScreenRec.quickChoosing = false;
                ScreenRec.quickScreenChoosing = false;
            }
            // A surface opened: nothing needs the grace slot.
            closingGraceSurface = "";
            closingGraceTimer.stop();
        } else if (lastSurface.length > 0) {
            // Closed: hold the outgoing surface's Loader active through its
            // opacity fade-out (one morph duration, see closingGraceSurface).
            closingGraceSurface = lastSurface;
            closingGraceTimer.restart();
        }
    }

    QtObject {
        id: clock
        readonly property var loc: Qt.locale("en_US")
        readonly property var now: sysClock.date
        readonly property string timeFormat: (Flags.time12h ? "h:mm" : "HH:mm")
            + (Flags.clockSeconds ? ":ss" : "")
            + (Flags.time12h ? " AP" : "")
        readonly property string hhmm: Qt.formatTime(now, timeFormat)
        readonly property string date: loc.toString(now, "ddd d MMM")
    }

    SystemClock {
        id: sysClock
        precision: Flags.clockSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    property real morphRadius: (mode === "rest" || mode === "hover") ? restCorner : openCorner

    /**
     * Target geometry for the non-surface morph modes. Surface sizes come from
     * the `surfaces` descriptor; these three are the pill's own modes that have no
     * surface item. Thunks so the properties they read register as live deps of
     * targetSize.
     */
    readonly property var modeSize: ({
        osd:   () => Qt.size(osd.desiredW, osd.desiredH),
        toast: () => Qt.size(toastW, toastLoader.item ? toastLoader.item.implicitHeight + 24 * s : restH),
        hover: () => Qt.size(hoverW, hoverH),
        quickChoose: () => Qt.size(quickChooseW, quickChooseH),
        quickCount:  () => Qt.size(quickCountW, quickCountH)
    })

    readonly property size targetSize: {
        const sf = surfaces[mode];
        if (sf)
            return sf.size();
        const f = modeSize[mode];
        return f ? f() : Qt.size(Math.max(restW, restRow.implicitWidth + 36 * s), restH);
    }
    readonly property real targetW: targetSize.width
    readonly property real targetH: targetSize.height

    width: targetW
    height: targetH

    /**
     * How settled the pill is into its target geometry: 0 while the morph is far
     * away, 1 once it arrives. Content opacities key off this, not their own
     * timers, so a surface fades in as the pill reaches full size, never over a
     * half-grown pill.
     */
    readonly property real morphCloseness: {
        const d = Math.max(Math.abs(width - targetW), Math.abs(height - targetH));
        return 1 - Math.min(1, d / (110 * s));
    }

    /**
     * Gate the soul bead until the hover morph has arrived and its icons exist.
     * Fire it earlier and the bead aims at anchors that aren't laid out yet.
     * Latched so small width changes inside hover (workspace dot growing, tray
     * icons appearing) don't flicker the bead off.
     */
    property bool hoverSoulGate: false
    readonly property bool hoverArrived: mode === "hover" && morphCloseness > 0.55
    onHoverArrivedChanged: if (hoverArrived) hoverSoulGate = true
    onModeChanged: if (mode !== "hover") {
        hoverSoulGate = false;
        soulTarget = "";
        soulWsIndex = -1;
    }
    property string soulTarget: ""
    property int soulWsIndex: -1

    Behavior on width { NumberAnimation { duration: Motion.morph; easing.type: Motion.easeMorph; easing.bezierCurve: Motion.morphCurve } }
    Behavior on height { NumberAnimation { duration: Motion.morph; easing.type: Motion.easeMorph; easing.bezierCurve: Motion.morphCurve } }
    Behavior on morphRadius { NumberAnimation { duration: Motion.morph; easing.type: Motion.easeMorph; easing.bezierCurve: Motion.morphCurve } }

    /**
     * Compositor-gated pill alpha. Hyprland blurs the quickshell layer
     * (layerrule = blur on, match:namespace quickshell), so the Look → Pill
     * opacity stepper can stay translucent there. Niri has no layer blur yet,
     * so the pill renders fully solid until a compositor-level blur exists —
     * and a value changed on Hyprland never leaks into niri's rendering.
     */
    readonly property real pillAlpha: Theme.pillAlpha

    Glass {
        anchors.fill: parent
        radius: pill.morphRadius
        // Pill opacity owns the pill's see-through once: in aurora mode it
        // scales the glass tint (the Glass is the surface); in yemi mode it
        // is the body fill's alpha below. Never both. Routed through
        // pillAlpha so niri stays solid regardless of the stored value.
        tintScale: pill.pillAlpha
    }

    Rectangle {
        id: bud
        // Gate on mediaPlaying (music actually playing), NOT on any registered
        // MPRIS endpoint — a browser alone would keep the bud on the pill.
        // See Pill.mediaPlaying above.
        readonly property bool shown: pill.mode === "hover" && pill.mediaPlaying
        property real budR: (budArea.containsMouse ? 15 : 12) * pill.s
        width: budR * 2
        height: budR * 2
        radius: budR
        x: pill.width - budR
        anchors.verticalCenter: parent.verticalCenter
        visible: opacity > 0.01
        opacity: shown ? 1 : 0
        border.width: 1
        border.color: Theme.border
        gradient: Gradient {
            // Base tokens + one alpha: the resolved cardTop/cardBot are
            // already aurora-transparentized, so alphaing them again
            // double-dims the bud.
            GradientStop { position: 0.0; color: Qt.alpha(Theme.cardTopBase, pill.pillAlpha) }
            GradientStop { position: 1.0; color: Qt.alpha(Theme.cardBotBase, pill.pillAlpha) }
        }
        Behavior on budR { NumberAnimation { duration: Motion.fast; easing.type: Motion.easeStandard } }
        Behavior on opacity { NumberAnimation { duration: Motion.standard } }

        Canvas {
            id: budBead
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: 3 * pill.s
            width: 18 * pill.s
            height: 18 * pill.s
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const c = width / 2;
                const R = (budArea.containsMouse ? 5.2 : 4) * pill.s;
                const hg = ctx.createRadialGradient(c - R * 0.32, c - R * 0.38, 0, c, c, R);
                hg.addColorStop(0, Theme.flameInk);
                hg.addColorStop(0.55, Theme.vermLit);
                hg.addColorStop(0.92, Theme.verm);
                hg.addColorStop(1, Theme.flameEmber);
                ctx.beginPath();
                ctx.arc(c, c, R, 0, 7);
                ctx.fillStyle = hg;
                ctx.fill();
                ctx.beginPath();
                ctx.ellipse(c - R * 0.62, c - R * 0.66, R * 0.6, R * 0.36);
                ctx.fillStyle = "rgba(255,246,240,0.6)";
                ctx.fill();
            }
        }

        MouseArea {
            id: budArea
            anchors.fill: parent
            // Follow the bud's visual presence (opacity fade), not the
            // instantaneous `shown` bool: when paused, `shown` flips false but
            // the bud still paints its fade-out, so a per-frame enabled/disabled
            // here would make it flash un-clickable mid-fade.
            enabled: bud.opacity > 0.01
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.requestSurface("media")
            onContainsMouseChanged: budBead.requestPaint()
        }
    }

    Rectangle {
        id: body
        anchors.fill: parent
        radius: pill.morphRadius

        // 🎛️ TWEAK ZONE — Yemi, adjust these yourself:
        // - Flags.pillOpacity (Look → Pill opacity) = alpha/transparency of
        //   this fill in the yemi style. Lower = more see-through.
        //   In the aurora style this fill steps aside and the Glass tint
        //   (scaled by the same flag) is the surface. Hyprland only — niri
        //   renders at full alpha via pill.pillAlpha (no layer blur there).
        // - border.color alpha (Theme.frameBorder, 0.10) = edge line visibility.
        // - Top highlight gradient's "0.04" = how strong the glossy shine looks.
        color: Theme.auroraActive ? "transparent"
            : Qt.rgba(Theme.cardBotBase.r, Theme.cardBotBase.g, Theme.cardBotBase.b, pill.pillAlpha)
        // ⚠️ DESIGN LOCK — intentionally Theme.frameBorder (cream @0.10 veil),
        // NOT Ricelin's Theme.border for the pill BODY. The Ricelin border was
        // tried here and the user reverted it (read as an unwanted dark line).
        // An agent diffing against the Ricelin reference will see this drift —
        // it is deliberate; do not "restore parity" on this line.
        border.width: 1
        border.color: Theme.frameBorder

        // Top highlight — same as bar pills
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 1 * pill.s
            height: parent.height / 2
            radius: parent.radius - 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.04) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    /**
     * Rest anchor for Ame: the clock text centre. The idle bead parks here
     * before it moves on hover.
     */
    readonly property point wakePoint: {
      void pill.width;
      void pill.height;
      return restRow.mapToItem(pill, restRow.width / 2, restRow.height / 2);
    }

    /**
     * Bead target while hovered. soulTarget is a sticky key written by the hover
     * sources: the bead parks on the last focused dot or icon and glides to the
     * next, so crossing a gap between targets doesn't snap it back to the active
     * workspace. Pill geometry is voided so the anchor follows the hover morph,
     * the point stays live.
     */
    readonly property point soulPoint: {
        void pill.width;
        void pill.height;
        const drop = 12 * pill.s;
        if (soulTarget === "wifi")
            return wifiIcon.mapToItem(pill, wifiIcon.width / 2, wifiIcon.height + drop * 0.55);
        if (soulTarget === "battery")
            return batteryIcon.mapToItem(pill, batteryIcon.width / 2, batteryIcon.height + drop * 0.55);
        if (soulTarget === "inbox")
            return inboxIcon.mapToItem(pill, inboxIcon.width / 2, inboxIcon.height + drop * 0.55);
        if (soulTarget === "mixer")
            return mixerIcon.mapToItem(pill, mixerIcon.width / 2, mixerIcon.height + drop * 0.55);
        if (soulTarget === "power")
            return powerIcon.mapToItem(pill, powerIcon.width / 2, powerIcon.height + drop * 0.55);
        if (soulTarget === "settings")
            return settingsIcon.mapToItem(pill, settingsIcon.width / 2, settingsIcon.height + drop * 0.55);
        if (soulTarget === "recorder")
            return recorderIcon.mapToItem(pill, recorderIcon.width / 2, recorderIcon.height + drop * 0.55);
        if (soulTarget === "sysmon")
            return sysmonIcon.mapToItem(pill, sysmonIcon.width / 2, sysmonIcon.height + drop * 0.55);
        if (soulTarget === "ws" && soulWsIndex >= 0) {
            void ws.activeName;
            void ws.width;
            const p = ws.mapToItem(pill, ws.slotCenterX(soulWsIndex), ws.height / 2);
            return Qt.point(p.x, p.y + drop);
        }
        return ws.mapToItem(pill, ws.activeDotPoint.x, ws.activeDotPoint.y + drop);
    }

    /**
     * Which open surface owns Ame's anchor. Each surface exports its own
     * `ameForm`/`amePoint`; the pill picks the open surface's `ame` from the
     * descriptor and maps it. Null = nothing open (or a surface with no anchor,
     * e.g. wallpaper), so Ame falls back to the pill's own hover/wake anchor.
     */
    readonly property var ameSurface: (surfaceOpen && surfaces[surface] !== undefined)
        ? surfaces[surface].ame : null

    Ame {
        id: ame
        anchors.fill: parent
        s: pill.s
        heat: pill.powerOpen ? (power?.holdProgress ?? 0) : 0
        wake: pill.wakePoint
        wickDir: pill.powerOpen ? 1 : -1
        form: pill.ameSurface ? pill.ameSurface.ameForm
            : (pill.mode === "hover" && pill.hoverSoulGate ? "soul" : "off")
        point: pill.ameSurface
            ? Qt.point(pill.ameSurface.x + pill.ameSurface.amePoint.x,
                       pill.ameSurface.y + pill.ameSurface.amePoint.y)
            : (pill.mode === "hover" ? pill.soulPoint : pill.wakePoint)
    }

    /**
     * Extra input width past the pill's right edge while the media bud sticks
     * out there, so the window mask covers the bud's outer half. pill.hovered is
     * fed by a window-level HoverHandler in shell.qml: pointer events only exist
     * inside the input mask, so "window hovered" means "pointer over the pill (or
     * bud)". That sidesteps the per-item hover flicker the child MouseAreas and
     * the centred width morph would otherwise cause.
     * Tracks bud.opacity (not bud.shown) so the mask keeps covering the bud
     * through its fade-out instead of snapping away the frame music pauses.
     */
    readonly property real inputPadRight: bud.opacity > 0.01 ? bud.budR + 2 * s : 0
    readonly property real inputPadTop: 2 * s

    onHoveredChanged: {
        if (hovered) {
            hoverLatch = true;
            graceTimer.stop();
        } else {
            graceTimer.restart();
        }
    }

    Timer {
        id: graceTimer
        interval: 300
        onTriggered: {
            if (pill.morphCloseness < 0.95) {
                graceTimer.restart();
                return;
            }
            pill.hoverLatch = false;
        }
    }

    TapHandler {
        enabled: !pill.surfaceOpen
        gesturePolicy: TapHandler.WithinBounds
        onTapped: pill.pinned = !pill.pinned
    }

    Item {
        id: rest
        anchors.fill: parent
        opacity: (pill.expanded || pill.mode === "toast" || pill.mode === "osd" || pill.mode === "quickChoose" || pill.mode === "quickCount") ? 0 : Math.pow(pill.morphCloseness, 1.5)
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: pill.mode === "rest" ? Motion.fast : 260 } }

        Row {
          id: restRow
          anchors.centerIn: parent
          spacing: 0
          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: (QsServices.TimerService.pomodoroRunning && !QsServices.TimerService.pomodoroPaused) ? QsServices.TimerService.countdownString : clock.hhmm
                color: (QsServices.TimerService.pomodoroRunning && !QsServices.TimerService.pomodoroPaused) ? Theme.vermLit : Theme.cream
                font.family: Theme.font
                font.pixelSize: 16 * pill.s
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
            }
          Item {
            id: restMicDot
            anchors.verticalCenter: parent.verticalCenter
            width: QsServices.Privacy.micActive ? 14 * pill.s : 0
            height: 9 * pill.s
            visible: QsServices.Privacy.micActive
            Rectangle {
                x: 6 * pill.s
                width: 9 * pill.s
                height: 9 * pill.s
                radius: width / 2
                color: Theme.verm
                SequentialAnimation on opacity {
                    running: QsServices.Privacy.micActive
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.4; duration: 500; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 500; easing.type: Easing.InOutSine }
                }
            }
          }
        }
    }

    Item {
        id: hover
        anchors.fill: parent
        opacity: pill.mode === "hover" ? Math.pow(pill.morphCloseness, 1.2) : 0
        visible: true
        Behavior on opacity { NumberAnimation { duration: pill.mode === "hover" ? Motion.fast : 40 } }

        readonly property bool live: pill.mode === "hover"

        Row {
            id: hoverRow
            anchors.centerIn: parent
            spacing: 20 * pill.s

            Workspaces {
                id: ws
                anchors.verticalCenter: parent.verticalCenter
                width: implicitWidth
                screenName: pill.screenName
                s: pill.s
                gap: 8 * pill.s
                enabled: hover.live
                onHoverIndexChanged: if (hoverIndex >= 0) {
                    pill.soulTarget = "ws";
                    pill.soulWsIndex = hoverIndex;
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 22 * pill.s
                color: Theme.hair
            }

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: hoverClock.implicitWidth
                height: hoverClock.implicitHeight

                Column {
                    id: hoverClock
                    anchors.centerIn: parent
                    spacing: 2 * pill.s
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: clock.hhmm
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 18 * pill.s
                        font.weight: Font.DemiBold
                        font.features: { "tnum": 1 }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: clock.date
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 8.5 * pill.s
                        font.weight: Font.Medium
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1.6 * pill.s
                    }
                }

                MouseArea {
                    anchors.centerIn: parent
                    width: hoverClock.implicitWidth + 22 * pill.s
                    height: hoverClock.implicitHeight + 10 * pill.s
                    enabled: hover.live
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pill.requestSurface("calendar")
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 22 * pill.s
                color: Theme.hair
            }

            Row {
                id: statusRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12 * pill.s

                Row {
                    id: weatherGlance
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Weather.ready
                    spacing: 5 * pill.s

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                        enabled: hover.live
                    }
                    TapHandler {
                        enabled: hover.live
                        onTapped: pill.requestSurface("calendar")
                    }

                    GlyphIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16 * pill.s
                        height: 16 * pill.s
                        name: Weather.glyphFor(Weather.codeNow, Weather.isDay)
                        color: Theme.subtle
                        stroke: 1.8
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Weather.tempNow + "°"
                        color: Theme.subtle
                        font.family: Theme.font
                        font.pixelSize: 12.5 * pill.s
                        font.weight: Font.Medium
                        font.features: { "tnum": 1 }
                    }
                }

                MinimizedTray {
                    id: minimized
                    anchors.verticalCenter: parent.verticalCenter
                    s: pill.s
                    screenName: pill.screenName
                    enabled: hover.live
                    visible: count > 0
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: minimized.count > 0
                    width: 1
                    height: 14 * pill.s
                    color: Theme.hair
                    opacity: 0.7
                }

                Tray {
                    anchors.verticalCenter: parent.verticalCenter
                    s: pill.s
                    barWindow: pill.barWindow
                    enabled: hover.live
                }

                Item {
                    id: dndIcon
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Flags.dnd
                    width: 16 * pill.s
                    height: 16 * pill.s

                    Shape {
                        id: dndShape

                        width: 16
                        height: 16
                        scale: pill.s
                        transformOrigin: Item.TopLeft
                        x: dndShape.boundingRect.width > 0
                           ? dndIcon.width / 2 - (dndShape.boundingRect.x + dndShape.boundingRect.width / 2) * pill.s
                           : (dndIcon.width - 16 * pill.s) / 2
                        y: dndShape.boundingRect.height > 0
                           ? dndIcon.height / 2 - (dndShape.boundingRect.y + dndShape.boundingRect.height / 2) * pill.s
                           : (dndIcon.height - 16 * pill.s) / 2
                        preferredRendererType: Shape.CurveRenderer

                        ShapePath {
                            strokeColor: Theme.vermLit
                            strokeWidth: 1.5
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            joinStyle: ShapePath.RoundJoin
                            startX: 5.2; startY: 12.2
                            PathLine { x: 12.2; y: 12.2 }
                            PathLine { x: 12.2; y: 7.2 }
                            PathCubic {
                                control1X: 12.2; control1Y: 5.4
                                control2X: 11.2; control2Y: 4.0
                                x: 9.5; y: 3.5
                            }
                        }
                        ShapePath {
                            strokeColor: Theme.vermLit
                            strokeWidth: 1.5
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            startX: 6.8; startY: 13.6
                            PathLine { x: 9.2; y: 13.6 }
                        }
                        ShapePath {
                            strokeColor: Theme.vermLit
                            strokeWidth: 1.6
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            startX: 3.2; startY: 2.8
                            PathLine { x: 13.0; y: 13.4 }
                        }
                    }
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: (pill.wifiDev !== null && pill.wifiOn) || Battery.present
                    spacing: 12 * pill.s

                    Item {
                        id: wifiIcon
                        anchors.verticalCenter: parent.verticalCenter
                        visible: pill.wifiDev !== null && pill.wifiOn
                        width: 17 * pill.s
                        height: 17 * pill.s

                        WifiGlyph {
                            anchors.centerIn: parent
                            s: pill.s
                            level: pill.wifiLevel
                            on: pill.wifiOn
                        }

                        MouseArea {
                            id: wifiArea
                            anchors.fill: parent
                            anchors.margins: -6 * pill.s
                            hoverEnabled: true
                            enabled: hover.live
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                pill.linkInitialView = "wifi";
                                pill.requestSurface("link");
                            }
                            onContainsMouseChanged: if (containsMouse) pill.soulTarget = "wifi"
                        }
                    }

                    Item {
                        id: batteryIcon
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Battery.present
                        width: battPct.implicitWidth
                        height: 17 * pill.s

                        Text {
                            id: battPct
                            anchors.centerIn: parent
                            text: Battery.pct + "%"
                            color: Battery.low ? Theme.vermLit : (Battery.charging ? Theme.flameGlow : Theme.subtle)
                            font.family: Theme.font
                            font.pixelSize: 13 * pill.s
                            font.weight: Battery.charging ? Font.DemiBold : Font.Medium
                            font.features: { "tnum": 1 }
                        }

                        MouseArea {
                            id: batteryArea
                            anchors.fill: parent
                            anchors.margins: -6 * pill.s
                            hoverEnabled: true
                            enabled: hover.live
                            cursorShape: Qt.PointingHandCursor
                            onClicked: pill.requestSurface("battery")
                            onContainsMouseChanged: if (containsMouse) pill.soulTarget = "battery"
                        }
                    }
                }

                Item {
                    id: inboxIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: 17 * pill.s
                    height: 17 * pill.s

                    GlyphIcon {
                        anchors.fill: parent
                        name: "inbox"
                        color: inboxArea.containsMouse ? Theme.cream : Theme.iconDim
                        stroke: 1.7
                    }

                    Rectangle {
                        visible: Notifs.unread > 0
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: -2 * pill.s
                        anchors.rightMargin: -2 * pill.s
                        width: 5 * pill.s
                        height: 5 * pill.s
                        radius: width / 2
                        color: Theme.flameGlow
                    }

                    MouseArea {
                        id: inboxArea
                        anchors.fill: parent
                        anchors.margins: -6 * pill.s
                        hoverEnabled: true
                        enabled: hover.live
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            pill.linkInitialView = "main";
                            pill.requestSurface("link");
                        }
                        onContainsMouseChanged: if (containsMouse) pill.soulTarget = "inbox"
                    }
                }

                Item {
                    id: mixerIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: 17 * pill.s
                    height: 17 * pill.s

                    GlyphIcon {
                        anchors.fill: parent
                        name: "mixer"
                        color: mixerArea.containsMouse ? Theme.cream : Theme.iconDim
                        stroke: 1.7
                    }

                    MouseArea {
                        id: mixerArea
                        anchors.fill: parent
                        anchors.margins: -6 * pill.s
                        hoverEnabled: true
                        enabled: hover.live
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pill.requestSurface("mixer")
                        onContainsMouseChanged: if (containsMouse) pill.soulTarget = "mixer"
                    }
                }

                Item {
                    id: sysmonIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: 17 * pill.s
                    height: 17 * pill.s

                    GlyphIcon {
                        anchors.fill: parent
                        name: "monitor"
                        color: sysmonArea.containsMouse ? Theme.cream : Theme.iconDim
                        stroke: 1.7
                    }

                    MouseArea {
                        id: sysmonArea
                        anchors.fill: parent
                        anchors.margins: -6 * pill.s
                        hoverEnabled: true
                        enabled: hover.live
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pill.requestSurface("sysmon")
                        onContainsMouseChanged: if (containsMouse) pill.soulTarget = "sysmon"
                    }
                }

                Item {
                    id: recorderIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: 17 * pill.s
                    height: 17 * pill.s

                    GlyphIcon {
                        anchors.fill: parent
                        visible: !ScreenRec.recording
                        name: "video"
                        color: recorderArea.containsMouse ? Theme.cream : Theme.iconDim
                        stroke: 1.7
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        visible: ScreenRec.recording
                        width: 12 * pill.s
                        height: 12 * pill.s
                        radius: width / 2
                        color: Theme.verm
                        SequentialAnimation on opacity {
                            running: ScreenRec.recording
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.4; duration: 500; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1; duration: 500; easing.type: Easing.InOutSine }
                        }
                    }

                    MouseArea {
                        id: recorderArea
                        anchors.fill: parent
                        anchors.margins: -6 * pill.s
                        hoverEnabled: true
                        enabled: hover.live
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (e) => {
                            if (e.button === Qt.RightButton) {
                                if (ScreenRec.recording)
                                    ScreenRec.stop();
                                return;
                            }
                            pill.requestSurface("recorder");
                        }
                        onDoubleClicked: (e) => {
                            if (e.button === Qt.LeftButton && ScreenRec.recording)
                                ScreenRec.stop();
                        }
                        onContainsMouseChanged: if (containsMouse) pill.soulTarget = "recorder"
                    }
                }

                Item {
                    id: micIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: 17 * pill.s
                    height: 17 * pill.s

                    GlyphIcon {
                        anchors.fill: parent
                        name: "mic"
                        color: QsServices.Privacy.micActive ? Theme.verm : Theme.iconDim
                        stroke: 1.7
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        visible: QsServices.Privacy.micActive
                        width: 12 * pill.s
                        height: 12 * pill.s
                        radius: width / 2
                        color: Theme.verm
                        SequentialAnimation on opacity {
                            running: QsServices.Privacy.micActive
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.4; duration: 500; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1; duration: 500; easing.type: Easing.InOutSine }
                        }
                    }
                }

                Item {
                    id: settingsIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: 17 * pill.s
                    height: 17 * pill.s

                    GlyphIcon {
                        anchors.fill: parent
                        name: "cog"
                        color: settingsArea.containsMouse ? Theme.cream : Theme.iconDim
                        stroke: 1.6
                    }

                    MouseArea {
                        id: settingsArea
                        anchors.fill: parent
                        anchors.margins: -6 * pill.s
                        hoverEnabled: true
                        enabled: hover.live
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pill.requestSurface("settings")
                        onContainsMouseChanged: if (containsMouse) pill.soulTarget = "settings"
                    }
                }

                Item {
                    id: powerIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: 17 * pill.s
                    height: 17 * pill.s

                    GlyphIcon {
                        anchors.fill: parent
                        name: "shutdown"
                        color: powerArea.containsMouse ? Theme.cream : Theme.iconDim
                        stroke: 1.7
                    }

                    MouseArea {
                        id: powerArea
                        anchors.fill: parent
                        anchors.margins: -6 * pill.s
                        hoverEnabled: true
                        enabled: hover.live
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pill.requestSurface("power")
                        onContainsMouseChanged: if (containsMouse) pill.soulTarget = "power"
                    }
                }
            }
        }
    }

    Mixer {
        id: mixer
        s: pill.s
        open: pill.mixerOpen
        morphCloseness: pill.morphCloseness
    }

    Calendar {
        id: calendar
        s: pill.s
        open: pill.calendarOpen
        morphCloseness: pill.morphCloseness
    }

    Launcher {
        id: launcher
        s: pill.s
        open: pill.launcherOpen
        morphCloseness: pill.morphCloseness
        onRequestClose: pill.requestClose()
    }

    Clipboard {
        id: clip
        s: pill.s
        open: pill.clipboardOpen
        morphCloseness: pill.morphCloseness
        onRequestClose: pill.requestClose()
    }

    Loader {
        id: wallLoader
        active: pill.wallpaperOpen || pill.closingGraceSurface === "wallpaper"
        anchors.fill: parent

        sourceComponent: Wallpaper {
            id: wall
            s: pill.s
            open: pill.wallpaperOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
        }
    }

    Power {
        id: power
        s: pill.s
        open: pill.powerOpen
        morphCloseness: pill.morphCloseness
        onRequestClose: pill.requestClose()
    }

    Media {
        id: media
        s: pill.s
        open: pill.mediaOpen
        morphCloseness: pill.morphCloseness
        onRequestClose: pill.requestClose()
    }

    Link {
        id: link
        s: pill.s
        open: pill.linkOpen
        initialView: pill.linkInitialView
        morphCloseness: pill.morphCloseness
        onRequestClose: pill.requestClose()
    }
    
    onLinkOpenChanged: if (!linkOpen) QsSingletons.PillState.pendingLinkView = "main"
    
    Link {
        id: linkBt
        s: pill.s
        open: pill.linkBtOpen
        initialView: pill.linkBtInitialView
        morphCloseness: pill.morphCloseness
        onRequestClose: pill.requestClose()
    }
    
    onLinkBtOpenChanged: if (!linkBtOpen) linkBtInitialView = "bt"

    BatterySurface {
        id: battery
        s: pill.s
        open: pill.batteryOpen
        morphCloseness: pill.morphCloseness
        onRequestClose: pill.requestClose()
    }

    Settings {
        id: settings
        s: pill.s
        open: pill.settingsOpen
        morphCloseness: pill.morphCloseness
        onRequestClose: pill.requestClose()
        onRequestSurface: (name) => pill.requestSurface(name)
    }

    Loader {
        id: keybindsLoader
        // active follows open plus the close-grace slot so the PillSurface
        // opacity fade-out completes before the item is destroyed.
        active: pill.keybindsOpen || pill.closingGraceSurface === "keybinds"
        anchors.fill: parent

        sourceComponent: Keybinds {
            id: keybinds
            s: pill.s
            open: pill.keybindsOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
            onRequestSurface: (name) => pill.requestSurface(name)
        }
    }

    Loader {
        id: recorderLoader
        // active follows open plus the close-grace slot so the PillSurface
        // opacity fade-out completes before the item is destroyed.
        active: pill.recorderOpen || pill.closingGraceSurface === "recorder"
        anchors.fill: parent

        sourceComponent: Recorder {
            id: recorder
            s: pill.s
            screenName: pill.screenName
            open: pill.recorderOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
        }
    }

    Loader {
        id: sysmonLoader
        active: pill.sysmonOpen || pill.closingGraceSurface === "sysmon"
        anchors.fill: parent

        sourceComponent: SysmonSurface {
            id: sysmon
            s: pill.s
            open: pill.sysmonOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
        }
    }

    Loader {
        id: appearanceLoader
        active: pill.appearanceOpen || pill.closingGraceSurface === "appearance"
        anchors.fill: parent

        sourceComponent: Appearance {
            id: appearance
            s: pill.s
            open: pill.appearanceOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
            onRequestSurface: (name) => pill.requestSurface(name)
        }
    }

    Loader {
        id: updatesLoader
        active: pill.updatesOpen || pill.closingGraceSurface === "updates"
        anchors.fill: parent

        sourceComponent: Updates {
            id: updates
            s: pill.s
            open: pill.updatesOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
            onRequestSurface: (name) => pill.requestSurface(name)
        }
    }

    Loader {
        id: displayLoader
        active: pill.displayOpen || pill.closingGraceSurface === "display"
        anchors.fill: parent

        sourceComponent: Display {
            id: display
            s: pill.s
            open: pill.displayOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
            onRequestSurface: (name) => pill.requestSurface(name)
        }
    }

    Loader {
        id: inputLoader
        active: pill.inputOpen || pill.closingGraceSurface === "input"
        anchors.fill: parent

        sourceComponent: Input {
            id: input
            s: pill.s
            open: pill.inputOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
            onRequestSurface: (name) => pill.requestSurface(name)
        }
    }

    Loader {
        id: lookLoader
        active: pill.lookOpen || pill.closingGraceSurface === "look"
        anchors.fill: parent

        sourceComponent: Look {
            id: look
            s: pill.s
            open: pill.lookOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
            onRequestSurface: (name) => pill.requestSurface(name)
        }
    }

    Loader {
        id: idlelockLoader
        active: pill.idlelockOpen || pill.closingGraceSurface === "idlelock"
        anchors.fill: parent

        sourceComponent: IdleLock {
            id: idlelock
            s: pill.s
            open: pill.idlelockOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
            onRequestSurface: (name) => pill.requestSurface(name)
        }
    }

    Loader {
        id: fontpickerLoader
        active: pill.fontpickerOpen || pill.closingGraceSurface === "fontpicker"
        anchors.fill: parent

        sourceComponent: FontPicker {
            id: fontpicker
            s: pill.s
            open: pill.fontpickerOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
            onRequestSurface: (name) => pill.requestSurface(name)
        }
    }

    Loader {
        id: barPillsLoader
        active: pill.barPillsOpen || pill.closingGraceSurface === "barpills"
        anchors.fill: parent

        sourceComponent: BarPills {
            id: barPills
            s: pill.s
            open: pill.barPillsOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
            onRequestSurface: (name) => pill.requestSurface(name)
        }
    }

    Loader {
        id: backgroundLoader
        active: pill.backgroundOpen || pill.closingGraceSurface === "background"
        anchors.fill: parent

        sourceComponent: Background {
            id: background
            s: pill.s
            open: pill.backgroundOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
            onRequestSurface: (name) => pill.requestSurface(name)
        }
    }

    Osd {
        id: osd
        anchors.fill: parent
        anchors.topMargin: 12 * pill.s
        anchors.leftMargin: 18 * pill.s
        anchors.rightMargin: 18 * pill.s
        anchors.bottomMargin: 12 * pill.s
        s: pill.s
        screenName: pill.screenName
        suppressed: pill.surfaceOpen || pill.held
        enabled: pill.mode === "osd"
        opacity: pill.mode === "osd" ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity {
            NumberAnimation { duration: Motion.standard; easing.type: Motion.easeStandard }
        }
    }

    Loader {
        id: toastLoader
        active: pill.toastActive
        anchors.fill: parent
        anchors.topMargin: 12 * pill.s
        anchors.leftMargin: 16 * pill.s
        anchors.rightMargin: 16 * pill.s
        anchors.bottomMargin: 12 * pill.s
        enabled: pill.mode === "toast"
        opacity: pill.mode === "toast" ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity {
            NumberAnimation { duration: Motion.standard; easing.type: Motion.easeStandard }
        }

        sourceComponent: Item {
            implicitHeight: toastContent.implicitHeight

            Toast {
                id: toastContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                s: pill.s
                // 16*s loader margin on each side (see toastLoader above).
                // Feeds Toast.settledBodyWidth so the wrapped body text stops
                // re-wrapping — and re-targeting targetH — every morph frame.
                settledWidth: pill.toastW - 32 * pill.s
                live: pill.mode === "toast"
                notif: Notifs.popups.length > 0 ? Notifs.popups[Notifs.popups.length - 1] : null
                onOpenCenter: {
                    pill.linkInitialView = "main";
                    pill.requestSurface("link");
                }
            }

            Text {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                visible: Notifs.popups.length > 1
                text: "+" + (Notifs.popups.length - 1)
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 9 * pill.s
                font.weight: Font.DemiBold
            }
        }
    }

    /**
     * Standalone quick-record source chooser. Driven by the SUPER+D keybind with
     * no recorder surface open: it grows the pill on the focused monitor only
     * (mode "quickChoose") and offers the same Screen and Window / Region picks as
     * the surface. Screen with one monitor resolves at once; several monitors flip
     * to the inline sub-choice. A pick fires ScreenRec.prepareScreen / prepareWindow
     * → targetReady → the central countdown, then closes.
     */
    Item {
        id: quickChooser
        anchors.fill: parent
        anchors.margins: 6 * pill.s
        enabled: pill.mode === "quickChoose"
        opacity: pill.mode === "quickChoose" ? Math.pow(pill.morphCloseness, 1.3) : 0
        visible: opacity > 0.01
        Behavior on opacity {
            NumberAnimation { duration: Motion.standard; easing.type: Motion.easeStandard }
        }

        Row {
            id: quickSources
            anchors.fill: parent
            visible: !ScreenRec.quickScreenChoosing
            spacing: 6 * pill.s

            Repeater {
                model: [
                    { kind: "screen", label: "Screen", glyph: "monitor" },
                    { kind: "window", label: "Window / Region", glyph: "video" }
                ]

                Rectangle {
                    id: qSrcTile
                    required property var modelData
                    width: (quickSources.width - 6 * pill.s) / 2
                    height: parent.height
                    radius: 11 * pill.s
                    color: qSrcArea.containsMouse ? Qt.alpha(Theme.vermLit, 0.16) : Theme.tileBg
                    border.width: 1
                    border.color: qSrcArea.containsMouse ? Qt.alpha(Theme.vermLit, 0.5) : Theme.border
                    Behavior on color { ColorAnimation { duration: Motion.fast } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 8 * pill.s

                        GlyphIcon {
                            width: 16 * pill.s
                            height: 16 * pill.s
                            name: qSrcTile.modelData.glyph
                            color: qSrcArea.containsMouse ? Theme.vermLit : Theme.iconDim
                            stroke: 1.7
                        }
                        Text {
                            height: 16 * pill.s
                            verticalAlignment: Text.AlignVCenter
                            text: qSrcTile.modelData.label
                            color: qSrcArea.containsMouse ? Theme.cream : Theme.subtle
                            font.family: Theme.font
                            font.pixelSize: 11 * pill.s
                            font.weight: Font.Bold
                        }
                    }

                    MouseArea {
                        id: qSrcArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pill.quickChooseSource(qSrcTile.modelData.kind)
                    }
                }
            }
        }

        ListView {
            id: quickScreens
            anchors.fill: parent
            anchors.rightMargin: 22 * pill.s
            visible: ScreenRec.quickScreenChoosing
            orientation: ListView.Horizontal
            spacing: 6 * pill.s
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: ScreenRec.monitors

            delegate: Rectangle {
                id: qMonTile
                required property var modelData
                width: 152 * pill.s
                height: quickScreens.height
                radius: 11 * pill.s
                color: qMonArea.containsMouse ? Qt.alpha(Theme.vermLit, 0.16) : Theme.tileBg
                border.width: 1
                border.color: qMonArea.containsMouse ? Qt.alpha(Theme.vermLit, 0.5) : Theme.border
                Behavior on color { ColorAnimation { duration: Motion.fast } }

                Column {
                    anchors.centerIn: parent
                    spacing: 2 * pill.s

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qMonTile.modelData.name
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 11.5 * pill.s
                        font.weight: Font.Bold
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qMonTile.modelData.w + " × " + qMonTile.modelData.h
                        color: Theme.subtle
                        font.family: Theme.font
                        font.pixelSize: 9.5 * pill.s
                        font.features: { "tnum": 1 }
                    }
                }

                MouseArea {
                    id: qMonArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pill.quickPickMonitor(qMonTile.modelData.name)
                }
            }
        }

        WheelScroller {
            flick: quickScreens
            s: pill.s
            anchors.fill: quickScreens
            visible: ScreenRec.quickScreenChoosing
        }

        GlyphIcon {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 5 * pill.s
            visible: ScreenRec.quickScreenChoosing
            width: 12 * pill.s
            height: 12 * pill.s
            name: "chevron-left"
            color: qBackArea.containsMouse ? Theme.cream : Theme.faint
            stroke: 2

            MouseArea {
                id: qBackArea
                anchors.fill: parent
                anchors.margins: -7 * pill.s
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ScreenRec.quickScreenChoosing = false
            }
        }
    }

    /**
     * Standalone pre-roll countdown toast. Shown at the pill top on the focused
     * monitor when the central countdown runs and the recorder surface is closed
     * (mode "quickCount"): a big flame-glow numeral over a small "GET READY" label.
     * Tapping cancels. The surface's own in-bar countdown covers the surface case.
     */
    Item {
        id: quickCount
        anchors.fill: parent
        enabled: pill.mode === "quickCount"
        opacity: pill.mode === "quickCount" ? Math.pow(pill.morphCloseness, 1.3) : 0
        visible: opacity > 0.01
        Behavior on opacity {
            NumberAnimation { duration: Motion.standard; easing.type: Motion.easeStandard }
        }

        Column {
            anchors.centerIn: parent
            spacing: 1 * pill.s

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: ScreenRec.countdown
                color: Theme.flameGlow
                font.family: Theme.font
                font.pixelSize: 28 * pill.s
                font.weight: Font.ExtraBold
                font.features: { "tnum": 1 }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "GET READY"
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 8.5 * pill.s
                font.weight: Font.Bold
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1.6 * pill.s
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: ScreenRec.cancel()
        }
    }

}
