pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "Singletons"

/**
 * Wallpaper surface: a filmstrip over the wallpaper directory, rendered as one
 * of the pill's surfaces. Thumbs come from the Walls singleton snapshot, newest
 * first. The focused thumb is large and fully lit; neighbours shrink, dim and
 * desaturate as they slide under it, so the strip reads as depth. Arrow keys
 * and wheel move focus, clicking a neighbour glides to it, Enter or a tap on
 * the focused thumb applies it via wallpaper.sh (strip stays open so you can
 * keep trying picks). Hold the focused thumb for the heat duration to trash the
 * file (press-and-hold confirm, same as the clipboard wipe); progress sweeps
 * along the thumb's lower edge and drains on early release.
 *
 * Typing any printable character while the strip is open drops it into a
 * DuckDuckGo image search: a search field reveals at the top, the strip swaps
 * its model from local files to remote results (debounced fetch through
 * wallpaper-search.sh), and selecting a result downloads it, applies it and
 * returns to the local strip. Escape, an emptied query or a finished pick all
 * fall back to the local view.
 */
PillSurface {
    id: root

    property int focusIndex: 0

    /**
     * Search mode. While off the strip browses local files and bare keys are
     * watched for the first printable character; while on the search field is
     * shown, holds focus and the strip renders remote results for `query`.
     */
    property bool searching: false
    property string query: ""
    property var ddgResults: []

    /**
     * Active model and its select handler. The strip, navigation and empty
     * states all read these so the local and search views share one code path:
     * a populated query in search mode shows remote results, anything else the
     * local snapshot.
     */
    readonly property var items: (searching && query.length > 0) ? ddgResults : Walls.entries
    readonly property int itemCount: items.length

    /**
     * Gesture hint visibility. Hidden while the focus is moving so paging
     * through wallpapers stays clean; the dwell timer reveals it only once the
     * pick has been held still, so it reads as a quiet caption, not a nag.
     */
    property bool hintShown: false

    onFocusIndexChanged: {
        hintShown = false;
        hintDwell.restart();
        autoApply.restart();
    }

    onItemsChanged: if (focusIndex >= itemCount) focusIndex = Math.max(0, itemCount - 1);

    Timer {
        id: hintDwell
        interval: 600
        onTriggered: root.hintShown = true
    }

    /**
     * Scroll-to-set: once the strip comes to rest — focus unchanged and the
     * glide settled for the full dwell — the centered wallpaper is applied on
     * its own, no tap needed. Guards keep this to the plain local-strip flow:
     * search results still need an explicit pick (selecting downloads), the
     * backdrop selection flow keeps its deliberate tap, and re-applying the
     * wallpaper already on screen is skipped so opening the pill (which
     * centers on current) is never itself a trigger.
     */
    Timer {
        id: autoApply
        interval: 550
        onTriggered: {
            if (!root.active || root.searching)
                return;
            if (Math.abs(root.pos - root.focusIndex) > 0.01)
                return;
            var entry = root.items[root.focusIndex];
            if (!entry || entry.image !== undefined)
                return;
            if (Flags.wallpaperSelectionTarget === "backdrop")
                return;
            if (entry.path === Walls.current)
                return;
            root.activate();
        }
    }

    /**
     * Continuous view position chasing focusIndex. The strip renders from this
     * single value, so any input rate (40Hz key autorepeat, wheel bursts) stays
     * coherent: lag is bounded by the chase time constant, not piled up across
     * per-tile retargeting animations.
     */
    property real pos: 0

    // Any view motion (chase glide included) delays scroll-to-set; the dwell
    // timer below only fires once both focus and the glide are still.
    onPosChanged: autoApply.restart()

    /**
     * Window anchor for the strip's fixed delegate slots: the wallpaper index
     * the chase position is currently rounded to. Slots fan out ±6 from here,
     * so the strip only ever holds 13 live tiles regardless of library size.
     */
    readonly property int windowAnchor: itemCount > 0
        ? Math.max(0, Math.min(itemCount - 1, Math.round(pos)))
        : 0

    clip: true

    readonly property var slotW:      [196, 126, 104, 88, 74]
    readonly property var slotH:      [110, 71, 59, 50, 42]
    readonly property var slotCX:     [0, 143, 244, 326, 393]
    readonly property var slotBright: [1, 0.56, 0.42, 0.30, 0.22]
    readonly property var slotSat:    [1, 0.65, 0.55, 0.45, 0.40]

    function slotLerp(arr, ao) {
        if (ao >= 4)
            return arr[4];
        var i = Math.floor(ao);
        var f = ao - i;
        return arr[i] + (arr[i + 1] - arr[i]) * f;
    }

    function offsetX(off) {
        var ao = Math.abs(off);
        var cx = ao <= 4 ? slotLerp(slotCX, ao) : slotCX[4] + (ao - 4) * 60;
        return (off < 0 ? -cx : cx) * s;
    }

    function move(delta) {
        if (itemCount === 0)
            return;
        focusIndex = Math.max(0, Math.min(itemCount - 1, focusIndex + delta));
    }

    FrameAnimation {
        running: root.active && root.pos !== root.focusIndex
        onTriggered: {
            var k = 1 - Math.exp(-frameTime / 0.07);
            var next = root.pos + (root.focusIndex - root.pos) * k;
            root.pos = Math.abs(next - root.focusIndex) < 0.001 ? root.focusIndex : next;
        }
    }

    function activate() {
        if (focusIndex < 0 || focusIndex >= itemCount)
            return;
        var entry = items[focusIndex];
        if (entry.image !== undefined) {
            if (dlProc.running)
                return;
            dlProc.target = entry.image;
            dlProc.command = ["bash", root.searchScript, "download", entry.image];
            dlProc.running = true;
        } else if (Flags.wallpaperSelectionTarget === "backdrop") {
            Flags.backdropWallpaperPath = entry.path;
            Flags.wallpaperSelectionTarget = "";
            if (Flags.backdropThemeColors)
                backdropColorProc.exec(["sh", "-c",
                    'sh "$HOME/.config/quickshell/scripts/after-wall.sh" "' + Flags.systemMood + '"']);
        } else {
            Walls.apply(entry.path);
        }
    }

    function centerOnCurrent() {
        var idx = 0;
        for (var i = 0; i < Walls.entries.length; i++)
            if (Walls.entries[i].path === Walls.current) {
                idx = i;
                break;
            }
        focusIndex = idx;
        pos = idx;
    }

    /**
     * Leave search mode and fall back to the local strip, re-centring on the
     * wallpaper currently on screen. Used by Escape, an emptied query and a
     * completed download.
     */
    function exitSearch() {
        searching = false;
        query = "";
        ddgResults = [];
        searchField.text = "";
        centerOnCurrent();
    }

    /**
     * Begin a search seeded with the first typed character and move keyboard
     * focus to the field so the rest of the query lands there. shell.qml routes
     * the opening keystroke here and hands focus back when the search ends.
     */
    function startSearch(ch) {
        searching = true;
        focusIndex = 0;
        pos = 0;
        searchField.text = ch;
        Qt.callLater(searchField.input.forceActiveFocus);
    }

    onActiveChanged: if (active) {
        searching = false;
        query = "";
        ddgResults = [];
        searchField.text = "";
        Walls.refresh();
        centerOnCurrent();
        hintShown = false;
        hintDwell.restart();
    }

    Connections {
        target: Walls
        function onEntriesChanged() {
            if (!root.searching && root.focusIndex >= Walls.count)
                root.focusIndex = Math.max(0, Walls.count - 1);
            if (root.active)
                root.centerOnCurrent();
        }
        function onCurrentChanged() {
            if (root.active)
                root.centerOnCurrent();
        }
    }

    readonly property string searchScript: Quickshell.env("RICE_HOME") + "/hypr/scripts/wallpaper-search.sh"

    Timer {
        id: debounce
        interval: 350
        onTriggered: {
            if (root.query.length === 0) {
                root.ddgResults = [];
                return;
            }
            searchProc.command = ["bash", root.searchScript, "search", root.query];
            searchProc.running = true;
        }
    }

    Process {
        id: searchProc
        stdout: StdioCollector {
            onStreamFinished: {
                var out = [];
                try {
                    var parsed = JSON.parse(this.text);
                    if (Array.isArray(parsed))
                        out = parsed;
                } catch (e) {
                    out = [];
                }
                root.ddgResults = out;
                root.focusIndex = 0;
                root.pos = 0;
            }
        }
    }

    Process {
        id: dlProc
        property string target: ""
        property string failed: ""
        property string savedPath: ""
        stdout: StdioCollector {
            onStreamFinished: dlProc.savedPath = this.text.trim()
        }
        onExited: function(exitCode) {
            if (exitCode === 0 && savedPath.length) {
                failed = "";
                Walls.refresh();
                Walls.apply(savedPath);
                root.exitSearch();
            } else {
                failed = target;
            }
            savedPath = "";
        }
    }

    /// Regenerates the color scheme from the newly-picked backdrop image when
    /// backdropThemeColors is enabled (after-wall.sh swaps the source itself).
    Process {
        id: backdropColorProc
        onExited: (code) => {
            if (Flags.debug) console.log("[Wallpaper] Backdrop color regen exited:", code)
        }
    }

    SearchField {
        id: searchField
        anchors.top: parent.top
        anchors.topMargin: 6 * root.s
        anchors.left: parent.left
        anchors.leftMargin: 20 * root.s
        anchors.right: parent.right
        anchors.rightMargin: 20 * root.s
        s: root.s
        kanji: ""
        placeholder: "Search wallpapers"
        visible: root.searching
        enabled: root.searching
        horizontalNav: true
        z: 30
        onTextChanged: {
            root.query = text;
            debounce.restart();
        }
        onMoved: (d) => root.move(d)
        onAccepted: root.activate()
        onDismissed: root.exitSearch()
        onKeyPressed: (e) => {
            if (e.key === Qt.Key_Backspace && root.query.length <= 1 && searchField.input.selectedText.length === 0) {
                root.exitSearch();
                e.accepted = true;
            }
        }
    }

    Text {
      anchors.left: parent.left
      anchors.leftMargin: 20 * root.s
      anchors.verticalCenter: parent.verticalCenter
      z: 0
      visible: !root.searching
        color: Theme.ghost
        opacity: 0.55
        font.family: Theme.fontJp
        font.weight: Font.Medium
        font.pixelSize: 30 * root.s
    }

    Repeater {
        // Fixed 13-slot window: slot 6 rides the chase anchor (windowAnchor),
        // the rest fan out to |offset| 6 — past the visible range (opacity
        // hits 0 at 5), so slots slide in and out without ever resetting the
        // model. The old full-library model built one delegate tree per
        // wallpaper on open; on a thousand-entry library that stalled the
        // morph before it started and starved the async thumbnail decodes.
        model: 13

        delegate: Item {
            id: tile

            required property int index

            /** Library index this slot renders; null past either strip end. */
            readonly property int wallIndex: root.windowAnchor + index - 6
            readonly property var entry: root.items[wallIndex] ?? null

            readonly property string thumb: entry && entry.thumb !== undefined ? entry.thumb : ""
            readonly property bool remote: entry !== null && entry.image !== undefined
            readonly property string thumbSource: remote ? thumb : ("file://" + thumb)

            readonly property real off: wallIndex - root.pos
            readonly property real ao: Math.abs(off)
            readonly property bool focused: Math.round(root.pos) === wallIndex

            /**
             * Hit-test focus, mirroring the reference strip: true the moment
             * focusIndex points here, even while pos is still gliding. Input
             * (press/release/click) keys off this so a tap on the arriving
             * tile counts immediately; `focused` above stays pos-driven for
             * visuals so the shadow rides the glide instead of jumping.
             */
            readonly property bool selected: root.focusIndex === wallIndex

            readonly property real bright: root.slotLerp(root.slotBright, ao)
            readonly property real sat: root.slotLerp(root.slotSat, ao)
            readonly property real corner: (8 + 2 * Math.max(0, 1 - ao)) * root.s

            readonly property real hold: trashHeat.hold
            readonly property bool committing: trashHeat.hold >= trashHeat.tapThreshold
            readonly property real commitProgress: Math.max(0, (trashHeat.hold - trashHeat.tapThreshold) / (1 - trashHeat.tapThreshold))

            /**
             * Fade a tile out as its outer edge nears the clipped strip
             * boundary, so the strip ends soften instead of getting hard-cut by
             * the pill's clip.
             */
            readonly property real edgeFade: {
                var soft = 70 * root.s;
                var gap = Math.min(x, root.width - (x + width));
                return Math.max(0, Math.min(1, gap / soft));
            }

            width: root.slotLerp(root.slotW, ao) * root.s
            height: root.slotLerp(root.slotH, ao) * root.s
            x: root.width / 2 + root.offsetX(off) - width / 2
            y: (root.height - height) / 2
            z: 10 - ao
            // entry null past either strip end: the slot hides entirely, the
            // same way the old full-array model simply had no delegate there.
            visible: entry !== null && ao <= 5
            opacity: edgeFade * (ao <= 4 ? 1 : Math.max(0, 5 - ao))

            onFocusedChanged: if (!focused) trashHeat.cancel()

            // Slots are reused as the anchor moves: when this slot is handed
            // to a different wallpaper, any trash heat it was carrying dies
            // with the press — a mid-glide meter must never land on (and
            // trash) the wallpaper that slid into the slot.
            onWallIndexChanged: if (trashHeat.holding) trashHeat.cancel()

            ClippingRectangle {
                id: card
                anchors.fill: parent
                radius: tile.corner
                color: Theme.tileBg

                layer.enabled: true
                layer.effect: MultiEffect {
                    saturation: tile.sat - 1
                    shadowEnabled: tile.focused
                    shadowColor: Qt.rgba(0, 0, 0, Theme.shadowOpacity)
                    shadowBlur: 0.7
                    shadowVerticalOffset: 4 * root.s
                }

                Image {
                    id: thumbImage
                    anchors.fill: parent
                    source: tile.entry && tile.ao <= 6 ? tile.thumbSource : ""
                    sourceSize.width: 512
                    sourceSize.height: 220
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                }

                Rectangle {
                    anchors.fill: parent
                    color: Theme.tileBg
                    visible: thumbImage.status === Image.Error
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 1)
                    opacity: 1 - tile.bright
                }

                Rectangle {
                    id: consume
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: card.height * tile.commitProgress
                    visible: tile.committing
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.alpha(Theme.vermBurn, 0.66) }
                        GradientStop { position: 0.74; color: Qt.alpha(Theme.vermLit, 0.30) }
                        GradientStop { position: 1.0; color: Qt.alpha(Theme.flameGlow, 0.0) }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: 2 * root.s
                        opacity: Math.min(1, tile.commitProgress * 3)
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Qt.alpha(Theme.flameGlow, 0.0) }
                            GradientStop { position: 0.5; color: Theme.flameGlow }
                            GradientStop { position: 1.0; color: Qt.alpha(Theme.flameGlow, 0.0) }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: tile.focused && tile.remote && dlProc.running && dlProc.target === tile.entry.image
                    text: "saving…"
                    color: Theme.cream
                    font.family: Theme.font
                    font.pixelSize: 11 * root.s
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 6 * root.s
                    visible: tile.focused && tile.remote && tile.entry.w > 0 && !(dlProc.running && dlProc.target === tile.entry.image)
                    width: resText.implicitWidth + 12 * root.s
                    height: resText.implicitHeight + 5 * root.s
                    radius: height / 2
                    color: Qt.rgba(0, 0, 0, 0.55)
                    Text {
                        id: resText
                        anchors.centerIn: parent
                        text: tile.entry ? (tile.entry.w + "×" + tile.entry.h) : ""
                        color: Theme.bright
                        font.family: Theme.font
                        font.pixelSize: 9.5 * root.s
                        font.features: { "tnum": 1 }
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: tile.corner
                color: "transparent"
                border.width: 1
                border.color: {
                    if (tile.remote && dlProc.failed.length && dlProc.failed === tile.entry.image)
                        return Theme.vermLit;
                    return tile.committing ? Theme.vermLit : Theme.border;
                }
                Behavior on border.color { ColorAnimation { duration: Motion.fast } }
            }

            HeatHold {
                id: trashHeat
                tapThreshold: 0.25
                enabled: !tile.remote
                onConfirmed: if (tile.entry && !tile.remote) Walls.trash(tile.entry.path)
                onTapped: {
                    root.activate();
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: {
                    // Only the centered wallpaper answers a press (reference
                    // semantics): arming the trash heat on a neighbour used to
                    // leave the fill running after a quick tap-release during
                    // the glide — it completed on its own and trashed whatever
                    // wallpaper the slot had re-bound to.
                    if (!tile.selected)
                        return;
                    if (tile.remote)
                        root.activate();
                    else
                        trashHeat.press();
                }
                onReleased: if (tile.selected && !tile.remote) trashHeat.release()
                onExited: trashHeat.cancel()
                onClicked: if (!tile.selected) root.focusIndex = tile.wallIndex
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: root.itemCount === 0 && !searchProc.running
        text: {
            if (!root.searching)
                return "No wallpapers in ~/Pictures/Wallpapers";
            return root.query.length ? "no results" : "No wallpapers in ~/Pictures/Wallpapers";
        }
        color: Theme.faint
        font.family: Theme.font
        font.pixelSize: 10.5 * root.s
    }

    Text {
        anchors.centerIn: parent
        visible: searchProc.running
        text: "searching…"
        color: Theme.faint
        font.family: Theme.font
        font.pixelSize: 10.5 * root.s
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 11 * root.s
        visible: root.itemCount > 0 && !root.searching
        opacity: root.hintShown ? 1 : 0
        text: "scroll to set · hold to delete"
        color: Theme.subtle
        font.family: Theme.font
        font.pixelSize: 10 * root.s
        font.weight: Font.Medium
        font.letterSpacing: 0.4 * root.s
        Behavior on opacity { NumberAnimation { duration: Motion.standard } }
    }

    MouseArea {
        id: wheelArea
        anchors.fill: parent
        z: 20
        acceptedButtons: Qt.NoButton
        property real acc: 0
        onWheel: (event) => {
            acc += event.angleDelta.y / 120;
            const notches = Math.trunc(acc);
            if (notches !== 0) {
                root.move(-notches);
                acc -= notches;
            }
            event.accepted = true;
        }
    }
}
