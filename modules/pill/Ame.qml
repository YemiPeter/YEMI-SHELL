pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import "Singletons"

/**
 * 飴 Ame, the shapeshifter. One molten-glass bead, the shell's only glowing
 * element. Idle it just breathes (2.5% scale over ~8s). No music/audio/physics
 * coupling; every motion is a fixed, scripted timeline.
 *
 * Travel: a form change runs the full shapeshift over Motion.shapeshift ms.
 * anticipation stretch, a remnant droplet pinching off at the origin, a
 * quadratic-bezier flight with a tapered streak, a three-droplet landing splash,
 * then an easeOutBack settle into the new form. The flight launches once and
 * tracks a moving target live (bezier endpoint, control point and heading
 * recomputed per frame), so anchors that slide with the pill's 320ms morph bend
 * the arc, no restart. Short-distance form change skips travel and plays the
 * settle in place. Same-form target moves (hover width, seam progress, mixer
 * focus hops, seeks) glide over Motion.glide ms, chasing the anchor, never
 * escalating to a flight.
 *
 * Forms: "rest" breathing bead, "caret" blinking launcher capsule, "seam" media
 * bead, "ring" calendar ring, "dock" plain bead (mixer/power/link), "off"
 * hidden. Entering "off" fades out over Motion.fast ms; leaving it snaps to
 * the current anchor and pops back with the settle, so toast/OSD handoffs don't
 * ghost-fly from stale positions. Body draws on a QtQuick Canvas: FrameAnimation
 * drives full-rate repaint only while the timeline, splash, remnant or a glide
 * is live; otherwise a Timer ticks the slow inner swirl at 12fps (30fps while
 * the caret blinks) to keep idle cost low for a 24/7 shell.
 */
Item {
    id: root

    property real s: 1
    property point point: Qt.point(0, 0)
    property string form: "rest"
    property real heat: 0
    property point wake: Qt.point(0, 0)
    property real wickDir: -1

    opacity: form === "off" ? 0 : 1
    Behavior on opacity { NumberAnimation { duration: Motion.fast } }
    visible: opacity > 0.001

    readonly property real restR: 5 * s
    readonly property real heatScale: 1 - 0.4 * heat
    readonly property real flightThreshold: 30 * s
    readonly property real pAntic: 0.146
    readonly property real pFly: 0.658

    property real bx: 0
    property real by: 0
    property string activeForm: "rest"
    property bool hidden: false
    property bool arcFlip: false
    property bool quickFlight: false
    property point lastTarget: Qt.point(0, 0)

    property real prog: 1
    property real travelProg: 0
    property real settleProg: 0
    property real splashProg: 0
    property real remnantProg: 0
    property real glideProg: 1
    property real caretBlink: 0
    property int caretDir: 1
    property real swirl: 0
    property real heatPulse: 0

    x: point.x - restR
    y: point.y - restR
    width: restR * 2
    height: restR * 2

    Behavior on x { NumberAnimation { duration: Motion.glide; easing.type: Motion.easeStandard } }
    Behavior on y { NumberAnimation { duration: Motion.glide; easing.type: Motion.easeStandard } }

    onFormChanged: {
        if (form === "off") {
            hidden = true;
            return;
        }
        if (hidden) {
            hidden = false;
            bx = point.x;
            by = point.y;
            prog = 0;
            settleProg = 0;
            travelProg = 0;
            settleAnim.restart();
            return;
        }
        if (activeForm === form) {
            // Same form — glide to new position
            lastTarget = point;
            glideProg = 0;
            glideAnim.restart();
            return;
        }
        // Form change — full shapeshift
        activeForm = form;
        prog = 0;
        travelProg = 0;
        settleProg = 0;
        splashProg = 0;
        remnantProg = 0;
        bx = point.x;
        by = point.y;
        const dist = Math.sqrt(Math.pow(point.x - bx, 2) + Math.pow(point.y - by, 2));
        if (dist > flightThreshold) {
            quickFlight = false;
            travelAnim.restart();
        } else {
            quickFlight = true;
            settleAnim.restart();
        }
    }

    onPointChanged: {
        if (hidden || form === "off") return;
        if (activeForm === form && prog >= 1) {
            lastTarget = point;
            glideProg = 0;
            glideAnim.restart();
        }
    }

    onHeatChanged: {
        if (heat > 0) {
            heatPulse = 0;
            heatAnim.restart();
        }
    }

    // Idle breathing
    Timer {
        id: idleTimer
        interval: 80
        running: !hidden && form !== "off" && prog >= 1 && travelProg >= 1 && settleProg >= 1
        repeat: true
        onTriggered: {
            swirl += 0.08;
            if (swirl > Math.PI * 2) swirl -= Math.PI * 2;
        }
    }

    // Caret blink (launcher)
    Timer {
        id: caretTimer
        interval: 50
        running: activeForm === "caret" && prog >= 1
        repeat: true
        onTriggered: {
            caretBlink += 0.12 * caretDir;
            if (caretBlink >= 1) { caretBlink = 1; caretDir = -1; }
            if (caretBlink <= 0) { caretBlink = 0; caretDir = 1; }
        }
    }

    // Heat pulse
    Timer {
        id: heatTimer
        interval: 60
        running: heat > 0 && prog >= 1
        repeat: true
        onTriggered: {
            heatPulse += 0.1;
            if (heatPulse > Math.PI * 2) heatPulse -= Math.PI * 2;
        }
    }

    // Frame animation for canvas
    FrameAnimation {
        id: frameAnim
        running: prog < 1 || travelProg < 1 || settleProg < 1 || splashProg > 0 || remnantProg > 0 || glideProg < 1
        onTriggered: beadCanvas.requestPaint()
    }

    // --- Animations ---

    SequentialAnimation {
        id: travelAnim
        NumberAnimation { target: root; property: "prog"; to: 1; duration: 100; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "travelProg"; to: 1; duration: Motion.shapeshift; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.16, 1, 0.3, 1, 1, 1] }
        NumberAnimation { target: root; property: "splashProg"; to: 1; duration: 180; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "remnantProg"; to: 1; duration: 200; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "settleProg"; to: 1; duration: 280; easing.type: Easing.OutBack }
    }

    SequentialAnimation {
        id: settleAnim
        NumberAnimation { target: root; property: "prog"; to: 1; duration: 80; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "settleProg"; to: 1; duration: 260; easing.type: Easing.OutBack }
    }

    SequentialAnimation {
        id: glideAnim
        NumberAnimation { target: root; property: "glideProg"; to: 1; duration: Motion.glide; easing.type: Motion.easeStandard }
    }

    SequentialAnimation {
        id: heatAnim
        loops: Animation.Infinite
        NumberAnimation { target: root; property: "heatPulse"; to: Math.PI * 2; duration: 600; easing.type: Easing.InOutSine }
    }

    // --- Canvas ---

    Canvas {
        id: beadCanvas
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const cx = width / 2;
            const cy = height / 2;
            const R = restR * heatScale;

            if (hidden || form === "off") return;

            // Idle breathing
            const breath = 1 + Math.sin(swirl) * 0.025;
            const drawR = R * breath;

            // Glow
            const glowGrad = ctx.createRadialGradient(cx, cy, drawR * 0.3, cx, cy, drawR * 1.8);
            glowGrad.addColorStop(0, Qt.alpha(Theme.flameGlow, 0.3));
            glowGrad.addColorStop(1, "transparent");
            ctx.beginPath();
            ctx.arc(cx, cy, drawR * 1.8, 0, Math.PI * 2);
            ctx.fillStyle = glowGrad;
            ctx.fill();

            // Body
            const bodyGrad = ctx.createRadialGradient(cx - drawR * 0.3, cy - drawR * 0.3, 0, cx, cy, drawR);
            bodyGrad.addColorStop(0, Theme.flameCore);
            bodyGrad.addColorStop(0.7, Theme.flameGlow);
            bodyGrad.addColorStop(1, Theme.verm);
            ctx.beginPath();
            ctx.arc(cx, cy, drawR, 0, Math.PI * 2);
            ctx.fillStyle = bodyGrad;
            ctx.fill();

            // Heat highlight
            if (heat > 0) {
                const hAlpha = 0.3 + Math.sin(heatPulse) * 0.15;
                ctx.beginPath();
                ctx.arc(cx, cy, drawR * 1.1, 0, Math.PI * 2);
                ctx.fillStyle = Qt.alpha(Theme.flameGlow, hAlpha);
                ctx.fill();
            }
        }
    }
}
