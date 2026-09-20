import QtQuick
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Io
import qs.compositor
import qs.services as QsServices
import "Singletons"

Item {
    id: root

    property real s: 1
    property string screenName: ""
    property bool suppressed: false
    property bool flashing: false
    property string kind: "volume"
    property bool armed: false
    property string shownTrackLine: ""
    property bool shownPlaying: false
    property string shownArtUrl: ""
    property string lastTrackLine: ""
    property bool lastPlaying: false
    property real brightness: 0
    property int lastBrightness: -1
    property bool recordStarted: false

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    // Absolute volume that can exceed 1 when the safe max is raised; the bar
    // below normalises against Audio.effectiveMax instead of hard-clamping.
    readonly property real volume: sink && sink.audio ? Math.max(0, sink.audio.volume) : 0

    property var stickyPlayer: null
    readonly property var player: {
        var list = Mpris.players.values;
        // Skip the internal skwd-music endpoint — same exclusion Media.qml and
        // Pill.mediaPlaying apply, so the OSD never advertises a sign-off track.
        list = list.filter(function(p) { return p && p.identity !== "skwd-music"; });
        if (!list || list.length === 0)
            return null;
        for (var i = 0; i < list.length; i++) {
            if (list[i] && list[i].isPlaying)
                return list[i];
        }
        if (stickyPlayer && list.indexOf(stickyPlayer) >= 0)
            return stickyPlayer;
        return list[0];
    }
    readonly property bool playing: player !== null && player.isPlaying
    readonly property string trackLine: {
        if (!player)
            return "";
        var t = player.trackTitle ? player.trackTitle : "";
        var a = Theme.joinArtists(player.trackArtists, player.trackArtist);
        return a.length > 0 ? t + " — " + a : t;
    }

    readonly property real desiredW: kind === "workspace" ? Math.max(120 * s, wsIndicator.implicitWidth + 40 * s)
        : (kind === "track" ? 332 * s : (kind === "record" ? 256 * s : 248 * s))
    readonly property real desiredH: kind === "track" ? 56 * s : 44 * s

    /**
     * Active workspace name on this monitor. Any switch (Super+arrow,
     * Super+wheel, clicking a dot) changes it, so flashing the workspace OSD
     * here briefly morphs the pill open to show where you landed. The arm timer
     * swallows the initial populate, so login doesn't flash.
     */
    readonly property string activeWsName: {
        var mons = Compositor.monitors;
        for (var i = 0; i < mons.length; i++)
            if (mons[i].name === screenName)
                return mons[i].activeWorkspace ? mons[i].activeWorkspace.name : "";
        return "";
    }
    onActiveWsNameChanged: if (activeWsName.length > 0) flash("workspace");

    function trackEvent() {
        var line = trackLine;
        var p = playing;
        if (line === lastTrackLine && p === lastPlaying)
            return;
        lastTrackLine = line;
        lastPlaying = p;
        flash("track");
    }

    function flash(which) {
        if (!armed || suppressed || cooldownTimer.running)
            return;
        if (which === "track") {
            shownTrackLine = trackLine;
            shownPlaying = playing;
            shownArtUrl = player && player.trackArtUrl ? player.trackArtUrl : "";
        }
        kind = which;
        flashing = true;
        hideTimer.interval = (which === "battery" || which === "record") ? 2000 : 1400;
        hideTimer.restart();
    }

    onSuppressedChanged: {
        if (suppressed) {
            hideTimer.stop();
            flashing = false;
        } else {
            cooldownTimer.restart();
        }
    }

    Timer {
        interval: 1500
        running: true
        onTriggered: root.armed = true
    }

    Timer {
        id: hideTimer
        interval: 1400
        onTriggered: root.flashing = false
    }

    Timer {
        id: cooldownTimer
        interval: 200
    }

    PwObjectTracker {
        objects: [root.sink].filter(Boolean)
    }

    Connections {
        target: root.sink && root.sink.audio ? root.sink.audio : null
        function onVolumesChanged() { root.flash("volume"); }
        function onMutedChanged() { root.flash("volume"); }
    }

    onPlayerChanged: {
        Qt.callLater(function() {
            if (stickyPlayer !== player)
                stickyPlayer = player;
        });
        trackEvent();
    }

    Connections {
        target: root.player
        function onTrackTitleChanged() { root.trackEvent(); }
        function onPlaybackStateChanged() { root.trackEvent(); }
    }

    Connections {
        target: Battery
        enabled: Battery.present
        function onChargingChanged() {
            if (Battery.charging)
                root.flash("battery");
        }
    }

    Connections {
        target: ScreenRec
        function onRecordingChanged() {
            root.recordStarted = ScreenRec.recording;
            root.flash("record");
        }
    }

    Process {
        id: brightMonitor
        command: ["sh", "-c", "dev=$(ls /sys/class/backlight 2>/dev/null | head -n1); [ -n \"$dev\" ] || exit 0; max=$(cat /sys/class/backlight/$dev/max_brightness); last=\"\"; while true; do val=$(cat /sys/class/backlight/$dev/brightness); if [ \"$val\" != \"$last\" ]; then echo \"$(( val * 100 / max ))\"; last=\"$val\"; fi; sleep 0.4; done"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                var pct = parseInt(line.trim(), 10);
                if (isNaN(pct))
                    return;
                var seen = root.lastBrightness >= 0;
                root.brightness = Math.max(0, Math.min(100, pct)) / 100.0;
                root.lastBrightness = pct;
                if (seen)
                    root.flash("brightness");
            }
        }
    }

    Item {
        id: volRow
        anchors.fill: parent
        opacity: root.kind === "volume" ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 150 } }

        GlyphIcon {
            id: volGlyph
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 17 * root.s
            height: 17 * root.s
            name: root.muted ? "speaker-off" : "speaker"
            color: root.muted ? Theme.dim : Theme.iconDim
            stroke: 1.7
        }

        Text {
            id: volPct
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 32 * root.s
            horizontalAlignment: Text.AlignRight
            text: Math.round(root.volume * 100) + "%"
            color: root.muted ? Theme.dim : Theme.cream
            font.family: Theme.font
            font.pixelSize: 11 * root.s
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }

        Rectangle {
            id: volTrack
            anchors.left: volGlyph.right
            anchors.leftMargin: 12 * root.s
            anchors.right: volPct.left
            anchors.rightMargin: 12 * root.s
            anchors.verticalCenter: parent.verticalCenter
            height: 4 * root.s
            radius: 2 * root.s
            color: Theme.threadBg

            /**
             * Animated position of the 100% mark on the track, as a fraction of
             * the track width. At rest it is 1.0 — the whole track IS the first
             * hundred percent, exactly the old display. The moment volume climbs
             * past 100 (and the safe max allows boost), it eases down to
             * 1/effectiveMax, so the 0-100 segment smoothly shrinks and makes
             * room for the 100-max zone to land in; the track's total length
             * never changes. Dropping back to 100 or below eases it out again.
             */
            readonly property bool boostLive: root.volume > 1.001 && QsServices.Audio.effectiveMax > 1.001
            property real hundredMark: boostLive ? 1.0 / QsServices.Audio.effectiveMax : 1.0
            Behavior on hundredMark {
                NumberAnimation { duration: Motion.standard; easing.type: Motion.easeStandard }
            }

            Rectangle {
                id: volFill
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                // 0-100 segment maps to `hundredMark` of the track; the boost
                // zone maps to whatever remains. With a 100 safe max this
                // reduces to the old min(1, volume) exactly.
                width: parent.width * (function () {
                    var em = QsServices.Audio.effectiveMax
                    var k = volTrack.hundredMark
                    if (em <= 1.001)
                        return Math.min(1, root.volume)
                    if (root.volume <= 1.0)
                        return Math.min(1, root.volume) * k
                    return k + (Math.min(root.volume, em) - 1.0) / (em - 1.0) * (1.0 - k)
                })()
                radius: parent.radius
                color: root.muted ? Theme.vermDim : Theme.vermLit
                Behavior on width { NumberAnimation { duration: Motion.fast } }
                Behavior on color { ColorAnimation { duration: Motion.fast } }
            }

            // Faint tick where 100% lands once the track re-seats — makes the
            // boost zone readable instead of the fill just stopping early.
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: parent.width * volTrack.hundredMark - width / 2
                width: 1.5 * root.s
                height: 8 * root.s
                radius: width / 2
                color: Theme.faint
                opacity: volTrack.boostLive ? 0.55 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: Motion.standard } }
            }
        }
    }

    Item {
        id: trackRow
        anchors.fill: parent
        opacity: root.kind === "track" ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 150 } }

        ClippingRectangle {
            id: coverBox
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 30 * root.s
            height: 30 * root.s
            radius: 8 * root.s
            color: Theme.tileBg

            Image {
                id: cover
                anchors.fill: parent
                source: root.shownArtUrl
                fillMode: Image.PreserveAspectCrop
                // Cover art decodes at 4x the 30px slot, not native res
                // (skill-audit roundup step 2).
                sourceSize: Qt.size(128, 128)
                asynchronous: true
                cache: true
                visible: status === Image.Ready && root.shownArtUrl !== ""
            }
            GlyphIcon {
                anchors.centerIn: parent
                width: parent.width * 0.45
                height: width
                name: "music"
                color: Theme.subtle
                visible: !cover.visible
            }
        }

        GlyphIcon {
            id: trackGlyph
            anchors.left: coverBox.right
            anchors.leftMargin: 11 * root.s
            anchors.verticalCenter: parent.verticalCenter
            width: 16 * root.s
            height: 16 * root.s
            name: root.shownPlaying ? "play-s" : "pause-s"
            color: Theme.iconDim
            stroke: 1.7
        }

        Text {
            anchors.left: trackGlyph.right
            anchors.leftMargin: 10 * root.s
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.shownTrackLine
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 11.5 * root.s
            font.weight: Font.DemiBold
            maximumLineCount: 1
            elide: Text.ElideRight
        }
    }

    Item {
        id: brightRow
        anchors.fill: parent
        opacity: root.kind === "brightness" ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 150 } }

        GlyphIcon {
            id: brightGlyph
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 17 * root.s
            height: 17 * root.s
            name: "sun"
            color: Theme.iconDim
            stroke: 1.7
        }

        Text {
            id: brightPct
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 32 * root.s
            horizontalAlignment: Text.AlignRight
            text: Math.round(root.brightness * 100) + "%"
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 11 * root.s
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }

        Rectangle {
            anchors.left: brightGlyph.right
            anchors.leftMargin: 12 * root.s
            anchors.right: brightPct.left
            anchors.rightMargin: 12 * root.s
            anchors.verticalCenter: parent.verticalCenter
            height: 4 * root.s
            radius: 2 * root.s
            color: Theme.threadBg

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * root.brightness
                radius: parent.radius
                color: Theme.vermLit
                Behavior on width { NumberAnimation { duration: Motion.fast } }
            }
        }
    }

    Item {
        id: batteryRow
        anchors.fill: parent
        opacity: root.kind === "battery" ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 150 } }

        GlyphIcon {
            id: battGlyph
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 17 * root.s
            height: 17 * root.s
            name: "bolt"
            color: Theme.flameGlow
            stroke: 1.7
        }

        Text {
            id: battPct
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 40 * root.s
            horizontalAlignment: Text.AlignRight
            text: Battery.pct + "%"
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 11 * root.s
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }

        Rectangle {
            anchors.left: battGlyph.right
            anchors.leftMargin: 12 * root.s
            anchors.right: battPct.left
            anchors.rightMargin: 12 * root.s
            anchors.verticalCenter: parent.verticalCenter
            height: 4 * root.s
            radius: 2 * root.s
            color: Theme.threadBg
            clip: true

            Rectangle {
                id: battFill
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * Battery.frac
                radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Theme.vermDeep }
                    GradientStop { position: 1.0; color: Theme.flameGlow }
                }
                Behavior on width { NumberAnimation { duration: Motion.fast } }

                Rectangle {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 34 * root.s
                    color: "transparent"
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#00ffffff" }
                        GradientStop { position: 0.5; color: "#55ffe6d6" }
                        GradientStop { position: 1.0; color: "#00ffffff" }
                    }

                    NumberAnimation on x {
                        from: -34 * root.s
                        to: battFill.width
                        duration: 1200
                        loops: Animation.Infinite
                        running: root.kind === "battery" && Battery.charging
                    }
                }
            }
        }
    }

    Item {
        id: workspaceRow
        anchors.fill: parent
        opacity: root.kind === "workspace" ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Workspaces {
            id: wsIndicator
            anchors.centerIn: parent
            screenName: root.screenName
            s: root.s
            gap: 8 * root.s
            enabled: false
        }
    }

    Item {
        id: recordRow
        anchors.fill: parent
        opacity: root.kind === "record" ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Rectangle {
            id: recGlyph
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 13 * root.s
            height: 13 * root.s
            radius: width / 2
            color: root.recordStarted ? Theme.verm : Theme.dim

            SequentialAnimation on opacity {
                running: root.recordStarted && root.kind === "record"
                loops: Animation.Infinite
                NumberAnimation { to: 0.4; duration: 500; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 500; easing.type: Easing.InOutSine }
            }
        }

        Text {
            anchors.left: recGlyph.right
            anchors.leftMargin: 13 * root.s
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.recordStarted ? "Recording started" : "Recording stopped"
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 11.5 * root.s
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}
